-- ============================================================
-- BanditsAIOverhaul
-- BAO Routine System V1.0
-- ============================================================
--
-- Purpose:
--   Provides a flexible daily routine/schedule system for NPCs.
--
-- Architecture:
--
--   Routine
--      ↓
--   Scheduled Activity
--      ↓
--   Current Activity
--      ↓
--   Decision / Action layer
--
-- Routine System does NOT directly control:
--   - movement
--   - animation
--   - combat
--   - inventory
--
-- Those systems will consume routine activities later.
--
-- Example:
--
--   07:00 - wake_up
--   07:30 - eat
--   08:00 - work
--   12:00 - eat
--   13:00 - work
--   18:00 - social
--   20:00 - rest
--   23:00 - sleep
--
-- ============================================================

local RoutineSystem = {}

local MODULE_NAME = "BAO_RoutineSystem"
local VERSION = "V1.0"

local initialized = false
local initializeAttempts = 0

local routines = {}
local currentActivities = {}

local nextRoutineId = 1

-- ============================================================
-- CONSTANTS
-- ============================================================

RoutineSystem.ACTIVITY_STATE = {
    PENDING = "pending",
    ACTIVE = "active",
    COMPLETED = "completed",
    INTERRUPTED = "interrupted",
    CANCELLED = "cancelled",
    FAILED = "failed"
}

RoutineSystem.PRIORITY = {
    LOW = 20,
    NORMAL = 50,
    HIGH = 80,
    CRITICAL = 100
}

-- ============================================================
-- LOGGING
-- ============================================================

local function Log(message)
    print("[BAO][" .. MODULE_NAME .. "] " .. tostring(message))
end

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

local function GenerateRoutineId()
    local id = "bao_routine_" .. tostring(nextRoutineId)
    nextRoutineId = nextRoutineId + 1
    return id
end

local function GenerateActivityId(routineId)
    local routine = routines[routineId]

    if not routine then
        return nil
    end

    routine.nextActivityId = routine.nextActivityId + 1

    return routineId .. "_activity_" .. tostring(routine.nextActivityId)
end

local function NormalizeNumber(value, defaultValue)
    if type(value) ~= "number" then
        return defaultValue
    end

    return value
end

local function NormalizeString(value, defaultValue)
    if type(value) ~= "string" or value == "" then
        return defaultValue
    end

    return value
end

-- ============================================================
-- ROUTINE CREATION
-- ============================================================

function RoutineSystem.CreateRoutine(ownerId, name)
    local routineId = GenerateRoutineId()

    local routine = {
        id = routineId,

        ownerId = ownerId,

        name = NormalizeString(name, "Default Routine"),

        enabled = true,

        activities = {},

        currentActivityId = nil,

        nextActivityId = 0,

        lastUpdatedHour = nil,

        lastUpdatedMinute = nil,

        metadata = {}
    }

    routines[routineId] = routine

    Log(
        "Routine created: "
        .. routineId
        .. " ["
        .. routine.name
        .. "]"
    )

    return routine
end

-- ============================================================
-- ROUTINE REGISTRATION
-- ============================================================

function RoutineSystem.RegisterRoutine(routine)
    if not routine then
        Log("RegisterRoutine failed: routine is nil")
        return false
    end

    if not routine.id then
        Log("RegisterRoutine failed: routine has no id")
        return false
    end

    routines[routine.id] = routine

    if routine.nextActivityId == nil then
        routine.nextActivityId = 0
    end

    if routine.activities == nil then
        routine.activities = {}
    end

    if routine.enabled == nil then
        routine.enabled = true
    end

    Log("Routine registered: " .. tostring(routine.id))

    return true
end

-- ============================================================
-- ROUTINE ACCESS
-- ============================================================

function RoutineSystem.GetRoutine(routineId)
    return routines[routineId]
end

function RoutineSystem.GetRoutines()
    return routines
end

-- ============================================================
-- ACTIVITY CREATION
-- ============================================================

function RoutineSystem.AddActivity(
    routineId,
    activityType,
    startHour,
    startMinute,
    durationMinutes,
    priority,
    options
)
    local routine = routines[routineId]

    if not routine then
        Log("AddActivity failed: routine not found: " .. tostring(routineId))
        return nil
    end

    local activityId = GenerateActivityId(routineId)

    if not activityId then
        return nil
    end

    local activity = {
        id = activityId,

        routineId = routineId,

        type = NormalizeString(activityType, "idle"),

        startHour = NormalizeNumber(startHour, 0),

        startMinute = NormalizeNumber(startMinute, 0),

        durationMinutes = NormalizeNumber(durationMinutes, 60),

        priority = NormalizeNumber(priority, RoutineSystem.PRIORITY.NORMAL),

        state = RoutineSystem.ACTIVITY_STATE.PENDING,

        interruptible = true,

        required = false,

        repeatable = true,

        condition = nil,

        onStart = nil,

        onComplete = nil,

        onInterrupt = nil,

        onFail = nil,

        metadata = {}
    }

    if type(options) == "table" then

        if options.interruptible ~= nil then
            activity.interruptible = options.interruptible
        end

        if options.required ~= nil then
            activity.required = options.required
        end

        if options.repeatable ~= nil then
            activity.repeatable = options.repeatable
        end

        if type(options.condition) == "function" then
            activity.condition = options.condition
        end

        if type(options.onStart) == "function" then
            activity.onStart = options.onStart
        end

        if type(options.onComplete) == "function" then
            activity.onComplete = options.onComplete
        end

        if type(options.onInterrupt) == "function" then
            activity.onInterrupt = options.onInterrupt
        end

        if type(options.onFail) == "function" then
            activity.onFail = options.onFail
        end

        if type(options.metadata) == "table" then
            activity.metadata = options.metadata
        end
    end

    table.insert(routine.activities, activity)

    Log(
        "Activity added: "
        .. activity.id
        .. " ["
        .. activity.type
        .. "] "
        .. string.format(
            "%02d:%02d",
            activity.startHour,
            activity.startMinute
        )
    )

    return activity
end

-- ============================================================
-- ACTIVITY ACCESS
-- ============================================================

function RoutineSystem.GetActivity(routineId, activityId)
    local routine = routines[routineId]

    if not routine then
        return nil
    end

    for _, activity in ipairs(routine.activities) do
        if activity.id == activityId then
            return activity
        end
    end

    return nil
end

function RoutineSystem.GetActivities(routineId)
    local routine = routines[routineId]

    if not routine then
        return {}
    end

    return routine.activities
end

-- ============================================================
-- TIME HELPERS
-- ============================================================

local function GetTimeInMinutes(hour, minute)
    return (hour * 60) + minute
end

local function IsActivityInTime(activity, currentMinutes)
    local startMinutes = GetTimeInMinutes(
        activity.startHour,
        activity.startMinute
    )

    local endMinutes = startMinutes + activity.durationMinutes

    if endMinutes < 1440 then
        return currentMinutes >= startMinutes
            and currentMinutes < endMinutes
    end

    -- Handles activities crossing midnight.

    local wrappedEnd = endMinutes - 1440

    return currentMinutes >= startMinutes
        or currentMinutes < wrappedEnd
end

-- ============================================================
-- CONDITION CHECK
-- ============================================================

function RoutineSystem.CheckActivityCondition(activity, context)
    if not activity then
        return false
    end

    if type(activity.condition) ~= "function" then
        return true
    end

    local success, result = pcall(
        activity.condition,
        activity,
        context
    )

    if not success then
        Log(
            "Activity condition error: "
            .. tostring(result)
        )

        return false
    end

    return result == true
end

-- ============================================================
-- ACTIVITY SELECTION
-- ============================================================

function RoutineSystem.FindCurrentActivity(
    routineId,
    hour,
    minute,
    context
)
    local routine = routines[routineId]

    if not routine or not routine.enabled then
        return nil
    end

    local currentMinutes = GetTimeInMinutes(hour, minute)

    local selected = nil

    for _, activity in ipairs(routine.activities) do

        if IsActivityInTime(activity, currentMinutes) then

            if RoutineSystem.CheckActivityCondition(
                activity,
                context
            ) then

                if not selected then
                    selected = activity

                elseif activity.priority > selected.priority then
                    selected = activity

                elseif activity.priority == selected.priority then

                    local selectedStart =
                        GetTimeInMinutes(
                            selected.startHour,
                            selected.startMinute
                        )

                    local activityStart =
                        GetTimeInMinutes(
                            activity.startHour,
                            activity.startMinute
                        )

                    if activityStart > selectedStart then
                        selected = activity
                    end
                end
            end
        end
    end

    return selected
end

-- ============================================================
-- START ACTIVITY
-- ============================================================

function RoutineSystem.StartActivity(
    routineId,
    activity,
    context
)
    local routine = routines[routineId]

    if not routine then
        return false
    end

    if not activity then
        return false
    end

    activity.state =
        RoutineSystem.ACTIVITY_STATE.ACTIVE

    activity.startedAt = {
        hour = context and context.hour or nil,
        minute = context and context.minute or nil
    }

    routine.currentActivityId = activity.id

    currentActivities[routine.ownerId or routineId] =
        activity

    if type(activity.onStart) == "function" then
        local success, result = pcall(
            activity.onStart,
            activity,
            context
        )

        if not success then
            Log(
                "Activity onStart error: "
                .. tostring(result)
            )
        end
    end

    Log(
        "Activity started: "
        .. activity.id
        .. " ["
        .. activity.type
        .. "]"
    )

    return true
end

-- ============================================================
-- COMPLETE ACTIVITY
-- ============================================================

function RoutineSystem.CompleteActivity(
    routineId,
    activityId,
    context
)
    local routine = routines[routineId]

    if not routine then
        return false
    end

    local activity =
        RoutineSystem.GetActivity(
            routineId,
            activityId
        )

    if not activity then
        return false
    end

    activity.state =
        RoutineSystem.ACTIVITY_STATE.COMPLETED

    activity.completedAt = {
        hour = context and context.hour or nil,
        minute = context and context.minute or nil
    }

    if routine.currentActivityId == activityId then
        routine.currentActivityId = nil
    end

    if currentActivities[routine.ownerId or routineId] == activity then
        currentActivities[routine.ownerId or routineId] = nil
    end

    if type(activity.onComplete) == "function" then
        local success, result = pcall(
            activity.onComplete,
            activity,
            context
        )

        if not success then
            Log(
                "Activity onComplete error: "
                .. tostring(result)
            )
        end
    end

    Log(
        "Activity completed: "
        .. activity.id
        .. " ["
        .. activity.type
        .. "]"
    )

    return true
end

-- ============================================================
-- INTERRUPT ACTIVITY
-- ============================================================

function RoutineSystem.InterruptActivity(
    routineId,
    activityId,
    reason,
    context
)
    local routine = routines[routineId]

    if not routine then
        return false
    end

    local activity =
        RoutineSystem.GetActivity(
            routineId,
            activityId
        )

    if not activity then
        return false
    end

    if not activity.interruptible then
        Log(
            "Activity cannot be interrupted: "
            .. activity.id
        )

        return false
    end

    activity.state =
        RoutineSystem.ACTIVITY_STATE.INTERRUPTED

    activity.interruptReason =
        NormalizeString(
            reason,
            "unknown"
        )

    if routine.currentActivityId == activityId then
        routine.currentActivityId = nil
    end

    if currentActivities[routine.ownerId or routineId] == activity then
        currentActivities[routine.ownerId or routineId] = nil
    end

    if type(activity.onInterrupt) == "function" then
        local success, result = pcall(
            activity.onInterrupt,
            activity,
            context
        )

        if not success then
            Log(
                "Activity onInterrupt error: "
                .. tostring(result)
            )
        end
    end

    Log(
        "Activity interrupted: "
        .. activity.id
        .. " reason="
        .. tostring(reason)
    )

    return true
end

-- ============================================================
-- CANCEL ACTIVITY
-- ============================================================

function RoutineSystem.CancelActivity(
    routineId,
    activityId,
    reason
)
    local routine = routines[routineId]

    if not routine then
        return false
    end

    local activity =
        RoutineSystem.GetActivity(
            routineId,
            activityId
        )

    if not activity then
        return false
    end

    activity.state =
        RoutineSystem.ACTIVITY_STATE.CANCELLED

    activity.cancelReason =
        NormalizeString(
            reason,
            "unknown"
        )

    if routine.currentActivityId == activityId then
        routine.currentActivityId = nil
    end

    if currentActivities[routine.ownerId or routineId] == activity then
        currentActivities[routine.ownerId or routineId] = nil
    end

    Log(
        "Activity cancelled: "
        .. activity.id
    )

    return true
end

-- ============================================================
-- UPDATE ROUTINE
-- ============================================================

function RoutineSystem.Update(
    routineId,
    hour,
    minute,
    context
)
    local routine = routines[routineId]

    if not routine or not routine.enabled then
        return nil
    end

    hour = NormalizeNumber(hour, 0)
    minute = NormalizeNumber(minute, 0)

    local currentActivity = nil

    if routine.currentActivityId then
        currentActivity =
            RoutineSystem.GetActivity(
                routineId,
                routine.currentActivityId
            )
    end

    -- If an activity is currently active,
    -- keep it until another system interrupts/completes it.

    if currentActivity
        and currentActivity.state ==
            RoutineSystem.ACTIVITY_STATE.ACTIVE then

        return currentActivity
    end

    local selected =
        RoutineSystem.FindCurrentActivity(
            routineId,
            hour,
            minute,
            context
        )

    if selected then

        if selected.state ==
            RoutineSystem.ACTIVITY_STATE.PENDING
            or selected.state ==
            RoutineSystem.ACTIVITY_STATE.COMPLETED
            or selected.state ==
            RoutineSystem.ACTIVITY_STATE.INTERRUPTED then

            RoutineSystem.StartActivity(
                routineId,
                selected,
                context
            )

            return selected
        end
    end

    return nil
end

-- ============================================================
-- CURRENT ACTIVITY
-- ============================================================

function RoutineSystem.GetCurrentActivity(ownerId)
    return currentActivities[ownerId]
end

function RoutineSystem.GetCurrentActivityForRoutine(routineId)
    local routine = routines[routineId]

    if not routine then
        return nil
    end

    if not routine.currentActivityId then
        return nil
    end

    return RoutineSystem.GetActivity(
        routineId,
        routine.currentActivityId
    )
end

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================

function RoutineSystem.SetEnabled(routineId, enabled)
    local routine = routines[routineId]

    if not routine then
        return false
    end

    routine.enabled = enabled == true

    Log(
        "Routine "
        .. routineId
        .. " enabled="
        .. tostring(routine.enabled)
    )

    return true
end

function RoutineSystem.IsEnabled(routineId)
    local routine = routines[routineId]

    if not routine then
        return false
    end

    return routine.enabled == true
end

-- ============================================================
-- RESET
-- ============================================================

function RoutineSystem.ResetActivityStates(routineId)
    local routine = routines[routineId]

    if not routine then
        return false
    end

    routine.currentActivityId = nil

    for _, activity in ipairs(routine.activities) do
        activity.state =
            RoutineSystem.ACTIVITY_STATE.PENDING

        activity.startedAt = nil
        activity.completedAt = nil
        activity.interruptReason = nil
        activity.cancelReason = nil
    end

    if currentActivities[routine.ownerId or routineId] then
        currentActivities[
            routine.ownerId or routineId
        ] = nil
    end

    Log(
        "Routine activity states reset: "
        .. routineId
    )

    return true
end

-- ============================================================
-- STATUS
-- ============================================================

function RoutineSystem.GetStatus()
    local routineCount = 0
    local activityCount = 0

    for _, routine in pairs(routines) do
        routineCount = routineCount + 1

        if routine.activities then
            activityCount =
                activityCount
                + #routine.activities
        end
    end

    return {
        initialized = initialized,

        version = VERSION,

        initializeAttempts = initializeAttempts,

        routineCount = routineCount,

        activityCount = activityCount
    }
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

function RoutineSystem.Initialize()
    initializeAttempts =
        initializeAttempts + 1

    Log(
        "Initialize attempt #"
        .. tostring(initializeAttempts)
    )

    if initialized then
        Log("Routine System already initialized")
        return true
    end

    initialized = true

    Log(
        "Routine System initialized "
        .. VERSION
    )

    return true
end

-- ============================================================
-- EVENT HOOKS
-- ============================================================

if Events then

    Events.OnGameStart.Add(function()

        Log("OnGameStart")

        if not initialized then
            RoutineSystem.Initialize()
        end

    end)

end

-- ============================================================
-- EXPORT
-- ============================================================

BAO = BAO or {}

BAO.RoutineSystem = RoutineSystem

Log(
    "Routine System "
    .. VERSION
    .. " module loaded"
)

return RoutineSystem

