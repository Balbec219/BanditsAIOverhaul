-- ============================================================
-- BanditsAIOverhaul
-- BAO_ActionExecutorTestHarness.lua
--
-- Action Executor V1.0 Test Harness
-- ============================================================

local TestHarness = {}

TestHarness.VERSION = "1.0"

TestHarness.total = 0
TestHarness.pass = 0
TestHarness.fail = 0

-- ============================================================
-- LOG
-- ============================================================

local function Log(message)

    print(
        "[BAO][BAO_ActionExecutorTestHarness] "
        .. tostring(message)
    )

end

-- ============================================================
-- TEST
-- ============================================================

local function Test(name, condition)

    TestHarness.total =
        TestHarness.total + 1

    if condition then

        TestHarness.pass =
            TestHarness.pass + 1

        Log(
            "PASS: "
            .. tostring(name)
        )

        return true

    end

    TestHarness.fail =
        TestHarness.fail + 1

    Log(
        "FAIL: "
        .. tostring(name)
    )

    return false

end

-- ============================================================
-- DEPENDENCIES
-- ============================================================

local function TestDependencies()

    Log("=== TEST 1: DEPENDENCIES ===")

    Test(
        "BAO exists",
        BAO ~= nil
    )

    Test(
        "ActionSystem exists",
        BAO ~= nil
        and BAO.ActionSystem ~= nil
    )

    Test(
        "ActionExecutor exists",
        BAO ~= nil
        and BAO.ActionExecutor ~= nil
    )

end

-- ============================================================
-- INITIALIZATION
-- ============================================================

local function TestInitialization()

    Log("=== TEST 2: INITIALIZATION ===")

    if not BAO
        or not BAO.ActionExecutor then

        Test(
            "ActionExecutor initialized",
            false
        )

        Test(
            "Version is 1.0",
            false
        )

        return

    end

    local executor =
        BAO.ActionExecutor

    Test(
        "ActionExecutor initialized",
        executor.initialized == true
    )

    Test(
        "Version is 1.0",
        executor.VERSION == "1.0"
    )

end

-- ============================================================
-- EXECUTOR TYPES
-- ============================================================

local function TestExecutorTypes()

    Log("=== TEST 3: EXECUTOR TYPES ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    Test(
        "patrol mapping",
        executor.GetExecutorType("patrol")
            == executor.TYPES.PATROL
    )

    Test(
        "explore mapping",
        executor.GetExecutorType("explore")
            == executor.TYPES.EXPLORE
    )

    Test(
        "gather_resources mapping",
        executor.GetExecutorType(
            "gather_resources"
        )
        == executor.TYPES.GATHER_RESOURCES
    )

    Test(
        "guard mapping",
        executor.GetExecutorType("guard")
            == executor.TYPES.GUARD
    )

    Test(
        "help_ally mapping",
        executor.GetExecutorType("help_ally")
            == executor.TYPES.HELP_ALLY
    )

    Test(
        "rest mapping",
        executor.GetExecutorType("rest")
            == executor.TYPES.REST
    )

    Test(
        "heal mapping",
        executor.GetExecutorType("heal")
            == executor.TYPES.HEAL
    )

    Test(
        "retreat mapping",
        executor.GetExecutorType("retreat")
            == executor.TYPES.RETREAT
    )

    Test(
        "combat mapping",
        executor.GetExecutorType("combat")
            == executor.TYPES.COMBAT
    )

    Test(
        "unknown mapping",
        executor.GetExecutorType(
            "unknown_action"
        )
        == executor.TYPES.GENERIC
    )

end

-- ============================================================
-- PLAN CREATION
-- ============================================================

local function TestPlanCreation()

    Log("=== TEST 4: PLAN CREATION ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local action = {
        type = "patrol"
    }

    local plan =
        executor.CreatePlan(
            action,
            {
                source = "test_harness"
            }
        )

    Test(
        "plan created",
        type(plan) == "table"
    )

    if type(plan) ~= "table" then
        return
    end

    Test(
        "correct executor type",
        plan.executorType
            == executor.TYPES.PATROL
    )

    Test(
        "action type stored",
        plan.actionType == "patrol"
    )

    Test(
        "steps table exists",
        type(plan.steps) == "table"
    )

    Test(
        "initial step is prepare",
        plan.currentStep == "prepare"
    )

    Test(
        "navigation required",
        plan.navigationRequired == true
    )

    Test(
        "animation required",
        plan.animationRequired == true
    )

    Test(
        "plan is interruptible",
        plan.interruptible == true
    )

end

-- ============================================================
-- GATHER RESOURCE PLAN
-- ============================================================

local function TestGatherPlan()

    Log("=== TEST 5: GATHER PLAN ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local action = {
        type = "gather_resources"
    }

    local plan =
        executor.CreatePlan(
            action
        )

    Test(
        "gather plan created",
        type(plan) == "table"
    )

    if type(plan) ~= "table" then
        return
    end

    Test(
        "gather executor type",
        plan.executorType
            == executor.TYPES.GATHER_RESOURCES
    )

    Test(
        "gather navigation required",
        plan.navigationRequired == true
    )

    Test(
        "gather animation required",
        plan.animationRequired == true
    )

    Test(
        "gather interaction required",
        plan.interactionRequired == true
    )

end

-- ============================================================
-- COMBAT PLAN
-- ============================================================

local function TestCombatPlan()

    Log("=== TEST 6: COMBAT PLAN ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local action = {
        type = "combat"
    }

    local plan =
        executor.CreatePlan(
            action
        )

    Test(
        "combat plan created",
        type(plan) == "table"
    )

    if type(plan) ~= "table" then
        return
    end

    Test(
        "combat executor type",
        plan.executorType
            == executor.TYPES.COMBAT
    )

    Test(
        "combat navigation required",
        plan.navigationRequired == true
    )

    Test(
        "combat animation required",
        plan.animationRequired == true
    )

    Test(
        "combat required",
        plan.combatRequired == true
    )

end

-- ============================================================
-- EXECUTION CREATION
-- ============================================================

local function TestExecutionCreation()

    Log("=== TEST 7: EXECUTION CREATION ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return nil
    end

    local action = {
        type = "gather_resources"
    }

    local execution =
        executor.CreateExecution(
            "test_action_001",
            action,
            {
                source = "test_harness"
            }
        )

    Test(
        "execution created",
        type(execution) == "table"
    )

    if type(execution) ~= "table" then
        return nil
    end

    Test(
        "execution has id",
        execution.id ~= nil
    )

    Test(
        "action id linked",
        execution.actionId
            == "test_action_001"
    )

    Test(
        "action type linked",
        execution.actionType
            == "gather_resources"
    )

    Test(
        "executor type linked",
        execution.executorType
            == executor.TYPES.GATHER_RESOURCES
    )

    Test(
        "initial state is IDLE",
        execution.state
            == executor.STATES.IDLE
    )

    Test(
        "result is nil",
        execution.result == nil
    )

    Test(
        "execution plan exists",
        type(execution.plan) == "table"
    )

    Test(
        "metadata exists",
        type(execution.metadata) == "table"
    )

    return execution

end

-- ============================================================
-- VALIDATION
-- ============================================================

local function TestValidation(execution)

    Log("=== TEST 8: VALIDATION ===")

    local executor =
        BAO.ActionExecutor

    if not executor
        or not execution then

        return
    end

    local valid, reason =
        executor.ValidateExecution(
            execution
        )

    Test(
        "valid execution",
        valid == true
    )

    Test(
        "validation reason is nil",
        reason == nil
    )

end

-- ============================================================
-- START
-- ============================================================

local function TestStart(execution)

    Log("=== TEST 9: START ===")

    local executor =
        BAO.ActionExecutor

    if not executor
        or not execution then

        return
    end

    local started, reason =
        executor.StartExecution(
            execution
        )

    Test(
        "execution started",
        started == true
    )

    Test(
        "start reason is nil",
        reason == nil
    )

    Test(
        "state is PREPARING",
        execution.state
            == executor.STATES.PREPARING
    )

    Test(
        "current execution linked",
        executor.GetCurrentExecution()
            == execution
    )

    Test(
        "startedAt exists",
        execution.startedAt ~= nil
    )

    Test(
        "attempts increased",
        execution.attempts >= 1
    )

end

-- ============================================================
-- PREPARE / UPDATE
-- ============================================================

local function TestUpdate(execution)

    Log("=== TEST 10: UPDATE ===")

    local executor =
        BAO.ActionExecutor

    if not executor
        or not execution then

        return
    end

    executor.Update()

    Test(
        "state moved to EXECUTING",
        execution.state
            == executor.STATES.EXECUTING
    )

    Test(
        "plan moved to execute",
        execution.plan.currentStep
            == "execute"
    )

end

-- ============================================================
-- COMPLETE
-- ============================================================

local function TestCompletion(execution)

    Log("=== TEST 11: COMPLETION ===")

    local executor =
        BAO.ActionExecutor

    if not executor
        or not execution then

        return
    end

    local completed =
        executor.CompleteExecution(
            execution,
            "test_completed"
        )

    Test(
        "completion returned true",
        completed == true
    )

    Test(
        "state is COMPLETED",
        execution.state
            == executor.STATES.COMPLETED
    )

    Test(
        "result is SUCCESS",
        execution.result
            == executor.RESULTS.SUCCESS
    )

    Test(
        "reason stored",
        execution.reason
            == "test_completed"
    )

    Test(
        "finishedAt exists",
        execution.finishedAt ~= nil
    )

    Test(
        "current execution cleared",
        executor.GetCurrentExecution()
            == nil
    )

    Test(
        "last execution stored",
        executor.GetLastExecution()
            == execution
    )

end

-- ============================================================
-- INTERRUPT
-- ============================================================

local function TestInterrupt()

    Log("=== TEST 12: INTERRUPTION ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local action = {
        type = "guard"
    }

    local execution =
        executor.CreateExecution(
            "test_action_002",
            action
        )

    Test(
        "interrupt execution created",
        type(execution) == "table"
    )

    if type(execution) ~= "table" then
        return
    end

    local started =
        executor.StartExecution(
            execution
        )

    Test(
        "interrupt execution started",
        started == true
    )

    executor.Update()

    local interrupted =
        executor.InterruptExecution(
            execution,
            "test_interrupt"
        )

    Test(
        "interrupt returned true",
        interrupted == true
    )

    Test(
        "state is INTERRUPTED",
        execution.state
            == executor.STATES.INTERRUPTED
    )

    Test(
        "result is INTERRUPTED",
        execution.result
            == executor.RESULTS.INTERRUPTED
    )

    Test(
        "reason stored",
        execution.reason
            == "test_interrupt"
    )

end

-- ============================================================
-- FAILURE
-- ============================================================

local function TestFailure()

    Log("=== TEST 13: FAILURE ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local action = {
        type = "combat"
    }

    local execution =
        executor.CreateExecution(
            "test_action_003",
            action
        )

    Test(
        "failure execution created",
        type(execution) == "table"
    )

    if type(execution) ~= "table" then
        return
    end

    local started =
        executor.StartExecution(
            execution
        )

    Test(
        "failure execution started",
        started == true
    )

    executor.Update()

    local failed =
        executor.FailExecution(
            execution,
            "test_failure"
        )

    Test(
        "failure returned true",
        failed == true
    )

    Test(
        "state is FAILED",
        execution.state
            == executor.STATES.FAILED
    )

    Test(
        "result is FAILED",
        execution.result
            == executor.RESULTS.FAILED
    )

    Test(
        "reason stored",
        execution.reason
            == "test_failure"
    )

end

-- ============================================================
-- CANCEL
-- ============================================================

local function TestCancel()

    Log("=== TEST 14: CANCEL ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local action = {
        type = "rest"
    }

    local execution =
        executor.CreateExecution(
            "test_action_004",
            action
        )

    Test(
        "cancel execution created",
        type(execution) == "table"
    )

    if type(execution) ~= "table" then
        return
    end

    local started =
        executor.StartExecution(
            execution
        )

    Test(
        "cancel execution started",
        started == true
    )

    executor.Update()

    local cancelled =
        executor.CancelExecution(
            execution,
            "test_cancel"
        )

    Test(
        "cancel returned true",
        cancelled == true
    )

    Test(
        "state is CANCELLED",
        execution.state
            == executor.STATES.CANCELLED
    )

    Test(
        "result is CANCELLED",
        execution.result
            == executor.RESULTS.CANCELLED
    )

    Test(
        "reason stored",
        execution.reason
            == "test_cancel"
    )

end

-- ============================================================
-- HISTORY
-- ============================================================

local function TestHistory()

    Log("=== TEST 15: HISTORY ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local history =
        executor.GetExecutionHistory()

    Test(
        "history is table",
        type(history) == "table"
    )

    Test(
        "history contains executions",
        #history >= 4
    )

end

-- ============================================================
-- STATISTICS
-- ============================================================

local function TestStatistics()

    Log("=== TEST 16: STATISTICS ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local statistics =
        executor.GetStatistics()

    Test(
        "statistics is table",
        type(statistics) == "table"
    )

    if type(statistics) ~= "table" then
        return
    end

    Test(
        "executions created",
        statistics.executionsCreated >= 4
    )

    Test(
        "executions started",
        statistics.executionsStarted >= 4
    )

    Test(
        "executions completed",
        statistics.executionsCompleted >= 1
    )

    Test(
        "executions interrupted",
        statistics.executionsInterrupted >= 1
    )

    Test(
        "executions failed",
        statistics.executionsFailed >= 1
    )

    Test(
        "executions cancelled",
        statistics.executionsCancelled >= 1
    )

end

-- ============================================================
-- STATUS
-- ============================================================

local function TestStatus()

    Log("=== TEST 17: STATUS ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local status =
        executor.GetStatus()

    Test(
        "status is table",
        type(status) == "table"
    )

    if type(status) ~= "table" then
        return
    end

    Test(
        "status initialized",
        status.initialized == true
    )

    Test(
        "status version",
        status.version == "1.0"
    )

    Test(
        "status attempts",
        status.attempts >= 1
    )

    Test(
        "status history count",
        status.historyCount >= 4
    )

end

-- ============================================================
-- RESET
-- ============================================================

local function TestReset()

    Log("=== TEST 18: RESET ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    executor.Reset()

    Test(
        "current execution cleared",
        executor.GetCurrentExecution()
            == nil
    )

    Test(
        "last execution cleared",
        executor.GetLastExecution()
            == nil
    )

    local history =
        executor.GetExecutionHistory()

    Test(
        "history cleared",
        type(history) == "table"
        and #history == 0
    )

    local statistics =
        executor.GetStatistics()

    Test(
        "statistics reset",
        type(statistics) == "table"
        and statistics.executionsCreated == 0
    )

end

-- ============================================================
-- REINITIALIZATION
-- ============================================================

local function TestReinitialization()

    Log("=== TEST 19: REINITIALIZATION ===")

    local executor =
        BAO.ActionExecutor

    if not executor then
        return
    end

    local initialized =
        executor.Initialize()

    Test(
        "Initialize returns true",
        initialized == true
    )

    Test(
        "executor remains initialized",
        executor.initialized == true
    )

end

-- ============================================================
-- FINAL REPORT
-- ============================================================

local function PrintReport()

    Log("========================================")
    Log("ACTION EXECUTOR V1.0 TEST REPORT")
    Log("========================================")

    Log(
        "TOTAL: "
        .. tostring(TestHarness.total)
    )

    Log(
        "PASS: "
        .. tostring(TestHarness.pass)
    )

    Log(
        "FAIL: "
        .. tostring(TestHarness.fail)
    )

    if TestHarness.fail == 0 then

        Log(
            "STATUS: ALL TESTS PASSED"
        )

    else

        Log(
            "STATUS: TESTS FAILED"
        )

    end

    Log("========================================")

end

-- ============================================================
-- RUN TESTS
-- ============================================================

local function RunTests()

    Log(
        "Action Executor Test Harness V"
        .. TestHarness.VERSION
        .. " started"
    )

    TestDependencies()

    if not BAO
        or not BAO.ActionExecutor then

        Log(
            "ActionExecutor unavailable - tests stopped"
        )

        PrintReport()

        return
    end

    TestInitialization()

    TestExecutorTypes()

    TestPlanCreation()

    TestGatherPlan()

    TestCombatPlan()

    local execution =
        TestExecutionCreation()

    if execution then

        TestValidation(execution)

        TestStart(execution)

        TestUpdate(execution)

        TestCompletion(execution)

    end

    TestInterrupt()

    TestFailure()

    TestCancel()

    TestHistory()

    TestStatistics()

    TestStatus()

    TestReset()

    TestReinitialization()

    PrintReport()

end

-- ============================================================
-- GAME START
-- ============================================================

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            RunTests()

        end
    )

end

-- ============================================================
-- EXPORT
-- ============================================================

BAO = BAO or {}

BAO.ActionExecutorTestHarness =
    TestHarness

Log(
    "Action Executor Test Harness V"
    .. TestHarness.VERSION
    .. " module loaded"
)