-- Offline authorization/routing tests, no real game objects.
local server, client = BAO.DebugServer, BAO.NPCWorldClient
local creates, removes, replies = 0, 0, 0
local last, chosen
isServer = function() return true end
isClient = function() return false end
sendServerCommand = function(a,b,c,d)
    replies = replies + 1
    last = d or c
end
local player = { getAccessLevel = function() return 'none' end,
    getX = function() return 10 end, getY = function() return 20 end, getZ = function() return 0 end }
local actor = { getOnlineID = function() return 123 end, getPersistentOutfitID = function() return 456 end }
BAO.NPCWorldAdapter = {
    SpawnTestNPC = function(_, target)
        creates = creates + 1; chosen = target
        BAO.NPCWorldAdapter.owned = { character = actor }
        return true, 'spawned'
    end,
    RemoveTestNPC = function()
        removes = removes + 1; BAO.NPCWorldAdapter.owned = nil; return true, 'removed'
    end
}
server.OnClientCommand('BAO_Debug','world_spawn',player,{})
assert(creates == 0 and last.reason == 'admin_required')
player.getAccessLevel = function() return 'admin' end
server.OnClientCommand('BAO_Debug','world_spawn',player,{x=0/0,y=20,z=0})
server.OnClientCommand('BAO_Debug','world_spawn',player,{x=1000,y=20,z=0})
assert(creates == 0)
server.OnClientCommand('BAO_Debug','world_spawn',player,{x=12,y=20,z=0})
assert(creates == 1 and chosen.x == 12 and last.active.online == 123)
client.OnServerCommand('BAO_Debug','world_status',last)
local suppressed = 0
actor.setUseless = function() suppressed = suppressed + 1 end
actor.setTarget = function() end
client.OnZombieUpdate(actor)
assert(suppressed == 1)
local foreign = { getOnlineID = function() return 999 end }
client.OnZombieUpdate(foreign)
assert(suppressed == 1)
server.OnClientCommand('BAO_Debug','world_state',player,{})
assert(last.snapshot and last.active.outfit == 456 and creates == 1)
server.OnClientCommand('BAO_Debug','world_remove',player,{})
assert(removes == 1 and last.removed.online == 123 and last.active == nil)
client.OnServerCommand('BAO_Debug','world_status',last)
local cleaned = 0
actor.removeFromWorld = function() cleaned = cleaned + 1 end
actor.removeFromSquare = function() cleaned = cleaned + 1 end
client.OnZombieUpdate(actor)
assert(cleaned == 2)
