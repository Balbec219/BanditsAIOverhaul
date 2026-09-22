-----------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_DecisionSystem.lua
-- Decision System V1.2.1
--
-- V1.2.1:
-- - Added CalculateWithContext() for AI Test Harness
-- - Test calculations DO NOT modify runtime decision state
-- - Normal Decision System behavior remains unchanged
-----------------------------------------------------------

BAO = BAO or {}

local DecisionSystem = {}

local MODULE_NAME = "BAO_DecisionSystem"

-----------------------------------------------------------
-- LOG
-----------------------------------------------------------

local function Log(message)
    print("[BAO][" .. MODULE_NAME .. "] " .. tostring(message))
end

-----------------------------------------------------------
-- DECISIONS
-----------------------------------------------------------

local DECISIONS = {

    patrol = {
        Priority = 50
    },

    explore = {
        Priority = 30
    },

    gather_resources = {
        Priority = 40
    },

    guard = {
        Priority = 60
    },

    help_ally = {
        Priority = 70
    },

    rest = {
        Priority = 20
    },

    heal = {
        Priority = 100
    },

    retreat = {
        Priority = 90
    },

    combat = {
        Priority = 80
    }
}

-----------------------------------------------------------
-- RUNTIME STATE
-----------------------------------------------------------

local initialized = false

local attempts = 0

local currentDecision = nil
local previousDecision = nil

local lastCalculation = nil

local decisionChanged = false

local lastWorldContext = nil

-----------------------------------------------------------
-- UTILITIES
-----------------------------------------------------------

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

-----------------------------------------------------------
-- WORLD CONTEXT CHANGE DETECTION
-----------------------------------------------------------

local function WorldContextChanged(world)

    if not world then
        return true
    end

    if not lastWorldContext then
        return true
    end

    if world.Health ~= lastWorldContext.Health then
        return true
    end

    if world.Hunger ~= lastWorldContext.Hunger then
        return true
    end

    if world.Thirst ~= lastWorldContext.Thirst then
        return true
    end

    if world.Fatigue ~= lastWorldContext.Fatigue then
        return true
    end

    if world.Panic ~= lastWorldContext.Panic then
        return true
    end

    if world.Pain ~= lastWorldContext.Pain then
        return true
    end

    if world.ZombiesNearby ~= lastWorldContext.ZombiesNearby then
        return true
    end

    if world.Night ~= lastWorldContext.Night then
        return true
    end

    if world.HasWeapon ~= lastWorldContext.HasWeapon then
        return true
    end

    if world.Ranged ~= lastWorldContext.Ranged then
        return true
    end

    return false
end

-----------------------------------------------------------
-- STORE WORLD CONTEXT
-----------------------------------------------------------

local function StoreWorldContext(world)

    if not world then
        lastWorldContext = nil
        return
    end

    lastWorldContext = {

        Health = world.Health,
        Hunger = world.Hunger,
        Thirst = world.Thirst,
        Fatigue = world.Fatigue,
        Panic = world.Panic,
        Pain = world.Pain,

        ZombiesNearby = world.ZombiesNearby,

        Night = world.Night,

        HasWeapon = world.HasWeapon,
        Ranged = world.Ranged
    }
end

-----------------------------------------------------------
-- GET BEHAVIOR PROFILE
-----------------------------------------------------------

local function GetBehaviorProfile()

    if not BAO.BehaviorProfile then
        return nil
    end

    if BAO.BehaviorProfile.Get then
        return BAO.BehaviorProfile.Get()
    end

    return nil
end

-----------------------------------------------------------
-- GET WORLD CONTEXT
-----------------------------------------------------------

local function GetWorldContext()

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
-- CALCULATE BASE SCORES
-----------------------------------------------------------

local function CalculateBaseScores(behavior)

    local scores = {}

    -------------------------------------------------------
    -- PATROL
    -------------------------------------------------------

    scores.patrol =
        20
        + SafeNumber(behavior.Capabilities.Recon) * 0.25
        + SafeNumber(behavior.Capabilities.Security) * 0.20
        + SafeNumber(behavior.Personality.Discipline) * 0.10

    -------------------------------------------------------
    -- EXPLORE
    -------------------------------------------------------

    scores.explore =
        15
        + SafeNumber(behavior.Tendencies.ScoutingConfidence) * 0.35
        + SafeNumber(behavior.Tendencies.ExplorationDrive) * 0.25
        + SafeNumber(behavior.Personality.RiskTolerance) * 0.10

    -------------------------------------------------------
    -- GATHER RESOURCES
    -------------------------------------------------------

    scores.gather_resources =
        15
        + SafeNumber(behavior.Capabilities.Survival) * 0.20
        + SafeNumber(behavior.Capabilities.Logistics) * 0.25
        + SafeNumber(behavior.Tendencies.ResourcePriority) * 0.30

    -------------------------------------------------------
    -- GUARD
    -------------------------------------------------------

    scores.guard =
        20
        + SafeNumber(behavior.Capabilities.Security) * 0.30
        + SafeNumber(behavior.Personality.Discipline) * 0.20
        + SafeNumber(behavior.Personality.Courage) * 0.10

    -------------------------------------------------------
    -- HELP ALLY
    -------------------------------------------------------

    scores.help_ally =
        15
        + SafeNumber(behavior.Tendencies.Cooperation) * 0.30
        + SafeNumber(behavior.Personality.Courage) * 0.20
        + SafeNumber(behavior.Capabilities.Leadership) * 0.20

    -------------------------------------------------------
    -- REST
    -------------------------------------------------------

    scores.rest =
        15
        + SafeNumber(behavior.Capabilities.Survival) * 0.20
        + SafeNumber(behavior.Personality.Discipline) * 0.15
        + (100 - SafeNumber(behavior.Tendencies.CombatAggression)) * 0.10

    -------------------------------------------------------
    -- HEAL
    -------------------------------------------------------

    scores.heal =
        20
        + SafeNumber(behavior.Capabilities.Survival) * 0.15
        + SafeNumber(behavior.Personality.Discipline) * 0.10

    -------------------------------------------------------
    -- RETREAT
    -------------------------------------------------------

    scores.retreat =
        10
        + SafeNumber(behavior.Personality.Fear) * 0.20
        + (100 - SafeNumber(behavior.Personality.Courage)) * 0.20
        + (100 - SafeNumber(behavior.Personality.RiskTolerance)) * 0.20

    -------------------------------------------------------
    -- COMBAT
    -------------------------------------------------------

    scores.combat =
        15
        + SafeNumber(behavior.Capabilities.Combat) * 0.30
        + SafeNumber(behavior.Tendencies.CombatAggression) * 0.25
        + SafeNumber(behavior.Personality.Courage) * 0.15
        + SafeNumber(behavior.Personality.RiskTolerance) * 0.10
        + SafeNumber(behavior.Tendencies.CombatDiscipline) * 0.10

    return scores
end

-----------------------------------------------------------
-- APPLY WORLD CONTEXT
-----------------------------------------------------------

local function ApplyWorldContext(scores, world)

    if not world then
        return scores
    end

    local health = SafeNumber(world.Health, 100)
    local hunger = SafeNumber(world.Hunger, 0)
    local thirst = SafeNumber(world.Thirst, 0)
    local fatigue = SafeNumber(world.Fatigue, 0)
    local panic = SafeNumber(world.Panic, 0)
    local pain = SafeNumber(world.Pain, 0)

    local zombies = SafeNumber(world.ZombiesNearby, 0)

    -------------------------------------------------------
    -- HEALTH
    -------------------------------------------------------

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

    -------------------------------------------------------
    -- FATIGUE
    -------------------------------------------------------

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

    -------------------------------------------------------
    -- HUNGER
    -------------------------------------------------------

    if hunger > 50 then
        scores.gather_resources = scores.gather_resources + 20
    end

    if hunger > 75 then

        scores.gather_resources = scores.gather_resources + 20
        scores.rest = scores.rest + 5

    end

    -------------------------------------------------------
    -- THIRST
    -------------------------------------------------------

    if thirst > 50 then
        scores.gather_resources = scores.gather_resources + 25
    end

    if thirst > 75 then

        scores.gather_resources = scores.gather_resources + 25
        scores.combat = scores.combat - 10

    end

    -------------------------------------------------------
    -- PANIC
    -------------------------------------------------------

    if panic > 50 then

        scores.retreat = scores.retreat + 20
        scores.combat = scores.combat - 10

    end

    if panic > 75 then

        scores.retreat = scores.retreat + 30
        scores.combat = scores.combat - 20

    end

    -------------------------------------------------------
    -- PAIN
    -------------------------------------------------------

    if pain > 30 then

        scores.heal = scores.heal + 15
        scores.combat = scores.combat - 10

    end

    if pain > 60 then

        scores.heal = scores.heal + 25
        scores.retreat = scores.retreat + 15
        scores.combat = scores.combat - 20

    end

    -------------------------------------------------------
    -- ZOMBIES
    -------------------------------------------------------

    if zombies >= 5 then

        scores.combat = scores.combat + 10
        scores.retreat = scores.retreat + 10
        scores.guard = scores.guard + 5

    end

    if zombies >= 10 then

        scores.combat = scores.combat + 10
        scores.retreat = scores.retreat + 20

    end

    if zombies >= 20 then

        scores.retreat = scores.retreat + 30
        scores.combat = scores.combat + 5
        scores.explore = scores.explore - 20

    end

    -------------------------------------------------------
    -- WEAPON
    -------------------------------------------------------

    if world.HasWeapon == false then

        scores.combat = scores.combat - 20
        scores.gather_resources = scores.gather_resources + 10
        scores.retreat = scores.retreat + 5

    end

    -------------------------------------------------------
    -- RANGED WEAPON
    -------------------------------------------------------

    if world.Ranged == true then
        scores.combat = scores.combat + 5
    end

    -------------------------------------------------------
    -- NIGHT
    -------------------------------------------------------

    if world.Night == true then

        scores.guard = scores.guard + 10
        scores.explore = scores.explore - 15
        scores.patrol = scores.patrol - 5

    end

    -------------------------------------------------------
    -- CLAMP
    -------------------------------------------------------

    for decision, score in pairs(scores) do

        scores[decision] = Clamp(score, 0, 100)

    end

    return scores
end

-----------------------------------------------------------
-- SELECT BEST DECISION
-----------------------------------------------------------

local function SelectBestDecision(scores)

    local bestDecision = nil
    local bestScore = -1
    local bestPriority = -1

    for decision, score in pairs(scores) do

        local priority = 0

        if DECISIONS[decision] then
            priority = DECISIONS[decision].Priority or 0
        end

        if score > bestScore then

            bestDecision = decision
            bestScore = score
            bestPriority = priority

        elseif score == bestScore then

            if priority > bestPriority then

                bestDecision = decision
                bestScore = score
                bestPriority = priority

            end

        end
    end

    return {

        ID = bestDecision,

        Score = bestScore,

        Priority = bestPriority
    }
end

-----------------------------------------------------------
-- UPDATE RUNTIME DECISION STATE
-----------------------------------------------------------

local function UpdateDecisionState(result)

    previousDecision = currentDecision

    if currentDecision == nil then

        currentDecision = result

        decisionChanged = true

        Log(
            "Initial decision: "
            .. tostring(result.ID)
            .. " score="
            .. tostring(result.Score)
        )

    elseif currentDecision.ID ~= result.ID then

        Log(
            "Decision changed: "
            .. tostring(currentDecision.ID)
            .. " -> "
            .. tostring(result.ID)
        )

        currentDecision = result

        decisionChanged = true

    else

        currentDecision = result

        decisionChanged = false

    end
end

-----------------------------------------------------------
-- NORMAL CALCULATION
-----------------------------------------------------------

function DecisionSystem.Calculate()

    Log("Calculating decision...")

    local behavior = GetBehaviorProfile()

    if not behavior then

        Log("BehaviorProfile unavailable")

        return nil
    end

    local world = GetWorldContext()

    if not world then

        Log("WorldContext unavailable")

        return nil
    end

    -------------------------------------------------------
    -- BASE SCORES
    -------------------------------------------------------

    local scores = CalculateBaseScores(behavior)

    -------------------------------------------------------
    -- WORLD MODIFIERS
    -------------------------------------------------------

    scores = ApplyWorldContext(scores, world)

    -------------------------------------------------------
    -- SELECT DECISION
    -------------------------------------------------------

    local result = SelectBestDecision(scores)

    -------------------------------------------------------
    -- UPDATE STATE
    -------------------------------------------------------

    UpdateDecisionState(result)

    -------------------------------------------------------
    -- STORE CONTEXT
    -------------------------------------------------------

    StoreWorldContext(world)

    -------------------------------------------------------
    -- STORE CALCULATION
    -------------------------------------------------------

    lastCalculation = {

        Decision = result,

        Scores = scores,

        WorldContext = world,

        BehaviorProfile = behavior
    }

    return lastCalculation
end

-----------------------------------------------------------
-- TEST CALCULATION
--
-- IMPORTANT:
-- This function is intentionally isolated from the normal
-- runtime state.
--
-- It DOES NOT modify:
-- currentDecision
-- previousDecision
-- decisionChanged
-- lastCalculation
-- lastWorldContext
--
-- This allows the AI Test Harness to simulate situations
-- without affecting the real NPC decision state.
-----------------------------------------------------------

function DecisionSystem.CalculateWithContext(worldOverride)

    if not worldOverride then

        Log("TEST CalculateWithContext: missing world context")

        return nil
    end

    local behavior = GetBehaviorProfile()

    if not behavior then

        Log("TEST CalculateWithContext: BehaviorProfile unavailable")

        return nil
    end

    -------------------------------------------------------
    -- BASE SCORES
    -------------------------------------------------------

    local scores = CalculateBaseScores(behavior)

    -------------------------------------------------------
    -- APPLY TEST CONTEXT
    -------------------------------------------------------

    scores = ApplyWorldContext(scores, worldOverride)

    -------------------------------------------------------
    -- SELECT
    -------------------------------------------------------

    local result = SelectBestDecision(scores)

    -------------------------------------------------------
    -- TEST LOG
    -------------------------------------------------------

    Log(
        "TEST Decision scores: "
        .. "patrol=" .. string.format("%.2f", scores.patrol)
        .. " explore=" .. string.format("%.2f", scores.explore)
        .. " gather=" .. string.format("%.2f", scores.gather_resources)
        .. " guard=" .. string.format("%.2f", scores.guard)
        .. " help=" .. string.format("%.2f", scores.help_ally)
        .. " rest=" .. string.format("%.2f", scores.rest)
        .. " heal=" .. string.format("%.2f", scores.heal)
        .. " retreat=" .. string.format("%.2f", scores.retreat)
        .. " combat=" .. string.format("%.2f", scores.combat)
    )

    Log(
        "TEST FINAL DECISION: "
        .. tostring(result.ID)
        .. " score="
        .. string.format("%.2f", result.Score)
        .. " priority="
        .. tostring(result.Priority)
    )

    -------------------------------------------------------
    -- RETURN TEST RESULT
    -------------------------------------------------------

    return {

        Decision = result,

        Scores = scores,

        WorldContext = worldOverride,

        BehaviorProfile = behavior
    }
end

-----------------------------------------------------------
-- GET CURRENT DECISION
-----------------------------------------------------------

function DecisionSystem.Get()

    return currentDecision
end

-----------------------------------------------------------
-- RECALCULATE
-----------------------------------------------------------

function DecisionSystem.Recalculate()

    return DecisionSystem.Calculate()
end

-----------------------------------------------------------
-- GET CURRENT DECISION
-----------------------------------------------------------

function DecisionSystem.GetCurrentDecision()

    return currentDecision
end

-----------------------------------------------------------
-- GET PREVIOUS DECISION
-----------------------------------------------------------

function DecisionSystem.GetPreviousDecision()

    return previousDecision
end

-----------------------------------------------------------
-- HAS DECISION CHANGED
-----------------------------------------------------------

function DecisionSystem.HasDecisionChanged()

    return decisionChanged
end

-----------------------------------------------------------
-- GET LAST CALCULATION
-----------------------------------------------------------

function DecisionSystem.GetLastCalculation()

    return lastCalculation
end

-----------------------------------------------------------
-- CHECK WORLD CONTEXT
-----------------------------------------------------------

function DecisionSystem.CheckWorldContextUpdate()

    local world = GetWorldContext()

    if not world then
        return false
    end

    if WorldContextChanged(world) then

        DecisionSystem.Calculate()

        return true
    end

    return false
end

-----------------------------------------------------------
-- INITIALIZATION
-----------------------------------------------------------

function DecisionSystem.Initialize()

    if initialized then
        return true
    end

    attempts = attempts + 1

    Log("Initialize attempt #" .. tostring(attempts))

    local behavior = GetBehaviorProfile()

    if not behavior then

        Log("Waiting for BehaviorProfile...")

        return false
    end

    local world = GetWorldContext()

    if not world then

        Log("Waiting for WorldContext...")

        return false
    end

    local result = DecisionSystem.Calculate()

    if not result then

        Log("Initial calculation failed")

        return false
    end

    initialized = true

    Log(
        "Decision System initialized. Current decision: "
        .. tostring(result.Decision.ID)
    )

    return true
end

-----------------------------------------------------------
-- GAME START
-----------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(function()

        Log("OnGameStart")

        DecisionSystem.Initialize()

    end)

end

-----------------------------------------------------------
-- TICK
-----------------------------------------------------------

if Events and Events.OnTick then

    Events.OnTick.Add(function()

        if not initialized then

            DecisionSystem.Initialize()

            return
        end

        DecisionSystem.CheckWorldContextUpdate()

    end)

end

-----------------------------------------------------------
-- EXPORT
-----------------------------------------------------------

BAO.DecisionSystem = DecisionSystem

-----------------------------------------------------------
-- MODULE LOADED
-----------------------------------------------------------

Log("Decision System V1.2.1 module loaded")