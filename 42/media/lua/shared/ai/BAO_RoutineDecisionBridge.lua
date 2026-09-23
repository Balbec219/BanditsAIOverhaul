-- ============================================================
-- BanditsAIOverhaul
-- BAO Routine / Decision Bridge V1.0
-- ============================================================
--
-- Purpose:
--   Connects Routine System with Decision System.
--
-- Architecture:
--
--   Routine
--      ↓
--   Routine Intent
--      ↓
--   Decision Context
--      ↓
--   Decision System
--
-- IMPORTANT:
--   This module does NOT replace DecisionSystem.
--   This module does NOT replace AIController.
--   This module does NOT create Actions.
--
--   It only translates routine state into a decision context.
--
-- ============================================================

local RoutineDecisionBridge = {}

local MODULE_NAME = "BAO_RoutineDecisionBridge"
local VERSION = "V1.0"

local initialized = false
local initializeAttempts = 0

local bridgeState = {
    ownerId = nil,

    routineId = nil,

    routineActivity = nil,

    routineIntent = nil,

    routinePriority = 0,

    emergency = false,

    emergencyReason = nil,

    lastContext = nil,

    lastDecision = nil,

    lastUpdate = nil
}

-- ============================================================
-- LOG
-- ============================================================

local function Log(message)
    print(
        "[BAO]["
        .. MODULE_NAME
        .. "] "
        .. tostring(message)
    )
end

-- ============================================================
-- ROUTINE → INTENT MAP
-- ============================================================

local ROUTINE_INTENTS = {

    wake_up = {
        intent = "rest",
        priority = 20
    },

    sleep = {
        intent = "rest",
        priority = 30
    },

    rest = {
        intent = "rest",
        priority = 30
    },

    eat = {
        intent = "gather_resources",
        priority = 40
    },

    drink = {
        intent = "gather_resources",
        priority = 40
    },

    work = {
        intent = "gather_resources",
        priority = 30
    },

    gather = {
        intent = "gather_resources",
        priority = 40
    },

    farming = {
        intent = "gather_resources",
        priority = 30
    },

    cooking = {
        intent = "gather_resources",
        priority = 30
    },

    repair = {
        intent = "gather_resources",
        priority = 40
    },

    building = {
        intent = "gather_resources",
        priority = 30
    },

    guard = {
        intent = "guard",
        priority = 60
    },

    patrol = {
        intent = "patrol",
        priority = 60
    },

    socialize = {
        intent = "help_ally",
        priority = 20
    },

    talk = {
        intent = "help_ally",
        priority = 20
    },

    train = {
        intent = "gather_resources",
        priority = 30
    },

    idle = {
        intent = "rest",
        priority = 10
    }
}

-- ============================================================
-- DECISION PRIORITIES
-- ============================================================

local EMERGENCY_DECISIONS = {

    combat = true,

    retreat = true,

    heal = true
}

local function IsEmergencyDecision(decision)
    return EMERGENCY_DECISIONS[decision] == true
end

-- ============================================================
-- MODULE ACCESS
-- ============================================================

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

-- ============================================================
-- ROUTINE INTENT
-- ============================================================

function RoutineDecisionBridge.GetRoutineIntent(
    activityType
)
    if type(activityType) ~= "string" then
        return nil
    end

    return ROUTINE_INTENTS[activityType]
end

-- ============================================================
-- BUILD ROUTINE CONTEXT
-- ============================================================

function RoutineDecisionBridge.BuildRoutineContext(
    routineId,
    hour,
    minute,
    worldContext
)
    local routineSystem =
        GetRoutineSystem()

    if not routineSystem then
        Log(
            "BuildRoutineContext failed: "
            .. "RoutineSystem unavailable"
        )

        return nil
    end

    local routine =
        routineSystem.GetRoutine(
            routineId
        )

    if not routine then
        Log(
            "BuildRoutineContext failed: "
            .. "routine not found: "
            .. tostring(routineId)
        )

        return nil
    end

    local activity =
        routineSystem.FindCurrentActivity(
            routineId,
            hour,
            minute,
            worldContext
        )

    local context = {
        routineId = routineId,

        ownerId = routine.ownerId,

        routineEnabled = routine.enabled == true,

        activityId = nil,

        activityType = nil,

        routineIntent = nil,

        routinePriority = 0,

        hour = hour,

        minute = minute
    }

    if activity then

        context.activityId =
            activity.id

        context.activityType =
            activity.type

        local intent =
            RoutineDecisionBridge.GetRoutineIntent(
                activity.type
            )

        if intent then

            context.routineIntent =
                intent.intent

            context.routinePriority =
                intent.priority
        end
    end

    return context
end

-- ============================================================
-- BUILD DECISION OVERRIDE CONTEXT
-- ============================================================

function RoutineDecisionBridge.BuildDecisionContext(
    routineContext,
    worldContext
)
    local context = {}

    if type(worldContext) == "table" then

        for key, value in pairs(worldContext) do
            context[key] = value
        end
    end

    if type(routineContext) == "table" then

        context.routineId =
            routineContext.routineId

        context.routineActivityId =
            routineContext.activityId

        context.routineActivityType =
            routineContext.activityType

        context.routineIntent =
            routineContext.routineIntent

        context.routinePriority =
            routineContext.routinePriority

        context.routineEnabled =
            routineContext.routineEnabled
    end

    return context
end

-- ============================================================
-- EMERGENCY DETECTION
-- ============================================================

function RoutineDecisionBridge.EvaluateEmergency(
    worldContext
)
    if type(worldContext) ~= "table" then
        return false, nil
    end

    -- Combat state.

    if worldContext.inCombat == true then
        return true, "in_combat"
    end

    if worldContext.enemyDetected == true then
        return true, "enemy_detected"
    end

    -- Health emergency.

    if type(worldContext.health) == "number" then

        if worldContext.health <= 25 then
            return true, "critical_health"
        end
    end

    -- Zombie danger.

    if type(worldContext.zombiesNearby) == "number" then

        if worldContext.zombiesNearby >= 20 then
            return true, "high_zombie_density"
        end
    end

    -- Panic.

    if type(worldContext.panic) == "number" then

        if worldContext.panic >= 80 then
            return true, "high_panic"
        end
    end

    return false, nil
end

-- ============================================================
-- APPLY ROUTINE TO DECISION CONTEXT
-- ============================================================

function RoutineDecisionBridge.ApplyRoutineContext(
    worldContext,
    routineContext
)
    local context =
        RoutineDecisionBridge.BuildDecisionContext(
            routineContext,
            worldContext
        )

    local emergency, reason =
        RoutineDecisionBridge.EvaluateEmergency(
            worldContext
        )

    context.emergency = emergency

    context.emergencyReason = reason

    bridgeState.emergency =
        emergency

    bridgeState.emergencyReason =
        reason

    return context
end

-- ============================================================
-- GET ROUTINE PREFERENCE
-- ============================================================

function RoutineDecisionBridge.GetRoutinePreference(
    routineContext
)
    if type(routineContext) ~= "table" then
        return nil
    end

    if routineContext.routineIntent == nil then
        return nil
    end

    return {
        decision =
            routineContext.routineIntent,

        priority =
            routineContext.routinePriority or 0,

        activity =
            routineContext.activityType
    }
end

-- ============================================================
-- DECISION OVERRIDE EVALUATION
-- ============================================================

function RoutineDecisionBridge.EvaluateDecision(
    decision,
    routineContext,
    worldContext
)
    local result = {

        decision = decision,

        routineActivity =
            routineContext
            and routineContext.activityType
            or nil,

        routineIntent =
            routineContext
            and routineContext.routineIntent
            or nil,

        routinePriority =
            routineContext
            and routineContext.routinePriority
            or 0,

        emergency = false,

        emergencyReason = nil,

        routineOverridden = false
    }

    local emergency, reason =
        RoutineDecisionBridge.EvaluateEmergency(
            worldContext
        )

    result.emergency = emergency

    result.emergencyReason = reason

    if emergency then

        result.routineOverridden = true

        return result
    end

    -- If DecisionSystem already produced a valid decision,
    -- it remains authoritative.
    --
    -- Routine is contextual information, not a forced command.

    return result
end

-- ============================================================
-- PROCESS CURRENT STATE
-- ============================================================

function RoutineDecisionBridge.Update(
    ownerId,
    routineId,
    hour,
    minute,
    worldContext
)
    local routineSystem =
        GetRoutineSystem()

    if not routineSystem then
        return nil
    end

    local routineContext =
        RoutineDecisionBridge.BuildRoutineContext(
            routineId,
            hour,
            minute,
            worldContext
        )

    if not routineContext then
        return nil
    end

    local decisionContext =
        RoutineDecisionBridge.ApplyRoutineContext(
            worldContext,
            routineContext
        )

    bridgeState.ownerId =
        ownerId

    bridgeState.routineId =
        routineId

    bridgeState.routineActivity =
        routineContext.activityType

    bridgeState.routineIntent =
        routineContext.routineIntent

    bridgeState.routinePriority =
        routineContext.routinePriority

    bridgeState.lastContext =
        decisionContext

    bridgeState.lastUpdate = {
        hour = hour,
        minute = minute
    }

    return decisionContext
end

-- ============================================================
-- REGISTER DECISION
-- ============================================================

function RoutineDecisionBridge.RegisterDecision(
    decision
)
    bridgeState.lastDecision =
        decision

    return RoutineDecisionBridge.EvaluateDecision(
        decision,
        {
            activityType =
                bridgeState.routineActivity,

            routineIntent =
                bridgeState.routineIntent,

            routinePriority =
                bridgeState.routinePriority
        },
        bridgeState.lastContext
    )
end

-- ============================================================
-- STATE ACCESS
-- ============================================================

function RoutineDecisionBridge.GetState()
    return bridgeState
end

function RoutineDecisionBridge.GetLastContext()
    return bridgeState.lastContext
end

function RoutineDecisionBridge.GetLastDecision()
    return bridgeState.lastDecision
end

function RoutineDecisionBridge.IsEmergency()
    return bridgeState.emergency == true
end

function RoutineDecisionBridge.GetEmergencyReason()
    return bridgeState.emergencyReason
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

function RoutineDecisionBridge.Initialize()

    initializeAttempts =
        initializeAttempts + 1

    Log(
        "Initialize attempt #"
        .. tostring(initializeAttempts)
    )

    if initialized then

        Log(
            "Routine/Decision Bridge already initialized"
        )

        return true
    end

    if not GetRoutineSystem() then

        Log(
            "RoutineSystem unavailable"
        )

        return false
    end

    if not GetDecisionSystem() then

        Log(
            "DecisionSystem unavailable"
        )

        return false
    end

    initialized = true

    Log(
        "Routine/Decision Bridge initialized "
        .. VERSION
    )

    return true
end

-- ============================================================
-- STATUS
-- ============================================================

function RoutineDecisionBridge.GetStatus()

    return {

        initialized = initialized,

        version = VERSION,

        initializeAttempts =
            initializeAttempts,

        ownerId =
            bridgeState.ownerId,

        routineId =
            bridgeState.routineId,

        routineActivity =
            bridgeState.routineActivity,

        routineIntent =
            bridgeState.routineIntent,

        routinePriority =
            bridgeState.routinePriority,

        emergency =
            bridgeState.emergency,

        emergencyReason =
            bridgeState.emergencyReason,

        lastDecision =
            bridgeState.lastDecision
    }
end

-- ============================================================
-- EVENT
-- ============================================================

if Events then

    Events.OnGameStart.Add(function()

        Log("OnGameStart")

        if not initialized then

            local success =
                RoutineDecisionBridge.Initialize()

            if not success then

                Log(
                    "Initialization deferred: "
                    .. "dependencies not ready"
                )
            end
        end

    end)

end

-- ============================================================
-- EXPORT
-- ============================================================

BAO = BAO or {}

BAO.RoutineDecisionBridge =
    RoutineDecisionBridge

Log(
    "Routine / Decision Bridge "
    .. VERSION
    .. " module loaded"
)

return RoutineDecisionBridge

