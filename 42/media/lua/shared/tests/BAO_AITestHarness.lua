---------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_AITestHarness.lua
-- V1.1
--
-- Automated Decision System scenario testing.
--
-- IMPORTANT:
-- DecisionSystem uses WorldContext values in the 0-100
-- range for Health/Hunger/Thirst/Fatigue/Panic/Pain.
--
-- Test calculations use CalculateWithContext() and do
-- NOT modify the live DecisionSystem runtime state.
---------------------------------------------------------

BAO = BAO or {}
BAO.AITestHarness = BAO.AITestHarness or {}

local Harness = BAO.AITestHarness

---------------------------------------------------------
-- CONFIG
---------------------------------------------------------

Harness.Version = "V1.1"

Harness.Enabled = true

Harness.LogPrefix = "[BAO][AI Test Harness]"

---------------------------------------------------------
-- SCENARIOS
---------------------------------------------------------

Harness.Scenarios = {

    NORMAL = {

        Name = "NORMAL",

        WorldContext = {

            Health = 100,
            Hunger = 0,
            Thirst = 0,
            Fatigue = 0,
            Panic = 0,
            Pain = 0,

            ZombiesNearby = 0,

            Night = false,

            HasWeapon = true,
            Ranged = false
        }
    },

    LOW_HEALTH = {

        Name = "LOW_HEALTH",

        WorldContext = {

            Health = 25,
            Hunger = 0,
            Thirst = 0,
            Fatigue = 0,
            Panic = 0,
            Pain = 20,

            ZombiesNearby = 0,

            Night = false,

            HasWeapon = true,
            Ranged = false
        }
    },

    HIGH_FATIGUE = {

        Name = "HIGH_FATIGUE",

        WorldContext = {

            Health = 100,
            Hunger = 0,
            Thirst = 0,
            Fatigue = 90,
            Panic = 0,
            Pain = 0,

            ZombiesNearby = 0,

            Night = false,

            HasWeapon = true,
            Ranged = false
        }
    },

    MANY_ZOMBIES = {

        Name = "MANY_ZOMBIES",

        WorldContext = {

            Health = 100,
            Hunger = 0,
            Thirst = 0,
            Fatigue = 0,
            Panic = 0,
            Pain = 0,

            ZombiesNearby = 30,

            Night = false,

            HasWeapon = true,
            Ranged = false
        }
    },

    NIGHT = {

        Name = "NIGHT",

        WorldContext = {

            Health = 100,
            Hunger = 0,
            Thirst = 0,
            Fatigue = 0,
            Panic = 0,
            Pain = 0,

            ZombiesNearby = 0,

            Night = true,

            HasWeapon = true,
            Ranged = false
        }
    },

    NO_WEAPON = {

        Name = "NO_WEAPON",

        WorldContext = {

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

    HUNGRY = {

        Name = "HUNGRY",

        WorldContext = {

            Health = 100,
            Hunger = 90,
            Thirst = 0,
            Fatigue = 0,
            Panic = 0,
            Pain = 0,

            ZombiesNearby = 0,

            Night = false,

            HasWeapon = true,
            Ranged = false
        }
    },

    THIRSTY = {

        Name = "THIRSTY",

        WorldContext = {

            Health = 100,
            Hunger = 0,
            Thirst = 90,
            Fatigue = 0,
            Panic = 0,
            Pain = 0,

            ZombiesNearby = 0,

            Night = false,

            HasWeapon = true,
            Ranged = false
        }
    },

    PANIC = {

        Name = "PANIC",

        WorldContext = {

            Health = 100,
            Hunger = 0,
            Thirst = 0,
            Fatigue = 0,
            Panic = 100,
            Pain = 0,

            ZombiesNearby = 10,

            Night = false,

            HasWeapon = true,
            Ranged = false
        }
    }
}

---------------------------------------------------------
-- ORDER
---------------------------------------------------------

Harness.ScenarioOrder = {

    "NORMAL",
    "LOW_HEALTH",
    "HIGH_FATIGUE",
    "MANY_ZOMBIES",
    "NIGHT",
    "NO_WEAPON",
    "HUNGRY",
    "THIRSTY",
    "PANIC"
}

---------------------------------------------------------
-- LOG
---------------------------------------------------------

local function Log(message)

    print(
        Harness.LogPrefix
        .. " "
        .. tostring(message)
    )

end

---------------------------------------------------------
-- FORMAT NUMBER
---------------------------------------------------------

local function FormatNumber(value)

    if type(value) ~= "number" then
        return tostring(value)
    end

    return string.format("%.2f", value)

end

---------------------------------------------------------
-- CHECK DECISION SYSTEM
---------------------------------------------------------

function Harness.IsDecisionSystemReady()

    if not BAO.DecisionSystem then

        return false
    end

    if not BAO.DecisionSystem.CalculateWithContext then

        return false
    end

    return true

end

---------------------------------------------------------
-- GET SCENARIO
---------------------------------------------------------

function Harness.GetScenario(name)

    return Harness.Scenarios[name]

end

---------------------------------------------------------
-- RUN ONE SCENARIO
---------------------------------------------------------

function Harness.RunScenario(name)

    local scenario =
        Harness.GetScenario(name)

    if not scenario then

        Log(
            "ERROR: Unknown scenario: "
            .. tostring(name)
        )

        return nil
    end

    Log("")
    Log("========================================")
    Log(
        "SCENARIO: "
        .. tostring(scenario.Name)
    )
    Log("========================================")

    if not Harness.IsDecisionSystemReady() then

        Log(
            "ERROR: DecisionSystem.CalculateWithContext() unavailable"
        )

        return nil
    end

    local context =
        scenario.WorldContext

    Log(
        "Health="
        .. tostring(context.Health)
        .. " Hunger="
        .. tostring(context.Hunger)
        .. " Thirst="
        .. tostring(context.Thirst)
    )

    Log(
        "Fatigue="
        .. tostring(context.Fatigue)
        .. " Panic="
        .. tostring(context.Panic)
        .. " Pain="
        .. tostring(context.Pain)
    )

    Log(
        "Zombies="
        .. tostring(context.ZombiesNearby)
        .. " Night="
        .. tostring(context.Night)
        .. " Weapon="
        .. tostring(context.HasWeapon)
    )

    -----------------------------------------------------
    -- TEST CALCULATION
    -----------------------------------------------------

    local result =
        BAO.DecisionSystem.CalculateWithContext(
            context
        )

    if not result then

        Log(
            "FAIL: DecisionSystem returned nil"
        )

        return nil
    end

    if not result.Decision then

        Log(
            "FAIL: Result has no Decision"
        )

        return nil
    end

    -----------------------------------------------------
    -- RESULT
    -----------------------------------------------------

    local decision =
        result.Decision

    Log("")
    Log("RESULT")
    Log(
        "Decision="
        .. tostring(decision.ID)
    )

    Log(
        "Score="
        .. FormatNumber(decision.Score)
    )

    Log(
        "Priority="
        .. tostring(decision.Priority)
    )

    -----------------------------------------------------
    -- SCORE TABLE
    -----------------------------------------------------

    if result.Scores then

        Log("")
        Log("SCORES")

        for decisionName, score
            in pairs(result.Scores) do

            Log(
                tostring(decisionName)
                .. "="
                .. FormatNumber(score)
            )

        end

    end

    -----------------------------------------------------
    -- RETURN STRUCTURED RESULT
    -----------------------------------------------------

    return {

        Scenario = scenario.Name,

        Decision = decision.ID,

        Score = decision.Score,

        Priority = decision.Priority,

        Scores = result.Scores,

        WorldContext = result.WorldContext
    }

end

---------------------------------------------------------
-- RUN ALL
---------------------------------------------------------

function Harness.RunAll()

    Log("")
    Log("########################################")
    Log(
        "BAO AI TEST HARNESS "
        .. Harness.Version
    )
    Log("FULL SCENARIO TEST")
    Log("########################################")

    local results = {}

    local passed = 0
    local failed = 0

    for _, scenarioName
        in ipairs(Harness.ScenarioOrder) do

        local result =
            Harness.RunScenario(
                scenarioName
            )

        results[scenarioName] = result

        if result then

            passed = passed + 1

        else

            failed = failed + 1

        end

    end

    Log("")
    Log("########################################")
    Log("TEST COMPLETE")
    Log(
        "PASSED="
        .. tostring(passed)
    )

    Log(
        "FAILED="
        .. tostring(failed)
    )

    Log("########################################")

    return {

        Results = results,

        Passed = passed,

        Failed = failed,

        Total = passed + failed
    }

end

---------------------------------------------------------
-- INDIVIDUAL TEST API
---------------------------------------------------------

function Harness.TestNormal()

    return Harness.RunScenario("NORMAL")

end

function Harness.TestLowHealth()

    return Harness.RunScenario("LOW_HEALTH")

end

function Harness.TestHighFatigue()

    return Harness.RunScenario("HIGH_FATIGUE")

end

function Harness.TestManyZombies()

    return Harness.RunScenario("MANY_ZOMBIES")

end

function Harness.TestNight()

    return Harness.RunScenario("NIGHT")

end

function Harness.TestNoWeapon()

    return Harness.RunScenario("NO_WEAPON")

end

function Harness.TestHungry()

    return Harness.RunScenario("HUNGRY")

end

function Harness.TestThirsty()

    return Harness.RunScenario("THIRSTY")

end

function Harness.TestPanic()

    return Harness.RunScenario("PANIC")

end

---------------------------------------------------------
-- LOADED
---------------------------------------------------------

Log(
    "Loaded successfully - "
    .. Harness.Version
)