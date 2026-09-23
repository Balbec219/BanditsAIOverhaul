-----------------------------------------------------------
-- BAO_ActionSystem.lua
-- BanditsAIOverhaul
--
-- Action System V1.0
--
-- Architecture:
-- Decision -> Action -> Result
--
-- This version provides the universal action engine.
-- It does not directly control physical NPC movement
-- or animations yet.
-----------------------------------------------------------

if not BAO then
    BAO = {}
end

local ActionSystem = {}

-----------------------------------------------------------
-- VERSION
-----------------------------------------------------------

ActionSystem.Version = "V1.0"

-----------------------------------------------------------
-- ACTION STATES
-----------------------------------------------------------

ActionSystem.State = {
    PENDING = "pending",
    RUNNING = "running",
    COMPLETED = "completed",
    FAILED = "failed",
    INTERRUPTED = "interrupted",
    CANCELLED = "cancelled"
}

-----------------------------------------------------------
-- ACTION RESULTS
-----------------------------------------------------------

ActionSystem.Result = {
    SUCCESS = "success",
    FAILED = "failed",
    BLOCKED = "blocked",
    INTERRUPTED = "interrupted",
    CANCELLED = "cancelled"
}

-----------------------------------------------------------
-- INTERNAL RUNTIME STATE
-----------------------------------------------------------

ActionSystem.initialized = false
ActionSystem.actions = {}
ActionSystem.nextActionId = 1
ActionSystem.lastAction = nil
ActionSystem.lastResult = nil

-----------------------------------------------------------
-- LOGGING
-----------------------------------------------------------

local function Log(message)
    print("[BAO ActionSystem V1.0] " .. tostring(message))
end

-----------------------------------------------------------
-- UTILITY
-----------------------------------------------------------

local function GenerateActionId()
    local id = "bao_action_" .. tostring(ActionSystem.nextActionId)

    ActionSystem.nextActionId =
        ActionSystem.nextActionId + 1

    return id
end

-----------------------------------------------------------
-- ACTION OBJECT
-----------------------------------------------------------

function ActionSystem.CreateAction(actionType, data)

    data = data or {}

    local action = {}

    -------------------------------------------------------
    -- IDENTITY
    -------------------------------------------------------

    action.id = data.id or GenerateActionId()
    action.type = actionType or data.type or "unknown"

    -------------------------------------------------------
    -- STATE
    -------------------------------------------------------

    action.state = ActionSystem.State.PENDING

    -------------------------------------------------------
    -- PRIORITY
    -------------------------------------------------------

    action.priority = data.priority or 0

    -------------------------------------------------------
    -- TARGET
    -------------------------------------------------------

    action.target = data.target or nil
    action.targetId = data.targetId or nil

    -------------------------------------------------------
    -- LOCATION
    -------------------------------------------------------

    action.location = data.location or nil

    -------------------------------------------------------
    -- TIMING
    -------------------------------------------------------

    action.duration = data.duration or 0
    action.elapsed = 0

    -------------------------------------------------------
    -- CONTROL
    -------------------------------------------------------

    if data.interruptible == nil then
        action.interruptible = true
    else
        action.interruptible = data.interruptible
    end

    -------------------------------------------------------
    -- REQUIREMENTS
    -------------------------------------------------------

    action.requirements = data.requirements or {}

    -------------------------------------------------------
    -- RESULT
    -------------------------------------------------------

    action.result = nil
    action.resultData = nil

    -------------------------------------------------------
    -- FAILURE / INTERRUPTION REASON
    -------------------------------------------------------

    action.reason = nil

    -------------------------------------------------------
    -- CALLBACKS
    -------------------------------------------------------

    action.onStart = data.onStart or nil
    action.onUpdate = data.onUpdate or nil
    action.onInterrupt = data.onInterrupt or nil
    action.onComplete = data.onComplete or nil
    action.onFail = data.onFail or nil
    action.onCancel = data.onCancel or nil

    -------------------------------------------------------
    -- METADATA
    -------------------------------------------------------

    action.metadata = data.metadata or {}

    -------------------------------------------------------
    -- INTERNAL FLAGS
    -------------------------------------------------------

    action._started = false
    action._finished = false

    return action
end

-----------------------------------------------------------
-- REGISTER ACTION
-----------------------------------------------------------

function ActionSystem.RegisterAction(action)

    if not action then
        Log("RegisterAction failed: action is nil")
        return false
    end

    if not action.id then
        Log("RegisterAction failed: action has no ID")
        return false
    end

    ActionSystem.actions[action.id] = action

    ActionSystem.lastAction = action

    Log(
        "Action registered: " ..
        tostring(action.id) ..
        " [" ..
        tostring(action.type) ..
        "]"
    )

    return true
end

-----------------------------------------------------------
-- GET ACTION
-----------------------------------------------------------

function ActionSystem.GetAction(actionId)

    if not actionId then
        return nil
    end

    return ActionSystem.actions[actionId]
end

-----------------------------------------------------------
-- CHECK REQUIREMENTS
-----------------------------------------------------------

function ActionSystem.CheckRequirements(action)

    if not action then
        return false, "action_nil"
    end

    if not action.requirements then
        return true, nil
    end

    -------------------------------------------------------
    -- Requirements may later contain:
    --
    -- hasWeapon
    -- hasFood
    -- hasTools
    -- targetExists
    -- sufficientHealth
    -- sufficientEnergy
    -- etc.
    --
    -- V1.0 only supports boolean/function requirements.
    -------------------------------------------------------

    for key, requirement in pairs(action.requirements) do

        if type(requirement) == "boolean" then

            if requirement == false then
                return false, "requirement_failed:" .. tostring(key)
            end

        elseif type(requirement) == "function" then

            local success, result, reason =
                pcall(requirement, action)

            if not success then

                return false,
                    "requirement_error:" .. tostring(key)

            end

            if result == false then

                return false,
                    reason or
                    ("requirement_failed:" .. tostring(key))

            end
        end
    end

    return true, nil
end

-----------------------------------------------------------
-- START ACTION
-----------------------------------------------------------

function ActionSystem.StartAction(actionId)

    local action = ActionSystem.GetAction(actionId)

    if not action then
        Log("StartAction failed: action not found")
        return false
    end

    -------------------------------------------------------
    -- Only pending actions can start.
    -------------------------------------------------------

    if action.state ~= ActionSystem.State.PENDING then

        Log(
            "StartAction blocked: action " ..
            tostring(action.id) ..
            " is already " ..
            tostring(action.state)
        )

        return false
    end

    -------------------------------------------------------
    -- Requirements
    -------------------------------------------------------

    local requirementsMet, reason =
        ActionSystem.CheckRequirements(action)

    if not requirementsMet then

        action.state = ActionSystem.State.FAILED
        action.result = ActionSystem.Result.BLOCKED
        action.reason = reason

        ActionSystem.lastAction = action
        ActionSystem.lastResult = action.result

        Log(
            "Action blocked: " ..
            tostring(action.id) ..
            " reason=" ..
            tostring(reason)
        )

        if action.onFail then
            pcall(action.onFail, action, reason)
        end

        return false
    end

    -------------------------------------------------------
    -- Start
    -------------------------------------------------------

    action.state = ActionSystem.State.RUNNING
    action.elapsed = 0
    action._started = true

    ActionSystem.lastAction = action

    Log(
        "Action started: " ..
        tostring(action.id) ..
        " [" ..
        tostring(action.type) ..
        "]"
    )

    -------------------------------------------------------
    -- Callback
    -------------------------------------------------------

    if action.onStart then
        local success, err =
            pcall(action.onStart, action)

        if not success then

            Log(
                "onStart error for " ..
                tostring(action.id) ..
                ": " ..
                tostring(err)
            )
        end
    end

    -------------------------------------------------------
    -- Instant action
    -------------------------------------------------------

    if action.duration <= 0 then
        ActionSystem.CompleteAction(
            action.id,
            ActionSystem.Result.SUCCESS
        )
    end

    return true
end

-----------------------------------------------------------
-- UPDATE ACTION
-----------------------------------------------------------

function ActionSystem.UpdateAction(actionId, deltaTime)

    local action = ActionSystem.GetAction(actionId)

    if not action then
        return false
    end

    if action.state ~= ActionSystem.State.RUNNING then
        return false
    end

    deltaTime = tonumber(deltaTime) or 0

    if deltaTime < 0 then
        deltaTime = 0
    end

    -------------------------------------------------------
    -- Update elapsed time
    -------------------------------------------------------

    action.elapsed =
        action.elapsed + deltaTime

    -------------------------------------------------------
    -- Callback
    -------------------------------------------------------

    if action.onUpdate then

        local success, result, reason =
            pcall(
                action.onUpdate,
                action,
                deltaTime
            )

        if not success then

            Log(
                "onUpdate error for " ..
                tostring(action.id) ..
                ": " ..
                tostring(result)
            )

            ActionSystem.FailAction(
                action.id,
                ActionSystem.Result.FAILED,
                "update_callback_error"
            )

            return false
        end

        ---------------------------------------------------
        -- Callback may explicitly complete the action.
        ---------------------------------------------------

        if result == "complete" then

            ActionSystem.CompleteAction(
                action.id,
                ActionSystem.Result.SUCCESS
            )

            return true

        elseif result == "fail" then

            ActionSystem.FailAction(
                action.id,
                ActionSystem.Result.FAILED,
                reason
            )

            return false
        end
    end

    -------------------------------------------------------
    -- Duration completed
    -------------------------------------------------------

    if action.duration > 0
        and action.elapsed >= action.duration then

        ActionSystem.CompleteAction(
            action.id,
            ActionSystem.Result.SUCCESS
        )
    end

    return true
end

-----------------------------------------------------------
-- COMPLETE ACTION
-----------------------------------------------------------

function ActionSystem.CompleteAction(actionId, result, resultData)

    local action = ActionSystem.GetAction(actionId)

    if not action then
        Log("CompleteAction failed: action not found")
        return false
    end

    if action.state ~= ActionSystem.State.RUNNING then

        Log(
            "CompleteAction blocked: action " ..
            tostring(action.id) ..
            " is not running"
        )

        return false
    end

    action.state = ActionSystem.State.COMPLETED

    action.result =
        result or ActionSystem.Result.SUCCESS

    action.resultData = resultData or nil

    action._finished = true

    ActionSystem.lastAction = action
    ActionSystem.lastResult = action.result

    Log(
        "Action completed: " ..
        tostring(action.id) ..
        " result=" ..
        tostring(action.result)
    )

    -------------------------------------------------------
    -- Callback
    -------------------------------------------------------

    if action.onComplete then

        local success, err =
            pcall(
                action.onComplete,
                action,
                action.result,
                action.resultData
            )

        if not success then

            Log(
                "onComplete error for " ..
                tostring(action.id) ..
                ": " ..
                tostring(err)
            )
        end
    end

    return true
end

-----------------------------------------------------------
-- FAIL ACTION
-----------------------------------------------------------

function ActionSystem.FailAction(
    actionId,
    result,
    reason,
    resultData
)

    local action = ActionSystem.GetAction(actionId)

    if not action then
        Log("FailAction failed: action not found")
        return false
    end

    if action.state ~= ActionSystem.State.RUNNING
        and action.state ~= ActionSystem.State.PENDING then

        Log(
            "FailAction blocked: action " ..
            tostring(action.id) ..
            " is " ..
            tostring(action.state)
        )

        return false
    end

    action.state = ActionSystem.State.FAILED

    action.result =
        result or ActionSystem.Result.FAILED

    action.reason = reason
    action.resultData = resultData or nil

    action._finished = true

    ActionSystem.lastAction = action
    ActionSystem.lastResult = action.result

    Log(
        "Action failed: " ..
        tostring(action.id) ..
        " result=" ..
        tostring(action.result) ..
        " reason=" ..
        tostring(reason)
    )

    if action.onFail then

        local success, err =
            pcall(
                action.onFail,
                action,
                action.result,
                action.reason,
                action.resultData
            )

        if not success then

            Log(
                "onFail error for " ..
                tostring(action.id) ..
                ": " ..
                tostring(err)
            )
        end
    end

    return true
end

-----------------------------------------------------------
-- INTERRUPT ACTION
-----------------------------------------------------------

function ActionSystem.InterruptAction(actionId, reason)

    local action = ActionSystem.GetAction(actionId)

    if not action then
        Log("InterruptAction failed: action not found")
        return false
    end

    if action.state ~= ActionSystem.State.RUNNING then

        Log(
            "InterruptAction blocked: action " ..
            tostring(action.id) ..
            " is not running"
        )

        return false
    end

    if not action.interruptible then

        Log(
            "InterruptAction blocked: action " ..
            tostring(action.id) ..
            " is not interruptible"
        )

        return false
    end

    action.state = ActionSystem.State.INTERRUPTED

    action.result =
        ActionSystem.Result.INTERRUPTED

    action.reason = reason or "interrupted"

    action._finished = true

    ActionSystem.lastAction = action
    ActionSystem.lastResult = action.result

    Log(
        "Action interrupted: " ..
        tostring(action.id) ..
        " reason=" ..
        tostring(action.reason)
    )

    if action.onInterrupt then

        local success, err =
            pcall(
                action.onInterrupt,
                action,
                action.reason
            )

        if not success then

            Log(
                "onInterrupt error for " ..
                tostring(action.id) ..
                ": " ..
                tostring(err)
            )
        end
    end

    return true
end

-----------------------------------------------------------
-- CANCEL ACTION
-----------------------------------------------------------

function ActionSystem.CancelAction(actionId, reason)

    local action = ActionSystem.GetAction(actionId)

    if not action then
        Log("CancelAction failed: action not found")
        return false
    end

    if action.state ~= ActionSystem.State.PENDING
        and action.state ~= ActionSystem.State.RUNNING then

        Log(
            "CancelAction blocked: action " ..
            tostring(action.id) ..
            " cannot be cancelled"
        )

        return false
    end

    action.state = ActionSystem.State.CANCELLED

    action.result =
        ActionSystem.Result.CANCELLED

    action.reason = reason or "cancelled"

    action._finished = true

    ActionSystem.lastAction = action
    ActionSystem.lastResult = action.result

    Log(
        "Action cancelled: " ..
        tostring(action.id) ..
        " reason=" ..
        tostring(action.reason)
    )

    if action.onCancel then

        local success, err =
            pcall(
                action.onCancel,
                action,
                action.reason
            )

        if not success then

            Log(
                "onCancel error for " ..
                tostring(action.id) ..
                ": " ..
                tostring(err)
            )
        end
    end

    return true
end

-----------------------------------------------------------
-- UPDATE ALL RUNNING ACTIONS
-----------------------------------------------------------

function ActionSystem.Update(deltaTime)

    for actionId, action in pairs(ActionSystem.actions) do

        if action.state == ActionSystem.State.RUNNING then

            ActionSystem.UpdateAction(
                actionId,
                deltaTime
            )
        end
    end
end

-----------------------------------------------------------
-- REMOVE ACTION
-----------------------------------------------------------

function ActionSystem.RemoveAction(actionId)

    if not actionId then
        return false
    end

    if not ActionSystem.actions[actionId] then
        return false
    end

    ActionSystem.actions[actionId] = nil

    return true
end

-----------------------------------------------------------
-- CLEAR ALL ACTIONS
-----------------------------------------------------------

function ActionSystem.Clear()

    ActionSystem.actions = {}
    ActionSystem.nextActionId = 1
    ActionSystem.lastAction = nil
    ActionSystem.lastResult = nil

    Log("All actions cleared")

    return true
end

-----------------------------------------------------------
-- GET CURRENT ACTIONS
-----------------------------------------------------------

function ActionSystem.GetActions()

    return ActionSystem.actions
end

-----------------------------------------------------------
-- GET LAST ACTION
-----------------------------------------------------------

function ActionSystem.GetLastAction()

    return ActionSystem.lastAction
end

-----------------------------------------------------------
-- GET LAST RESULT
-----------------------------------------------------------

function ActionSystem.GetLastResult()

    return ActionSystem.lastResult
end

-----------------------------------------------------------
-- INITIALIZE
-----------------------------------------------------------

function ActionSystem.Initialize()

    if ActionSystem.initialized then

        Log("Already initialized")

        return true
    end

    ActionSystem.initialized = true

    Log(
        "Initialized Action System " ..
        ActionSystem.Version
    )

    return true
end

-----------------------------------------------------------
-- EXPORT
-----------------------------------------------------------

BAO.ActionSystem = ActionSystem

Log(
    "BAO_ActionSystem.lua loaded - " ..
    ActionSystem.Version
)