-----------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_AIController.lua
--
-- AI Controller V1.0
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
-- V1.0:
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

AIController.Version = "V1.0"

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
-- V1.0 has one global controller.
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

    if not action then
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
            currentDecision
                and currentDecision.ID
                or nil

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
            currentDecision
                and currentDecision.ID
                or nil

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

                duration = 3600,

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

    return action

end

-----------------------------------------------------------
-- START ACTION FOR DECISION
-----------------------------------------------------------

local function StartActionForDecision(decision)

    if not decision then
        return false
    end

    local actionSystem =
        GetActionSystem()

    if not actionSystem then
        return false
    end

    local action =
        CreateActionForDecision(
            decision
        )

    if not action then

        controllerState =
            AIController.State.ERROR

        return false

    end

    statistics.actionsCreated =
        statistics.actionsCreated + 1

    local registered =
        actionSystem.RegisterAction(
            action
        )

    if not registered then

        Log(
            "Failed to register action: " ..
            tostring(action.id)
        )

        controllerState =
            AIController.State.ERROR

        return false

    end

    local started =
        actionSystem.StartAction(
            action.id
        )

    if not started then

        Log(
            "Failed to start action: " ..
            tostring(action.id)
        )

        controllerState =
            AIController.State.ERROR

        return false

    end

    currentActionId =
        action.id

    currentAction =
        action

    statistics.actionsStarted =
        statistics.actionsStarted + 1

    controllerState =
        AIController.State.EXECUTING

    Log(
        "Controller started action: " ..
        tostring(action.type) ..
        " for decision=" ..
        tostring(decision.ID)
    )

    return true

end

-----------------------------------------------------------
-- INTERRUPT CURRENT ACTION
-----------------------------------------------------------

local function InterruptCurrentAction(reason)

    RefreshCurrentAction()

    if not currentAction then
        return false
    end

    if IsActionFinished(currentAction) then

        RecordActionResult(
            currentAction
        )

        return false

    end

    local actionSystem =
        GetActionSystem()

    if not actionSystem then
        return false
    end

    controllerState =
        AIController.State.INTERRUPTING

    local interrupted =
        actionSystem.InterruptAction(

            currentAction.id,

            reason or
                "controller_interrupt"

        )

    if interrupted then

        RefreshCurrentAction()

        RecordActionResult(
            currentAction
        )

        Log(
            "Current action interrupted: " ..
            tostring(
                currentAction.id
            )
        )

        currentAction = nil
        currentActionId = nil

        return true

    end

    return false

end

-----------------------------------------------------------
-- APPLY NEW DECISION
-----------------------------------------------------------

local function ApplyDecision(decision)

    if not decision then
        return false
    end

    local newDecisionId =
        decision.ID

    if not newDecisionId then

        Log(
            "Decision has no ID"
        )

        return false

    end

    -------------------------------------------------------
    -- First decision
    -------------------------------------------------------

    if currentDecision == nil then

        previousDecision = nil

        currentDecision =
            decision

        statistics.decisionsProcessed =
            statistics.decisionsProcessed + 1

        Log(
            "Controller received initial decision: " ..
            tostring(newDecisionId)
        )

        return
            StartActionForDecision(
                decision
            )

    end

    -------------------------------------------------------
    -- Same decision
    -------------------------------------------------------

    if currentDecision.ID ==
        newDecisionId then

        currentDecision =
            decision

        return true

    end

    -------------------------------------------------------
    -- Decision changed
    -------------------------------------------------------

    previousDecision =
        currentDecision

    currentDecision =
        decision

    statistics.decisionsProcessed =
        statistics.decisionsProcessed + 1

    Log(
        "Controller decision changed: " ..
        tostring(previousDecision.ID) ..
        " -> " ..
        tostring(currentDecision.ID)
    )

    -------------------------------------------------------
    -- Old action is no longer valid.
    -------------------------------------------------------

    InterruptCurrentAction(
        "decision_changed"
    )

    -------------------------------------------------------
    -- Start new action.
    -------------------------------------------------------

    return
        StartActionForDecision(
            currentDecision
        )

end

-----------------------------------------------------------
-- CHECK ACTION STATE
-----------------------------------------------------------

local function UpdateCurrentAction()

    RefreshCurrentAction()

    if not currentAction then
        return
    end

    -------------------------------------------------------
    -- Finished action
    -------------------------------------------------------

    if IsActionFinished(
        currentAction
    ) then

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

        Log(
            "No decision available"
        )

        controllerState =
            AIController.State.WAITING

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

        InterruptCurrentAction(
            "controller_reset"
        )

    end

    -------------------------------------------------------
    -- Reset state.
    -------------------------------------------------------

    currentDecision = nil

    previousDecision = nil

    currentAction = nil

    currentActionId = nil

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