-----------------------------------------------------------
-- BAO_ActionTestHarness.lua
-- BanditsAIOverhaul
--
-- Action Test Harness V1.0
--
-- Tests the universal Action System without requiring
-- physical NPC movement.
-----------------------------------------------------------

if not BAO then
    BAO = {}
end

local ActionTestHarness = {}

-----------------------------------------------------------
-- VERSION
-----------------------------------------------------------

ActionTestHarness.Version = "V1.0"

-----------------------------------------------------------
-- TEST STATE
-----------------------------------------------------------

ActionTestHarness.total = 0
ActionTestHarness.passed = 0
ActionTestHarness.failed = 0

-----------------------------------------------------------
-- LOGGING
-----------------------------------------------------------

local function Log(message)
    print(
        "[BAO ActionTestHarness V1.0] " ..
        tostring(message)
    )
end

-----------------------------------------------------------
-- TEST RESULT
-----------------------------------------------------------

local function TestResult(name, passed, details)

    ActionTestHarness.total =
        ActionTestHarness.total + 1

    if passed then

        ActionTestHarness.passed =
            ActionTestHarness.passed + 1

        Log(
            "PASS: " ..
            tostring(name) ..
            (
                details
                and (" - " .. tostring(details))
                or ""
            )
        )

    else

        ActionTestHarness.failed =
            ActionTestHarness.failed + 1

        Log(
            "FAIL: " ..
            tostring(name) ..
            (
                details
                and (" - " .. tostring(details))
                or ""
            )
        )
    end
end

-----------------------------------------------------------
-- RESET TEST COUNTERS
-----------------------------------------------------------

function ActionTestHarness.Reset()

    ActionTestHarness.total = 0
    ActionTestHarness.passed = 0
    ActionTestHarness.failed = 0

end

-----------------------------------------------------------
-- DEPENDENCY TEST
-----------------------------------------------------------

function ActionTestHarness.TestDependency()

    local actionSystem = BAO.ActionSystem

    if actionSystem then

        TestResult(
            "ActionSystem dependency",
            true,
            "found"
        )

        return true
    end

    TestResult(
        "ActionSystem dependency",
        false,
        "BAO.ActionSystem not found"
    )

    return false
end

-----------------------------------------------------------
-- TEST CREATE ACTION
-----------------------------------------------------------

function ActionTestHarness.TestCreateAction()

    local AS = BAO.ActionSystem

    local action =
        AS.CreateAction(
            "test_action",
            {
                priority = 50,
                duration = 10,
                interruptible = true
            }
        )

    local passed =
        action ~= nil
        and action.id ~= nil
        and action.type == "test_action"
        and action.state == AS.State.PENDING
        and action.priority == 50
        and action.duration == 10
        and action.interruptible == true

    TestResult(
        "Create Action",
        passed,
        passed
        and "action created correctly"
        or "invalid action object"
    )

    return action
end

-----------------------------------------------------------
-- TEST REGISTER
-----------------------------------------------------------

function ActionTestHarness.TestRegister(action)

    local AS = BAO.ActionSystem

    local result =
        AS.RegisterAction(action)

    local stored =
        AS.GetAction(action.id)

    local passed =
        result == true
        and stored == action

    TestResult(
        "Register Action",
        passed,
        passed
        and "action registered"
        or "action not registered"
    )

    return passed
end

-----------------------------------------------------------
-- TEST START
-----------------------------------------------------------

function ActionTestHarness.TestStart(action)

    local AS = BAO.ActionSystem

    local result =
        AS.StartAction(action.id)

    local passed =
        result == true
        and action.state == AS.State.RUNNING

    TestResult(
        "Start Action",
        passed,
        passed
        and "state=running"
        or ("state=" .. tostring(action.state))
    )

    return passed
end

-----------------------------------------------------------
-- TEST UPDATE
-----------------------------------------------------------

function ActionTestHarness.TestUpdate(action)

    local AS = BAO.ActionSystem

    AS.UpdateAction(
        action.id,
        2
    )

    local passed =
        action.state == AS.State.RUNNING
        and action.elapsed == 2

    TestResult(
        "Update Action",
        passed,
        passed
        and "elapsed=2"
        or ("elapsed=" .. tostring(action.elapsed))
    )

    return passed
end

-----------------------------------------------------------
-- TEST COMPLETE
-----------------------------------------------------------

function ActionTestHarness.TestComplete(action)

    local AS = BAO.ActionSystem

    local result =
        AS.CompleteAction(
            action.id,
            AS.Result.SUCCESS,
            {
                test = true
            }
        )

    local passed =
        result == true
        and action.state == AS.State.COMPLETED
        and action.result == AS.Result.SUCCESS
        and action.resultData ~= nil

    TestResult(
        "Complete Action",
        passed,
        passed
        and "state=completed"
        or "completion failed"
    )

    return passed
end

-----------------------------------------------------------
-- TEST FAILED ACTION
-----------------------------------------------------------

function ActionTestHarness.TestFail()

    local AS = BAO.ActionSystem

    local action =
        AS.CreateAction(
            "test_fail",
            {
                duration = 10
            }
        )

    AS.RegisterAction(action)

    AS.StartAction(action.id)

    local result =
        AS.FailAction(
            action.id,
            AS.Result.FAILED,
            "test_failure"
        )

    local passed =
        result == true
        and action.state == AS.State.FAILED
        and action.result == AS.Result.FAILED
        and action.reason == "test_failure"

    TestResult(
        "Fail Action",
        passed,
        passed
        and "failure recorded"
        or "failure handling failed"
    )

    return passed
end

-----------------------------------------------------------
-- TEST INTERRUPT
-----------------------------------------------------------

function ActionTestHarness.TestInterrupt()

    local AS = BAO.ActionSystem

    local action =
        AS.CreateAction(
            "test_interrupt",
            {
                duration = 100,
                interruptible = true
            }
        )

    AS.RegisterAction(action)

    AS.StartAction(action.id)

    local result =
        AS.InterruptAction(
            action.id,
            "test_interrupt"
        )

    local passed =
        result == true
        and action.state == AS.State.INTERRUPTED
        and action.result == AS.Result.INTERRUPTED
        and action.reason == "test_interrupt"

    TestResult(
        "Interrupt Action",
        passed,
        passed
        and "interruption recorded"
        or "interruption failed"
    )

    return passed
end

-----------------------------------------------------------
-- TEST CANCEL
-----------------------------------------------------------

function ActionTestHarness.TestCancel()

    local AS = BAO.ActionSystem

    local action =
        AS.CreateAction(
            "test_cancel",
            {
                duration = 100
            }
        )

    AS.RegisterAction(action)

    local result =
        AS.CancelAction(
            action.id,
            "test_cancel"
        )

    local passed =
        result == true
        and action.state == AS.State.CANCELLED
        and action.result == AS.Result.CANCELLED
        and action.reason == "test_cancel"

    TestResult(
        "Cancel Action",
        passed,
        passed
        and "cancellation recorded"
        or "cancellation failed"
    )

    return passed
end

-----------------------------------------------------------
-- TEST BLOCKED REQUIREMENT
-----------------------------------------------------------

function ActionTestHarness.TestBlockedRequirement()

    local AS = BAO.ActionSystem

    local action =
        AS.CreateAction(
            "test_blocked",
            {
                requirements = {
                    hasTool = false
                }
            }
        )

    AS.RegisterAction(action)

    local result =
        AS.StartAction(action.id)

    local passed =
        result == false
        and action.state == AS.State.FAILED
        and action.result == AS.Result.BLOCKED

    TestResult(
        "Blocked Requirement",
        passed,
        passed
        and "action correctly blocked"
        or "requirement blocking failed"
    )

    return passed
end

-----------------------------------------------------------
-- TEST CALLBACKS
-----------------------------------------------------------

function ActionTestHarness.TestCallbacks()

    local AS = BAO.ActionSystem

    local callbackState = {
        started = false,
        completed = false
    }

    local action =
        AS.CreateAction(
            "test_callbacks",
            {
                duration = 1,

                onStart = function()
                    callbackState.started = true
                end,

                onComplete = function()
                    callbackState.completed = true
                end
            }
        )

    AS.RegisterAction(action)

    AS.StartAction(action.id)

    AS.UpdateAction(
        action.id,
        1
    )

    local passed =
        callbackState.started == true
        and callbackState.completed == true

    TestResult(
        "Action Callbacks",
        passed,
        passed
        and "start/complete callbacks executed"
        or "callback execution failed"
    )

    return passed
end

-----------------------------------------------------------
-- TEST FULL LIFECYCLE
-----------------------------------------------------------

function ActionTestHarness.TestFullLifecycle()

    local AS = BAO.ActionSystem

    local action =
        AS.CreateAction(
            "test_lifecycle",
            {
                priority = 100,
                duration = 5,
                interruptible = true
            }
        )

    AS.RegisterAction(action)

    local startResult =
        AS.StartAction(action.id)

    local updateResult =
        AS.UpdateAction(
            action.id,
            2
        )

    local completeResult =
        AS.CompleteAction(
            action.id,
            AS.Result.SUCCESS
        )

    local passed =
        startResult == true
        and updateResult == true
        and completeResult == true
        and action.state == AS.State.COMPLETED
        and action.result == AS.Result.SUCCESS

    TestResult(
        "Full Action Lifecycle",
        passed,
        passed
        and "create -> register -> start -> update -> complete"
        or "lifecycle failed"
    )

    return passed
end

-----------------------------------------------------------
-- RUN ALL TESTS
-----------------------------------------------------------

function ActionTestHarness.Run()

    ActionTestHarness.Reset()

    Log("========================================")
    Log("ACTION SYSTEM TEST HARNESS V1.0")
    Log("========================================")

    -------------------------------------------------------
    -- Dependency
    -------------------------------------------------------

    if not ActionTestHarness.TestDependency() then

        Log("STATUS: FAILED - dependency missing")

        return false
    end

    local AS = BAO.ActionSystem

    -------------------------------------------------------
    -- Clean state
    -------------------------------------------------------

    AS.Clear()

    -------------------------------------------------------
    -- Test 1
    -------------------------------------------------------

    local action =
        ActionTestHarness.TestCreateAction()

    -------------------------------------------------------
    -- Test 2
    -------------------------------------------------------

    if action then
        ActionTestHarness.TestRegister(action)
    else
        TestResult(
            "Register Action",
            false,
            "action creation failed"
        )
    end

    -------------------------------------------------------
    -- Test 3
    -------------------------------------------------------

    if action then
        ActionTestHarness.TestStart(action)
    else
        TestResult(
            "Start Action",
            false,
            "action creation failed"
        )
    end

    -------------------------------------------------------
    -- Test 4
    -------------------------------------------------------

    if action then
        ActionTestHarness.TestUpdate(action)
    else
        TestResult(
            "Update Action",
            false,
            "action creation failed"
        )
    end

    -------------------------------------------------------
    -- Test 5
    -------------------------------------------------------

    if action then
        ActionTestHarness.TestComplete(action)
    else
        TestResult(
            "Complete Action",
            false,
            "action creation failed"
        )
    end

    -------------------------------------------------------
    -- Additional tests
    -------------------------------------------------------

    ActionTestHarness.TestFail()

    ActionTestHarness.TestInterrupt()

    ActionTestHarness.TestCancel()

    ActionTestHarness.TestBlockedRequirement()

    ActionTestHarness.TestCallbacks()

    ActionTestHarness.TestFullLifecycle()

    -------------------------------------------------------
    -- Summary
    -------------------------------------------------------

    Log("========================================")
    Log(
        "TOTAL: " ..
        tostring(ActionTestHarness.total)
    )

    Log(
        "PASS: " ..
        tostring(ActionTestHarness.passed)
    )

    Log(
        "FAIL: " ..
        tostring(ActionTestHarness.failed)
    )

    if ActionTestHarness.failed == 0 then

        Log("STATUS: ALL TESTS PASSED")

    else

        Log("STATUS: TESTS FAILED")

    end

    Log("========================================")

    return ActionTestHarness.failed == 0
end

-----------------------------------------------------------
-- EXPORT
-----------------------------------------------------------

BAO.ActionTestHarness = ActionTestHarness

-----------------------------------------------------------
-- AUTOMATIC TEST
-----------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(function()

        Log("OnGameStart detected")

        if BAO.ActionSystem then

            Log("ActionSystem dependency available")

            ActionTestHarness.Run()

        else

            Log(
                "ERROR: ActionSystem dependency missing"
            )

        end

    end)

else

    Log(
        "WARNING: Events.OnGameStart not available"
    )

end

-----------------------------------------------------------
-- LOAD MESSAGE
-----------------------------------------------------------

Log(
    "BAO_ActionTestHarness.lua loaded - " ..
    ActionTestHarness.Version
)