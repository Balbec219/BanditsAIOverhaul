---------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_AITestHarness.lua
-- V1.0
--
-- Purpose:
-- Automated testing of BAO Decision System
--
-- Scenarios:
-- NORMAL
-- LOW_HEALTH
-- HIGH_FATIGUE
-- MANY_ZOMBIES
-- NIGHT
-- NO_WEAPON
-- HUNGRY
-- THIRSTY
-- PANIC
---------------------------------------------------------

BAO = BAO or {}
BAO.AITestHarness = BAO.AITestHarness or {}

local Harness = BAO.AITestHarness

---------------------------------------------------------
-- Configuration
---------------------------------------------------------

Harness.Version = "V1.0"

Harness.Enabled = true

Harness.LogPrefix = "[BAO][AI Test Harness]"

---------------------------------------------------------
-- Scenario definitions
---------------------------------------------------------

Harness.Scenarios = {

    NORMAL = {
        name = "NORMAL",

        world = {
            threatLevel = 0,
            zombieCount = 0,
            isNight = false,
        },

        player = {
            health = 1.0,
            fatigue = 0.0,
            hunger = 0.0,
            thirst = 0.0,
            panic = 0.0,
            hasWeapon = true,
        },
    },

    LOW_HEALTH = {
        name = "LOW_HEALTH",

        world = {
            threatLevel = 0,
            zombieCount = 0,
            isNight = false,
        },

        player = {
            health = 0.25,
            fatigue = 0.0,
            hunger = 0.0,
            thirst = 0.0,
            panic = 0.0,
            hasWeapon = true,
        },
    },

    HIGH_FATIGUE = {
        name = "HIGH_FATIGUE",

        world = {
            threatLevel = 0,
            zombieCount = 0,
            isNight = false,
        },

        player = {
            health = 1.0,
            fatigue = 0.90,
            hunger = 0.0,
            thirst = 0.0,
            panic = 0.0,
            hasWeapon = true,
        },
    },

    MANY_ZOMBIES = {
        name = "MANY_ZOMBIES",

        world = {
            threatLevel = 1.0,
            zombieCount = 30,
            isNight = false,
        },

        player = {
            health = 1.0,
            fatigue = 0.0,
            hunger = 0.0,
            thirst = 0.0,
            panic = 0.0,
            hasWeapon = true,
        },
    },

    NIGHT = {
        name = "NIGHT",

        world = {
            threatLevel = 0,
            zombieCount = 0,
            isNight = true,
        },

        player = {
            health = 1.0,
            fatigue = 0.0,
            hunger = 0.0,
            thirst = 0.0,
            panic = 0.0,
            hasWeapon = true,
        },
    },

    NO_WEAPON = {
        name = "NO_WEAPON",

        world = {
            threatLevel = 0,
            zombieCount = 0,
            isNight = false,
        },

        player = {
            health = 1.0,
            fatigue = 0.0,
            hunger = 0.0,
            thirst = 0.0,
            panic = 0.0,
            hasWeapon = false,
        },
    },

    HUNGRY = {
        name = "HUNGRY",

        world = {
            threatLevel = 0,
            zombieCount = 0,
            isNight = false,
        },

        player = {
            health = 1.0,
            fatigue = 0.0,
            hunger = 0.90,
            thirst = 0.0,
            panic = 0.0,
            hasWeapon = true,
        },
    },

    THIRSTY = {
        name = "THIRSTY",

        world = {
            threatLevel = 0,
            zombieCount = 0,
            isNight = false,
        },

        player = {
            health = 1.0,
            fatigue = 0.0,
            hunger = 0.0,
            thirst = 0.90,
            panic = 0.0,
            hasWeapon = true,
        },
    },

    PANIC = {
        name = "PANIC",

        world = {
            threatLevel = 1.0,
            zombieCount = 10,
            isNight = false,
        },

        player = {
            health = 1.0,
            fatigue = 0.0,
            hunger = 0.0,
            thirst = 0.0,
            panic = 1.0,
            hasWeapon = true,
        },
    },
}

---------------------------------------------------------
-- Ordered scenario list
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
    "PANIC",

}

---------------------------------------------------------
-- Utility
---------------------------------------------------------

local function Log(message)

    print(
        Harness.LogPrefix
        .. " "
        .. tostring(message)
    )

end

---------------------------------------------------------
-- Print scenario
---------------------------------------------------------

function Harness.PrintScenario(scenario)

    if not scenario then

        Log("ERROR: scenario is nil")

        return

    end

    Log("----------------------------------------")

    Log(
        "Scenario: "
        .. tostring(scenario.name)
    )

    Log(
        "Health: "
        .. tostring(scenario.player.health)
    )

    Log(
        "Fatigue: "
        .. tostring(scenario.player.fatigue)
    )

    Log(
        "Hunger: "
        .. tostring(scenario.player.hunger)
    )

    Log(
        "Thirst: "
        .. tostring(scenario.player.thirst)
    )

    Log(
        "Panic: "
        .. tostring(scenario.player.panic)
    )

    Log(
        "Weapon: "
        .. tostring(scenario.player.hasWeapon)
    )

    Log(
        "Zombies: "
        .. tostring(scenario.world.zombieCount)
    )

    Log(
        "Threat: "
        .. tostring(scenario.world.threatLevel)
    )

    Log(
        "Night: "
        .. tostring(scenario.world.isNight)
    )

end

---------------------------------------------------------
-- Run one scenario
---------------------------------------------------------

function Harness.RunScenario(name)

    local scenario =
        Harness.Scenarios[name]

    if not scenario then

        Log(
            "ERROR: unknown scenario: "
            .. tostring(name)
        )

        return nil

    end

    Log("")
    Log("========================================")
    Log("RUNNING SCENARIO: " .. tostring(name))
    Log("========================================")

    Harness.PrintScenario(scenario)

    -----------------------------------------------------
    -- DecisionSystem integration
    -----------------------------------------------------

    if BAO.DecisionSystem
        and BAO.DecisionSystem.CalculateWithContext then

        Log(
            "Calling DecisionSystem.CalculateWithContext()"
        )

        local result =
            BAO.DecisionSystem.CalculateWithContext(
                scenario
            )

        if result then

            Log(
                "Decision: "
                .. tostring(result.decision)
            )

            Log(
                "Score: "
                .. tostring(result.score)
            )

            Log(
                "Priority: "
                .. tostring(result.priority)
            )

            return result

        else

            Log(
                "DecisionSystem returned nil"
            )

        end

    else

        Log(
            "DecisionSystem.CalculateWithContext() not available"
        )

    end

    return nil

end

---------------------------------------------------------
-- Run all scenarios
---------------------------------------------------------

function Harness.RunAll()

    Log("")
    Log("########################################")
    Log("BAO AI TEST HARNESS " .. Harness.Version)
    Log("STARTING FULL TEST")
    Log("########################################")

    local results = {}

    for _, scenarioName
        in ipairs(Harness.ScenarioOrder) do

        local result =
            Harness.RunScenario(
                scenarioName
            )

        results[scenarioName] = result

    end

    Log("")
    Log("########################################")
    Log("BAO AI TEST HARNESS COMPLETE")
    Log("########################################")

    return results

end

---------------------------------------------------------
-- Simple public API
---------------------------------------------------------

function Harness.TestNormal()

    return Harness.RunScenario(
        "NORMAL"
    )

end

function Harness.TestLowHealth()

    return Harness.RunScenario(
        "LOW_HEALTH"
    )

end

function Harness.TestHighFatigue()

    return Harness.RunScenario(
        "HIGH_FATIGUE"
    )

end

function Harness.TestManyZombies()

    return Harness.RunScenario(
        "MANY_ZOMBIES"
    )

end

function Harness.TestNight()

    return Harness.RunScenario(
        "NIGHT"
    )

end

function Harness.TestNoWeapon()

    return Harness.RunScenario(
        "NO_WEAPON"
    )

end

function Harness.TestHungry()

    return Harness.RunScenario(
        "HUNGRY"
    )

end

function Harness.TestThirsty()

    return Harness.RunScenario(
        "THIRSTY"
    )

end

function Harness.TestPanic()

    return Harness.RunScenario(
        "PANIC"
    )

end

---------------------------------------------------------
-- Loaded
---------------------------------------------------------

Log(
    "Loaded successfully - "
    .. Harness.Version
)
