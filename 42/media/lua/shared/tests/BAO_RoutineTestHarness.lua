-- ============================================================
-- BanditsAIOverhaul
-- BAO Routine Test Harness V1.0
-- ============================================================

local Harness = {}

local MODULE_NAME = "BAO_RoutineTestHarness"
local VERSION = "V1.0"

local started = false
local completed = false

local totalTests = 0
local passedTests = 0
local failedTests = 0

local routine = nil

-- ============================================================
-- LOG
-- ============================================================

local function Log(message)
    print("[BAO][" .. MODULE_NAME .. "] " .. tostring(message))
end

-- ============================================================
-- ASSERT
-- ============================================================

local function Test(name, condition)
    totalTests = totalTests + 1

    if condition then
        passedTests = passedTests + 1
        Log("PASS: " .. name)
        return true
    end

    failedTests = failedTests + 1
    Log("FAIL: " .. name)
    return false
end

-- ============================================================
-- TEST 1
-- MODULE AVAILABLE
-- ============================================================

local function TestModuleAvailable()
    local system = BAO and BAO.RoutineSystem

    Test(
        "RoutineSystem available",
        system ~= nil
    )

    return system
end

-- ============================================================
-- TEST 2
-- INITIALIZATION
-- ============================================================

local function TestInitialization(system)

    if not system then
        return
    end

    local result = system.Initialize()

    Test(
        "RoutineSystem.Initialize()",
        result == true
    )

    local status = system.GetStatus()

    Test(
        "RoutineSystem initialized",
        status ~= nil
        and status.initialized == true
    )
end

-- ============================================================
-- TEST 3
-- CREATE ROUTINE
-- ============================================================

local function TestCreateRoutine(system)

    if not system then
        return
    end

    routine = system.CreateRoutine(
        "bao_test_npc_001",
        "Test NPC Daily Routine"
    )

    Test(
        "Routine created",
        routine ~= nil
    )

    Test(
        "Routine has ID",
        routine ~= nil
        and routine.id ~= nil
    )

    Test(
        "Routine owner assigned",
        routine ~= nil
        and routine.ownerId == "bao_test_npc_001"
    )
end

-- ============================================================
-- TEST 4
-- ADD ACTIVITIES
-- ============================================================

local function TestAddActivities(system)

    if not system or not routine then
        return
    end

    local wake =
        system.AddActivity(
            routine.id,
            "wake_up",
            7,
            0,
            30,
            system.PRIORITY.NORMAL
        )

    local eat =
        system.AddActivity(
            routine.id,
            "eat",
            7,
            30,
            30,
            system.PRIORITY.HIGH
        )

    local work =
        system.AddActivity(
            routine.id,
            "work",
            8,
            0,
            240,
            system.PRIORITY.NORMAL
        )

    local social =
        system.AddActivity(
            routine.id,
            "socialize",
            18,
            0,
            120,
            system.PRIORITY.LOW
        )

    local sleep =
        system.AddActivity(
            routine.id,
            "sleep",
            23,
            0,
            480,
            system.PRIORITY.HIGH
        )

    Test(
        "Wake activity created",
        wake ~= nil
    )

    Test(
        "Eat activity created",
        eat ~= nil
    )

    Test(
        "Work activity created",
        work ~= nil
    )

    Test(
        "Social activity created",
        social ~= nil
    )

    Test(
        "Sleep activity created",
        sleep ~= nil
    )

    Test(
        "Routine contains 5 activities",
        #routine.activities == 5
    )
end

-- ============================================================
-- TEST 5
-- GET ROUTINE
-- ============================================================

local function TestRoutineAccess(system)

    if not system or not routine then
        return
    end

    local retrieved =
        system.GetRoutine(routine.id)

    Test(
        "GetRoutine() returns routine",
        retrieved ~= nil
    )

    Test(
        "GetRoutine() returns correct routine",
        retrieved == routine
    )

    local activities =
        system.GetActivities(routine.id)

    Test(
        "GetActivities() returns table",
        type(activities) == "table"
    )

    Test(
        "GetActivities() returns 5 activities",
        #activities == 5
    )
end

-- ============================================================
-- TEST 6
-- FIND CURRENT ACTIVITY
-- ============================================================

local function TestTimeSelection(system)

    if not system or not routine then
        return
    end

    local context = {
        hour = 8,
        minute = 30
    }

    local activity =
        system.FindCurrentActivity(
            routine.id,
            8,
            30,
            context
        )

    Test(
        "8:30 selects work",
        activity ~= nil
        and activity.type == "work"
    )

    context.hour = 18
    context.minute = 30

    activity =
        system.FindCurrentActivity(
            routine.id,
            18,
            30,
            context
        )

    Test(
        "18:30 selects socialize",
        activity ~= nil
        and activity.type == "socialize"
    )

    context.hour = 23
    context.minute = 30

    activity =
        system.FindCurrentActivity(
            routine.id,
            23,
            30,
            context
        )

    Test(
        "23:30 selects sleep",
        activity ~= nil
        and activity.type == "sleep"
    )
end

-- ============================================================
-- TEST 7
-- PRIORITY
-- ============================================================

local function TestPriority(system)

    if not system or not routine then
        return
    end

    local urgent =
        system.AddActivity(
            routine.id,
            "urgent_medical",
            8,
            30,
            30,
            system.PRIORITY.CRITICAL
        )

    Test(
        "Critical activity created",
        urgent ~= nil
    )

    local activity =
        system.FindCurrentActivity(
            routine.id,
            8,
            30,
            {}
        )

    Test(
        "Critical priority overrides normal activity",
        activity ~= nil
        and activity.type == "urgent_medical"
    )
end

-- ============================================================
-- TEST 8
-- CONDITIONS
-- ============================================================

local function TestConditions(system)

    if not system or not routine then
        return
    end

    local conditional =
        system.AddActivity(
            routine.id,
            "special_training",
            10,
            0,
            60,
            system.PRIORITY.HIGH,
            {
                condition = function(activity, context)

                    if not context then
                        return false
                    end

                    return context.trainingAvailable == true
                end
            }
        )

    Test(
        "Conditional activity created",
        conditional ~= nil
    )

    local blocked =
        system.FindCurrentActivity(
            routine.id,
            10,
            30,
            {
                trainingAvailable = false
            }
        )

    Test(
        "Condition blocks activity",
        blocked == nil
        or blocked.type ~= "special_training"
    )

    local allowed =
        system.FindCurrentActivity(
            routine.id,
            10,
            30,
            {
                trainingAvailable = true
            }
        )

    Test(
        "Condition allows activity",
        allowed ~= nil
        and allowed.type == "special_training"
    )
end

-- ============================================================
-- TEST 9
-- START / CURRENT ACTIVITY
-- ============================================================

local function TestStart(system)

    if not system or not routine then
        return
    end

    system.ResetActivityStates(routine.id)

    local activity =
        system.Update(
            routine.id,
            8,
            30,
            {
                hour = 8,
                minute = 30
            }
        )

    Test(
        "Update() returns activity",
        activity ~= nil
    )

    Test(
        "Activity becomes active",
        activity ~= nil
        and activity.state ==
            system.ACTIVITY_STATE.ACTIVE
    )

    local current =
        system.GetCurrentActivity(
            routine.ownerId
        )

    Test(
        "GetCurrentActivity() works",
        current ~= nil
    )

    Test(
        "Current activity matches selected activity",
        current == activity
    )
end

-- ============================================================
-- TEST 10
-- COMPLETE
-- ============================================================

local function TestComplete(system)

    if not system or not routine then
        return
    end

    local activity =
        system.GetCurrentActivity(
            routine.ownerId
        )

    if not activity then
        return
    end

    local result =
        system.CompleteActivity(
            routine.id,
            activity.id,
            {
                hour = 9,
                minute = 0
            }
        )

    Test(
        "CompleteActivity() succeeds",
        result == true
    )

    Test(
        "Activity becomes completed",
        activity.state ==
            system.ACTIVITY_STATE.COMPLETED
    )

    Test(
        "Current activity cleared",
        system.GetCurrentActivity(
            routine.ownerId
        ) == nil
    )
end

-- ============================================================
-- TEST 11
-- INTERRUPTION
-- ============================================================

local function TestInterruption(system)

    if not system or not routine then
        return
    end

    system.ResetActivityStates(routine.id)

    local activity =
        system.Update(
            routine.id,
            8,
            30,
            {
                hour = 8,
                minute = 30
            }
        )

    Test(
        "Activity restarted after reset",
        activity ~= nil
    )

    if not activity then
        return
    end

    local result =
        system.InterruptActivity(
            routine.id,
            activity.id,
            "enemy_detected",
            {
                hour = 8,
                minute = 45
            }
        )

    Test(
        "InterruptActivity() succeeds",
        result == true
    )

    Test(
        "Activity becomes interrupted",
        activity.state ==
            system.ACTIVITY_STATE.INTERRUPTED
    )

    Test(
        "Current activity cleared after interruption",
        system.GetCurrentActivity(
            routine.ownerId
        ) == nil
    )
end

-- ============================================================
-- TEST 12
-- ENABLE / DISABLE
-- ============================================================

local function TestEnableDisable(system)

    if not system or not routine then
        return
    end

    local result =
        system.SetEnabled(
            routine.id,
            false
        )

    Test(
        "Routine disabled",
        result == true
        and system.IsEnabled(routine.id) == false
    )

    local disabled =
        system.Update(
            routine.id,
            8,
            30,
            {}
        )

    Test(
        "Disabled routine does not update",
        disabled == nil
    )

    result =
        system.SetEnabled(
            routine.id,
            true
        )

    Test(
        "Routine re-enabled",
        result == true
        and system.IsEnabled(routine.id) == true
    )
end

-- ============================================================
-- TEST 13
-- CALLBACKS
-- ============================================================

local function TestCallbacks(system)

    if not system or not routine then
        return
    end

    local startedCallback = false
    local completedCallback = false

    local callbackActivity =
        system.AddActivity(
            routine.id,
            "callback_test",
            2,
            0,
            30,
            system.PRIORITY.CRITICAL,
            {
                onStart = function()
                    startedCallback = true
                end,

                onComplete = function()
                    completedCallback = true
                end
            }
        )

    Test(
        "Callback activity created",
        callbackActivity ~= nil
    )

    system.ResetActivityStates(routine.id)

    local activity =
        system.Update(
            routine.id,
            2,
            15,
            {
                hour = 2,
                minute = 15
            }
        )

    Test(
        "onStart callback executed",
        startedCallback == true
    )

    if activity then
        system.CompleteActivity(
            routine.id,
            activity.id,
            {
                hour = 2,
                minute = 30
            }
        )
    end

    Test(
        "onComplete callback executed",
        completedCallback == true
    )
end

-- ============================================================
-- TEST 14
-- STATUS
-- ============================================================

local function TestStatus(system)

    if not system then
        return
    end

    local status =
        system.GetStatus()

    Test(
        "GetStatus() works",
        status ~= nil
    )

    Test(
        "Status reports initialized",
        status ~= nil
        and status.initialized == true
    )

    Test(
        "Status reports routines",
        status ~= nil
        and status.routineCount >= 1
    )

    Test(
        "Status reports activities",
        status ~= nil
        and status.activityCount >= 1
    )
end

-- ============================================================
-- FINAL REPORT
-- ============================================================

local function PrintReport()

    Log("========================================")
    Log("ROUTINE SYSTEM TEST REPORT " .. VERSION)
    Log("========================================")

    Log("TOTAL: " .. tostring(totalTests))
    Log("PASS: " .. tostring(passedTests))
    Log("FAIL: " .. tostring(failedTests))

    if failedTests == 0 then
        Log("STATUS: ALL TESTS PASSED")
    else
        Log("STATUS: TESTS FAILED")
    end

    Log("========================================")
end

-- ============================================================
-- MAIN
-- ============================================================

function Harness.Run()

    if started then
        return
    end

    started = true

    Log("========================================")
    Log("Routine System Test Harness " .. VERSION)
    Log("========================================")

    local system =
        TestModuleAvailable()

    if not system then
        PrintReport()
        completed = true
        return
    end

    TestInitialization(system)

    TestCreateRoutine(system)

    TestAddActivities(system)

    TestRoutineAccess(system)

    TestTimeSelection(system)

    TestPriority(system)

    TestConditions(system)

    TestStart(system)

    TestComplete(system)

    TestInterruption(system)

    TestEnableDisable(system)

    TestCallbacks(system)

    TestStatus(system)

    PrintReport()

    completed = true
end

-- ============================================================
-- EVENT
-- ============================================================

if Events then

    Events.OnGameStart.Add(function()

        -- Delay test slightly so the Routine System
        -- has already processed its own initialization.

        if not started then
            Harness.Run()
        end

    end)

end

BAO = BAO or {}

BAO.RoutineTestHarness = Harness

Log(
    "Routine Test Harness "
    .. VERSION
    .. " module loaded"
)

return Harness