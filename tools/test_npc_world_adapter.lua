-- Offline: real BAO adapter/runtime, synthetic engine objects.
---@diagnostic disable: lowercase-global
-- Intentional engine-global replacements in this isolated offline Lua VM.
local a = BAO.NPCWorldAdapter
BAO.Log = function() end
isServer = function() return false end
isClient = function() return false end
local actors, calls, removed, floor, failAt = {}, 0, 0, true, nil
local player = { getX=function() return 10 end, getY=function() return 10 end, getZ=function() return 0 end }
local tiles = {}
getCell = function() return { getGridSquare = function(_,x,y,z)
    tiles[#tiles+1]={x,y,z}
    return { TreatAsSolidFloor=function() return floor end,
        isFree=function() return false end }
end } end
addZombiesInOutfit = function(x,y,z)
    calls = calls + 1
    if calls == failAt then return {size=function() return 0 end} end
    local actor = {dead=false, variables={}, data={}, world=0, square=0}
    actor.isDead=function(self) return self.dead end
    actor.getOnlineID=function() return calls end
    local id = calls
    actor.getOnlineID=function() return id end
    actor.getPersistentOutfitID=function() return id+100 end
    actor.getX=function() return x end; actor.getY=function() return y end; actor.getZ=function() return z end
    actor.setVariable=function(self,k,v) self.variables[k]=v end
    actor.setUseless=function() end; actor.setTarget=function() end
    actor.getModData=function(self) return self.data end
    actor.removeFromWorld=function(self) self.world=self.world+1; removed=removed+1 end
    actor.removeFromSquare=function(self)
        if self.fail then error('offline cleanup failure') end
        self.square=self.square+1
    end
    actors[#actors+1]=actor
    return {size=function() return 1 end, get=function() return actor end}
end
assert(a.SpawnTestNPC(player,{x=20,y=20,z=0,count=5}))
assert(a.Count()==5 and #a.GetSnapshot()==5)
assert(a.SpawnTestNPC(player,{x=20,y=20,z=0,count=3}))
assert(a.Count()==8 and calls==8) -- occupied tile allowed, no lost old bindings
for _,actor in ipairs(actors) do
    assert(BAO.NPCRuntime.GetByCharacter(actor) and actor.variables.BAOHuman)
end
assert(not a.SpawnTestNPC(player,{count=21}) and calls==8)
assert(not a.SpawnTestNPC(player,{count=0/0}) and calls==8)
local navigationGet = BAO.NavigationSystem.GetCurrentNavigation
BAO.NavigationSystem.GetCurrentNavigation = function() return {character=actors[1]} end
local cleanupOK,cleanupReason = a.RemoveTestNPC()
assert(not cleanupOK and cleanupReason=='partial_cleanup' and a.Count()==1)
BAO.NavigationSystem.GetCurrentNavigation = navigationGet
assert(a.RemoveTestNPC())
actors = {}
assert(a.SpawnTestNPC(player,{count=8}))
local corpse=actors[1]; corpse.dead=true
assert(a.ReleaseDeadNPC(corpse) and a.Count()==7 and corpse.world==0)
assert(not a.ReleaseDeadNPC(corpse))
actors[2].dead=true
assert(a.SpawnTestNPC(player) and a.Count()==7 and actors[2].world==0)
local before=calls
floor=false
assert(not a.SpawnTestNPC(player) and calls==before)
floor=true
failAt=calls+3
local ok,reason,n=a.SpawnTestNPC(player,{count=5})
assert(not ok and reason=='spawn_failed' and n==2 and a.Count()==9)
failAt=nil
local blocked=actors[#actors]
blocked.fail=true
local clean,why,ids=a.RemoveTestNPC()
assert(not clean and why=='partial_cleanup' and #ids==8 and a.Count()==1)
before=calls
assert(not a.SpawnTestNPC(player) and calls==before)
blocked.fail=false
assert(a.RemoveTestNPC() and a.Count()==0 and blocked.world==1)
assert(not a.RemoveTestNPC())
assert(a.SpawnTestNPC(player,{count=20}))
assert(a.SpawnTestNPC(player,{count=20}))
assert(not a.SpawnTestNPC(player,{count=11}) and a.Count()==40)
assert(a.SpawnTestNPC(player,{count=10}) and a.Count()==50)
assert(a.RemoveTestNPC())
isClient=function() return true end
assert(not a.SpawnTestNPC(player) and not a.RemoveTestNPC())
isClient=function() return false end
print('Batch lifecycle: same tile, unique bindings, death, partial failure, cleanup retry, caps PASS')

-- Admin patrol commands use owned IDs, validated cells and the real per-NPC pipeline.
assert(a.SpawnTestNPC(player))
local entry
for _, item in pairs(a.entries) do entry=item end
local actor=entry.character
local requests=0
actor.getPathFindBehavior2=function() return {cancel=function() end} end
actor.setPath2=function() end
actor.pathToLocationF=function() requests=requests+1 end
player.getAccessLevel=function() return 'none' end
isServer=function() return true end
local target={id=entry.id,x=15,y=10,z=0}
local success,reason=a.CommandNPC(player,'npc_patrol',target)
assert(not success and reason=='admin_required')
player.getAccessLevel=function() return 'admin' end
assert(not a.CommandNPC(player,'npc_patrol',{id='foreign',x=15,y=10,z=0}))
assert(not a.CommandNPC(player,'npc_patrol',{id=entry.id,x=0/0,y=10,z=0}))
assert(not a.CommandNPC(player,'npc_patrol',{id=entry.id,x=1000,y=10,z=0}))
assert(not a.CommandNPC(player,'npc_patrol',{id=entry.id,x=15,y=10,z=1}))
floor=false
assert(not a.CommandNPC(player,'npc_patrol',target))
floor=true
assert(a.CommandNPC(player,'npc_patrol',target))
BAO.NPCRuntime.UpdateAI(0.1)
assert(requests==0 and a.GetSnapshot()[1].route, "MP server observes; client must drive")
assert(not a.CommandNPC(player,'npc_patrol',target), 'busy route must not be replaced')
local statusOK,_,detail=a.CommandNPC(player,'npc_status',{id=entry.id})
assert(statusOK and detail.state=='PATHFINDING' and detail.reason=='working')
assert(detail.pathIssued and detail.routeId and detail.targetX==15.5)
local controller=BAO.NPCRuntime.Get(entry.id).ai.AIController
local originalResult=controller.GetLastActionResult
controller.GetLastActionResult=function() return {Reason='navigation_stuck'} end
local _,_,fresh=a.CommandNPC(player,'npc_status',{id=entry.id})
assert(fresh.reason=='working', 'old failure must not label a new route')
controller.GetLastActionResult=originalResult
local firstRoute=a.GetSnapshot()[1].route.id
assert(a.CommandNPC(player,'npc_stop',{id=entry.id}))
assert(a.CommandNPC(player,'npc_stop',{id=entry.id}), 'stop is idempotent')
assert(a.CommandNPC(player,'npc_patrol',target), 'restart after stop')
BAO.NPCRuntime.UpdateAI(0.1)
assert(requests==0 and a.GetSnapshot()[1].route and a.GetSnapshot()[1].route.id ~= firstRoute, "restart must use a fresh route ID")
assert(a.RemoveTestNPC(), 'remove must stop the owned pipeline')
isServer=function() return false end
