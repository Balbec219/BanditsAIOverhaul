"""Offline Lua 5.1 checks; requires lupa (--runtime-path for a local install).

Only event registration is stubbed. This does not test Project Zomboid movement.
"""
import argparse
from pathlib import Path
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--runtime-path")
args = parser.parse_args()
if args.runtime_path:
    sys.path.insert(0, args.runtime_path)
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
shared = root / "42/media/lua/shared"
runtime = LuaRuntime(unpack_returned_tuples=True)
messages = []
runtime.globals().print = lambda *values: messages.append(" ".join(map(str, values)))
runtime.execute("""
BAO = {}
Events = { OnGameStart = {}, OnTick = {} }
startup = {}
Events.OnGameStart.Add = function(callback) startup[#startup + 1] = callback end
Events.OnTick.Add = function(callback) end
""")
lua_files = list((root / "42/media/lua").rglob("*.lua"))
for path in lua_files:
    runtime.compile(path.read_text(encoding="utf-8-sig"), name=str(path))
print(f"Lua 5.1 syntax: {len(lua_files)} files PASS")

for relative in (
    "navigation/BAO_NavigationSystem.lua",
    "npc/BAO_NPCData.lua", "npc/BAO_NPCRuntime.lua", "npc/BAO_NPCWorldAdapter.lua",
    "ai/BAO_ActionSystem.lua", "ai/BAO_ActionExecutor.lua", "ai/BAO_AIController.lua",
    "tests/BAO_ActionTestHarness.lua", "tests/BAO_ActionExecutorTestHarness.lua",
    "tests/BAO_AIControllerTestHarness.lua",
    "tests/BAO_NavigationTestHarness.lua", "tests/BAO_NPCRuntimeTestHarness.lua",
):
    path = shared / relative
    runtime.execute(path.read_text(encoding="utf-8-sig"), name=str(path))
try:
    runtime.execute("""
for _, callback in ipairs(startup) do callback() end
assert(BAO.ActionTestHarness.failed == 0, 'Action regression suite failed')
assert(BAO.ActionExecutorTestHarness.fail == 0, 'Executor regression suite failed')
assert(BAO.AIControllerTestHarness.GetSummary().Success, 'Pipeline suite failed')
assert(BAO.NavigationTestHarness.failed == 0, 'Navigation suite failed')
assert(BAO.NPCRuntimeTestHarness.GetSummary().Success, 'NPC Runtime suite failed')

BAO.DecisionSystem = { GetCurrentDecision = function()
    return { ID = 'patrol', Score = 60, Priority = 50 }
end }
assert(BAO.AIController.Update())
local action = BAO.AIController.GetCurrentAction()
local execution = BAO.AIController.GetCurrentExecution()
local actionIdCounter = BAO.ActionSystem.nextActionId
local executionIdCounter = BAO.ActionExecutor.nextExecutionId
for i = 1, 2 do
    assert(BAO.AIControllerTestHarness.Run())
    assert(BAO.AIController.GetCurrentAction() == action)
    assert(BAO.ActionExecutor.GetCurrentExecution() == execution)
    assert(action.state == 'running' and not execution._finished)
    assert(BAO.ActionSystem.nextActionId == actionIdCounter)
    assert(BAO.ActionExecutor.nextExecutionId == executionIdCounter)
end
local ok = BAO.AIController.WithIsolatedState(function() error('expected isolation failure') end)
assert(ok == false)
assert(BAO.AIController.GetCurrentAction() == action)
assert(BAO.AIController.GetCurrentExecution() == execution)
-- Fault injection stays offline: Kahlua reports caught error() in the game UI.
local system = BAO.ActionSystem
local broken = system.CreateAction('offline_exception', {
    onStart = function() error('expected offline test error') end
})
system.RegisterAction(broken)
assert(system.StartAction(broken.id) == false)
assert(broken.state == system.State.FAILED and broken.reason == 'start_callback_error')
system.RemoveAction(broken.id)

-- Keep an actual bound test route active while rerunning the full harness.
local controller, executor, navigation = BAO.AIController, BAO.ActionExecutor, BAO.NavigationSystem
controller.Reset()
local actor = { x = 0, stopCalls = 0, pathCalls = 0 }
actor.getX = function(self) return self.x end
actor.getY = function() return 0 end
actor.getZ = function() return 0 end
actor.behavior = { cancel = function() actor.stopCalls = actor.stopCalls + 1 end }
actor.getPathFindBehavior2 = function(self) return self.behavior end
actor.setPath2 = function() end
actor.pathToLocationF = function(self) self.pathCalls = self.pathCalls + 1 end
assert(controller.SetPatrolTarget(actor, 10, 0, 0))
assert(controller.Update())
executor.Update()
local request = navigation.GetCurrentNavigation()
local liveRuntime = navigation.runtime
assert(request and actor.pathCalls == 1)
assert(BAO.AIControllerTestHarness.Run())
assert(navigation.runtime == liveRuntime and navigation.GetCurrentNavigation() == request)
assert(actor.stopCalls == 0 and actor.pathCalls == 1 and actor.x == 0)

local step = 1 / 60
getGameTime = function() return { getRealworldSecondsSinceLastUpdate = function() return step end } end
local polls = navigation.GetStatistics().polls
for i = 1, 5 do navigation.OnTick() end
assert(navigation.GetStatistics().polls == polls, 'Navigation polled on every frame')
for i = 1, 7 do navigation.OnTick() end
assert(navigation.GetStatistics().polls > polls and navigation.GetStatistics().polls <= polls + 2)
local elapsed = request.elapsed
step = 0
for i = 1, 200 do navigation.OnTick() end
assert(request.elapsed == elapsed, 'Pause incorrectly consumed timeout')
step = 120
navigation.OnTick()
assert(request.elapsed - elapsed < 0.5, 'Long resumed frame consumed entire timeout')
assert(actor.pathCalls == 1, 'Polling reissued engine path')
getGameTime = nil

-- Only offline: cleanup exceptions must retain route/controller ownership.
local cancel = actor.behavior.cancel
actor.behavior.cancel = function() error('expected offline cleanup exception') end
local ownedAction = controller.GetCurrentAction()
local ownedExecution = controller.GetCurrentExecution()
BAO.ActionSystem.FailAction(ownedAction.id, BAO.ActionSystem.Result.FAILED, 'external_failure')
controller.Update()
assert(controller.GetCurrentExecution() == ownedExecution)
assert(executor.GetCurrentExecution() == ownedExecution)
assert(navigation.GetCurrentNavigation() == request)
actor.behavior.cancel = cancel
controller.Update()
assert(navigation.GetCurrentNavigation() == nil and executor.GetCurrentExecution() == nil)
assert(controller.GetCurrentAction() == nil)
""")
except Exception:
    print("\n".join(messages[-100:]))
    raise

# Check the existing routine bridge harness against its real boolean/reason API.
for relative in (
    "routine/BAO_RoutineSystem.lua", "ai/BAO_RoutineDecisionBridge.lua",
    "tests/BAO_RoutineDecisionBridgeTestHarness.lua",
):
    path = shared / relative
    runtime.execute(path.read_text(encoding="utf-8-sig"), name=str(path))
routine_start = len(messages)
runtime.execute("""
assert(BAO.RoutineSystem.Initialize())
assert(BAO.RoutineDecisionBridge.Initialize())
BAO.RoutineDecisionBridgeTestHarness.Run()
""")
routine_report = messages[routine_start:]
assert any("STATUS: ALL TESTS PASSED" in line for line in routine_report), "\n".join(routine_report)

# Exercise the real UI button handler without rendering PZ widgets.
runtime.execute("""
package.preload['ISUI/ISCollapsableWindow'] = function()
    ISCollapsableWindow = { derive = function() BAOTestWindow = {}; return BAOTestWindow end }
end
package.preload['ISUI/ISButton'] = function() ISButton = {} end
""")
ui_path = root / "42/media/lua/client/BAO_DebugUI.lua"
runtime.execute(ui_path.read_text(encoding="utf-8-sig"), name=str(ui_path))
runtime.execute("""
local window = {}
BAOTestWindow.onTestButton(window)
assert(window.lastScenario == 'PIPELINE' and window.lastTestStatus == 'PASS')
local savedHarness = BAO.AIControllerTestHarness
BAO.AIControllerTestHarness = nil
BAOTestWindow.onTestButton(window)
assert(window.lastTestStatus == 'HARNESS UNAVAILABLE')
BAO.AIControllerTestHarness = {
    Run = function() return false end,
    GetSummary = function() return { Passed = 1, Total = 2 } end
}
BAOTestWindow.onTestButton(window)
assert(window.lastTestStatus == 'FAIL' and window.lastDecision == '1/2 PASSED')
BAO.AIControllerTestHarness.Run = function() error('expected test exception') end
BAOTestWindow.onTestButton(window)
assert(window.lastTestStatus == 'ERROR')
BAO.AIControllerTestHarness = savedHarness
""")
runtime.execute((root / "tools/test_npc_world_adapter.lua").read_text(encoding="utf-8-sig"))
runtime.execute("""
local vanillaCalls = 0
ISSpawnHordeUI = {
    createChildren = function(self)
        self.outfit = { addOptionWithData = function() end }
    end,
    onSpawn = function() vanillaCalls = vanillaCalls + 1 end
}
package.preload['DebugUIs/ISSpawnHordeUI'] = function() end
package.preload['ISUI/ISModalDialog'] = function() end
ISModalDialog = { new = function() return {
    initialise = function() end, addToUIManager = function() end
} end }
baoVanillaCalls = function() return vanillaCalls end
""")
runtime.execute((root / "42/media/lua/client/BAO_NPCWorldClient.lua").read_text(encoding="utf-8-sig"))
runtime.execute((root / "42/media/lua/client/BAO_HordeManager.lua").read_text(encoding="utf-8-sig"))
runtime.execute("""
local window = { getOutfit = function() return 'Police' end }
ISSpawnHordeUI.onSpawn(window)
assert(baoVanillaCalls() == 1)
window.getOutfit = function() return '__BAO_TEST_NPC__' end
window.getZombiesNumber = function() return 1 end
window.getHeightOffset = function() return 0 end
window.getRadius = function() return 0 end
window.chr = {}
local sent = 0
sendClientCommand = function(_, module, command) assert(module == 'BAO_Debug' and command == 'world_spawn'); sent = sent + 1 end
isClient = function() return true end
ISSpawnHordeUI.onSpawn(window)
assert(baoVanillaCalls() == 1 and sent == 1, 'BAO request did not use own server command')
isClient = function() return false end
local called
BAO.NPCWorldAdapter.SpawnTestNPC = function(_, target) called = target; return true, 'spawned' end
window.getZombiesNumber = function() return 1 end
window.getHeightOffset = function() return 0 end
window.selectX, window.selectY, window.selectZ = 10, 20, 1
ISSpawnHordeUI.onSpawn(window)
assert(called.x == 10 and called.y == 20 and called.z == 1)
assert(baoVanillaCalls() == 1)
""")
runtime.execute((root / "42/media/lua/server/BAO_DebugServer.lua").read_text(encoding="utf-8-sig"))
runtime.execute((root / "tools/test_npc_server.lua").read_text(encoding="utf-8-sig"))
print("Server authority, admin gate, target validation, snapshot, client identity/cleanup: PASS")
print("Horde Manager: vanilla delegation, network request and selected tile: PASS")
print("NPC world adapter: batches, same tile, IDs, death, partial failure, cleanup retry, busy route, caps: PASS")
for line in messages:
    if "PIPELINE V" in line or "NPC RUNTIME V" in line or "STATUS:" in line or "FAIL:" in line:
        print(line)
print("Live-state restoration, repeat run and exception restoration: PASS")
print("Pipeline UI handler: PASS / FAIL / unavailable / exception: PASS (no rendering)")
print("Active route isolation, throttled polling and paused-time handling: PASS")
