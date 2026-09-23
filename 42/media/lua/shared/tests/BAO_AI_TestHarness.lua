-----------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_AI_TestHarness.lua
-- AI Test Harness V1.3
--
-- Purpose:
-- Safe one-shot testing of Decision System.
--
-- IMPORTANT:
-- Harness waits for BehaviorProfile to become actually
-- available before running tests.
--
-- Tests are executed ONLY ONCE.
-- No continuous decision calculations.
-----------------------------------------------------------

BAO = BAO or {}

-----------------------------------------------------------
-- DUPLICATE PROTECTION
-----------------------------------------------------------

if BAO.__AI_TEST_HARNESS_STARTED then

    print("[BAO][AI_TestHarness] Duplicate load ignored")

else

    BAO.__AI_TEST_HARNESS_STARTED = true

    -------------------------------------------------------
    -- MODULE
    -------------------------------------------------------

    local TestHarness = {}

    local MODULE_NAME = "BAO_AI_TestHarness"

    -------------------------------------------------------
    -- LOG
    -------------------------------------------------------

    local function Log(message)

        print(
            "[BAO][" .. MODULE_NAME .. "] "
            .. tostring(message)
        )

    end

    -------------------------------------------------------
    -- STATE
    -------------------------------------------------------

    local initialized = false
    local running = false
    local completed = false

    local retryTick = 0

    local passCount = 0
    local failCount = 0
    local totalCount = 0

    local retryHandler = nil

    -------------------------------------------------------
    -- TEST DEFINITIONS
    -------------------------------------------------------

    local TESTS = {

        ---------------------------------------------------
        -- NORMAL
        ---------------------------------------------------

        {
            Name = "NORMAL",

            Expected = "combat",

            Context = {

                Health = 100,
                Hunger = 0,
                Thirst = 0,
                Fatigue = 0,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 0,

                Night = false,

                HasWeapon = true,
                Ranged = true
            }
        },

        ---------------------------------------------------
        -- LOW HEALTH
        ---------------------------------------------------

        {
            Name = "LOW_HEALTH",

            Expected = "heal",

            Context = {

                Health = 20,
                Hunger = 0,
                Thirst = 0,
                Fatigue = 0,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 0,

                Night = false,

                HasWeapon = true,
                Ranged = true
            }
        },

        ---------------------------------------------------
        -- HIGH FATIGUE
        ---------------------------------------------------

        {
            Name = "HIGH_FATIGUE",

            Expected = "rest",

            Context = {

                Health = 100,
                Hunger = 0,
                Thirst = 0,
                Fatigue = 90,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 0,

                Night = false,

                HasWeapon = true,
                Ranged = true
            }
        },

        ---------------------------------------------------
        -- MANY ZOMBIES
        ---------------------------------------------------

        {
            Name = "MANY_ZOMBIES",

            Expected = "retreat",

            Context = {

                Health = 100,
                Hunger = 0,
                Thirst = 0,
                Fatigue = 0,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 25,

                Night = false,

                HasWeapon = true,
                Ranged = true
            }
        },

        ---------------------------------------------------
        -- NIGHT
        ---------------------------------------------------

        {
            Name = "NIGHT",

            Expected = "combat",

            Context = {

                Health = 100,
                Hunger = 0,
                Thirst = 0,
                Fatigue = 0,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 0,

                Night = true,

                HasWeapon = true,
                Ranged = true
            }
        },

        ---------------------------------------------------
        -- NO WEAPON
        ---------------------------------------------------

        {
            Name = "NO_WEAPON",

            Expected = "gather_resources",

            Context = {

                Health = 100,
                Hunger = 0,
                Thirst = 0,
                Fatigue = 0,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 0,

                Night = false,

                HasWeapon = false,
                Ranged = false
            }
        },

        ---------------------------------------------------
        -- HUNGRY
        ---------------------------------------------------

        {
            Name = "HUNGRY",

            Expected = "gather_resources",

            Context = {

                Health = 100,
                Hunger = 90,
                Thirst = 0,
                Fatigue = 0,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 0,

                Night = false,

                HasWeapon = true,
                Ranged = true
            }
        },

        ---------------------------------------------------
        -- THIRSTY
        ---------------------------------------------------

        {
            Name = "THIRSTY",

            Expected = "gather_resources",

            Context = {

                Health = 100,
                Hunger = 0,
                Thirst = 90,
                Fatigue = 0,
                Panic = 0,
                Pain = 0,

                ZombiesNearby = 0,

                Night = false,

                HasWeapon = true,
                Ranged = true
            }
        },

        ---------------------------------------------------
        -- PANIC
        ---------------------------------------------------

        {
            Name = "PANIC",

            Expected = "retreat",

            Context = {

                Health = 100,
                Hunger = 0,
                Thirst = 0,
                Fatigue = 0,
                Panic = 90,
                Pain = 0,

                ZombiesNearby = 0,

                Night = false,

                HasWeapon = true,
                Ranged = true
            }
        }
    }

    -------------------------------------------------------
    -- REMOVE RETRY HANDLER
    -------------------------------------------------------

    local function RemoveRetryHandler()

        if retryHandler
        and Events
        and Events.OnTick then

            Events.OnTick.Remove(retryHandler)

            retryHandler = nil

            Log("Retry OnTick handler removed")

        end

    end

    -------------------------------------------------------
    -- CHECK BEHAVIOR PROFILE
    -------------------------------------------------------

    local function GetReadyBehaviorProfile()

        if not BAO.BehaviorProfile then
            return nil
        end

        if not BAO.BehaviorProfile.Get then
            return nil
        end

        local profile = BAO.BehaviorProfile.Get()

        if not profile then
            return nil
        end

        ---------------------------------------------------
        -- Verify that the profile actually contains data.
        ---------------------------------------------------

        if not profile.Personality then
            return nil
        end

        if not profile.Capabilities then
            return nil
        end

        if not profile.Tendencies then
            return nil
        end

        return profile

    end

    -------------------------------------------------------
    -- CHECK WORLD CONTEXT
    -------------------------------------------------------

    local function WorldContextReady()

        if not BAO.WorldContext then
            return false
        end

        if BAO.WorldContext.Current then
            return true
        end

        if BAO.WorldContext.Get then

            local world = BAO.WorldContext.Get()

            if world then
                return true
            end

        end

        return false

    end

    -------------------------------------------------------
    -- CHECK ALL DEPENDENCIES
    -------------------------------------------------------

    local function DependenciesReady()

        ---------------------------------------------------
        -- DecisionSystem
        ---------------------------------------------------

        if not BAO.DecisionSystem then

            return false
        end

        if not BAO.DecisionSystem.CalculateWithContext then

            return false
        end

        ---------------------------------------------------
        -- BehaviorProfile
        ---------------------------------------------------

        local behavior = GetReadyBehaviorProfile()

        if not behavior then

            return false
        end

        ---------------------------------------------------
        -- WorldContext
        ---------------------------------------------------

        if not WorldContextReady() then

            return false
        end

        return true

    end

    -------------------------------------------------------
    -- RUN SINGLE TEST
    -------------------------------------------------------

    local function RunTest(test)

        totalCount = totalCount + 1

        Log("")
        Log("--------------------------------------------")
        Log(
            "TEST #"
            .. tostring(totalCount)
            .. ": "
            .. tostring(test.Name)
        )
        Log("--------------------------------------------")

        local DecisionSystem = BAO.DecisionSystem

        if not DecisionSystem then

            Log("FAIL: DecisionSystem unavailable")

            failCount = failCount + 1

            return

        end

        if not DecisionSystem.CalculateWithContext then

            Log("FAIL: CalculateWithContext unavailable")

            failCount = failCount + 1

            return

        end

        local result =
            DecisionSystem.CalculateWithContext(
                test.Context
            )

        if not result then

            Log("FAIL: test returned nil")

            failCount = failCount + 1

            return

        end

        if not result.Decision then

            Log("FAIL: result.Decision missing")

            failCount = failCount + 1

            return

        end

        local actual = result.Decision.ID
        local score = result.Decision.Score
        local priority = result.Decision.Priority

        Log(
            "Expected: "
            .. tostring(test.Expected)
        )

        Log(
            "Actual: "
            .. tostring(actual)
        )

        Log(
            "Score: "
            .. string.format("%.2f", score)
        )

        Log(
            "Priority: "
            .. tostring(priority)
        )

        if actual == test.Expected then

            passCount = passCount + 1

            Log("RESULT: PASS")

        else

            failCount = failCount + 1

            Log("RESULT: FAIL")

        end

    end

    -------------------------------------------------------
    -- RUN ALL TESTS
    -------------------------------------------------------

    local function RunAllTests()

        if running then

            Log("Test suite already running")

            return

        end

        if completed then

            Log("Test suite already completed")

            return

        end

        running = true

        passCount = 0
        failCount = 0
        totalCount = 0

        Log("")
        Log("============================================")
        Log("BAO AI TEST HARNESS V1.3")
        Log("STARTING TEST SUITE")
        Log("============================================")

        ---------------------------------------------------
        -- RUN EACH TEST EXACTLY ONCE
        ---------------------------------------------------

        for _, test in ipairs(TESTS) do

            RunTest(test)

        end

        ---------------------------------------------------
        -- SUMMARY
        ---------------------------------------------------

        Log("")
        Log("============================================")
        Log("TEST SUITE COMPLETE")
        Log("============================================")

        Log(
            "TOTAL: "
            .. tostring(totalCount)
        )

        Log(
            "PASS: "
            .. tostring(passCount)
        )

        Log(
            "FAIL: "
            .. tostring(failCount)
        )

        if failCount == 0 then

            Log("STATUS: ALL TESTS PASSED")

        else

            Log("STATUS: SOME TESTS FAILED")

        end

        Log("============================================")

        completed = true
        running = false

        ---------------------------------------------------
        -- IMPORTANT:
        -- Never poll again after completion.
        ---------------------------------------------------

        RemoveRetryHandler()

    end

    -------------------------------------------------------
    -- TRY START
    -------------------------------------------------------

    local function TryStartTests()

        if initialized then
            return
        end

        if running then
            return
        end

        if completed then
            return
        end

        ---------------------------------------------------
        -- Wait until ALL BAO dependencies are actually
        -- initialized.
        ---------------------------------------------------

        if not DependenciesReady() then

            return

        end

        ---------------------------------------------------
        -- Everything is ready.
        ---------------------------------------------------

        initialized = true

        Log("All dependencies ready")

        RemoveRetryHandler()

        RunAllTests()

    end

    -------------------------------------------------------
    -- GAME START
    -------------------------------------------------------

    if Events and Events.OnGameStart then

        Events.OnGameStart.Add(function()

            Log("OnGameStart")

            ------------------------------------------------
            -- Do NOT assume dependencies are ready here.
            ------------------------------------------------

            TryStartTests()

        end)

    end

    -------------------------------------------------------
    -- RETRY
    --
    -- Check only once every 60 ticks.
    --
    -- This is NOT a decision calculation.
    -- It only checks whether modules are ready.
    -------------------------------------------------------

    if Events and Events.OnTick then

        retryHandler = function()

            if initialized or completed then

                RemoveRetryHandler()

                return

            end

            retryTick = retryTick + 1

            if retryTick >= 60 then

                retryTick = 0

                TryStartTests()

            end

        end

        Events.OnTick.Add(retryHandler)

    end

    -------------------------------------------------------
    -- PUBLIC MANUAL RUN
    -------------------------------------------------------

    function TestHarness.Run()

        if completed then

            Log(
                "Manual Run ignored: suite already completed"
            )

            return false

        end

        if running then

            Log(
                "Manual Run ignored: suite already running"
            )

            return false

        end

        if not DependenciesReady() then

            Log(
                "Manual Run failed: dependencies not ready"
            )

            return false

        end

        initialized = true

        RemoveRetryHandler()

        RunAllTests()

        return true

    end

    -------------------------------------------------------
    -- STATUS
    -------------------------------------------------------

    function TestHarness.IsCompleted()

        return completed

    end

    -------------------------------------------------------

    function TestHarness.GetResults()

        return {

            Total = totalCount,

            Passed = passCount,

            Failed = failCount,

            Completed = completed

        }

    end

    -------------------------------------------------------
    -- EXPORT
    -------------------------------------------------------

    BAO.AI_TestHarness = TestHarness

    -------------------------------------------------------
    -- MODULE LOADED
    -------------------------------------------------------

    Log("AI Test Harness V1.3 module loaded")

end