-----------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_AIControllerTestHarness.lua
--
-- AI Controller Test Harness V1.0
--
-- Tests:
-- DecisionSystem
-- ActionSystem
-- AIController
--
-- Architecture under test:
--
-- Decision
--    ↓
-- AIController
--    ↓
-- Action
--
-- This harness is isolated from physical NPC control.
-----------------------------------------------------------

BAO = BAO or {}

local Harness = {}

local MODULE_NAME =
    "BAO_AIControllerTestHarness"

local VERSION = "V1.0"

-----------------------------------------------------------
-- LOG
-----------------------------------------------------------

local function Log(message)

    print(
        "[BAO][" ..
        MODULE_NAME ..
        "] " ..
        tostring(message)
    )

end

-----------------------------------------------------------
-- TEST STATE
-----------------------------------------------------------

local totalTests = 0
local passedTests = 0
local failedTests = 0

local results = {}

-----------------------------------------------------------
-- TEST RESULT
-----------------------------------------------------------

local function Test(name, condition, details)

    totalTests =
        totalTests + 1

    if condition then

        passedTests =
            passedTests + 1

        results[#results + 1] = {

            Name = name,
            Passed = true,
            Details = details

        }

        Log(
            "PASS: " ..
            tostring(name)
        )

    else

        failedTests =
            failedTests + 1

        results[#results + 1] = {

            Name = name,
            Passed = false,
            Details = details

        }

        Log(
            "FAIL: " ..
            tostring(name) ..
            (
                details
                and
                " | " ..
                tostring(details)
                or
                ""
            )
        )

    end

end

-----------------------------------------------------------
-- RESET TEST COUNTERS
-----------------------------------------------------------

local function ResetTests()

    totalTests = 0
    passedTests = 0
    failedTests = 0
    results = {}

end

-----------------------------------------------------------
-- DEPENDENCY TEST
-----------------------------------------------------------

local function TestDependencies()

    Log(
        "Testing dependencies..."
    )

    Test(
        "DecisionSystem available",
        BAO.DecisionSystem ~= nil
    )

    Test(
        "ActionSystem available",
        BAO.ActionSystem ~= nil
    )

    Test(
        "AIController available",
        BAO.AIController ~= nil
    )

end

-----------------------------------------------------------
-- INITIALIZATION TEST
-----------------------------------------------------------

local function TestInitialization()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local initialized =
        controller.Initialize()

    Test(
        "AIController.Initialize()",
        initialized == true
    )

    Test(
        "AIController initialized",
        controller.GetStatus()
            .Initialized == true
    )

end

-----------------------------------------------------------
-- DECISION TEST
-----------------------------------------------------------

local function TestDecision()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local decision =
        controller.GetCurrentDecision()

    Test(
        "Controller has current decision",
        decision ~= nil
    )

    if decision then

        Test(
            "Decision has ID",
            decision.ID ~= nil
        )

        Test(
            "Decision has score",
            type(decision.Score)
                == "number"
        )

    end

end

-----------------------------------------------------------
-- ACTION TEST
-----------------------------------------------------------

local function TestCurrentAction()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local action =
        controller.GetCurrentAction()

    Test(
        "Controller has current action",
        action ~= nil
    )

    if action then

        Test(
            "Action has ID",
            action.id ~= nil
        )

        Test(
            "Action has type",
            action.type ~= nil
        )

        Test(
            "Action is running",
            action.state ==
                BAO.ActionSystem.State.RUNNING
        )

    end

end

-----------------------------------------------------------
-- DECISION -> ACTION TEST
-----------------------------------------------------------

local function TestDecisionActionLink()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local decision =
        controller.GetCurrentDecision()

    local action =
        controller.GetCurrentAction()

    if not decision or not action then
        return
    end

    Test(
        "Decision and Action linked",
        action.metadata ~= nil
        and
        action.metadata.decisionId
            == decision.ID
    )

    Test(
        "Action source is DecisionSystem",
        action.metadata ~= nil
        and
        action.metadata.source
            == "DecisionSystem"
    )

end

-----------------------------------------------------------
-- UPDATE STABILITY TEST
-----------------------------------------------------------

local function TestUpdateStability()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local actionBefore =
        controller.GetCurrentActionId()

    controller.Update()
    controller.Update()
    controller.Update()

    local actionAfter =
        controller.GetCurrentActionId()

    Test(
        "Repeated Update does not duplicate action",
        actionBefore == actionAfter
    )

end

-----------------------------------------------------------
-- FORCE DECISION CHANGE
-----------------------------------------------------------
--
-- We deliberately use DecisionSystem's existing
-- CalculateWithContext() to produce an isolated test
-- result.
--
-- It does not alter DecisionSystem runtime state.
--
-- Therefore we cannot use it directly to change the
-- controller's real decision.
--
-- Instead we temporarily use the public DecisionSystem
-- runtime state by calling Recalculate() only after
-- modifying a known WorldContext field when such a field
-- is exposed as mutable.
--
-- If the current WorldContext implementation does not
-- expose mutable test data, this test reports that fact
-- instead of modifying internal data unsafely.
-----------------------------------------------------------

local function FindWorldContext()

    if not BAO.WorldContext then
        return nil
    end

    if BAO.WorldContext.Current then
        return BAO.WorldContext.Current
    end

    if BAO.WorldContext.Get then
        return BAO.WorldContext.Get()
    end

    return nil

end

-----------------------------------------------------------
-- RETREAT TEST
-----------------------------------------------------------

local function TestRetreatDecision()

    local decisionSystem =
        BAO.DecisionSystem

    local controller =
        BAO.AIController

    if not decisionSystem
        or not controller then

        return

    end

    local world =
        FindWorldContext()

    if not world then

        Log(
            "Retreat test skipped: " ..
            "WorldContext unavailable"
        )

        return

    end

    -------------------------------------------------------
    -- Build an isolated extreme danger context.
    -------------------------------------------------------

    local testContext = {

        Health = 15,

        Hunger = 80,

        Thirst = 80,

        Fatigue = 80,

        Panic = 95,

        Pain = 70,

        ZombiesNearby = 30,

        Night = false,

        HasWeapon = false,

        Ranged = false

    }

    local testResult =
        decisionSystem.CalculateWithContext(
            testContext
        )

    Test(
        "Danger test calculation available",
        testResult ~= nil
    )

    if not testResult then
        return
    end

    Test(
        "Danger test selects retreat",
        testResult.Decision ~= nil
        and
        testResult.Decision.ID
            == "retreat"
    )

    Log(
        "Isolated danger decision: " ..
        tostring(
            testResult.Decision
                and testResult.Decision.ID
                or
                nil
        )
    )

end

-----------------------------------------------------------
-- ACTION SYSTEM MANUAL TRANSITION TEST
-----------------------------------------------------------
--
-- This test verifies the controller's action interruption
-- machinery without corrupting DecisionSystem internals.
--
-- We use the controller's currently running action.
-----------------------------------------------------------

local function TestActionInterruption()

    local controller =
        BAO.AIController

    local actionSystem =
        BAO.ActionSystem

    if not controller
        or not actionSystem then

        return

    end

    local action =
        controller.GetCurrentAction()

    if not action then

        Log(
            "Action interruption test skipped: " ..
            "no current action"
        )

        return

    end

    local actionId =
        action.id

    local interrupted =
        actionSystem.InterruptAction(
            actionId,
            "test_harness"
        )

    Test(
        "Current action can be interrupted",
        interrupted == true
    )

    local after =
        actionSystem.GetAction(
            actionId
        )

    Test(
        "Interrupted action has correct state",
        after ~= nil
        and
        after.state ==
            actionSystem.State.INTERRUPTED
    )

    Test(
        "Interrupted action has correct result",
        after ~= nil
        and
        after.result ==
            actionSystem.Result.INTERRUPTED
    )

    -------------------------------------------------------
    -- Controller must detect that the action ended.
    -------------------------------------------------------

    controller.Update()

    Test(
        "Controller detects interrupted action",
        controller.GetCurrentAction() == nil
    )

end

-----------------------------------------------------------
-- STATUS TEST
-----------------------------------------------------------

local function TestStatus()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local status =
        controller.GetStatus()

    Test(
        "GetStatus() returns table",
        type(status) == "table"
    )

    if status then

        Test(
            "Status has ControllerId",
            status.ControllerId ~= nil
        )

        Test(
            "Status has State",
            status.State ~= nil
        )

        Test(
            "Status has Statistics",
            status.Statistics ~= nil
        )

    end

end

-----------------------------------------------------------
-- STATISTICS TEST
-----------------------------------------------------------

local function TestStatistics()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local statistics =
        controller.GetStatistics()

    Test(
        "Statistics available",
        type(statistics) == "table"
    )

    if statistics then

        Test(
            "Statistics track decisions",
            type(
                statistics.decisionsProcessed
            ) == "number"
        )

        Test(
            "Statistics track actions created",
            type(
                statistics.actionsCreated
            ) == "number"
        )

        Test(
            "Statistics track actions started",
            type(
                statistics.actionsStarted
            ) == "number"
        )

    end

end

-----------------------------------------------------------
-- RESET TEST
-----------------------------------------------------------

local function TestReset()

    local controller =
        BAO.AIController

    if not controller then
        return
    end

    local reset =
        controller.Reset()

    Test(
        "Controller Reset()",
        reset == true
    )

    Test(
        "Reset clears current decision",
        controller.GetCurrentDecision()
            == nil
    )

    Test(
        "Reset clears current action",
        controller.GetCurrentAction()
            == nil
    )

    Test(
        "Reset returns controller to idle",
        controller.GetState()
            == controller.State.IDLE
    )

    -------------------------------------------------------
    -- Reinitialize after reset.
    -------------------------------------------------------

    local initialized =
        controller.Initialize()

    Test(
        "Controller remains initialized after reset",
        initialized == true
    )

end

-----------------------------------------------------------
-- MAIN TEST
-----------------------------------------------------------

function Harness.Run()

    ResetTests()

    Log(
        "========================================"
    )

    Log(
        "AI Controller Test Harness " ..
        VERSION
    )

    Log(
        "========================================"
    )

    -------------------------------------------------------
    -- Dependencies
    -------------------------------------------------------

    TestDependencies()

    if not BAO.AIController then

        Log(
            "AIController unavailable. " ..
            "Tests stopped."
        )

        return false

    end

    -------------------------------------------------------
    -- Initialize
    -------------------------------------------------------

    TestInitialization()

    -------------------------------------------------------
    -- Update controller once.
    --
    -- This allows the controller to obtain the current
    -- DecisionSystem decision and create its Action.
    -------------------------------------------------------

    BAO.AIController.Update()

    -------------------------------------------------------
    -- Core tests
    -------------------------------------------------------

    TestDecision()

    TestCurrentAction()

    TestDecisionActionLink()

    TestUpdateStability()

    TestRetreatDecision()

    TestActionInterruption()

    TestStatus()

    TestStatistics()

    -------------------------------------------------------
    -- Reset
    -------------------------------------------------------

    TestReset()

    -------------------------------------------------------
    -- Final report
    -------------------------------------------------------

    Log(
        "========================================"
    )

    Log(
        "AI CONTROLLER TEST RESULTS"
    )

    Log(
        "TOTAL: " ..
        tostring(totalTests)
    )

    Log(
        "PASS: " ..
        tostring(passedTests)
    )

    Log(
        "FAIL: " ..
        tostring(failedTests)
    )

    if failedTests == 0 then

        Log(
            "STATUS: ALL TESTS PASSED"
        )

    else

        Log(
            "STATUS: TESTS FAILED"
        )

    end

    Log(
        "========================================"
    )

    return failedTests == 0

end

-----------------------------------------------------------
-- GET RESULTS
-----------------------------------------------------------

function Harness.GetResults()

    return results

end

-----------------------------------------------------------
-- GET SUMMARY
-----------------------------------------------------------

function Harness.GetSummary()

    return {

        Total = totalTests,

        Passed = passedTests,

        Failed = failedTests,

        Success =
            failedTests == 0

    }

end

-----------------------------------------------------------
-- GAME START
-----------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(

        function()

            Log(
                "OnGameStart"
            )

            ------------------------------------------------
            -- Delay is not required here.
            --
            -- Harness.Run() itself checks dependencies
            -- and the controller can initialize when
            -- dependencies become available.
            ------------------------------------------------

            Harness.Run()

        end

    )

end

-----------------------------------------------------------
-- EXPORT
-----------------------------------------------------------

BAO.AIControllerTestHarness =
    Harness

-----------------------------------------------------------
-- MODULE LOADED
-----------------------------------------------------------

Log(
    "AI Controller Test Harness " ..
    VERSION ..
    " module loaded"
)