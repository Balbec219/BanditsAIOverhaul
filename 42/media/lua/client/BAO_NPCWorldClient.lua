-- Network presentation only. No decisions or paths are calculated here.
BAO = BAO or {}
local Client = { active = {}, removed = {}, lastStatus = nil, hasEntries = false }
local applied = setmetatable({}, { __mode = "k" })
BAO.NPCWorldClient = Client
function Client.Request(spawn, player, target)
    if not player then return false, "player_unavailable" end
    if _G["isClient"] and isClient() then
        sendClientCommand(player, "BAO_Debug", spawn and "world_spawn" or "world_remove", target or {})
        return true, "request_sent"
    end
    if spawn then return BAO.NPCWorldAdapter.SpawnTestNPC(player, target) end
    return BAO.NPCWorldAdapter.RemoveTestNPC()
end
local function Key(identity) return identity.online end
local function Now() return _G["getTimestampMs"] and getTimestampMs() / 1000 or os.time() end
function Client.OnServerCommand(module, command, args)
    if module ~= "BAO_Debug" or command ~= "world_status" or type(args) ~= "table" then return end
    if args.snapshot then
        Client.active = {}
        for _, identity in ipairs(args.active or {}) do Client.active[Key(identity)] = identity end
    end
    local now = Now()
    for key, notice in pairs(Client.removed) do if notice.expiry <= now then Client.removed[key] = nil end end
    for _, identity in ipairs(args.removed or {}) do
        Client.removed[Key(identity)] = { outfit = identity.outfit, expiry = now + 60 }
    end
    -- A currently active network identity takes precedence over old cleanup notices.
    for key in pairs(Client.active) do Client.removed[key] = nil end
    Client.hasEntries = next(Client.active) ~= nil or next(Client.removed) ~= nil
    Client.lastStatus = args
    print("[BAO][NPCWorldClient] success=" .. tostring(args.success) .. " reason=" .. tostring(args.reason)
        .. " spawned=" .. tostring(args.spawned or 0))
end
function Client.OnZombieUpdate(zombie)
    local identity
    if _G["isClient"] and isClient() then
        if not Client.hasEntries and not applied[zombie] then return end
        local key = zombie:getOnlineID()
        local notice = Client.removed[key]
        if notice then
            if notice.expiry > Now() then
                if zombie:getPersistentOutfitID() == notice.outfit then
                    zombie:removeFromWorld(); zombie:removeFromSquare(); return
                end
            else
                Client.removed[key] = nil
                Client.hasEntries = next(Client.active) ~= nil or next(Client.removed) ~= nil
            end
        end
        identity = Client.active[key]
        if identity and zombie:getPersistentOutfitID() ~= identity.outfit then identity = nil end
    else
        local adapter = BAO.NPCWorldAdapter
        identity = adapter and adapter.byCharacter[zombie]
    end
    if not identity then
        if applied[zombie] then zombie:setVariable("BAOHuman", false); applied[zombie] = nil end
        return
    end
    if zombie:isDead() then return end
    if applied[zombie] ~= identity.id then
        zombie:setVariable("BAOHuman", true)
        applied[zombie] = identity.id
    end
    zombie:setUseless(true)
    zombie:setTarget(nil)
end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(Client.OnServerCommand) end
if Events and Events.OnZombieUpdate then Events.OnZombieUpdate.Add(Client.OnZombieUpdate) end
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(_, player)
        if _G["isClient"] and isClient() then sendClientCommand(player, "BAO_Debug", "world_state", {}) end
    end)
end
