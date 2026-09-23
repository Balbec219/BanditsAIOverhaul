------------------------------------------------------------
-- BAO_RoutineDecisionBridgeTestHarness.lua
-- BanditsAIOverhaul
--
-- Routine / Decision Bridge Test Harness V1.0
--
-- Tests:
--   1. Dependencies
--   2. Initialization
--   3. Routine creation
--   4. Activity creation
--   5. Routine intent mapping
--   6. Routine context
--   7. Decision context
--   8. Emergency detection
--   9. Emergency override
--  10. Bridge Update
--  11. Decision registration
--  12. Status
--  13. Final report
------------------------------------------------------------

local MODULE_NAME = "BAO_RoutineDecisionBridgeTest"

local TestHarness = {}

------------------------------------------------------------
-- TEST STATE
------------------------------------------------------------

local totalTests = 0
local passedTests = 0
local failedTests = 0

local testRoutineId = nil
local testActivityIds = {}

------------------------------------------------------------
-- LOGGING
------------------------------------------------------------

local function Log(message)
    print("[BAO][" .. MODULE_NAME .. "] " .. tostring(message))
end

------------------------------------------------------------
-- TEST HELPER
------------------------------------------------------------

local function Test(name, condition, details)
    totalTests = totalTests + 1

    if condition then
        passedTests = passedTests + 1

        if details then
            Log("PASS: " .. name .. " - " .. tostring(details))
        else
            Log("PASS: " .. name)
        end

        return true
    end

    failedTests = failedTests + 1

    if details then
        Log("FAIL: " .. name .. " - " .. tostring(details))
    else
        Log("FAIL: " .. name)
    end

    return false
end

------------------------------------------------------------
-- SAFE DYNAMIC FIELD ACCESS
------------------------------------------------------------
--
-- Important:
-- Lua Diagnostics may infer bridge results as table|nil.
--
-- We therefore NEVER pass a possibly-nil value directly
-- into rawget().
--
-- ReadField() accepts any runtime value and performs the
-- type check internally.
------------------------------------------------------------

local function ReadField(data, fieldName)
    if type(data) ~= "table" then
        return nil
    end

    return rawget(data, fieldName)
end

------------------------------------------------------------
-- DEPENDENCIES
------------------------------------------------------------

local function GetRoutineSystem()
    if BAO and BAO.RoutineSystem then
        return BAO.RoutineSystem
    end

    return nil
end

local function GetDecisionSystem()
    if BAO and BAO.DecisionSystem then
        return BAO.DecisionSystem
    end

    return nil
end

local function GetBridge()
    if BAO and BAO.RoutineDecisionBridge then
        return BAO.RoutineDecisionBridge
    end

    return nil
end

------------------------------------------------------------
-- TEST 1
-- DEPENDENCIES
------------------------------------------------------------

local function TestDependencies()
    Log("------------------------------------------------")
    Log("TEST 1: Dependencies")
    Log("------------------------------------------------")

    local routineSystem = GetRoutineSystem()
    local decisionSystem = GetDecisionSystem()
    local bridge = GetBridge()

    Test(
        "RoutineSystem available",
        routineSystem ~= nil,
        routineSystem and "RoutineSystem found" or "RoutineSystem missing"
    )

    Test(
        "DecisionSystem available",
        decisionSystem ~= nil,
        decisionSystem and "DecisionSystem found" or "DecisionSystem missing"
    )

    Test(
        "RoutineDecisionBridge available",
        bridge ~= nil,
        bridge and "Bridge found" or "Bridge missing"
    )

    return routineSystem ~= nil
        and decisionSystem ~= nil
        and bridge ~= nil
end

------------------------------------------------------------
-- TEST 2
-- INITIALIZATION
------------------------------------------------------------

local function TestInitialization()
    Log("------------------------------------------------")
    Log("TEST 2: Initialization")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge then
        Test(
            "Bridge initialized",
            false,
            "Bridge unavailable"
        )

        return false
    end

    local status = nil

    if bridge.GetStatus then
        status = bridge.GetStatus()
    end

    local initialized = false

    if type(status) == "table" then
        initialized = ReadField(
            status,
            "initialized"
        ) == true
    end

    Test(
        "Bridge initialized",
        initialized,
        initialized and "initialized=true" or "initialized=false"
    )

    return initialized
end

------------------------------------------------------------
-- TEST 3
-- CREATE TEST ROUTINE
------------------------------------------------------------

local function TestRoutineCreation()
    Log("------------------------------------------------")
    Log("TEST 3: Routine creation")
    Log("------------------------------------------------")

    local routineSystem = GetRoutineSystem()

    if not routineSystem then
        Test(
            "Create test routine",
            false,
            "RoutineSystem unavailable"
        )

        return false
    end

    if not routineSystem.CreateRoutine then
        Test(
            "Create test routine",
            false,
            "CreateRoutine unavailable"
        )

        return false
    end

    local result = routineSystem.CreateRoutine(
        "bao_bridge_test_owner",
        "BAO Bridge Test Routine"
    )

    testRoutineId = nil

    if type(result) == "table" then

        testRoutineId = ReadField(
            result,
            "id"
        )

        if testRoutineId == nil then
            testRoutineId = ReadField(
                result,
                "routineId"
            )
        end

    else

        testRoutineId = result

    end

    Test(
        "Create test routine",
        testRoutineId ~= nil,
        "routineId=" .. tostring(testRoutineId)
    )

    return testRoutineId ~= nil
end

------------------------------------------------------------
-- TEST 4
-- CREATE ACTIVITIES
------------------------------------------------------------

local function AddTestActivity(
    activityType,
    startHour,
    startMinute,
    durationMinutes,
    priority
)
    local routineSystem = GetRoutineSystem()

    if not routineSystem then
        return nil
    end

    if not routineSystem.AddActivity then
        return nil
    end

    if testRoutineId == nil then
        return nil
    end

    local result = routineSystem.AddActivity(
        testRoutineId,
        activityType,
        startHour,
        startMinute,
        durationMinutes,
        priority,
        {}
    )

    if type(result) == "table" then

        local activityId = ReadField(
            result,
            "id"
        )

        if activityId == nil then
            activityId = ReadField(
                result,
                "activityId"
            )
        end

        return activityId
    end

    return result
end

local function TestActivityCreation()
    Log("------------------------------------------------")
    Log("TEST 4: Activity creation")
    Log("------------------------------------------------")

    if testRoutineId == nil then
        Test(
            "Create activities",
            false,
            "Test routine unavailable"
        )

        return false
    end

    testActivityIds = {}

    local workId = AddTestActivity(
        "work",
        8,
        0,
        180,
        50
    )

    local eatId = AddTestActivity(
        "eat",
        12,
        0,
        30,
        50
    )

    local guardId = AddTestActivity(
        "guard",
        14,
        0,
        120,
        80
    )

    local sleepId = AddTestActivity(
        "sleep",
        23,
        0,
        480,
        80
    )

    testActivityIds.work = workId
    testActivityIds.eat = eatId
    testActivityIds.guard = guardId
    testActivityIds.sleep = sleepId

    local success =
        workId ~= nil
        and eatId ~= nil
        and guardId ~= nil
        and sleepId ~= nil

    Test(
        "Create activities",
        success,
        "work=" .. tostring(workId)
            .. " eat=" .. tostring(eatId)
            .. " guard=" .. tostring(guardId)
            .. " sleep=" .. tostring(sleepId)
    )

    return success
end

------------------------------------------------------------
-- TEST 5
-- ROUTINE INTENT MAPPING
------------------------------------------------------------

local function TestIntentMapping()
    Log("------------------------------------------------")
    Log("TEST 5: Routine intent mapping")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.GetRoutineIntent then
        Test(
            "Intent mapping available",
            false
        )

        return false
    end

    local mappings = {
        work = "gather_resources",
        eat = "gather_resources",
        guard = "guard",
        sleep = "rest"
    }

    local allPassed = true

    for activityType, expectedDecision in pairs(mappings) do

        local result = bridge.GetRoutineIntent(
            activityType
        )

        local decision = nil

        if type(result) == "table" then

            decision = ReadField(
                result,
                "decision"
            )

            if decision == nil then
                decision = ReadField(
                    result,
                    "intent"
                )
            end

        elseif type(result) == "string" then

            decision = result

        end

        local passed =
            decision == expectedDecision

        Test(
            "Intent " .. activityType,
            passed,
            "expected=" .. tostring(expectedDecision)
                .. " actual=" .. tostring(decision)
        )

        if not passed then
            allPassed = false
        end
    end

    return allPassed
end

------------------------------------------------------------
-- TEST 6
-- ROUTINE CONTEXT
------------------------------------------------------------

local function TestRoutineContext()
    Log("------------------------------------------------")
    Log("TEST 6: Routine context")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.BuildRoutineContext then
        Test(
            "BuildRoutineContext available",
            false
        )

        return false
    end

    local context = bridge.BuildRoutineContext(
        testRoutineId,
        14,
        30,
        {}
    )

    local valid =
        type(context) == "table"

    Test(
        "Build routine context",
        valid,
        "contextType=" .. type(context)
    )

    if not valid then
        return false
    end

    local routineId = ReadField(
        context,
        "routineId"
    )

    local hour = ReadField(
        context,
        "hour"
    )

    local minute = ReadField(
        context,
        "minute"
    )

    Test(
        "Routine context routineId",
        routineId == testRoutineId,
        "value=" .. tostring(routineId)
    )

    Test(
        "Routine context hour",
        hour == 14,
        "value=" .. tostring(hour)
    )

    Test(
        "Routine context minute",
        minute == 30,
        "value=" .. tostring(minute)
    )

    return true
end

------------------------------------------------------------
-- TEST 7
-- DECISION CONTEXT
------------------------------------------------------------

local function TestDecisionContext()
    Log("------------------------------------------------")
    Log("TEST 7: Decision context")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.BuildDecisionContext then
        Test(
            "BuildDecisionContext available",
            false
        )

        return false
    end

    local routineContext =
        bridge.BuildRoutineContext(
            testRoutineId,
            14,
            30,
            {}
        )

    if type(routineContext) ~= "table" then

        Test(
            "Build decision context",
            false,
            "Routine context is not a table"
        )

        return false
    end

    local decisionContext =
        bridge.BuildDecisionContext(
            routineContext,
            {}
        )

    local valid =
        type(decisionContext) == "table"

    Test(
        "Build decision context",
        valid,
        "contextType=" .. type(decisionContext)
    )

    return valid
end

------------------------------------------------------------
-- TEST 8
-- EMERGENCY DETECTION
------------------------------------------------------------

local function TestEmergencyDetection()
    Log("------------------------------------------------")
    Log("TEST 8: Emergency detection")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.EvaluateEmergency then

        Test(
            "EvaluateEmergency available",
            false
        )

        return false
    end

    --------------------------------------------------------
    -- NORMAL WORLD
    --------------------------------------------------------

    local normalWorld = {
        inCombat = false,
        enemyDetected = false,
        health = 100,
        zombiesNearby = 0,
        panic = 0
    }

    local normalResult =
        bridge.EvaluateEmergency(
            normalWorld
        )

    local normalEmergency = nil

    if type(normalResult) == "table" then

        normalEmergency =
            ReadField(
                normalResult,
                "emergency"
            )

        if normalEmergency == nil then

            normalEmergency =
                ReadField(
                    normalResult,
                    "isEmergency"
                )

        end
    end

    Test(
        "Normal world is not emergency",
        normalEmergency ~= true,
        "emergency=" .. tostring(normalEmergency)
    )

    --------------------------------------------------------
    -- COMBAT
    --------------------------------------------------------

    local combatWorld = {
        inCombat = true,
        enemyDetected = false,
        health = 100,
        zombiesNearby = 0,
        panic = 0
    }

    local combatResult =
        bridge.EvaluateEmergency(
            combatWorld
        )

    local combatEmergency = nil
    local combatReason = nil

    if type(combatResult) == "table" then

        combatEmergency =
            ReadField(
                combatResult,
                "emergency"
            )

        if combatEmergency == nil then

            combatEmergency =
                ReadField(
                    combatResult,
                    "isEmergency"
                )

        end

        combatReason =
            ReadField(
                combatResult,
                "reason"
            )

        if combatReason == nil then

            combatReason =
                ReadField(
                    combatResult,
                    "emergencyReason"
                )

        end
    end

    Test(
        "Combat detected as emergency",
        combatEmergency == true,
        "emergency=" .. tostring(combatEmergency)
    )

    Test(
        "Combat emergency has reason",
        combatReason ~= nil,
        "reason=" .. tostring(combatReason)
    )

    --------------------------------------------------------
    -- CRITICAL HEALTH
    --------------------------------------------------------

    local healthWorld = {
        inCombat = false,
        enemyDetected = false,
        health = 20,
        zombiesNearby = 0,
        panic = 0
    }

    local healthResult =
        bridge.EvaluateEmergency(
            healthWorld
        )

    local healthEmergency = nil

    if type(healthResult) == "table" then

        healthEmergency =
            ReadField(
                healthResult,
                "emergency"
            )

        if healthEmergency == nil then

            healthEmergency =
                ReadField(
                    healthResult,
                    "isEmergency"
                )

        end
    end

    Test(
        "Critical health detected",
        healthEmergency == true,
        "emergency=" .. tostring(healthEmergency)
    )

    --------------------------------------------------------
    -- HIGH ZOMBIE DENSITY
    --------------------------------------------------------

    local zombieWorld = {
        inCombat = false,
        enemyDetected = false,
        health = 100,
        zombiesNearby = 25,
        panic = 0
    }

    local zombieResult =
        bridge.EvaluateEmergency(
            zombieWorld
        )

    local zombieEmergency = nil

    if type(zombieResult) == "table" then

        zombieEmergency =
            ReadField(
                zombieResult,
                "emergency"
            )

        if zombieEmergency == nil then

            zombieEmergency =
                ReadField(
                    zombieResult,
                    "isEmergency"
                )

        end
    end

    Test(
        "High zombie density detected",
        zombieEmergency == true,
        "emergency=" .. tostring(zombieEmergency)
    )

    return true
end

------------------------------------------------------------
-- TEST 9
-- EMERGENCY OVERRIDE
------------------------------------------------------------

local function TestEmergencyOverride()
    Log("------------------------------------------------")
    Log("TEST 9: Emergency override")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.Update then

        Test(
            "Bridge Update available",
            false
        )

        return false
    end

    --------------------------------------------------------
    -- NORMAL ROUTINE
    --------------------------------------------------------

    local normalWorld = {
        inCombat = false,
        enemyDetected = false,
        health = 100,
        zombiesNearby = 0,
        panic = 0
    }

    local normalResult =
        bridge.Update(
            "bao_bridge_test_owner",
            testRoutineId,
            14,
            30,
            normalWorld
        )

    Test(
        "Normal Bridge Update",
        normalResult ~= nil,
        "result=" .. tostring(normalResult ~= nil)
    )

    --------------------------------------------------------
    -- EMERGENCY ROUTINE OVERRIDE
    --------------------------------------------------------

    local dangerWorld = {
        inCombat = true,
        enemyDetected = true,
        health = 100,
        zombiesNearby = 30,
        panic = 90
    }

    local dangerResult =
        bridge.Update(
            "bao_bridge_test_owner",
            testRoutineId,
            14,
            30,
            dangerWorld
        )

    Test(
        "Emergency Bridge Update",
        dangerResult ~= nil,
        "result=" .. tostring(dangerResult ~= nil)
    )

    if type(dangerResult) ~= "table" then

        Test(
            "Emergency result is table",
            false,
            "type=" .. type(dangerResult)
        )

        return false
    end

    --------------------------------------------------------
    -- ROUTINE OVERRIDE STATE
    --------------------------------------------------------

    local routineOverridden =
        ReadField(
            dangerResult,
            "routineOverridden"
        )

    --------------------------------------------------------
    -- EMERGENCY STATE
    --------------------------------------------------------

    local emergencyState =
        ReadField(
            dangerResult,
            "emergency"
        )

    if emergencyState == nil then

        emergencyState =
            ReadField(
                dangerResult,
                "isEmergency"
            )

    end

    --------------------------------------------------------
    -- NESTED EMERGENCY FALLBACK
    --------------------------------------------------------

    if emergencyState == nil then

        local emergencyData =
            ReadField(
                dangerResult,
                "emergency"
            )

        if type(emergencyData) == "table" then

            emergencyState =
                ReadField(
                    emergencyData,
                    "emergency"
                )

            if emergencyState == nil then

                emergencyState =
                    ReadField(
                        emergencyData,
                        "isEmergency"
                    )

            end
        end
    end

    Test(
        "Emergency state detected",
        emergencyState == true,
        "emergency=" .. tostring(emergencyState)
    )

    if routineOverridden ~= nil then

        Test(
            "Routine overridden by emergency",
            routineOverridden == true,
            "routineOverridden="
                .. tostring(routineOverridden)
        )

    else

        Test(
            "Emergency override result exists",
            emergencyState == true,
            "override state inferred from emergency result"
        )

    end

    return emergencyState == true
end

------------------------------------------------------------
-- TEST 10
-- BRIDGE UPDATE
------------------------------------------------------------

local function TestBridgeUpdate()
    Log("------------------------------------------------")
    Log("TEST 10: Bridge Update")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.Update then

        Test(
            "Bridge Update available",
            false
        )

        return false
    end

    local worldContext = {
        inCombat = false,
        enemyDetected = false,
        health = 100,
        zombiesNearby = 0,
        panic = 0
    }

    local result =
        bridge.Update(
            "bao_bridge_test_owner",
            testRoutineId,
            8,
            30,
            worldContext
        )

    local valid =
        result ~= nil

    Test(
        "Bridge Update executes",
        valid,
        "result=" .. tostring(result)
    )

    return valid
end

------------------------------------------------------------
-- TEST 11
-- REGISTER DECISION
------------------------------------------------------------

local function TestRegisterDecision()
    Log("------------------------------------------------")
    Log("TEST 11: Decision registration")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.RegisterDecision then

        Test(
            "RegisterDecision available",
            false
        )

        return false
    end

    local decision = {
        id = "bao_bridge_test_decision",
        decision = "guard",
        score = 75,
        source = "routine_bridge_test"
    }

    local result =
        bridge.RegisterDecision(
            decision
        )

    local success =
        result ~= false

    Test(
        "Register decision",
        success,
        "result=" .. tostring(result)
    )

    return success
end

------------------------------------------------------------
-- TEST 12
-- STATUS
------------------------------------------------------------

local function TestStatus()
    Log("------------------------------------------------")
    Log("TEST 12: Status")
    Log("------------------------------------------------")

    local bridge = GetBridge()

    if not bridge or not bridge.GetStatus then

        Test(
            "GetStatus available",
            false
        )

        return false
    end

    local status =
        bridge.GetStatus()

    local valid =
        type(status) == "table"

    Test(
        "Bridge status available",
        valid,
        "statusType=" .. type(status)
    )

    if not valid then
        return false
    end

    local initialized =
        ReadField(
            status,
            "initialized"
        )

    Test(
        "Status initialized",
        initialized == true,
        "initialized=" .. tostring(initialized)
    )

    return true
end

------------------------------------------------------------
-- FINAL REPORT
------------------------------------------------------------

local function PrintFinalReport()
    Log("================================================")
    Log("ROUTINE / DECISION BRIDGE TEST REPORT")
    Log("================================================")

    Log(
        "TOTAL: "
        .. tostring(totalTests)
    )

    Log(
        "PASS:  "
        .. tostring(passedTests)
    )

    Log(
        "FAIL:  "
        .. tostring(failedTests)
    )

    if failedTests == 0 then
        Log("STATUS: ALL TESTS PASSED")
    else
        Log("STATUS: TESTS FAILED")
    end

    Log("================================================")
end

------------------------------------------------------------
-- RUN ALL TESTS
------------------------------------------------------------

function TestHarness.Run()
    Log("================================================")
    Log("Routine / Decision Bridge Test Harness V1.0")
    Log("================================================")

    totalTests = 0
    passedTests = 0
    failedTests = 0

    testRoutineId = nil
    testActivityIds = {}

    local dependenciesReady =
        TestDependencies()

    if not dependenciesReady then

        Log(
            "Dependencies are not ready."
        )

        PrintFinalReport()
        return
    end

    TestInitialization()

    TestRoutineCreation()

    if testRoutineId ~= nil then

        TestActivityCreation()
        TestIntentMapping()
        TestRoutineContext()
        TestDecisionContext()
        TestEmergencyDetection()
        TestEmergencyOverride()
        TestBridgeUpdate()
        TestRegisterDecision()
        TestStatus()

    else

        Log(
            "Skipping routine-dependent tests."
        )

    end

    PrintFinalReport()
end

------------------------------------------------------------
-- GAME START
------------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(function()

        Log("OnGameStart")

        local bridge =
            GetBridge()

        if not bridge then

            Log(
                "Bridge not available at OnGameStart"
            )

            return
        end

        if bridge.GetStatus then

            local status =
                bridge.GetStatus()

            if type(status) == "table"
                and ReadField(
                    status,
                    "initialized"
                ) == true then

                TestHarness.Run()

            else

                Log(
                    "Bridge exists but is not initialized yet"
                )

            end

        else

            TestHarness.Run()

        end

    end)

end

------------------------------------------------------------
-- EXPORT
------------------------------------------------------------

if not BAO then
    BAO = {}
end

BAO.RoutineDecisionBridgeTestHarness =
    TestHarness

Log(
    "Routine / Decision Bridge Test Harness V1.0 module loaded"
)
