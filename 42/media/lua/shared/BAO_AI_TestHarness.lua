-- =========================================================
-- BanditsAIOverhaul
-- BAO_AI_TestHarness.lua
-- AI Test Harness V1.1
--
-- Purpose:
--   Automated testing of DecisionSystem using artificial
--   WorldContext scenarios.
--
-- V1.1 fixes:
--   - Runs only once
--   - Removes OnTick callback after completion
--   - Prevents duplicate test runs
--   - Prevents infinite test loop
--   - Reduces excessive logging
--   - Does not modify real WorldContext permanently
--   - Tests the real DecisionSystem scoring logic
-- =========================================================

BAO = BAO or {}

local TestHarness = {}

local MODULE_NAME = "AI_TestHarness"

local function Log(message)
    print("[BAO][" .. MODULE_NAME .. "] " .. tostring(message))
end


-- =========================================================
-- Runtime state
-- =========================================================

local initialized = false
local running = false
local completed = false
local testScheduled = false

local totalTests = 0
local passedTests = 0
local failedTests = 0

local tickHandler = nil


-- =========================================================
-- Test scenarios
-- =========================================================

local TESTS = {

    {
        id = "NORMAL",

        description = "Normal healthy situation",

        expected = "gather_resources",

        context = {
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
        id = "LOW_HEALTH",

        description = "Critically low health",

        expected = "heal",

        context = {
            Health = 15,
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
        id = "HIGH_FATIGUE",

        description = "Extremely tired",

        expected = "rest",

        context = {
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
        id = "MANY_ZOMBIES",

        description = "Large zombie group nearby",

        expected = "retreat",

        context = {
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
        id = "NIGHT",

        description = "Night time",

        expected = "guard",

        context = {
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
        id = "NO_WEAPON",

        description = "No weapon available",

        expected = "gather_resources",

        context = {
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
        id = "HUNGRY",

        description = "Very hungry",

        expected = "gather_resources",

        context = {
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
        id = "THIRSTY",

        description = "Very thirsty",

        expected = "gather_resources",

        context = {
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
        id = "PANIC",

        description = "Extreme panic",

        expected = "retreat",

        context = {
            Health = 100,
            Hunger = 0,
            Thirst = 0,
            Fatigue = 0,
            Panic = 100,
            Pain = 0,
            ZombiesNearby = 0,
            Night = false,
            HasWeapon = true,
            Ranged = true
        }
    }
}


-- =========================================================
-- Check dependencies
-- =========================================================

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

    if not BAO.BehaviorProfile.Get then
        return false
    end

    return true
end


-- =========================================================
-- Remove OnTick handler
-- =========================================================

local function RemoveTickHandler()

    if tickHandler and Events and Events.OnTick then

        Events.OnTick.Remove(tickHandler)

        tickHandler = nil

        Log("OnTick test handler removed")

    end
end


-- =========================================================
-- Run one test
-- =========================================================

local function RunTest(test)

    Log("----------------------------------------")
    Log("TEST: " .. test.id)
    Log("Description: " .. test.description)

    local result =
        BAO.DecisionSystem.CalculateWithContext(
            test.context
        )


    if not result then

        Log("Expected: " .. tostring(test.expected))
        Log("Actual:   nil")
        Log("RESULT: FAIL")

        failedTests = failedTests + 1
        totalTests = totalTests + 1

        return

    end


    local decision = result.Decision

    local actual =
        decision and decision.ID or nil

    local score =
        decision and decision.Score or 0

    local priority =
        decision and decision.Priority or 0


    local passed =
        actual == test.expected


    Log(
        "Expected: " ..
        tostring(test.expected)
    )

    Log(
        "Actual:   " ..
        tostring(actual)
    )

    Log(
        "Score:    " ..
        string.format("%.2f", score)
    )

    Log(
        "Priority: " ..
        tostring(priority)
    )


    if passed then

        Log("RESULT: PASS")

        passedTests = passedTests + 1

    else

        Log("RESULT: FAIL")

        failedTests = failedTests + 1

    end


    totalTests = totalTests + 1
end


-- =========================================================
-- Run all tests
-- =========================================================

local function RunAllTests()

    if running then
        return
    end

    if completed then
        return
    end


    if not DependenciesReady() then

        Log("Dependencies are not ready")

        return

    end


    running = true


    Log("")
    Log("========================================")
    Log("BAO AI TEST HARNESS V1.1")
    Log("========================================")
    Log("Starting Decision System tests...")
    Log("")


    totalTests = 0
    passedTests = 0
    failedTests = 0


    for _, test in ipairs(TESTS) do

        RunTest(test)

    end


    Log("")
    Log("========================================")
    Log("TEST HARNESS SUMMARY")
    Log("========================================")

    Log(
        "Total:  " ..
        tostring(totalTests)
    )

    Log(
        "Passed: " ..
        tostring(passedTests)
    )

    Log(
        "Failed: " ..
        tostring(failedTests)
    )


    if failedTests == 0 then

        Log("ALL TESTS PASSED")

    else

        Log("SOME TESTS FAILED")

    end


    Log("========================================")
    Log("AI Test Harness V1.1 complete")
    Log("========================================")


    running = false
    completed = true

    RemoveTickHandler()
end


-- =========================================================
-- Delayed execution
--
-- We wait for the normal BAO initialization chain:
--
-- PlayerProfile
--      ↓
-- RoleScoring
--      ↓
-- Specialization
--      ↓
-- BehaviorProfile
--      ↓
-- WorldContext
--      ↓
-- DecisionSystem
--
-- Only then start the tests.
-- =========================================================

local function TryStartTests()

    if completed then
        return
    end

    if running then
        return
    end

    if testScheduled then
        return
    end


    if not DependenciesReady() then
        return
    end


    testScheduled = true

    Log("Dependencies ready")
    Log("Scheduling AI tests...")


    -- Execute on the next tick.
    --
    -- This prevents the harness from running in the middle
    -- of another BAO initialization event.

    if Events and Events.OnTick then

        local oneShotHandler

        oneShotHandler = function()

            if Events and Events.OnTick then
                Events.OnTick.Remove(oneShotHandler)
            end

            testScheduled = false

            RunAllTests()

        end

        Events.OnTick.Add(oneShotHandler)

    else

        testScheduled = false
        RunAllTests()

    end
end


-- =========================================================
-- Event registration
-- =========================================================

if Events then

    if Events.OnGameStart then

        Events.OnGameStart.Add(function()

            Log("OnGameStart received")

            TryStartTests()

        end)

    end


    if Events.OnTick then

        tickHandler = function()

            if completed then

                RemoveTickHandler()

                return

            end


            TryStartTests()

        end


        Events.OnTick.Add(tickHandler)

    end

end


-- =========================================================
-- Public API
-- =========================================================

function TestHarness.Run()

    RunAllTests()

end


function TestHarness.IsCompleted()

    return completed

end


function TestHarness.GetResults()

    return {
        Total = totalTests,
        Passed = passedTests,
        Failed = failedTests,
        Completed = completed
    }

end


BAO.AI_TestHarness =
    TestHarness


Log("AI Test Harness V1.1 module loaded")