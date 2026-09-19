---@diagnostic disable: undefined-global

BAO = BAO or {}
BAO.DecisionSystem = BAO.DecisionSystem or {}

--------------------------------------------------
-- BAO Decision System V1
-- High-level decision making
--
-- This module does NOT execute actions.
-- It only decides what the character SHOULD want to do.
--
-- Pipeline:
-- PlayerProfile
--      ↓
-- RoleScoring
--      ↓
-- Specialization
--      ↓
-- BehaviorProfile
--      ↓
-- DecisionSystem
--      ↓
-- ActionSelection (future)
--      ↓
-- NPC Actions (future)
--------------------------------------------------


--------------------------------------------------
-- LOG
--------------------------------------------------

local function Log(message)
    print("[BAO] " .. tostring(message))
end


--------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or 0

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end


local function Round(value, decimals)
    value = tonumber(value) or 0
    decimals = decimals or 2

    local multiplier = 10 ^ decimals

    return math.floor(value * multiplier + 0.5) / multiplier
end


local function GetTableValue(tbl, key, defaultValue)
    if type(tbl) ~= "table" then
        return defaultValue
    end

    local value = tbl[key]

    if value == nil then
        return defaultValue
    end

    return value
end


--------------------------------------------------
-- DECISION DEFINITIONS
--------------------------------------------------

BAO.DecisionSystem.Decisions = {
    PATROL = "patrol",
    EXPLORE = "explore",
    GATHER_RESOURCES = "gather_resources",
    GUARD = "guard",
    HELP_ALLY = "help_ally",
    REST = "rest",
    HEAL = "heal",
    RETREAT = "retreat",
    COMBAT = "combat"
}


--------------------------------------------------
-- DECISION PRIORITIES
--------------------------------------------------

-- Higher priority means the decision is more important
-- when two decisions have similar scores.

BAO.DecisionSystem.Priority = {
    heal = 100,
    retreat = 90,
    combat = 80,
    help_ally = 70,
    guard = 60,
    patrol = 50,
    gather_resources = 40,
    explore = 30,
    rest = 20
}


--------------------------------------------------
-- CURRENT DECISION DATA
--------------------------------------------------

BAO.DecisionSystem.CurrentDecision = nil
BAO.DecisionSystem.LastScores = nil
BAO.DecisionSystem.Initialized = false


--------------------------------------------------
-- GET BEHAVIOR PROFILE
--------------------------------------------------

function BAO.DecisionSystem.GetBehaviorProfile()

    if not BAO.BehaviorProfile then
        return nil
    end

    if not BAO.BehaviorProfile.Get then
        return nil
    end

    return BAO.BehaviorProfile.Get()
end


--------------------------------------------------
-- CALCULATE PATROL SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculatePatrolScore(profile)

    local capabilities = profile.Capabilities or {}
    local tendencies = profile.Tendencies or {}
    local personality = profile.Personality or {}

    local security = GetTableValue(capabilities, "Security", 0)
    local recon = GetTableValue(capabilities, "Recon", 0)
    local combat = GetTableValue(capabilities, "Combat", 0)

    local scoutingConfidence =
        GetTableValue(tendencies, "ScoutingConfidence", 0)

    local discipline =
        GetTableValue(personality, "Discipline", 50)

    local score =
        security * 0.25 +
        recon * 0.25 +
        combat * 0.15 +
        scoutingConfidence * 0.20 +
        discipline * 0.15

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE EXPLORE SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateExploreScore(profile)

    local capabilities = profile.Capabilities or {}
    local tendencies = profile.Tendencies or {}
    local personality = profile.Personality or {}

    local recon =
        GetTableValue(capabilities, "Recon", 0)

    local survival =
        GetTableValue(capabilities, "Survival", 0)

    local explorationDrive =
        GetTableValue(tendencies, "ExplorationDrive", 0)

    local scoutingConfidence =
        GetTableValue(tendencies, "ScoutingConfidence", 0)

    local curiosity =
        GetTableValue(personality, "Curiosity", 50)

    local riskTolerance =
        GetTableValue(personality, "RiskTolerance", 50)

    local score =
        recon * 0.25 +
        survival * 0.15 +
        explorationDrive * 0.25 +
        scoutingConfidence * 0.15 +
        curiosity * 0.10 +
        riskTolerance * 0.10

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE RESOURCE GATHERING SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateGatherResourcesScore(profile)

    local capabilities = profile.Capabilities or {}
    local tendencies = profile.Tendencies or {}

    local survival =
        GetTableValue(capabilities, "Survival", 0)

    local logistics =
        GetTableValue(capabilities, "Logistics", 0)

    local agriculture =
        GetTableValue(capabilities, "Agriculture", 0)

    local resourcePriority =
        GetTableValue(tendencies, "ResourcePriority", 0)

    local wildernessConfidence =
        GetTableValue(tendencies, "WildernessConfidence", 0)

    local score =
        survival * 0.30 +
        logistics * 0.20 +
        agriculture * 0.10 +
        resourcePriority * 0.25 +
        wildernessConfidence * 0.15

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE GUARD SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateGuardScore(profile)

    local capabilities = profile.Capabilities or {}
    local tendencies = profile.Tendencies or {}
    local personality = profile.Personality or {}

    local security =
        GetTableValue(capabilities, "Security", 0)

    local combat =
        GetTableValue(capabilities, "Combat", 0)

    local discipline =
        GetTableValue(personality, "Discipline", 50)

    local combatDiscipline =
        GetTableValue(tendencies, "CombatDiscipline", 0)

    local courage =
        GetTableValue(personality, "Courage", 50)

    local score =
        security * 0.30 +
        combat * 0.20 +
        discipline * 0.20 +
        combatDiscipline * 0.15 +
        courage * 0.15

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE HELP ALLY SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateHelpAllyScore(profile)

    local capabilities = profile.Capabilities or {}
    local tendencies = profile.Tendencies or {}
    local personality = profile.Personality or {}

    local leadership =
        GetTableValue(capabilities, "Leadership", 0)

    local medical =
        GetTableValue(capabilities, "Medical", 0)

    local logistics =
        GetTableValue(capabilities, "Logistics", 0)

    local cooperation =
        GetTableValue(tendencies, "Cooperation", 0)

    local loyalty =
        GetTableValue(personality, "Loyalty", 50)

    local score =
        leadership * 0.20 +
        medical * 0.20 +
        logistics * 0.15 +
        cooperation * 0.25 +
        loyalty * 0.20

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE REST SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateRestScore(profile)

    local personality = profile.Personality or {}
    local tendencies = profile.Tendencies or {}

    local fear =
        GetTableValue(personality, "Fear", 50)

    local riskTolerance =
        GetTableValue(personality, "RiskTolerance", 50)

    local retreatTendency =
        GetTableValue(tendencies, "RetreatTendency", 0)

    local score =
        fear * 0.30 +
        (100 - riskTolerance) * 0.25 +
        retreatTendency * 0.25 +
        20

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE HEAL SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateHealScore(profile)

    local capabilities = profile.Capabilities or {}
    local personality = profile.Personality or {}

    local medical =
        GetTableValue(capabilities, "Medical", 0)

    local survival =
        GetTableValue(capabilities, "Survival", 0)

    local fear =
        GetTableValue(personality, "Fear", 50)

    local score =
        medical * 0.40 +
        survival * 0.20 +
        fear * 0.20 +
        20

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE RETREAT SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateRetreatScore(profile)

    local personality = profile.Personality or {}
    local tendencies = profile.Tendencies or {}
    local capabilities = profile.Capabilities or {}

    local fear =
        GetTableValue(personality, "Fear", 50)

    local courage =
        GetTableValue(personality, "Courage", 50)

    local riskTolerance =
        GetTableValue(personality, "RiskTolerance", 50)

    local retreatTendency =
        GetTableValue(tendencies, "RetreatTendency", 0)

    local combat =
        GetTableValue(capabilities, "Combat", 0)

    local score =
        fear * 0.30 +
        (100 - courage) * 0.15 +
        (100 - riskTolerance) * 0.20 +
        retreatTendency * 0.25 +
        (100 - combat) * 0.10

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE COMBAT SCORE
--------------------------------------------------

function BAO.DecisionSystem.CalculateCombatScore(profile)

    local capabilities = profile.Capabilities or {}
    local tendencies = profile.Tendencies or {}
    local personality = profile.Personality or {}

    local combat =
        GetTableValue(capabilities, "Combat", 0)

    local aggression =
        GetTableValue(personality, "Aggression", 50)

    local courage =
        GetTableValue(personality, "Courage", 50)

    local combatAggression =
        GetTableValue(tendencies, "CombatAggression", 0)

    local combatDiscipline =
        GetTableValue(tendencies, "CombatDiscipline", 0)

    local score =
        combat * 0.30 +
        aggression * 0.20 +
        courage * 0.15 +
        combatAggression * 0.20 +
        combatDiscipline * 0.15

    return Clamp(score, 0, 100)
end


--------------------------------------------------
-- CALCULATE ALL DECISIONS
--------------------------------------------------

function BAO.DecisionSystem.CalculateScores(profile)

    if not profile then
        return nil
    end

    local scores = {}

    scores.patrol =
        BAO.DecisionSystem.CalculatePatrolScore(profile)

    scores.explore =
        BAO.DecisionSystem.CalculateExploreScore(profile)

    scores.gather_resources =
        BAO.DecisionSystem.CalculateGatherResourcesScore(profile)

    scores.guard =
        BAO.DecisionSystem.CalculateGuardScore(profile)

    scores.help_ally =
        BAO.DecisionSystem.CalculateHelpAllyScore(profile)

    scores.rest =
        BAO.DecisionSystem.CalculateRestScore(profile)

    scores.heal =
        BAO.DecisionSystem.CalculateHealScore(profile)

    scores.retreat =
        BAO.DecisionSystem.CalculateRetreatScore(profile)

    scores.combat =
        BAO.DecisionSystem.CalculateCombatScore(profile)

    return scores
end


--------------------------------------------------
-- FIND BEST DECISION
--------------------------------------------------

function BAO.DecisionSystem.SelectBestDecision(scores)

    if not scores then
        return nil
    end

    local bestDecision = nil
    local bestScore = -1
    local bestPriority = -1

    for decision, score in pairs(scores) do

        local priority =
            BAO.DecisionSystem.Priority[decision] or 0

        if score > bestScore then

            bestDecision = decision
            bestScore = score
            bestPriority = priority

        elseif score == bestScore and priority > bestPriority then

            bestDecision = decision
            bestScore = score
            bestPriority = priority
        end
    end

    return {
        Decision = bestDecision,
        Score = bestScore,
        Priority = bestPriority
    }
end


--------------------------------------------------
-- PRINT SCORES
--------------------------------------------------

function BAO.DecisionSystem.PrintScores(scores)

    if not scores then
        Log("Decision scores are unavailable")
        return
    end

    Log("=== DECISION SCORES ===")

    Log(
        "patrol = " ..
        Round(scores.patrol)
    )

    Log(
        "explore = " ..
        Round(scores.explore)
    )

    Log(
        "gather_resources = " ..
        Round(scores.gather_resources)
    )

    Log(
        "guard = " ..
        Round(scores.guard)
    )

    Log(
        "help_ally = " ..
        Round(scores.help_ally)
    )

    Log(
        "rest = " ..
        Round(scores.rest)
    )

    Log(
        "heal = " ..
        Round(scores.heal)
    )

    Log(
        "retreat = " ..
        Round(scores.retreat)
    )

    Log(
        "combat = " ..
        Round(scores.combat)
    )
end


--------------------------------------------------
-- PRINT CURRENT DECISION
--------------------------------------------------

function BAO.DecisionSystem.PrintDecision(result)

    if not result then
        Log("No decision was selected")
        return
    end

    Log("=== PRIMARY DECISION ===")

    Log(
        "Decision: " ..
        tostring(result.Decision)
    )

    Log(
        "Score: " ..
        Round(result.Score)
    )

    Log(
        "Priority: " ..
        tostring(result.Priority)
    )
end


--------------------------------------------------
-- CALCULATE CURRENT PLAYER DECISION
--------------------------------------------------

function BAO.DecisionSystem.CalculateCurrentPlayer()

    if not BAO.PlayerProfile then
        Log("ERROR: BAO.PlayerProfile is unavailable")
        return nil
    end

    if not BAO.PlayerProfile.Get then
        Log("ERROR: BAO.PlayerProfile.Get is unavailable")
        return nil
    end

    local profile =
        BAO.PlayerProfile.Get()

    if not profile then
        Log("Decision System: PlayerProfile not ready")
        return nil
    end

    if not BAO.BehaviorProfile then
        Log("ERROR: BAO.BehaviorProfile is unavailable")
        return nil
    end

    local behaviorProfile =
        BAO.DecisionSystem.GetBehaviorProfile()

    if not behaviorProfile then
        Log("Decision System: BehaviorProfile not ready")
        return nil
    end

    local scores =
        BAO.DecisionSystem.CalculateScores(
            behaviorProfile
        )

    if not scores then
        Log("ERROR: Failed to calculate decision scores")
        return nil
    end

    local result =
        BAO.DecisionSystem.SelectBestDecision(
            scores
        )

    if not result then
        Log("ERROR: Failed to select decision")
        return nil
    end

    BAO.DecisionSystem.LastScores = scores
    BAO.DecisionSystem.CurrentDecision = result

    return result
end


--------------------------------------------------
-- PRINT FULL DIAGNOSTIC
--------------------------------------------------

function BAO.DecisionSystem.PrintCurrent()

    Log("========================================")
    Log("=== BAO DECISION SYSTEM V1 DIAGNOSTIC ===")
    Log("========================================")

    local result =
        BAO.DecisionSystem.CalculateCurrentPlayer()

    if not result then
        Log("Decision System diagnostic failed")
        return
    end

    BAO.DecisionSystem.PrintScores(
        BAO.DecisionSystem.LastScores
    )

    BAO.DecisionSystem.PrintDecision(
        result
    )

    Log("========================================")
    Log("Decision System V1 calculation complete")
    Log("========================================")
end


--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

function BAO.DecisionSystem.TryInitialize()

    if BAO.DecisionSystem.Initialized then
        return true
    end

    if not BAO.PlayerProfile then
        return false
    end

    if not BAO.PlayerProfile.Get then
        return false
    end

    local profile =
        BAO.PlayerProfile.Get()

    if not profile then
        return false
    end

    if not BAO.BehaviorProfile then
        return false
    end

    local behaviorProfile =
        BAO.DecisionSystem.GetBehaviorProfile()

    if not behaviorProfile then
        return false
    end

    BAO.DecisionSystem.Initialized = true

    Log("Decision System V1 initialized")

    BAO.DecisionSystem.PrintCurrent()

    return true
end


--------------------------------------------------
-- GAME START
--------------------------------------------------

if Events then

    Events.OnGameStart.Add(
        function()

            Log("Decision System V1: OnGameStart")

            Events.OnTick.Add(
                function()

                    if not BAO.DecisionSystem.Initialized then
                        BAO.DecisionSystem.TryInitialize()
                    end

                end
            )

        end
    )

end


--------------------------------------------------
-- MODULE LOADED
--------------------------------------------------

Log("Decision System V1 module loaded")