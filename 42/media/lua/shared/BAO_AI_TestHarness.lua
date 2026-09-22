-----------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_AI_TestHarness.lua
-- AI Test Harness V1.2
--
-- IMPORTANT:
-- This harness runs ONCE per game session.
-- It does NOT continuously calculate decisions.
-----------------------------------------------------------

BAO = BAO or {}

-----------------------------------------------------------
-- GLOBAL DUPLICATE PROTECTION
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
    -- RUN SINGLE TEST
    -------------------------------------------------------

    local function RunTest(test)

        totalCount = totalCount + 1

        Log("")
        Log("--------------------------------------------")
        Log("TEST #" .. tostring(totalCount) .. ": " .. test.Name)
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
        Log("BAO AI TEST HARNESS V1.2")
        Log("STARTING TEST SUITE")
        Log("============================================")

        ---------------------------------------------------
        -- RUN TESTS ONCE
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
        -- VERY IMPORTANT
        -- No more OnTick testing.
        ---------------------------------------------------

        RemoveRetryHandler()

    end

    -------------------------------------------------------
    -- CHECK DEPENDENCIES
    -------------------------------------------------------

    local function DependenciesReady()

        if not BAO.DecisionSystem then
            return false
        end

        if not BAO.DecisionSystem.CalculateWithContext then
            return false
        end

        if not BAO.BehaviorProfile then
            return false
        end

        return true
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

        if not DependenciesReady() then

            return
        end

        initialized = true

        ---------------------------------------------------
        -- Remove dependency polling BEFORE running tests.
        ---------------------------------------------------

        RemoveRetryHandler()

        ---------------------------------------------------
        -- Run exactly once.
        ---------------------------------------------------

        RunAllTests()

    end

    -------------------------------------------------------
    -- GAME START
    -------------------------------------------------------

    if Events and Events.OnGameStart then

        Events.OnGameStart.Add(function()

            Log("OnGameStart")

            TryStartTests()

        end)

    end

    -------------------------------------------------------
    -- RETRY HANDLER
    --
    -- IMPORTANT:
    -- We DO NOT run tests every tick.
    -- We only check dependencies once every 60 ticks.
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
    -- PUBLIC API
    -------------------------------------------------------

    function TestHarness.Run()

        if completed then

            Log("Manual Run ignored: suite already completed")

            return false
        end

        if running then

            Log("Manual Run ignored: suite already running")

            return false
        end

        if not DependenciesReady() then

            Log("Manual Run failed: dependencies not ready")

            return false
        end

        initialized = true

        RemoveRetryHandler()

        RunAllTests()

        return true
    end

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

    Log("AI Test Harness V1.2 module loaded")

end