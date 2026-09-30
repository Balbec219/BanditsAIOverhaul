-- Client requests; only the server creates the networked shell.
BAO = BAO or {}
local Client = { active = nil, removed = nil, lastStatus = nil }
BAO.NPCWorldClient = Client

function Client.Request(spawn, player, target)
    if not player then return false, "player_unavailable" end
    if _G.isClient and isClient() then
        sendClientCommand(player, "BAO_Debug", spawn and "world_spawn" or "world_remove", target or {})
        return true, "request_sent"
    end
    if spawn then return BAO.NPCWorldAdapter.SpawnTestNPC(player, target) end
    return BAO.NPCWorldAdapter.RemoveTestNPC()
end

function Client.OnServerCommand(module, command, args)
    if module ~= "BAO_Debug" or command ~= "world_status" or type(args) ~= "table" then return end
    if args.snapshot then Client.active = args.active end
    Client.lastStatus = args
    if args.removed then Client.removed = args.removed end
    print("[BAO][NPCWorldClient] success=" .. tostring(args.success) .. " reason=" .. tostring(args.reason))
end

local function Matches(zombie, identity)
    return identity and zombie:getOnlineID() == identity.online
        and zombie:getPersistentOutfitID() == identity.outfit
end

function Client.OnZombieUpdate(zombie)
    if not Client.active and not Client.removed then return end
    if Matches(zombie, Client.removed) then
        zombie:removeFromWorld()
        zombie:removeFromSquare()
        return
    end
    if not Matches(zombie, Client.active) then return end
    if zombie.isDead and zombie:isDead() then return end
    -- Suppress vanilla decisions on the client that owns zombie simulation.
    -- One identity comparison per event; no world scan, path request or logging.
    zombie:setUseless(true)
    zombie:setTarget(nil)
end

if Events and Events.OnServerCommand then Events.OnServerCommand.Add(Client.OnServerCommand) end
if Events and Events.OnZombieUpdate then Events.OnZombieUpdate.Add(Client.OnZombieUpdate) end
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(_, player)
        if _G.isClient and isClient() then sendClientCommand(player, "BAO_Debug", "world_state", {}) end
    end)
end
