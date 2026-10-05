-- Offline integration: two real AI pipelines with synthetic movement only.
local r = BAO.NPCRuntime
local savedState, savedLog = r.state, BAO.Log
local savedAction = BAO.AIController.GetCurrentAction()
local savedNavigation = BAO.NavigationSystem.GetCurrentNavigation()
BAO.Log = function() end
r.state = {bindings={}, order={}, nextGeneration=1, aiElapsed=0,
    statistics={bound=0,unbound=0,rejected=0,refreshes=0}}
local function Actor()
    local a = {x=0, requests=0, cancels=0}
    local behavior = {cancel=function() a.cancels=a.cancels+1 end}
    a.getX=function() return a.x end
    a.getY=function() return 0 end
    a.getZ=function() return 0 end
    a.getPathFindBehavior2=function() return behavior end
    a.setPath2=function() end
    a.pathToLocationF=function() a.requests=a.requests+1 end
    return a
end
local a,b = Actor(),Actor()
for i, actor in ipairs({a,b}) do
    local id='multi_test_'..i
    assert(BAO.NPCData.Create(id))
    assert(r.Bind(id,actor))
    assert(r.StartPatrol(id,10*i,0,0))
end
r.UpdateAI(0.1)
local ca,cb = r.Get('multi_test_1').ai,r.Get('multi_test_2').ai
assert(ca ~= cb and ca.ActionSystem ~= cb.ActionSystem)
local na,nb=ca.NavigationSystem.GetCurrentNavigation(),cb.NavigationSystem.GetCurrentNavigation()
assert(na and nb and na.id ~= nb.id and na.character == a and nb.character == b)
assert(a.requests==1 and b.requests==1)
for i=1,5 do r.UpdateAI(0.1) end
assert(a.requests==1 and b.requests==1, 'repeated path requests')
assert(r.SetActive('multi_test_1',false))
assert(a.cancels==1 and b.cancels==0, 'deactivation must stop only its own route')
assert(cb.NavigationSystem.GetCurrentNavigation()==nb)
b.x=20
r.UpdateAI(0.1)
assert(nb.state=='ARRIVED', 'second NPC must still complete')
assert(BAO.AIController.GetCurrentAction()==savedAction)
assert(BAO.NavigationSystem.GetCurrentNavigation()==savedNavigation)
for i=1,2 do
    assert(r.Unbind('multi_test_'..i))
    BAO.NPCData.Remove('multi_test_'..i)
end
r.state, BAO.Log = savedState, savedLog
