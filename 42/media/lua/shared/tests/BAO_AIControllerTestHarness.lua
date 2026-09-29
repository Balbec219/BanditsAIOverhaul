-- BanditsAIOverhaul: isolated Controller / Executor / Action integration, V1.2.
-- Real BAO modules with synthetic decisions; never moves the player/NPC.
BAO = BAO or {}
local Harness = { Version = "V1.2" }
local results = {}
local total, passed, failed = 0, 0, 0
local running = false

local function Log(message)
    print("[BAO][BAO_AIControllerTestHarness] " .. tostring(message))
end
local function Test(name, condition)
    total = total + 1
    if condition then passed = passed + 1 else failed = failed + 1 end
    results[#results + 1] = { Name = name, Passed = condition == true }
    Log((condition and "PASS: " or "FAIL: ") .. name)
end
local function Copy(source)
    local copy = {}
    for key, value in pairs(source) do copy[key] = value end
    return copy
end
local function Restore(target, saved)
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(saved) do target[key] = value end
end

local function RunIntegration()
    local controller, executor, system = BAO.AIController, BAO.ActionExecutor, BAO.ActionSystem
    local decision = { ID = "patrol", Score = 60, Priority = 50 }
    BAO.DecisionSystem = { GetCurrentDecision = function() return decision end }
    system.Clear()
    -- Detach before Reset so the user's live execution cannot be cancelled.
    executor.currentExecution = nil
    executor.Reset()
    local function Choose(id)
        decision = { ID = id, Score = 60, Priority = 50 }
        return controller.Update()
    end

    Test("controller initializes without player profile", controller.Initialize() == true)
    Test("decision starts linked pair", controller.Update() == true)
    local action = controller.GetCurrentAction()
    local execution = controller.GetCurrentExecution()
    Test("execution references registered action", execution.action == action
        and execution.actionId == action.id and system.GetAction(action.id) == action)
    Test("executor owns controller execution", executor.GetCurrentExecution() == execution)
    controller.Update()
    controller.Update()
    Test("repeated updates do not duplicate pair", controller.GetCurrentAction() == action
        and controller.GetCurrentExecution() == execution
        and executor.GetStatistics().executionsCreated == 1)
    executor.Update()
    Test("execution prepares", execution.state == executor.STATES.EXECUTING)
    system.UpdateAction(action.id, 100000)
    executor.Update()
    Test("patrol cannot succeed just by elapsed time", action.state == system.State.RUNNING
        and execution.state == executor.STATES.EXECUTING)

    local callbackCount = 0
    action.onComplete = function() callbackCount = callbackCount + 1 end
    Test("execution completion succeeds", executor.CompleteExecution(execution, "test_arrived", { test = true }))
    Test("completion synchronizes action", action.state == system.State.COMPLETED
        and action.result == system.Result.SUCCESS and action.resultData.test == true)
    Test("duplicate completion rejected", executor.CompleteExecution(execution) == false)
    controller.Update()
    controller.Update()
    Test("terminal result recorded once", #controller.GetActionHistory() == 1
        and executor.GetStatistics().executionsCompleted == 1 and callbackCount == 1)
    Test("completion reason reaches controller", controller.GetLastActionResult().Reason == "test_arrived")
    Test("same completed decision waits", controller.GetCurrentAction() == nil
        and controller.GetState() == controller.State.WAITING)
    Test("explicit restart creates next pair", controller.RestartCurrentDecision() == true
        and controller.GetCurrentAction() ~= action)

    local oldAction = controller.GetCurrentAction()
    local oldExecution = controller.GetCurrentExecution()
    Choose("retreat")
    Test("decision change interrupts both layers", oldAction.state == system.State.INTERRUPTED
        and oldExecution.state == executor.STATES.INTERRUPTED)
    Test("history keeps old decision", controller.GetLastActionResult().Decision == "patrol")
    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    Test("new decision gets new pair", action.type == "retreat" and execution.action == action)
    Test("stale completion cannot clear new owner", executor.CompleteExecution(oldExecution) == false
        and executor.GetCurrentExecution() == execution)
    action.interruptible = false
    Choose("heal")
    Test("non-interruptible pair retained", controller.GetCurrentAction() == action
        and executor.GetCurrentExecution() == execution
        and controller.GetCurrentDecision().ID == "retreat")
    Test("reset respects non-interruptible action", controller.Reset() == false
        and controller.GetCurrentAction() == action)
    action.interruptible = true
    controller.Update()
    Test("pending decision starts when interruption allowed", controller.GetCurrentAction().type == "heal")

    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    Test("executor failure accepted", executor.FailExecution(execution, "test_blocked"))
    controller.Update()
    Test("failure propagated to controller", action.state == system.State.FAILED
        and controller.GetLastActionResult().Reason == "test_blocked"
        and controller.GetCurrentAction() == nil)

    Choose("guard")
    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    system.CancelAction(action.id, "external_cancel")
    controller.Update()
    Test("external cancel synchronizes execution", execution.state == executor.STATES.CANCELLED
        and execution.reason == "external_cancel" and executor.GetCurrentExecution() == nil)
    Choose("rest")
    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    system.CompleteAction(action.id, system.Result.SUCCESS)
    executor.Update()
    controller.Update()
    Test("external completion synchronized", execution.state == executor.STATES.COMPLETED
        and controller.GetLastActionResult().Decision == "rest")

    Choose("explore")
    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    Test("stop interrupts owned execution", controller.StopCurrentAction("manual_stop") == true
        and execution.state == executor.STATES.INTERRUPTED and controller.GetCurrentAction() == nil)
    local historySize = #controller.GetActionHistory()
    controller.StopCurrentAction("again")
    controller.Update()
    Test("repeated stop does not double-record", #controller.GetActionHistory() == historySize)

    Choose("combat")
    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    Test("reset cleans owned pair", controller.Reset() == true
        and action.state == system.State.INTERRUPTED and execution.state == executor.STATES.INTERRUPTED
        and executor.GetCurrentExecution() == nil and controller.GetCurrentDecision() == nil)

    local foreign = executor.CreateExecution("standalone", { type = "generic" })
    executor.StartExecution(foreign)
    local count = controller.GetStatistics().actionsCreated
    Choose("patrol")
    controller.Update()
    Test("busy executor does not allocate orphan actions", controller.GetCurrentAction() == nil
        and controller.GetStatistics().actionsCreated == count
        and executor.GetCurrentExecution() == foreign)
    executor.CompleteExecution(foreign)
    controller.Update()
    Test("controller retries after executor is free", controller.GetCurrentAction() ~= nil)

    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    local reentrantResult
    action.onComplete = function()
        reentrantResult = executor.CompleteExecution(execution, "recursive")
    end
    Test("callback reentry cannot finish twice", executor.CompleteExecution(execution)
        and reentrantResult == false)
    controller.Update()

    Choose("guard")
    action, execution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    system.RemoveAction(action.id)
    controller.GetCurrentAction() -- A UI read must not lose the detached action's result.
    controller.Update()
    Test("removed action cannot leave orphan execution", executor.GetCurrentExecution() == nil
        and execution.state == executor.STATES.FAILED and controller.GetCurrentExecution() == nil
        and controller.GetLastActionResult().Reason == "linked_action_missing")

    local startExecution = executor.StartExecution
    executor.StartExecution = function() return false, "injected_start_failure" end
    Test("execution start failure reported", Choose("heal") == false)
    local failedCount = controller.GetStatistics().actionsCreated
    controller.Update()
    Test("failed startup leaves no running action or retry loop", controller.GetCurrentAction() == nil
        and controller.GetLastAction().state == system.State.FAILED
        and controller.GetStatistics().actionsCreated == failedCount)
    executor.StartExecution = startExecution
    Test("explicit retry after start failure works", controller.RestartCurrentDecision() == true)
    controller.StopCurrentAction("test_cleanup")

    local blockedReason
    local blocked = system.CreateAction("test", {
        requirements = { hasTool = false },
        onFail = function(_, result, reason) blockedReason = result .. ":" .. reason end
    })
    system.RegisterAction(blocked)
    Test("blocked action is terminal with consistent callback", system.StartAction(blocked.id) == false
        and blocked._finished == true and blockedReason == "blocked:requirement_failed:hasTool")
    -- Throwing deliberately increments PZ's error counter even inside pcall.
    -- The callback-exception case lives only in tools/run_lua_tests.py.
end

-- Coordinates are changed only in this synthetic fixture, never in production.
local function RunNavigationIntegration()
    local controller, executor, system, navigation = BAO.AIController, BAO.ActionExecutor, BAO.ActionSystem, BAO.NavigationSystem
    local decision = { ID = "patrol", Score = 60, Priority = 50 }
    BAO.DecisionSystem = { GetCurrentDecision = function() return decision end }
    local function Actor()
        local actor = { x = 0, y = 0, z = 0, pathCalls = 0, stopCalls = 0, clearCalls = 0 }
        actor.getX = function(self) return self.x end
        actor.getY = function(self) return self.y end
        actor.getZ = function(self) return self.z end
        actor.behavior = { cancel = function() actor.stopCalls = actor.stopCalls + 1 end }
        actor.getPathFindBehavior2 = function(self) return self.behavior end
        actor.setPath2 = function(self) self.clearCalls = self.clearCalls + 1 end
        actor.pathToLocationF = function(self, x, y, z)
            self.pathCalls = self.pathCalls + 1
            self.goalX, self.goalY, self.goalZ = x, y, z
            return self.rejectPath ~= true
        end
        return actor
    end
    local function Start(actor, options)
        controller.Reset()
        navigation.Reset()
        decision = { ID = "patrol", Score = 60, Priority = 50 }
        local bound = controller.SetPatrolTarget(actor, 5, 0, 0, options)
        controller.Update()
        executor.Update()
        return bound, controller.GetCurrentAction(), controller.GetCurrentExecution()
    end
    local actor = Actor()
    local bound, action, execution = Start(actor)
    local request = execution.navigation
    Test("patrol binds actor and location", bound and request.character == actor
        and actor.goalX == 5 and actor.goalY == 0 and actor.goalZ == 0)
    Test("patrol owns navigation", navigation.GetCurrentNavigation() == request)
    Test("arrival required by ActionSystem", system.CompleteAction(action.id) == false)
    Test("arrival required by Executor", executor.CompleteExecution(execution) == false)
    for i = 1, 20 do controller.Update(); executor.Update() end
    Test("path requested once across repeated updates", actor.pathCalls == 1)
    local reads = navigation.GetStatistics().positionReads
    navigation.Update(0.1)
    Test("one position snapshot per location poll", navigation.GetStatistics().positionReads == reads + 1)
    Test("expensive diagnostics disabled by default", navigation.GetStatistics().diagnosticReads == 0)
    actor.x, actor.z = 5, 1
    navigation.Update(0.1)
    executor.Update()
    Test("same XY on another floor is not arrival", request.state ~= "ARRIVED" and action.state == "running")
    actor.z = 0
    navigation.Update(0.1)
    executor.Update()
    controller.Update()
    Test("arrival completes the whole pipeline", request.state == "ARRIVED"
        and execution.state == "COMPLETED" and action.state == "completed"
        and controller.GetLastActionResult().Reason == "arrived")
    Test("arrival releases engine path once", actor.stopCalls == 1 and actor.clearCalls == 1)
    navigation.Update(1)
    executor.Update()
    Test("arrival stats recorded once", navigation.GetStatistics().completed == 1)
    Test("finished navigation cannot restart", navigation.Start(request) == false and actor.pathCalls == 1)
    reads = navigation.GetStatistics().positionReads
    navigation.OnTick()
    Test("idle navigation performs no position reads", navigation.GetStatistics().positionReads == reads)

    actor = Actor()
    bound, action, execution = Start(actor)
    request = execution.navigation
    action.interruptible = false
    Test("rejected interrupt leaves path running", controller.StopCurrentAction("test") == false
        and actor.stopCalls == 0 and navigation.GetCurrentNavigation() == request)
    action.interruptible = true
    Test("controller stop cancels engine path", controller.StopCurrentAction("test_stop") == true
        and actor.stopCalls == 1 and actor.clearCalls == 1 and request.state == "CANCELLED"
        and navigation.GetCurrentNavigation() == nil)
    Test("cancel statistic incremented", navigation.GetStatistics().cancelled == 1)

    actor = Actor()
    bound, action, execution = Start(actor, { stuckSeconds = 1 })
    navigation.Update(1)
    executor.Update()
    controller.Update()
    Test("stationary actor fails instead of hanging", action.state == "failed"
        and controller.GetLastActionResult().Reason == "navigation_stuck" and actor.stopCalls == 1)

    actor = Actor()
    bound, action, execution = Start(actor, { timeoutSeconds = 2, stuckSeconds = 5 })
    actor.x = 1
    navigation.Update(1)
    actor.x = 2
    navigation.Update(1)
    executor.Update()
    controller.Update()
    Test("moving actor still obeys total timeout", action.state == "failed"
        and controller.GetLastActionResult().Reason == "navigation_timeout")

    actor = Actor()
    actor.rejectPath = true
    bound, action, execution = Start(actor)
    controller.Update()
    Test("engine request refusal propagates", action.state == "failed"
        and controller.GetLastActionResult().Reason == "path_request_failed" and actor.stopCalls == 1)

    actor = Actor()
    bound, action, execution = Start(actor)
    Test("foreign cancel cannot stop owned navigation", navigation.Cancel("foreign", {}) == false
        and actor.stopCalls == 0)
    navigation.Cancel("external_cancel", execution.navigation)
    executor.Update()
    controller.Update()
    Test("external navigation cancellation propagates", action.state == "cancelled"
        and controller.GetLastActionResult().Reason == "external_cancel")

    actor = Actor()
    bound, action, execution = Start(actor)
    system.FailAction(action.id, system.Result.FAILED, "external_failure")
    executor.Update()
    controller.Update()
    Test("external action failure releases path", actor.stopCalls == 1
        and execution.state == "FAILED" and navigation.GetCurrentNavigation() == nil)

    actor = Actor()
    bound, action, execution = Start(actor)
    navigation.Cancel("replaced", execution.navigation)
    local foreignActor = Actor()
    local foreign = navigation.RequestLocation(foreignActor, 10, 0, 0)
    navigation.Start(foreign)
    executor.Update()
    controller.Update()
    Test("finishing stale execution preserves foreign navigation", navigation.GetCurrentNavigation() == foreign
        and foreignActor.stopCalls == 0)
    navigation.Cancel("cleanup", foreign)

    actor = Actor()
    actor.behavior.cancel = nil
    bound, action, execution = Start(actor)
    controller.Update()
    Test("missing stop API rejected before requesting path", actor.pathCalls == 0
        and controller.GetLastActionResult().Reason == "navigation_api_unavailable")
    Test("invalid target numbers rejected", not navigation.ValidateTarget(navigation.CreateLocationTarget(0/0, 0, 0))
        and not navigation.ValidateTarget(navigation.CreateLocationTarget("5", 0, 0)))
    Test("invalid timeout rejected", navigation.RequestLocation(Actor(), 5, 0, 0, { timeoutSeconds = -1 }) == nil)

    actor = Actor()
    bound, action, execution = Start(actor, { stuckSeconds = 1 })
    for i = 1, 4 do
        actor.x = i % 2 == 0 and 0 or 0.01
        navigation.Update(0.25)
    end
    executor.Update()
    controller.Update()
    Test("small jitter does not defeat stuck detection", action.state == "failed"
        and controller.GetLastActionResult().Reason == "navigation_stuck")
end

function Harness.Run()
    if running then return false end
    results, total, passed, failed = {}, 0, 0, 0
    if not BAO.AIController or not BAO.ActionExecutor or not BAO.ActionSystem or not BAO.NavigationSystem then
        Test("pipeline dependencies available", false)
        return false
    end
    running = true
    local system, executor = BAO.ActionSystem, BAO.ActionExecutor
    local savedSystem, savedExecutor = Copy(system), Copy(executor)
    local savedDecision = BAO.DecisionSystem
    local navigation = BAO.NavigationSystem
    local savedNavigationRuntime = navigation.runtime
    local controller = BAO.AIController
    local oldAction, oldExecution = controller.GetCurrentAction(), controller.GetCurrentExecution()
    local oldHistory, oldStatistics = controller.GetActionHistory(), controller.GetStatistics()
    local ok, errorMessage = controller.WithIsolatedState(function()
        navigation.runtime = nil
        navigation.Reset()
        RunIntegration()
        RunNavigationIntegration()
    end)
    navigation.runtime = savedNavigationRuntime
    Restore(system, savedSystem)
    Restore(executor, savedExecutor)
    BAO.DecisionSystem = savedDecision
    if not ok then
        Test("integration suite completed without exception", false)
        Log(errorMessage)
    end
    Test("live controller state restored", controller.GetCurrentAction() == oldAction
        and controller.GetCurrentExecution() == oldExecution
        and controller.GetActionHistory() == oldHistory and controller.GetStatistics() == oldStatistics)
    Test("live action/executor state restored", system.actions == savedSystem.actions
        and executor.currentExecution == savedExecutor.currentExecution
        and executor.executionHistory == savedExecutor.executionHistory
        and executor.statistics == savedExecutor.statistics and BAO.DecisionSystem == savedDecision)
    Test("live navigation runtime restored", navigation.runtime == savedNavigationRuntime)
    running = false
    Log("PIPELINE V1.2 TOTAL=" .. total .. " PASS=" .. passed .. " FAIL=" .. failed)
    Log(failed == 0 and "STATUS: ALL TESTS PASSED" or "STATUS: TESTS FAILED")
    return failed == 0
end

function Harness.GetResults() return results end
function Harness.GetSummary()
    return { Total = total, Passed = passed, Failed = failed, Success = total > 0 and failed == 0 }
end

BAO.AIControllerTestHarness = Harness
if Events and Events.OnGameStart then Events.OnGameStart.Add(Harness.Run) end
Log("AI Controller Test Harness V1.2 module loaded")
