-----------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_AIController.lua
--
-- AI Controller V1.2
--
-- Architecture:
--
-- BehaviorProfile
--       ↓
-- DecisionSystem
--       ↓
-- AIController
--       ↓
-- ActionSystem
--       ↓
-- Action
--
-- V1.2:
-- - Connects DecisionSystem with ActionSystem
-- - Maintains current AI decision
-- - Maintains current action
-- - Creates actions from decisions
-- - Detects decision changes
-- - Interrupts obsolete actions
-- - Starts new actions
-- - Tracks action results
-- - Tracks controller state
-- - Provides debug getters
--
-- IMPORTANT:
-- This version does NOT directly control physical NPCs.
-- Movement, navigation, animation and real NPC objects
-- will be connected in later systems.
-----------------------------------------------------------

BAO = BAO or {}

local AIController = {}

-----------------------------------------------------------
-- VERSION
-----------------------------------------------------------

AIController.Version = "V1.2"

local MODULE_NAME = "BAO_AIController"

-----------------------------------------------------------
-- LOG
-----------------------------------------------------------

local function Log(message)

    print(
        "[BAO][" ..
        MODULE_NAME ..
        "] " ..
        tostring(message)
    )

end

-----------------------------------------------------------
-- CONTROLLER STATES
-----------------------------------------------------------

AIController.State = {

    IDLE = "idle",
    THINKING = "thinking",
    EXECUTING = "executing",
    WAITING = "waiting",
    INTERRUPTING = "interrupting",
    ERROR = "error"

}

-----------------------------------------------------------
-- DECISION -> ACTION MAPPING
-----------------------------------------------------------
--
-- This is intentionally separate from DecisionSystem.
--
-- DecisionSystem answers:
--
-- "What does the AI want to do?"
--
-- AIController answers:
--
-- "What Action represents that decision?"
--
-- Later these mappings can become much more intelligent.
-----------------------------------------------------------

local DECISION_ACTIONS = {

    patrol = "patrol",

    explore = "explore",

    gather_resources = "gather_resources",

    guard = "guard",

    help_ally = "help_ally",

    rest = "rest",

    heal = "heal",

    retreat = "retreat",

    combat = "combat"

}

-----------------------------------------------------------
-- RUNTIME STATE
-----------------------------------------------------------

local initialized = false

local attempts = 0

local controllerState =
    AIController.State.IDLE

-----------------------------------------------------------
-- DECISION STATE
-----------------------------------------------------------

local currentDecision = nil

local previousDecision = nil

-----------------------------------------------------------
-- ACTION STATE
-----------------------------------------------------------

local currentAction = nil

local currentActionId = nil
local currentExecution = nil
local patrolContext = nil

local lastAction = nil

local lastActionResult = nil

-----------------------------------------------------------
-- HISTORY
-----------------------------------------------------------

local actionHistory = {}

local MAX_HISTORY = 20

-----------------------------------------------------------
-- STATISTICS
-----------------------------------------------------------

local statistics = {

    decisionsProcessed = 0,

    actionsCreated = 0,

    actionsStarted = 0,

    actionsCompleted = 0,

    actionsFailed = 0,

    actionsInterrupted = 0

}

-----------------------------------------------------------
-- CONTROLLER ID
-----------------------------------------------------------
--
-- V1.2 has one global controller.
--
-- The architecture intentionally keeps an identity field
-- so that later this can become one controller per NPC.
-----------------------------------------------------------

local controllerId = "bao_ai_controller_001"

-----------------------------------------------------------
-- UTILITY
-----------------------------------------------------------

local function AddHistory(entry)

    if not entry then
        return
    end

    table.insert(
        actionHistory,
        entry
    )

    while #actionHistory > MAX_HISTORY do

        table.remove(
            actionHistory,
            1
        )

    end

end

-----------------------------------------------------------
-- GET DECISION SYSTEM
-----------------------------------------------------------

local function GetDecisionSystem()

    if not BAO.DecisionSystem then

        Log(
            "DecisionSystem unavailable"
        )

        return nil

    end

    return BAO.DecisionSystem

end

-----------------------------------------------------------
-- GET ACTION SYSTEM
-----------------------------------------------------------

local function GetActionSystem()

    if not BAO.ActionSystem then

        Log(
            "ActionSystem unavailable"
        )

        return nil

    end

    return BAO.ActionSystem

end

-----------------------------------------------------------
-- GET CURRENT DECISION
-----------------------------------------------------------

local function ReadDecision()

    local decisionSystem =
        GetDecisionSystem()

    if not decisionSystem then
        return nil
    end

    if decisionSystem.GetCurrentDecision then

        return
            decisionSystem.GetCurrentDecision()

    end

    if decisionSystem.Get then

        return
            decisionSystem.Get()

    end

    return nil

end

-----------------------------------------------------------
-- GET ACTION TYPE
-----------------------------------------------------------

local function GetActionType(decision)

    if not decision then
        return nil
    end

    if not decision.ID then
        return nil
    end

    return DECISION_ACTIONS[
        decision.ID
    ]

end

-----------------------------------------------------------
-- CHECK CURRENT ACTION
-----------------------------------------------------------

local function RefreshCurrentAction()

    if not currentActionId then

        currentAction = nil

        return nil

    end

    local actionSystem =
        GetActionSystem()

    if not actionSystem then
        return currentAction
    end

    currentAction =
        actionSystem.GetAction(
            currentActionId
        )

    return currentAction

end

-----------------------------------------------------------
-- ACTION FINISHED?
-----------------------------------------------------------

local function IsActionFinished(action)

    if not action then
        return true
    end

    local state =
        action.state

    local actionSystem =
        GetActionSystem()

    if not actionSystem then
        return false
    end

    return
        state == actionSystem.State.COMPLETED
        or
        state == actionSystem.State.FAILED
        or
        state == actionSystem.State.INTERRUPTED
        or
        state == actionSystem.State.CANCELLED

end

-----------------------------------------------------------
-- RECORD ACTION RESULT
-----------------------------------------------------------

local function RecordActionResult(action)

    if not action or lastAction == action then
        return
    end

    lastAction = action

    lastActionResult = {

        ActionId = action.id,

        ActionType = action.type,

        State = action.state,

        Result = action.result,

        Reason = action.reason,

        Decision =
            action.metadata and action.metadata.decisionId or nil

    }

    if action.state == "completed" then

        statistics.actionsCompleted =
            statistics.actionsCompleted + 1

    elseif action.state == "failed" then

        statistics.actionsFailed =
            statistics.actionsFailed + 1

    elseif action.state == "interrupted" then

        statistics.actionsInterrupted =
            statistics.actionsInterrupted + 1

    end

    AddHistory({

        ActionId = action.id,

        ActionType = action.type,

        State = action.state,

        Result = action.result,

        Reason = action.reason,

        Decision =
            action.metadata and action.metadata.decisionId or nil

    })

end

-----------------------------------------------------------
-- CREATE ACTION FOR DECISION
-----------------------------------------------------------

local function CreateActionForDecision(decision)

    if not decision then

        Log(
            "Cannot create action: decision is nil"
        )

        return nil

    end

    local actionType =
        GetActionType(decision)

    if not actionType then

        Log(
            "No action mapping for decision: " ..
            tostring(decision.ID)
        )

        return nil

    end

    local actionSystem =
        GetActionSystem()

    if not actionSystem then
        return nil
    end

    -------------------------------------------------------
    -- The controller action is intentionally long-lived.
    --
    -- The ActionSystem currently represents execution time
    -- abstractly. Physical completion will later come from
    -- Navigation / Combat / Activity systems.
    --
    -- Therefore the controller keeps the action running
    -- until:
    --
    -- 1. a new decision replaces it
    -- 2. another system completes/fails it
    -- 3. the controller interrupts it
    -------------------------------------------------------

    local action =
        actionSystem.CreateAction(

            actionType,

            {

                priority =
                    decision.Priority or 0,

                duration = 0,
                externalCompletion = true,

                interruptible = true,

                metadata = {

                    controllerId =
                        controllerId,

                    decisionId =
                        decision.ID,

                    decisionScore =
                        decision.Score,

                    source =
                        "DecisionSystem"

                },

                onStart =
                    function(startedAction)

                        Log(
                            "Action execution started: " ..
                            tostring(startedAction.type)
                        )

                    end,

                onComplete =
                    function(
                        completedAction,
                        result,
                        resultData
                    )

                        Log(
                            "Action completed: " ..
                            tostring(
                                completedAction.type
                            )
                        )

                    end,

                onFail =
                    function(
                        failedAction,
                        result,
                        reason
                    )

                        Log(
                            "Action failed: " ..
                            tostring(
                                failedAction.type
                            ) ..
                            " reason=" ..
                            tostring(reason)
                        )

                    end,

                onInterrupt =
                    function(
                        interruptedAction,
                        reason
                    )

                        Log(
                            "Action interrupted: " ..
                            tostring(
                                interruptedAction.type
                            ) ..
                            " reason=" ..
                            tostring(reason)
                        )

                    end

            }

        )

    if actionType == "patrol" and patrolContext then
        action.metadata.navigation = patrolContext
    end
    return action

end

-----------------------------------------------------------
-- START ACTION FOR DECISION
-----------------------------------------------------------

local function StartActionForDecision(decision)
    local system = GetActionSystem()
    local executor = BAO.ActionExecutor
    if not system or not executor then return false end
    if executor.GetCurrentExecution() then
        return false, "executor_busy"
    end

    local action = CreateActionForDecision(decision)
    if not action then return false, "invalid_decision" end
    statistics.actionsCreated = statistics.actionsCreated + 1
    if not system.RegisterAction(action) then return false, "registration_failed" end
    if not system.StartAction(action.id) then
        RecordActionResult(action)
        return false, "action_start_failed"
    end

    local execution = executor.CreateExecution(action.id, action, {
        linkedAction = true,
        controllerId = controllerId,
        source = "AIController"
    })
    local started, reason = executor.StartExecution(execution)
    if not started then
        system.FailAction(action.id, system.Result.FAILED, reason or "execution_start_failed")
        RecordActionResult(action)
        return false, reason
    end

    currentActionId = action.id
    currentAction = action
    currentExecution = execution
    statistics.actionsStarted = statistics.actionsStarted + 1
    controllerState = AIController.State.EXECUTING
    Log("Controller started pair: action=" .. action.id
        .. " execution=" .. execution.id .. " decision=" .. tostring(decision.ID))
    return true
end

local function InterruptCurrentAction(reason)
    RefreshCurrentAction()
    if not currentAction then return false end
    local executor = BAO.ActionExecutor
    if not IsActionFinished(currentAction) then
        local interrupted
        if currentExecution and executor then
            interrupted = executor.InterruptExecution(currentExecution, reason or "controller_interrupt")
        else
            interrupted = BAO.ActionSystem.InterruptAction(currentAction.id, reason or "controller_interrupt")
        end
        if not interrupted then
            controllerState = AIController.State.EXECUTING
            return false
        end
    elseif currentExecution and executor then
        executor.SyncActionState(currentExecution)
        if not currentExecution._finished then return false end
    end
    RecordActionResult(currentAction)
    currentAction = nil
    currentActionId = nil
    currentExecution = nil
    return true
end

local function ApplyDecision(decision)
    if not decision or not GetActionType(decision) then return false end

    -- A consumed decision stays waiting until it changes or RestartCurrentDecision
    -- is explicitly called. This prevents retries/fake completions every tick.
    if currentDecision and currentDecision.ID == decision.ID then
        currentDecision = decision
        return true
    end

    if currentAction and not InterruptCurrentAction("decision_changed") then
        return true -- Keep the old decision and its non-interruptible pair.
    end
    if BAO.ActionExecutor.GetCurrentExecution() then
        controllerState = AIController.State.WAITING
        return true -- Retry when the executor becomes free, without allocating actions.
    end

    local oldDecision = currentDecision
    local started = StartActionForDecision(decision)
    previousDecision = oldDecision
    currentDecision = decision
    statistics.decisionsProcessed = statistics.decisionsProcessed + 1
    return started
end

local function UpdateCurrentAction()

    local trackedAction = currentAction or (currentExecution and currentExecution.action)
    if currentExecution and BAO.ActionExecutor then
        BAO.ActionExecutor.SyncActionState(currentExecution)
    end
    RefreshCurrentAction()

    if not currentAction then
        if trackedAction and currentExecution and currentExecution.reason == "linked_action_missing" then
            trackedAction.state = BAO.ActionSystem.State.FAILED
            trackedAction.result = BAO.ActionSystem.Result.FAILED
            trackedAction.reason = "linked_action_missing"
            trackedAction._finished = true
            RecordActionResult(trackedAction)
            currentActionId, currentExecution = nil, nil
        end
        return
    end

    -------------------------------------------------------
    -- Finished action
    -------------------------------------------------------

    if IsActionFinished(
        currentAction
    ) then

        -- A terminal Action must not release a still-owned path after cleanup failed.
        if currentExecution and not currentExecution._finished then return end

        RecordActionResult(
            currentAction
        )

        Log(
            "Controller detected finished action: " ..
            tostring(
                currentAction.type
            ) ..
            " state=" ..
            tostring(
                currentAction.state
            )
        )

        currentAction = nil
        currentActionId = nil
        currentExecution = nil

        controllerState =
            AIController.State.WAITING

        return

    end

    -------------------------------------------------------
    -- Still running
    -------------------------------------------------------

    controllerState =
        AIController.State.EXECUTING

end

-----------------------------------------------------------
-- MAIN UPDATE
-----------------------------------------------------------

function AIController.Update()

    if not initialized then

        AIController.Initialize()

        if not initialized then
            return false
        end

    end

    -------------------------------------------------------
    -- Update current action state first.
    -------------------------------------------------------

    UpdateCurrentAction()

    -------------------------------------------------------
    -- Read latest decision.
    -------------------------------------------------------

    controllerState =
        AIController.State.THINKING

    local decision =
        ReadDecision()

    if not decision then

        controllerState = currentAction and AIController.State.EXECUTING
            or AIController.State.WAITING

        return false

    end

    -------------------------------------------------------
    -- Apply decision.
    -------------------------------------------------------

    local success =
        ApplyDecision(
            decision
        )

    if not success then

        controllerState =
            AIController.State.ERROR

        return false

    end

    -------------------------------------------------------
    -- If we have an action, execution continues.
    -------------------------------------------------------

    if currentAction then

        controllerState =
            AIController.State.EXECUTING

    else

        controllerState =
            AIController.State.WAITING

    end

    return true

end

-----------------------------------------------------------
-- FORCE RE-EVALUATION
-----------------------------------------------------------

function AIController.Reevaluate()

    local decisionSystem =
        GetDecisionSystem()

    if not decisionSystem then
        return false
    end

    if decisionSystem.Recalculate then

        local result =
            decisionSystem.Recalculate()

        if not result then
            return false
        end

        AIController.Update()

        return true

    end

    return false

end

-----------------------------------------------------------
-- GET CONTROLLER STATE
-----------------------------------------------------------

function AIController.GetState()

    return controllerState

end

-----------------------------------------------------------
-- GET CONTROLLER ID
-----------------------------------------------------------

function AIController.GetControllerId()

    return controllerId

end

-----------------------------------------------------------
-- GET CURRENT DECISION
-----------------------------------------------------------

function AIController.GetCurrentDecision()

    return currentDecision

end

-----------------------------------------------------------
-- GET PREVIOUS DECISION
-----------------------------------------------------------

function AIController.GetPreviousDecision()

    return previousDecision

end

-----------------------------------------------------------
-- GET CURRENT ACTION
-----------------------------------------------------------

function AIController.GetCurrentAction()

    RefreshCurrentAction()

    return currentAction

end

-----------------------------------------------------------
-- GET CURRENT ACTION ID
-----------------------------------------------------------

-- Bind an existing non-player character for the next patrol decision.
-- No spawning, teleporting, or commandeering the player's input occurs here.
function AIController.SetPatrolTarget(character, x, y, z, options)
    if currentAction then return false, "controller_busy" end
    local navigation = BAO.NavigationSystem
    if not navigation or not navigation.IsValidCharacter(character)
        or not navigation.ValidateTarget(navigation.CreateLocationTarget(x, y, z)) then
        return false, "invalid_patrol_target"
    end
    local copiedOptions = {}
    for key, value in pairs(options or {}) do copiedOptions[key] = value end
    patrolContext = { character = character, x = x, y = y, z = z, options = copiedOptions }
    return true
end

function AIController.ClearPatrolTarget()
    if currentAction then return false end
    patrolContext = nil
    return true
end

function AIController.GetCurrentExecution()
    return currentExecution
end

-- Explicit retry after a completed/failed/stopped decision; never auto-loop.
function AIController.RestartCurrentDecision()
    UpdateCurrentAction()
    if currentAction or not currentDecision then return false end
    return StartActionForDecision(currentDecision)
end

function AIController.GetCurrentActionId()

    return currentActionId

end

-----------------------------------------------------------
-- GET LAST ACTION
-----------------------------------------------------------

function AIController.GetLastAction()

    return lastAction

end

-----------------------------------------------------------
-- GET LAST ACTION RESULT
-----------------------------------------------------------

function AIController.GetLastActionResult()

    return lastActionResult

end

-----------------------------------------------------------
-- GET ACTION HISTORY
-----------------------------------------------------------

function AIController.GetActionHistory()

    return actionHistory

end

-----------------------------------------------------------
-- GET STATISTICS
-----------------------------------------------------------

function AIController.GetStatistics()

    return statistics

end

-----------------------------------------------------------
-- GET STATUS
-----------------------------------------------------------

function AIController.GetStatus()

    RefreshCurrentAction()

    return {

        Initialized =
            initialized,

        ControllerId =
            controllerId,

        State =
            controllerState,

        CurrentDecision =
            currentDecision,

        PreviousDecision =
            previousDecision,

        CurrentAction =
            currentAction,

        CurrentActionId =
            currentActionId,
        CurrentExecution = currentExecution,

        LastAction =
            lastAction,

        LastActionResult =
            lastActionResult,

        Statistics =
            statistics

    }

end

-----------------------------------------------------------
-- STOP CURRENT ACTION
-----------------------------------------------------------

function AIController.StopCurrentAction(reason)

    local stopped =
        InterruptCurrentAction(
            reason or
                "controller_stop"
        )

    if stopped then

        controllerState =
            AIController.State.IDLE

    end

    return stopped

end

-----------------------------------------------------------
-- RESET CONTROLLER
-----------------------------------------------------------

function AIController.Reset()

    -------------------------------------------------------
    -- Interrupt active action.
    -------------------------------------------------------

    if currentAction then

        if not InterruptCurrentAction("controller_reset") then
            return false
        end

    end

    -------------------------------------------------------
    -- Reset state.
    -------------------------------------------------------

    currentDecision = nil

    previousDecision = nil

    currentAction = nil

    currentActionId = nil
    currentExecution = nil
    patrolContext = nil

    lastAction = nil

    lastActionResult = nil

    actionHistory = {}

    statistics = {

        decisionsProcessed = 0,

        actionsCreated = 0,

        actionsStarted = 0,

        actionsCompleted = 0,

        actionsFailed = 0,

        actionsInterrupted = 0

    }

    controllerState =
        AIController.State.IDLE

    Log(
        "Controller reset"
    )

    return true

end

-----------------------------------------------------------
-- INITIALIZE
-----------------------------------------------------------

-- Synchronous harness scope. Public dependencies are isolated by the harness;
-- private controller state is restored even if an assertion/callback throws.
function AIController.WithIsolatedState(callback)
    local saved = {
        initialized = initialized, attempts = attempts, state = controllerState,
        decision = currentDecision, previous = previousDecision,
        action = currentAction, actionId = currentActionId, execution = currentExecution,
        last = lastAction, result = lastActionResult, history = actionHistory,
        statistics = statistics, patrolContext = patrolContext
    }
    initialized = false
    attempts = 0
    controllerState = AIController.State.IDLE
    currentDecision, previousDecision = nil, nil
    currentAction, currentActionId, currentExecution = nil, nil, nil
    patrolContext = nil
    lastAction, lastActionResult = nil, nil
    actionHistory = {}
    statistics = {
        decisionsProcessed = 0, actionsCreated = 0, actionsStarted = 0,
        actionsCompleted = 0, actionsFailed = 0, actionsInterrupted = 0
    }
    local ok, result = pcall(callback)
    initialized, attempts, controllerState = saved.initialized, saved.attempts, saved.state
    currentDecision, previousDecision = saved.decision, saved.previous
    currentAction, currentActionId, currentExecution = saved.action, saved.actionId, saved.execution
    lastAction, lastActionResult, actionHistory = saved.last, saved.result, saved.history
    statistics = saved.statistics
    patrolContext = saved.patrolContext
    return ok, result
end

function AIController.Initialize()

    if initialized then
        return true
    end

    attempts =
        attempts + 1

    Log(
        "Initialize attempt #" ..
        tostring(attempts)
    )

    -------------------------------------------------------
    -- Check dependencies.
    -------------------------------------------------------

    local decisionSystem =
        GetDecisionSystem()

    if not decisionSystem then

        Log(
            "Waiting for DecisionSystem..."
        )

        return false

    end

    local actionSystem =
        GetActionSystem()

    if not actionSystem then

        Log(
            "Waiting for ActionSystem..."
        )

        return false

    end

    -------------------------------------------------------
    -- Initialize ActionSystem.
    -------------------------------------------------------

    local executor = BAO.ActionExecutor
    if not executor or not executor.Initialize() then return false end

    if actionSystem.Initialize then

        local initializedActionSystem =
            actionSystem.Initialize()

        if not initializedActionSystem then

            Log(
                "ActionSystem initialization failed"
            )

            return false

        end

    end

    -------------------------------------------------------
    -- We do NOT force DecisionSystem initialization here.
    --
    -- DecisionSystem owns its own initialization and
    -- WorldContext dependency.
    -------------------------------------------------------

    initialized = true

    controllerState =
        AIController.State.IDLE

    Log(
        "AI Controller initialized " ..
        AIController.Version
    )

    return true

end

-----------------------------------------------------------
-- GAME START
-----------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(

        function()

            Log(
                "OnGameStart"
            )

            AIController.Initialize()

        end

    )

end

-----------------------------------------------------------
-- TICK
-----------------------------------------------------------

if Events and Events.OnTick then

    Events.OnTick.Add(

        function()

            AIController.Update()

        end

    )

end

-----------------------------------------------------------
-- EXPORT
-----------------------------------------------------------

BAO.AIController =
    AIController

-----------------------------------------------------------
-- MODULE LOADED
-----------------------------------------------------------

Log(
    "AI Controller " ..
    AIController.Version ..
    " module loaded"
)
