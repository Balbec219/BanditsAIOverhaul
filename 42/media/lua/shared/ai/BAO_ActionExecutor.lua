-- ============================================================
-- BanditsAIOverhaul
-- BAO_ActionExecutor.lua
--
-- Action Executor V1.0
--
-- Purpose:
--   Converts abstract actions from BAO_ActionSystem
--   into executable plans.
--
-- Architecture:
--
--   Decision
--      ↓
--   AIController
--      ↓
--   ActionSystem
--      ↓
--   ActionExecutor
--      ↓
--   Navigation / Animation / Interaction / Combat
--
-- IMPORTANT:
--   V1.0 does NOT directly control NPC movement,
--   animation or combat.
--
--   It provides the execution layer that those systems
--   will use later.
-- ============================================================

local ActionExecutor = {}

-- ============================================================
-- VERSION
-- ============================================================

ActionExecutor.VERSION = "1.0"

-- ============================================================
-- EXECUTION STATES
-- ============================================================

ActionExecutor.STATES = {
    IDLE = "IDLE",
    PREPARING = "PREPARING",
    EXECUTING = "EXECUTING",
    COMPLETED = "COMPLETED",
    FAILED = "FAILED",
    INTERRUPTED = "INTERRUPTED",
    CANCELLED = "CANCELLED"
}

-- ============================================================
-- EXECUTION RESULTS
-- ============================================================

ActionExecutor.RESULTS = {
    SUCCESS = "SUCCESS",
    FAILED = "FAILED",
    BLOCKED = "BLOCKED",
    INTERRUPTED = "INTERRUPTED",
    CANCELLED = "CANCELLED",
    TIMEOUT = "TIMEOUT"
}

-- ============================================================
-- EXECUTOR TYPES
-- ============================================================

ActionExecutor.TYPES = {
    GENERIC = "generic",
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

-- ============================================================
-- RUNTIME
-- ============================================================

ActionExecutor.initialized = false
ActionExecutor.attempts = 0

ActionExecutor.currentExecution = nil
ActionExecutor.lastExecution = nil

ActionExecutor.executionHistory = {}
ActionExecutor.maxHistory = 20

ActionExecutor.nextExecutionId = 1

ActionExecutor.statistics = {
    executionsCreated = 0,
    executionsStarted = 0,
    executionsCompleted = 0,
    executionsFailed = 0,
    executionsInterrupted = 0,
    executionsCancelled = 0,
    executionsTimedOut = 0
}

-- ============================================================
-- LOGGING
-- ============================================================

local function Log(message)
    print("[BAO][BAO_ActionExecutor] " .. tostring(message))
end

-- ============================================================
-- HELPERS
-- ============================================================

local function GetActionSystem()
    if BAO and BAO.ActionSystem then
        return BAO.ActionSystem
    end

    return nil
end

local function GetCurrentTime()
    return os.time() * 1000
end

local function GenerateExecutionId()
    local id = "bao_execution_" .. tostring(ActionExecutor.nextExecutionId)

    ActionExecutor.nextExecutionId =
        ActionExecutor.nextExecutionId + 1

    return id
end

local function AddHistory(execution)
    if not execution then
        return
    end

    table.insert(
        ActionExecutor.executionHistory,
        execution
    )

    while #ActionExecutor.executionHistory >
        ActionExecutor.maxHistory do

        table.remove(
            ActionExecutor.executionHistory,
            1
        )
    end
end

-- ============================================================
-- ACTION → EXECUTOR TYPE
-- ============================================================

function ActionExecutor.GetExecutorType(actionType)

    if not actionType then
        return ActionExecutor.TYPES.GENERIC
    end

    if actionType == "patrol" then
        return ActionExecutor.TYPES.PATROL

    elseif actionType == "explore" then
        return ActionExecutor.TYPES.EXPLORE

    elseif actionType == "gather_resources" then
        return ActionExecutor.TYPES.GATHER_RESOURCES

    elseif actionType == "guard" then
        return ActionExecutor.TYPES.GUARD

    elseif actionType == "help_ally" then
        return ActionExecutor.TYPES.HELP_ALLY

    elseif actionType == "rest" then
        return ActionExecutor.TYPES.REST

    elseif actionType == "heal" then
        return ActionExecutor.TYPES.HEAL

    elseif actionType == "retreat" then
        return ActionExecutor.TYPES.RETREAT

    elseif actionType == "combat" then
        return ActionExecutor.TYPES.COMBAT
    end

    return ActionExecutor.TYPES.GENERIC
end

-- ============================================================
-- EXECUTION PLAN
-- ============================================================

function ActionExecutor.CreatePlan(
    action,
    metadata
)

    if not action then
        return nil
    end

    local actionType = action.type or action.actionType

    local executorType =
        ActionExecutor.GetExecutorType(actionType)

    local plan = {
        executorType = executorType,

        actionType = actionType,

        steps = {
            "prepare",
            "execute",
            "finish"
        },

        currentStep = "prepare",

        navigationRequired = false,
        animationRequired = false,
        interactionRequired = false,
        combatRequired = false,

        interruptible = true,

        metadata = metadata or {}
    }

    -- --------------------------------------------------------
    -- Future subsystem requirements
    -- --------------------------------------------------------

    if executorType == ActionExecutor.TYPES.PATROL then
        plan.navigationRequired = true
        plan.animationRequired = true

    elseif executorType == ActionExecutor.TYPES.EXPLORE then
        plan.navigationRequired = true
        plan.animationRequired = true

    elseif executorType ==
        ActionExecutor.TYPES.GATHER_RESOURCES then

        plan.navigationRequired = true
        plan.animationRequired = true
        plan.interactionRequired = true

    elseif executorType == ActionExecutor.TYPES.GUARD then
        plan.navigationRequired = true
        plan.animationRequired = true

    elseif executorType == ActionExecutor.TYPES.HELP_ALLY then
        plan.navigationRequired = true
        plan.animationRequired = true
        plan.interactionRequired = true

    elseif executorType == ActionExecutor.TYPES.REST then
        plan.navigationRequired = true
        plan.animationRequired = true

    elseif executorType == ActionExecutor.TYPES.HEAL then
        plan.navigationRequired = true
        plan.animationRequired = true
        plan.interactionRequired = true

    elseif executorType == ActionExecutor.TYPES.RETREAT then
        plan.navigationRequired = true
        plan.animationRequired = true

    elseif executorType == ActionExecutor.TYPES.COMBAT then
        plan.navigationRequired = true
        plan.animationRequired = true
        plan.combatRequired = true
    end

    return plan
end

-- ============================================================
-- CREATE EXECUTION
-- ============================================================

function ActionExecutor.CreateExecution(
    actionId,
    action,
    metadata
)

    if not action then
        return nil
    end

    local execution = {
        id = GenerateExecutionId(),

        actionId = actionId,

        actionType =
            action.type or action.actionType,

        executorType =
            ActionExecutor.GetExecutorType(
                action.type or action.actionType
            ),

        state = ActionExecutor.STATES.IDLE,

        result = nil,

        reason = nil,

        createdAt = GetCurrentTime(),

        startedAt = nil,

        finishedAt = nil,

        elapsedTime = 0,

        attempts = 0,

        maxAttempts = 3,

        timeout = nil,

        plan = nil,

        metadata = metadata or {}
    }

    execution.plan =
        ActionExecutor.CreatePlan(
            action,
            metadata
        )

    ActionExecutor.statistics.executionsCreated =
        ActionExecutor.statistics.executionsCreated + 1

    return execution
end

-- ============================================================
-- VALIDATION
-- ============================================================

function ActionExecutor.ValidateExecution(execution)

    if not execution then
        return false, "missing_execution"
    end

    if not execution.actionId then
        return false, "missing_action_id"
    end

    if not execution.actionType then
        return false, "missing_action_type"
    end

    if not execution.plan then
        return false, "missing_execution_plan"
    end

    return true, nil
end

-- ============================================================
-- START
-- ============================================================

function ActionExecutor.StartExecution(execution)

    if not execution then
        return false, "missing_execution"
    end

    local valid, reason =
        ActionExecutor.ValidateExecution(execution)

    if not valid then
        execution.state =
            ActionExecutor.STATES.FAILED

        execution.result =
            ActionExecutor.RESULTS.FAILED

        execution.reason = reason

        return false, reason
    end

    if ActionExecutor.currentExecution then
        return false, "execution_already_active"
    end

    execution.state =
        ActionExecutor.STATES.PREPARING

    execution.startedAt = GetCurrentTime()

    execution.attempts =
        execution.attempts + 1

    ActionExecutor.currentExecution =
        execution

    ActionExecutor.statistics.executionsStarted =
        ActionExecutor.statistics.executionsStarted + 1

    Log(
        "Execution started: "
        .. tostring(execution.id)
        .. " ["
        .. tostring(execution.actionType)
        .. "]"
    )

    return true, nil
end

-- ============================================================
-- PREPARE
-- ============================================================

function ActionExecutor.PrepareExecution(execution)

    if not execution then
        return false, "missing_execution"
    end

    if execution.state ~=
        ActionExecutor.STATES.PREPARING then

        return false, "invalid_state"
    end

    execution.plan.currentStep =
        "execute"

    execution.state =
        ActionExecutor.STATES.EXECUTING

    return true, nil
end

-- ============================================================
-- EXECUTE
-- ============================================================

function ActionExecutor.ExecuteStep(execution)

    if not execution then
        return false, "missing_execution"
    end

    if execution.state ~=
        ActionExecutor.STATES.EXECUTING then

        return false, "invalid_state"
    end

    -- --------------------------------------------------------
    -- V1.0:
    --
    -- The actual physical execution is intentionally deferred.
    --
    -- Future systems will be called here:
    --
    -- Navigation
    -- Animation
    -- Interaction
    -- Combat
    --
    -- For now we maintain a valid execution state.
    -- --------------------------------------------------------

    return true, nil
end

-- ============================================================
-- COMPLETE
-- ============================================================

function ActionExecutor.CompleteExecution(
    execution,
    reason
)

    if not execution then
        return false
    end

    execution.state =
        ActionExecutor.STATES.COMPLETED

    execution.result =
        ActionExecutor.RESULTS.SUCCESS

    execution.reason =
        reason or "completed"

    execution.finishedAt =
        GetCurrentTime()

    if execution.startedAt then
        execution.elapsedTime =
            execution.finishedAt
            - execution.startedAt
    end

    ActionExecutor.lastExecution =
        execution

    ActionExecutor.currentExecution =
        nil

    ActionExecutor.statistics.executionsCompleted =
        ActionExecutor.statistics.executionsCompleted + 1

    AddHistory(execution)

    Log(
        "Execution completed: "
        .. tostring(execution.id)
    )

    return true
end

-- ============================================================
-- FAIL
-- ============================================================

function ActionExecutor.FailExecution(
    execution,
    reason
)

    if not execution then
        return false
    end

    execution.state =
        ActionExecutor.STATES.FAILED

    execution.result =
        ActionExecutor.RESULTS.FAILED

    execution.reason =
        reason or "failed"

    execution.finishedAt =
        GetCurrentTime()

    if execution.startedAt then
        execution.elapsedTime =
            execution.finishedAt
            - execution.startedAt
    end

    ActionExecutor.lastExecution =
        execution

    ActionExecutor.currentExecution =
        nil

    ActionExecutor.statistics.executionsFailed =
        ActionExecutor.statistics.executionsFailed + 1

    AddHistory(execution)

    Log(
        "Execution failed: "
        .. tostring(execution.id)
        .. " reason="
        .. tostring(execution.reason)
    )

    return true
end

-- ============================================================
-- INTERRUPT
-- ============================================================

function ActionExecutor.InterruptExecution(
    execution,
    reason
)

    if not execution then
        return false
    end

    execution.state =
        ActionExecutor.STATES.INTERRUPTED

    execution.result =
        ActionExecutor.RESULTS.INTERRUPTED

    execution.reason =
        reason or "interrupted"

    execution.finishedAt =
        GetCurrentTime()

    if execution.startedAt then
        execution.elapsedTime =
            execution.finishedAt
            - execution.startedAt
    end

    ActionExecutor.lastExecution =
        execution

    ActionExecutor.currentExecution =
        nil

    ActionExecutor.statistics.executionsInterrupted =
        ActionExecutor.statistics.executionsInterrupted + 1

    AddHistory(execution)

    Log(
        "Execution interrupted: "
        .. tostring(execution.id)
        .. " reason="
        .. tostring(execution.reason)
    )

    return true
end

-- ============================================================
-- CANCEL
-- ============================================================

function ActionExecutor.CancelExecution(
    execution,
    reason
)

    if not execution then
        return false
    end

    execution.state =
        ActionExecutor.STATES.CANCELLED

    execution.result =
        ActionExecutor.RESULTS.CANCELLED

    execution.reason =
        reason or "cancelled"

    execution.finishedAt =
        GetCurrentTime()

    if execution.startedAt then
        execution.elapsedTime =
            execution.finishedAt
            - execution.startedAt
    end

    ActionExecutor.lastExecution =
        execution

    ActionExecutor.currentExecution =
        nil

    ActionExecutor.statistics.executionsCancelled =
        ActionExecutor.statistics.executionsCancelled + 1

    AddHistory(execution)

    Log(
        "Execution cancelled: "
        .. tostring(execution.id)
    )

    return true
end

-- ============================================================
-- UPDATE
-- ============================================================

function ActionExecutor.Update()

    local execution =
        ActionExecutor.currentExecution

    if not execution then
        return
    end

    local now = GetCurrentTime()

    if execution.startedAt then
        execution.elapsedTime =
            now - execution.startedAt
    end

    if execution.state ==
        ActionExecutor.STATES.PREPARING then

        ActionExecutor.PrepareExecution(execution)

        return
    end

    if execution.state ==
        ActionExecutor.STATES.EXECUTING then

        ActionExecutor.ExecuteStep(execution)

        return
    end
end

-- ============================================================
-- GET CURRENT EXECUTION
-- ============================================================

function ActionExecutor.GetCurrentExecution()
    return ActionExecutor.currentExecution
end

-- ============================================================
-- GET LAST EXECUTION
-- ============================================================

function ActionExecutor.GetLastExecution()
    return ActionExecutor.lastExecution
end

-- ============================================================
-- GET HISTORY
-- ============================================================

function ActionExecutor.GetExecutionHistory()
    return ActionExecutor.executionHistory
end

-- ============================================================
-- GET STATISTICS
-- ============================================================

function ActionExecutor.GetStatistics()
    return ActionExecutor.statistics
end

-- ============================================================
-- GET STATUS
-- ============================================================

function ActionExecutor.GetStatus()

    return {
        initialized =
            ActionExecutor.initialized,

        version =
            ActionExecutor.VERSION,

        attempts =
            ActionExecutor.attempts,

        currentExecution =
            ActionExecutor.currentExecution,

        lastExecution =
            ActionExecutor.lastExecution,

        historyCount =
            #ActionExecutor.executionHistory,

        statistics =
            ActionExecutor.statistics
    }
end

-- ============================================================
-- RESET
-- ============================================================

function ActionExecutor.Reset()

    ActionExecutor.currentExecution = nil
    ActionExecutor.lastExecution = nil

    ActionExecutor.executionHistory = {}

    ActionExecutor.nextExecutionId = 1

    ActionExecutor.statistics = {
        executionsCreated = 0,
        executionsStarted = 0,
        executionsCompleted = 0,
        executionsFailed = 0,
        executionsInterrupted = 0,
        executionsCancelled = 0,
        executionsTimedOut = 0
    }

    Log("Action Executor reset")
end

-- ============================================================
-- INITIALIZE
-- ============================================================

function ActionExecutor.Initialize()

    ActionExecutor.attempts =
        ActionExecutor.attempts + 1

    Log(
        "Initialize attempt #"
        .. tostring(ActionExecutor.attempts)
    )

    if ActionExecutor.initialized then
        return true
    end

    local actionSystem =
        GetActionSystem()

    if not actionSystem then
        Log(
            "WARNING: ActionSystem not available yet"
        )

        return false
    end

    ActionExecutor.initialized = true

    Log(
        "Action Executor initialized V"
        .. ActionExecutor.VERSION
    )

    return true
end

-- ============================================================
-- GAME EVENTS
-- ============================================================

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            Log("OnGameStart")

            ActionExecutor.Initialize()

        end
    )

end

if Events and Events.OnTick then

    Events.OnTick.Add(
        function()

            if ActionExecutor.initialized then
                ActionExecutor.Update()
            end

        end
    )

end

-- ============================================================
-- EXPORT
-- ============================================================

BAO = BAO or {}

BAO.ActionExecutor = ActionExecutor

Log(
    "Action Executor V"
    .. ActionExecutor.VERSION
    .. " module loaded"
)