-- Server-owned test bodies; AI remains in Decision/Action/Executor/Navigation.
BAO = BAO or {}
local Adapter = { VERSION = "0.4", entries = {}, byCharacter = {}, nextId = 1, MaxBatch = 20, MaxActive = 50 }
BAO.NPCWorldAdapter = Adapter
local function Log(message) print("[BAO][NPCWorldAdapter] " .. tostring(message)) end
local function Number(n) return type(n) == "number" and n == n and math.abs(n) ~= math.huge end
function Adapter.Count()
    local n = 0
    for _ in pairs(Adapter.entries) do n = n + 1 end
    return n
end
local function Identity(entry)
    return { id = entry.id, online = entry.character:getOnlineID(), outfit = entry.character:getPersistentOutfitID() }
end
function Adapter.GetSnapshot()
    local list = {}
    for _, entry in pairs(Adapter.entries) do list[#list + 1] = Identity(entry) end
    return list
end
local function Release(entry, reason)
    if BAO.NPCRuntime.IsBound(entry.id) then
        local ok = BAO.NPCRuntime.Unbind(entry.id, entry.character, reason)
        if not ok then return false end
    end
    if entry.data and BAO.NPCData.Get(entry.id) == entry.data then BAO.NPCData.Remove(entry.id) end
    Adapter.byCharacter[entry.character], Adapter.entries[entry.id] = nil, nil
    return true
end
function Adapter.ReleaseDeadNPC(character)
    if _G["isClient"] and isClient() then return false end
    local entry = Adapter.byCharacter[character]
    if not entry then return false end
    local binding = BAO.NPCRuntime.Get(entry.id)
    if binding and binding.character ~= character then return false end
    local navigation = BAO.NavigationSystem and BAO.NavigationSystem.GetCurrentNavigation()
    if navigation and navigation.character == character then
        if not BAO.NavigationSystem.Cancel("npc_died", navigation) then return false end
    end
    if not Release(entry, "npc_died") then return false end
    if _G["isServer"] and isServer() and _G["sendServerCommand"] then
        sendServerCommand("BAO_Debug", "world_status", { success = true, reason = "npc_died",
            snapshot = true, active = Adapter.GetSnapshot() })
    end
    Log("Death released " .. entry.id)
    return true
end
local function RemoveEntry(entry)
    local binding = BAO.NPCRuntime.Get(entry.id)
    if binding and binding.character ~= entry.character then return false, "binding_changed" end
    local navigation = BAO.NavigationSystem and BAO.NavigationSystem.GetCurrentNavigation()
    if navigation and navigation.character == entry.character then return false, "npc_navigation_busy" end
    if not BAO.NPCRuntime.StopAI(entry.id, "test_removed") then return false, "npc_ai_busy" end
    local identity = Identity(entry)
    local ok = pcall(function()
        if not entry.worldRemoved then entry.character:removeFromWorld(); entry.worldRemoved = true end
        entry.character:removeFromSquare()
    end)
    if not ok then entry.cleanupPending = true; return false, "cleanup_pending" end
    if not Release(entry, "test_removed") then return false, "npc_ai_busy" end
    return true, identity
end
function Adapter.RemoveTestNPC()
    if _G["isClient"] and isClient() then return false, "server_authority_required", {} end
    local pending, removed, failed = {}, {}, false
    for _, entry in pairs(Adapter.entries) do pending[#pending + 1] = entry end
    if #pending == 0 then return false, "no_test_npc", removed end
    for _, entry in ipairs(pending) do
        local ok, identity = RemoveEntry(entry)
        if ok then removed[#removed + 1] = identity else failed = true end
    end
    return not failed, failed and "partial_cleanup" or "removed", removed
end
function Adapter.SpawnTestNPC(player, target)
    if _G["isClient"] and isClient() then return false, "server_authority_required", 0 end
    if not player or not BAO.NPCRuntime or not BAO.NPCData then return false, "dependencies_missing", 0 end
    target = target or {}
    local count, radius = target.count or 1, target.radius or 0
    if not Number(count) or count % 1 ~= 0 or count < 1 or count > Adapter.MaxBatch
        or not Number(radius) or radius % 1 ~= 0 or radius < 0 or radius > 10 then
        return false, "invalid_count_or_radius", 0
    end
    local x, y, z = target.x, target.y, target.z
    if x == nil and y == nil and z == nil then
        x, y, z = math.floor(player:getX()) + 2, math.floor(player:getY()), math.floor(player:getZ())
    end
    if not Number(x) or not Number(y) or not Number(z) then return false, "invalid_target", 0 end
    x, y, z = math.floor(x), math.floor(y), math.floor(z)
    local dead = {}
    for character, entry in pairs(Adapter.byCharacter) do
        if entry.cleanupPending then return false, "cleanup_pending", 0 end
        if character:isDead() then dead[#dead + 1] = character end
    end
    for _, character in ipairs(dead) do Adapter.ReleaseDeadNPC(character) end
    if Adapter.Count() + count > Adapter.MaxActive then return false, "active_limit_50", 0 end
    if not _G["addZombiesInOutfit"] or not _G["getCell"] then return false, "factory_unavailable", 0 end
    local cell = getCell()
    if not cell then return false, "cell_unavailable", 0 end
    local spawned, failure = 0, nil
    for _ = 1, count do
        local sx = x + (radius > 0 and ZombRand(-radius, radius + 1) or 0)
        local sy = y + (radius > 0 and ZombRand(-radius, radius + 1) or 0)
        local square = cell:getGridSquare(sx, sy, z)
        -- Horde Manager allows several bodies on one tile; do not reject occupancy.
        if not square or not square:TreatAsSolidFloor() then failure = "square_unavailable"; break end
        local entry
        local ok, reason = pcall(function()
            local list = addZombiesInOutfit(sx, sy, z, 1, nil, 0,
                false, false, false, false, false, false, 1)
            if not list or list:size() == 0 then return "spawn_failed" end
            local actor = list:get(0)
            local id
            repeat
                id = "bao_world_test_" .. tostring(Adapter.nextId)
                Adapter.nextId = Adapter.nextId + 1
            until not BAO.NPCData.Exists(id)
            entry = { id = id, character = actor }
            Adapter.entries[id], Adapter.byCharacter[actor] = entry, entry
            actor:setUseless(true)
            actor:setTarget(nil)
            actor:setVariable("BAOHuman", true)
            actor:getModData().BAOTestShell = id
            entry.data = BAO.NPCData.Create(id, "BAO Test NPC")
            if not entry.data then return "data_creation_failed" end
            if not BAO.NPCRuntime.Bind(id, actor, { source = "debug_factory", ownedByBAO = true }) then
                return "binding_failed"
            end
        end)
        if not ok or reason then
            failure = ok and reason or "spawn_exception"
            if entry then RemoveEntry(entry) end
            break
        end
        spawned = spawned + 1
    end
    Log("Batch spawned=" .. spawned .. " requested=" .. count .. " active=" .. Adapter.Count())
    return failure == nil, failure or "spawned", spawned
end
function Adapter.Probe()
    Adapter.lastProbe = { ready = _G["addZombiesInOutfit"] ~= nil and _G["getCell"] ~= nil }
    Log("V0.4 factory ready=" .. tostring(Adapter.lastProbe.ready))
    return Adapter.lastProbe
end
function Adapter.GetLastProbe() return Adapter.lastProbe end
if Events and Events.OnGameStart then Events.OnGameStart.Add(Adapter.Probe) end
if Events and Events.OnZombieDead then Events.OnZombieDead.Add(Adapter.ReleaseDeadNPC) end
