-- ============================================================
-- BanditsAIOverhaul
-- BAO_ActionExecutor.lua
--
-- Action Executor V1.2
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
--   V1.2 does NOT directly control NPC movement,
--   animation or combat.
--
--   It provides the execution layer that those systems
--   will use later.
-- ============================================================

local ActionExecutor = {}

-- ============================================================
-- VERSION
-- ============================================================

ActionExecutor.VERSION = "1.2"

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
        -- Opt-in linkage preserves standalone plan/execution tests.
        action = metadata and metadata.linkedAction and action or nil,

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

    if execution.action and action.metadata and action.metadata.navigation then
        local previousCheck = action.canComplete
        action.canComplete = function(checkedAction)
            if not execution.navigation or execution.navigation.state ~= "ARRIVED" then return false end
            return not previousCheck or previousCheck(checkedAction) == true
        end
    end

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

    if execution.state ~= ActionExecutor.STATES.IDLE then
        return false, "invalid_state"
    end

    if execution.action then
        local system = GetActionSystem()
        if not system or system.GetAction(execution.actionId) ~= execution.action
            or execution.action.state ~= system.State.RUNNING then
            return false, "action_not_running"
        end
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

    local binding = execution.action and execution.action.metadata.navigation
    if binding then
        if execution.actionType ~= "patrol" then
            return ActionExecutor.FailExecution(execution, "unsupported_navigation_action")
        end
        local navigation = BAO.NavigationSystem
        if not navigation then return ActionExecutor.FailExecution(execution, "navigation_unavailable") end
        local request = navigation.RequestLocation(binding.character, binding.x, binding.y, binding.z, binding.options)
        if not request then return ActionExecutor.FailExecution(execution, "invalid_navigation_request") end
        execution.navigation = request
        execution.navigationModule = navigation
        local started, reason = navigation.Start(request)
        if not started then return ActionExecutor.FailExecution(execution, reason or "navigation_start_failed") end
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

    local request = execution.navigation
    if request then
        if request.state == "ARRIVED" then
            return ActionExecutor.CompleteExecution(execution, "arrived", { navigationId = request.id })
        elseif request.state == "FAILED" then
            return ActionExecutor.FailExecution(execution, request.reason or "navigation_failed")
        elseif request.state == "CANCELLED" then
            return ActionExecutor.CancelExecution(execution, request.reason or "navigation_cancelled")
        elseif execution.navigationModule.GetCurrentNavigation() ~= request then
            return ActionExecutor.FailExecution(execution, "navigation_ownership_lost")
        end
    end

    -- Unbound actions wait for an explicit result; they do not simulate movement.
    return true, nil
end

-- ============================================================
-- COMPLETE
-- ============================================================

-- Complete a pair exactly once. Never clear another execution's ownership.
local TERMINAL = {
    completed = { "COMPLETED", "SUCCESS", "executionsCompleted" },
    failed = { "FAILED", "FAILED", "executionsFailed" },
    interrupted = { "INTERRUPTED", "INTERRUPTED", "executionsInterrupted" },
    cancelled = { "CANCELLED", "CANCELLED", "executionsCancelled" }
}

local function FinishExecution(execution, outcome, reason, resultData)
    if not execution or ActionExecutor.currentExecution ~= execution
        or execution._finished or execution._finishing then
        return false
    end

    local action = execution.action
    local system = GetActionSystem()
    if outcome == "interrupted" and action and not action.interruptible
        and not TERMINAL[action.state] then return false end
    local navigation, request = execution.navigationModule, execution.navigation
    if outcome == "completed" and request and request.state ~= "ARRIVED" then return false end
    if navigation and navigation.GetCurrentNavigation() == request and request then
        if not navigation.Cancel(reason or outcome, request) then return false end
    end
    if action then
        if not system or system.GetAction(execution.actionId) ~= action then
            outcome, reason = "failed", "linked_action_missing"
        elseif not TERMINAL[action.state] then
            execution._finishing = true
            local changed = false
            if outcome == "completed" then
                changed = system.CompleteAction(action.id, system.Result.SUCCESS, resultData)
            elseif outcome == "failed" then
                changed = system.FailAction(action.id, system.Result.FAILED, reason, resultData)
            elseif outcome == "interrupted" then
                changed = system.InterruptAction(action.id, reason)
            elseif outcome == "cancelled" then
                changed = system.CancelAction(action.id, reason)
            end
            execution._finishing = nil
            if not changed then return false end
        end
        -- An externally completed action is authoritative, including its reason.
        if system and system.GetAction(execution.actionId) == action and TERMINAL[action.state] then
            outcome = action.state
            reason = action.reason or reason
            action.reason = reason
            resultData = action.resultData
        end
    end

    local terminal = TERMINAL[outcome]
    if not terminal then return false end
    execution.state = terminal[1]
    execution.result = terminal[2]
    if action and action.result == "blocked" and outcome == "failed" then
        execution.result = ActionExecutor.RESULTS.BLOCKED
    end
    execution.reason = reason or outcome
    execution.resultData = resultData
    execution.finishedAt = GetCurrentTime()
    execution.elapsedTime = execution.finishedAt - (execution.startedAt or execution.finishedAt)
    execution.plan.currentStep = "finish"
    execution._finished = true
    ActionExecutor.lastExecution = execution
    ActionExecutor.currentExecution = nil
    ActionExecutor.statistics[terminal[3]] = ActionExecutor.statistics[terminal[3]] + 1
    AddHistory(execution)
    Log("Execution " .. outcome .. ": " .. tostring(execution.id)
        .. " action=" .. tostring(execution.actionId)
        .. " reason=" .. tostring(execution.reason))
    return true
end

function ActionExecutor.CompleteExecution(execution, reason, resultData)
    return FinishExecution(execution, "completed", reason, resultData)
end

function ActionExecutor.FailExecution(execution, reason, resultData)
    return FinishExecution(execution, "failed", reason, resultData)
end

function ActionExecutor.InterruptExecution(execution, reason)
    return FinishExecution(execution, "interrupted", reason)
end

function ActionExecutor.CancelExecution(execution, reason)
    return FinishExecution(execution, "cancelled", reason)
end

-- Synchronize only; Controller may call this without advancing the executor tick.
function ActionExecutor.SyncActionState(execution)
    if not execution or ActionExecutor.currentExecution ~= execution then return false end
    local action = execution.action
    if not action then return false end
    local system = GetActionSystem()
    if not system or system.GetAction(execution.actionId) ~= action then
        return FinishExecution(execution, "failed", "linked_action_missing")
    end
    if TERMINAL[action.state] then
        return FinishExecution(execution, action.state, action.reason, action.resultData)
    end
    return false
end

-- ============================================================
-- UPDATE (physical handlers are a subsequent integration step)
-- ============================================================

function ActionExecutor.Update()

    local execution =
        ActionExecutor.currentExecution

    if not execution then
        return
    end

    if ActionExecutor.SyncActionState(execution) then return end

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

    if ActionExecutor.currentExecution then
        if not ActionExecutor.CancelExecution(ActionExecutor.currentExecution, "executor_reset") then
            return false
        end
    end

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
    return true
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
