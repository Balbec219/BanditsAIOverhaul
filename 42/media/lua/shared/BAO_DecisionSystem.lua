-- =========================================================
-- BanditsAIOverhaul
-- BAO_DecisionSystem.lua
-- Decision System V1.2
--
-- Purpose:
--   Combines:
--     1. BehaviorProfile - who the NPC is
--     2. WorldContext    - what is happening right now
--
-- V1.2 additions:
--   - Stores current decision
--   - Detects decision changes
--   - Logs decision changes
--   - Prevents repeated decision spam
--   - Supports automatic recalculation
--   - Provides API for future Action System
-- =========================================================

BAO = BAO or {}

local DecisionSystem = {}

local MODULE_NAME = "DecisionSystem"

local function Log(message)
    print("[BAO][" .. MODULE_NAME .. "] " .. tostring(message))
end


-- =========================================================
-- Decision definitions
-- =========================================================

local DECISIONS = {
    {
        id = "patrol",
        priority = 50
    },

    {
        id = "explore",
        priority = 30
    },

    {
        id = "gather_resources",
        priority = 40
    },

    {
        id = "guard",
        priority = 60
    },

    {
        id = "help_ally",
        priority = 70
    },

    {
        id = "rest",
        priority = 20
    },

    {
        id = "heal",
        priority = 100
    },

    {
        id = "retreat",
        priority = 90
    },

    {
        id = "combat",
        priority = 80
    }
}


-- =========================================================
-- Runtime state
-- =========================================================

local initialized = false
local attempts = 0

local currentDecision = nil
local previousDecision = nil

local lastCalculation = nil
local decisionChanged = false

local lastWorldContext = nil


-- =========================================================
-- Utility
-- =========================================================

local function Clamp(value, minValue, maxValue)

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end


local function SafeNumber(value, default)

    if type(value) == "number" then
        return value
    end

    return default or 0
end


-- =========================================================
-- World Context change detection
-- =========================================================

local function WorldContextChanged(world)

    if not world then
        return false
    end

    if not lastWorldContext then
        return true
    end

    local fields = {
        "Health",
        "Hunger",
        "Thirst",
        "Fatigue",
        "Panic",
        "Pain",
        "ZombiesNearby",
        "Night",
        "HasWeapon",
        "Ranged"
    }

    for _, field in ipairs(fields) do

        if world[field] ~= lastWorldContext[field] then
            return true
        end

    end

    return false
end


local function StoreWorldContext(world)

    if not world then
        lastWorldContext = nil
        return
    end

    lastWorldContext = {}

    local fields = {
        "Health",
        "Hunger",
        "Thirst",
        "Fatigue",
        "Panic",
        "Pain",
        "ZombiesNearby",
        "Night",
        "HasWeapon",
        "Ranged"
    }

    for _, field in ipairs(fields) do
        lastWorldContext[field] = world[field]
    end
end


-- =========================================================
-- Get Behavior Profile
-- =========================================================

local function GetBehaviorProfile()

    if not BAO.BehaviorProfile then
        return nil
    end

    if not BAO.BehaviorProfile.Get then
        return nil
    end

    return BAO.BehaviorProfile.Get()
end


-- =========================================================
-- Get World Context
-- =========================================================

local function GetWorldContext()

    if not BAO.WorldContext then
        return nil
    end

    -- Current is maintained by WorldContext V1.1
    if BAO.WorldContext.Current then
        return BAO.WorldContext.Current
    end

    -- Fallback if Get exists
    if BAO.WorldContext.Get then
        return BAO.WorldContext.Get()
    end

    return nil
end


-- =========================================================
-- Base scores
-- =========================================================

local function CalculateBaseScores(behavior)

    local scores = {}

    if not behavior then
        Log("BehaviorProfile is nil while calculating base scores")
        return scores
    end

    local personality = behavior.Personality or {}
    local capabilities = behavior.Capabilities or {}
    local tendencies = behavior.Tendencies or {}

    local combat = SafeNumber(capabilities.Combat, 0)
    local survival = SafeNumber(capabilities.Survival, 0)
    local recon = SafeNumber(capabilities.Recon, 0)
    local security = SafeNumber(capabilities.Security, 0)
    local logistics = SafeNumber(capabilities.Logistics, 0)
    local leadership = SafeNumber(capabilities.Leadership, 0)

    local aggression = SafeNumber(personality.Aggression, 50)
    local courage = SafeNumber(personality.Courage, 50)
    local fear = SafeNumber(personality.Fear, 50)
    local discipline = SafeNumber(personality.Discipline, 50)
    local riskTolerance = SafeNumber(personality.RiskTolerance, 50)
    local curiosity = SafeNumber(personality.Curiosity, 50)

    local combatAggression =
        SafeNumber(tendencies.CombatAggression, aggression)

    local combatDiscipline =
        SafeNumber(tendencies.CombatDiscipline, discipline)

    local scoutingConfidence =
        SafeNumber(tendencies.ScoutingConfidence, recon)

    local explorationDrive =
        SafeNumber(tendencies.ExplorationDrive, curiosity)

    local resourcePriority =
        SafeNumber(tendencies.ResourcePriority, logistics)

    local cooperation =
        SafeNumber(tendencies.Cooperation, leadership)


    -- Patrol
    scores.patrol =
        20
        + recon * 0.25
        + security * 0.20
        + discipline * 0.10


    -- Explore
    scores.explore =
        15
        + scoutingConfidence * 0.35
        + explorationDrive * 0.25
        + riskTolerance * 0.10


    -- Gather resources
    scores.gather_resources =
        15
        + survival * 0.20
        + logistics * 0.25
        + resourcePriority * 0.30


    -- Guard
    scores.guard =
        20
        + security * 0.30
        + discipline * 0.20
        + courage * 0.10


    -- Help ally
    scores.help_ally =
        15
        + cooperation * 0.30
        + courage * 0.20
        + leadership * 0.20


    -- Rest
    scores.rest =
        15
        + survival * 0.20
        + discipline * 0.15
        + (100 - combatAggression) * 0.10


    -- Heal
    scores.heal =
        20
        + survival * 0.15
        + discipline * 0.10


    -- Retreat
    scores.retreat =
        10
        + fear * 0.20
        + (100 - courage) * 0.20
        + (100 - riskTolerance) * 0.20


    -- Combat
    scores.combat =
        15
        + combat * 0.30
        + combatAggression * 0.25
        + courage * 0.15
        + riskTolerance * 0.10
        + combatDiscipline * 0.10


    return scores
end


-- =========================================================
-- World Context modifiers
-- =========================================================

local function ApplyWorldContext(scores, world)

    if not world then
        Log("WorldContext is nil - using BehaviorProfile only")
        return scores
    end

    local health =
        SafeNumber(world.Health, 100)

    local hunger =
        SafeNumber(world.Hunger, 0)

    local thirst =
        SafeNumber(world.Thirst, 0)

    local fatigue =
        SafeNumber(world.Fatigue, 0)

    local panic =
        SafeNumber(world.Panic, 0)

    local pain =
        SafeNumber(world.Pain, 0)

    local zombiesNearby =
        SafeNumber(world.ZombiesNearby, 0)

    local night =
        world.Night == true

    local hasWeapon =
        world.HasWeapon == true

    local ranged =
        world.Ranged == true


    -- -----------------------------------------------------
    -- HEALTH
    -- -----------------------------------------------------

    if health < 70 then
        scores.heal = scores.heal + 15
    end

    if health < 40 then
        scores.heal = scores.heal + 25
        scores.retreat = scores.retreat + 15
        scores.combat = scores.combat - 15
    end

    if health < 20 then
        scores.heal = scores.heal + 30
        scores.retreat = scores.retreat + 25
        scores.combat = scores.combat - 30
    end


    -- -----------------------------------------------------
    -- FATIGUE
    -- -----------------------------------------------------

    if fatigue > 50 then
        scores.rest = scores.rest + 20
        scores.combat = scores.combat - 10
        scores.explore = scores.explore - 5
    end

    if fatigue > 75 then
        scores.rest = scores.rest + 25
        scores.retreat = scores.retreat + 10
        scores.combat = scores.combat - 15
    end


    -- -----------------------------------------------------
    -- HUNGER
    -- -----------------------------------------------------

    if hunger > 50 then
        scores.gather_resources = scores.gather_resources + 20
    end

    if hunger > 75 then
        scores.gather_resources = scores.gather_resources + 20
        scores.rest = scores.rest + 5
    end


    -- -----------------------------------------------------
    -- THIRST
    -- -----------------------------------------------------

    if thirst > 50 then
        scores.gather_resources = scores.gather_resources + 25
    end

    if thirst > 75 then
        scores.gather_resources = scores.gather_resources + 25
        scores.combat = scores.combat - 10
    end


    -- -----------------------------------------------------
    -- PANIC
    -- -----------------------------------------------------

    if panic > 50 then
        scores.retreat = scores.retreat + 20
        scores.combat = scores.combat - 10
    end

    if panic > 75 then
        scores.retreat = scores.retreat + 30
        scores.combat = scores.combat - 20
    end


    -- -----------------------------------------------------
    -- PAIN
    -- -----------------------------------------------------

    if pain > 30 then
        scores.heal = scores.heal + 15
        scores.combat = scores.combat - 10
    end

    if pain > 60 then
        scores.heal = scores.heal + 25
        scores.retreat = scores.retreat + 15
        scores.combat = scores.combat - 20
    end


    -- -----------------------------------------------------
    -- ZOMBIE THREAT
    -- -----------------------------------------------------

    if zombiesNearby >= 5 then
        scores.combat = scores.combat + 10
        scores.retreat = scores.retreat + 10
        scores.guard = scores.guard + 5
    end

    if zombiesNearby >= 10 then
        scores.combat = scores.combat + 10
        scores.retreat = scores.retreat + 20
    end

    if zombiesNearby >= 20 then
        scores.retreat = scores.retreat + 30
        scores.combat = scores.combat + 5
        scores.explore = scores.explore - 20
    end


    -- -----------------------------------------------------
    -- WEAPON
    -- -----------------------------------------------------

    if not hasWeapon then
        scores.combat = scores.combat - 20
        scores.gather_resources = scores.gather_resources + 10
        scores.retreat = scores.retreat + 5
    end

    if ranged then
        scores.combat = scores.combat + 5
    end


    -- -----------------------------------------------------
    -- NIGHT
    -- -----------------------------------------------------

    if night then
        scores.guard = scores.guard + 10
        scores.explore = scores.explore - 15
        scores.patrol = scores.patrol - 5
    end


    -- -----------------------------------------------------
    -- Clamp all scores
    -- -----------------------------------------------------

    for id, score in pairs(scores) do
        scores[id] = Clamp(score, 0, 100)
    end

    return scores
end


-- =========================================================
-- Select best decision
-- =========================================================

local function SelectBestDecision(scores)

    local bestDecision = nil
    local bestScore = -1
    local bestPriority = -1

    for _, definition in ipairs(DECISIONS) do

        local score =
            SafeNumber(scores[definition.id], 0)

        if score > bestScore then

            bestDecision = definition.id
            bestScore = score
            bestPriority = definition.priority

        elseif score == bestScore then

            if definition.priority > bestPriority then
                bestDecision = definition.id
                bestScore = score
                bestPriority = definition.priority
            end
        end
    end

    return {
        ID = bestDecision,
        Score = bestScore,
        Priority = bestPriority
    }
end


-- =========================================================
-- Update decision state
-- =========================================================

local function UpdateDecisionState(result)

    decisionChanged = false

    if not result then
        return
    end

    local newDecision =
        result.ID

    local oldDecision =
        currentDecision and currentDecision.ID or nil


    -- First decision
    if not currentDecision then

        previousDecision = nil
        currentDecision = result

        Log(
            "Initial decision: " ..
            tostring(newDecision)
        )

        return
    end


    -- Decision changed
    if oldDecision ~= newDecision then

        previousDecision = currentDecision
        currentDecision = result

        decisionChanged = true

        Log(
            "Decision changed: " ..
            tostring(oldDecision) ..
            " -> " ..
            tostring(newDecision)
        )

        Log(
            "New decision score: " ..
            string.format("%.2f", result.Score)
        )

        Log(
            "New decision priority: " ..
            tostring(result.Priority)
        )

        return
    end


    -- Same decision
    --
    -- Update the stored result so that the Action System
    -- can always access the latest score/context.
    currentDecision = result
end


-- =========================================================
-- Calculate
-- =========================================================

function DecisionSystem.Calculate()

    Log("===== DECISION CALCULATION =====")


    local behavior =
        GetBehaviorProfile()

    if not behavior then
        Log("BehaviorProfile unavailable")
        return nil
    end

    Log("BehaviorProfile received")


    local world =
        GetWorldContext()

    if world then
        Log("WorldContext received")
    else
        Log("WorldContext unavailable")
    end


    -- Base personality/capability scores
    local scores =
        CalculateBaseScores(behavior)


    -- Dynamic world modifiers
    scores =
        ApplyWorldContext(scores, world)


    Log("Decision scores:")

    for _, definition in ipairs(DECISIONS) do

        local score =
            SafeNumber(scores[definition.id], 0)

        Log(
            definition.id ..
            " = " ..
            string.format("%.2f", score)
        )
    end


    local result =
        SelectBestDecision(scores)


    if result then

        Log(
            "FINAL DECISION: " ..
            tostring(result.ID)
        )

        Log(
            "FINAL SCORE: " ..
            string.format("%.2f", result.Score)
        )

        Log(
            "FINAL PRIORITY: " ..
            tostring(result.Priority)
        )
    end


    -- Update persistent decision state
    UpdateDecisionState(result)


    -- Store current WorldContext snapshot
    StoreWorldContext(world)


    lastCalculation = {
        Decision = result,
        Scores = scores,
        WorldContext = world,
        BehaviorProfile = behavior
    }


    Log("Decision System V1.2 calculation complete")

    return lastCalculation
end


-- =========================================================
-- Get
--
-- Compatibility API.
--
-- Returns the latest calculation.
-- If no calculation exists yet, calculates once.
-- =========================================================

function DecisionSystem.Get()

    if lastCalculation then
        return lastCalculation
    end

    return DecisionSystem.Calculate()
end


-- =========================================================
-- Recalculate
--
-- Explicit recalculation API.
--
-- Future systems can call:
--
-- BAO.DecisionSystem.Recalculate()
-- =========================================================

function DecisionSystem.Recalculate()

    return DecisionSystem.Calculate()
end


-- =========================================================
-- GetCurrentDecision
--
-- API for future Action System.
--
-- Returns:
--   {
--       ID = "...",
--       Score = number,
--       Priority = number
--   }
-- =========================================================

function DecisionSystem.GetCurrentDecision()

    return currentDecision
end


-- =========================================================
-- GetPreviousDecision
-- =========================================================

function DecisionSystem.GetPreviousDecision()

    return previousDecision
end


-- =========================================================
-- HasDecisionChanged
-- =========================================================

function DecisionSystem.HasDecisionChanged()

    return decisionChanged
end


-- =========================================================
-- GetLastCalculation
-- =========================================================

function DecisionSystem.GetLastCalculation()

    return lastCalculation
end


-- =========================================================
-- Automatic WorldContext update
-- =========================================================

local function CheckWorldContextUpdate()

    if not initialized then
        return
    end

    local world =
        GetWorldContext()

    if not world then
        return
    end


    if WorldContextChanged(world) then

        Log("WorldContext changed - recalculating decision")

        DecisionSystem.Calculate()

    end
end


-- =========================================================
-- Initialization
-- =========================================================

local function Initialize()

    if initialized then
        return true
    end

    attempts = attempts + 1

    Log("Initialization attempt " .. tostring(attempts))


    local behaviorProfile =
        GetBehaviorProfile()

    if not behaviorProfile then
        Log("Waiting for BehaviorProfile...")
        return false
    end


    local worldContext =
        GetWorldContext()

    if not worldContext then
        Log("Waiting for WorldContext...")
        return false
    end


    initialized = true

    Log("BehaviorProfile ready")
    Log("WorldContext ready")


    DecisionSystem.Calculate()


    Log("Decision System V1.2 initialization complete")

    return true
end


-- =========================================================
-- Events
-- =========================================================

if Events then

    if Events.OnGameStart then

        Events.OnGameStart.Add(function()

            Log("OnGameStart event received")

            Initialize()

        end)

    end


    if Events.OnTick then

        Events.OnTick.Add(function()

            if not initialized then

                Initialize()

            else

                CheckWorldContextUpdate()

            end

        end)

    end

end


-- =========================================================
-- Export
-- =========================================================

BAO.DecisionSystem =
    DecisionSystem


Log("Decision System V1.2 module loaded")