-- BanditsAIOverhaul NPC World Adapter V0.3: server-owned networked test shell.
local Adapter = { VERSION = "0.3", lastProbe = nil, owned = nil }

local function Log(message)
    print("[BAO][NPCWorldAdapter] " .. tostring(message))
end

local function HasMethod(owner, method)
    if owner == nil then return false end
    local ok, value = pcall(function() return owner[method] end)
    return ok and value ~= nil
end

function Adapter.Probe()
    local report = {
        survivorFactory = _G.SurvivorFactory ~= nil,
        createSurvivor = HasMethod(_G.SurvivorFactory, "CreateSurvivor"),
        instantiateInCell = HasMethod(_G.SurvivorFactory, "InstansiateInCell"),
        isoSurvivor = _G.IsoSurvivor ~= nil,
        isoSurvivorNew = HasMethod(_G.IsoSurvivor, "new"),
        getCell = type(_G.getCell) == "function",
        zombieFactory = _G.addZombiesInOutfit ~= nil
    }
    report.ready = report.zombieFactory and report.getCell
    Adapter.lastProbe = report
    Log("API probe ready=" .. tostring(report.ready)
        .. " zombieFactory=" .. tostring(report.zombieFactory)
        .. " factory=" .. tostring(report.survivorFactory)
        .. " create=" .. tostring(report.createSurvivor)
        .. " instantiate=" .. tostring(report.instantiateInCell)
        .. " IsoSurvivor.new=" .. tostring(report.isoSurvivorNew)
        .. " getCell=" .. tostring(report.getCell))
    return report
end

function Adapter.GetLastProbe()
    return Adapter.lastProbe
end

BAO = BAO or {}
BAO.NPCWorldAdapter = Adapter

-- One experimental test shell per server. Keep ownership if cleanup fails.
local testId = "bao_world_test_001"
function Adapter.ReleaseDeadNPC(character)
    if _G.isClient and isClient() then return false end
    local entry = Adapter.owned
    if not entry or entry.character ~= character then return false end
    local binding = BAO.NPCRuntime.Get(testId)
    if binding and binding.character ~= character then return false end
    local navigation = BAO.NavigationSystem and BAO.NavigationSystem.GetCurrentNavigation()
    if navigation and navigation.character == character then
        if not BAO.NavigationSystem.Cancel("npc_died", navigation) then return false end
    end
    -- Death/corpse conversion belongs to the engine: release only BAO bookkeeping.
    BAO.NPCRuntime.Unbind(testId, character, "npc_died")
    if entry.createdData and BAO.NPCData.Get(testId) == entry.data then
        entry.data.isAlive = false
        entry.data.state = "dead"
        BAO.NPCData.Remove(testId)
    end
    Adapter.owned = nil
    Log("Test NPC died; spawn slot released")
    if _G.isServer and isServer() and _G.sendServerCommand then
        sendServerCommand("BAO_Debug", "world_status", {
            success = true, reason = "npc_died", snapshot = true
        })
    end
    return true
end

function Adapter.RemoveTestNPC()
    local entry = Adapter.owned
    if not entry then return false, "no_test_npc" end
    local binding = BAO.NPCRuntime.Get(testId)
    if binding and binding.character ~= entry.character then return false, "binding_changed" end
    local navigation = BAO.NavigationSystem and BAO.NavigationSystem.GetCurrentNavigation()
    if navigation and navigation.character == entry.character then
        return false, "npc_navigation_busy"
    end
    local ok, reason = pcall(function()
        if not entry.worldRemoved then
            entry.character:removeFromWorld()
            entry.worldRemoved = true
        end
        entry.character:removeFromSquare()
    end)
    if not ok then
        Log("Cleanup pending: " .. tostring(reason))
        return false, "cleanup_pending"
    end
    BAO.NPCRuntime.Unbind(testId, entry.character, "test_removed")
    if entry.createdData and BAO.NPCData.Get(testId) == entry.data then BAO.NPCData.Remove(testId) end
    Adapter.owned = nil
    Log("Test NPC removed")
    return true, "removed"
end

function Adapter.SpawnTestNPC(player, target)
    if _G.isClient and isClient() then
        return false, "server_authority_required"
    end
    -- Fallback if the server missed the death event; no polling or world scan.
    if Adapter.owned then
        local actor = Adapter.owned.character
        if actor.isDead and actor:isDead() then Adapter.ReleaseDeadNPC(actor) end
    end
    if Adapter.owned then return false, "test_npc_exists" end
    if not player or not BAO.NPCRuntime or not BAO.NPCData then return false, "dependencies_missing" end
    if BAO.NPCData.Exists(testId) then return false, "test_id_in_use" end
    if not _G.addZombiesInOutfit then return false, "factory_unavailable" end
    local cell = getCell()
    if not cell then return false, "cell_unavailable" end
    local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    if target then
        for _, key in ipairs({ "x", "y", "z" }) do
            local value = target[key]
            if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
                return false, "invalid_target"
            end
        end
        x, y, z = math.floor(target.x), math.floor(target.y), math.floor(target.z)
    end
    local square
    -- Bounded search, once per button click. Never runs on a tick.
    local offsets = { {2,0}, {-2,0}, {0,2}, {0,-2}, {2,2}, {-2,-2}, {2,-2}, {-2,2} }
    if target then offsets = { {0,0} } end
    for _, offset in ipairs(offsets) do
        local candidate = cell:getGridSquare(x + offset[1], y + offset[2], z)
        if candidate and candidate:isFree(false) and candidate:TreatAsSolidFloor() then
            square = candidate
            break
        end
    end
    if not square then return false, "no_free_square" end
    local character
    local ok, reason = pcall(function()
        -- Vanilla B42 API, also used by Bandits' B42 compatibility adapter.
        local list = addZombiesInOutfit(square:getX(), square:getY(), square:getZ(),
            1, nil, 0, false, false, false, false, true, false, 1)
        if list and list:size() > 0 then
            character = list:get(0)
            Adapter.owned = { character = character, createdData = false }
            character:setUseless(true)
            character:setTarget(nil)
            character:getModData().BAOTestShell = true
        end
    end)
    if not character then
        Log("Spawn failed: " .. tostring(reason))
        return false, "spawn_failed"
    end
    Adapter.owned = { character = character, createdData = false }
    if not ok then Adapter.RemoveTestNPC(); return false, "spawn_failed" end
    local npc = BAO.NPCData.Create(testId, "BAO Test NPC")
    if not npc then Adapter.RemoveTestNPC(); return false, "data_creation_failed" end
    Adapter.owned.createdData = true
    Adapter.owned.data = npc
    local bound = BAO.NPCRuntime.Bind(testId, character, { source = "debug_factory", ownedByBAO = true })
    if not bound then Adapter.RemoveTestNPC(); return false, "binding_failed" end
    Log("Test NPC spawned id=" .. testId .. " x=" .. tostring(character:getX())
        .. " y=" .. tostring(character:getY()) .. " z=" .. tostring(character:getZ()))
    return true, "spawned"
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(Adapter.Probe) end
if Events and Events.OnZombieDead then Events.OnZombieDead.Add(Adapter.ReleaseDeadNPC) end
Log("NPC World Adapter V0.3 loaded (server-owned zombie shell)")
