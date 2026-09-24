--[[
    BanditsAIOverhaul
    Navigation System V1.0

    Architecture:

        Decision
            ↓
        Action
            ↓
        ActionExecutor
            ↓
        NavigationSystem
            ↓
        Project Zomboid PathFindBehavior2
            ↓
        NPC movement

    Navigation System is an abstraction layer.
    BAO AI systems should NOT directly manipulate PathFindBehavior2.

    Build target:
        Project Zomboid Build 42.20
]]

local NavigationSystem = {}

NavigationSystem.VERSION = "1.0"

--------------------------------------------------
-- STATES
--------------------------------------------------

NavigationSystem.STATE = {
    IDLE = "idle",
    REQUESTED = "requested",
    PATHFINDING = "pathfinding",
    MOVING = "moving",
    ARRIVED = "arrived",
    FAILED = "failed",
    CANCELLED = "cancelled"
}

--------------------------------------------------
-- RESULTS
--------------------------------------------------

NavigationSystem.RESULT = {
    SUCCESS = "success",
    WORKING = "working",
    FAILED = "failed",
    CANCELLED = "cancelled"
}

--------------------------------------------------
-- TARGET TYPES
--------------------------------------------------

NavigationSystem.TARGET_TYPE = {
    LOCATION = "location",
    CHARACTER = "character",
    SOUND = "sound"
}

--------------------------------------------------
-- PATHFIND BEHAVIOR RESULTS
--------------------------------------------------

NavigationSystem.PATH_RESULT = {
    WORKING = "Working",
    SUCCEEDED = "Succeeded",
    FAILED = "Failed"
}

--------------------------------------------------
-- RUNTIME
--------------------------------------------------

NavigationSystem.initialized = false
NavigationSystem.attempts = 0

NavigationSystem.currentNavigation = nil
NavigationSystem.lastNavigation = nil
NavigationSystem.navigationHistory = {}

NavigationSystem.maxHistory = 20
NavigationSystem.nextNavigationId = 1

NavigationSystem.statistics = {
    requests = 0,
    started = 0,
    completed = 0,
    failed = 0,
    cancelled = 0
}

--------------------------------------------------
-- LOGGING
--------------------------------------------------

local function Log(message)
    print("[BAO][BAO_NavigationSystem] " .. tostring(message))
end

--------------------------------------------------
-- TIME
--------------------------------------------------

local function GetCurrentTime()
    return os.time() * 1000
end

--------------------------------------------------
-- ID
--------------------------------------------------

local function GenerateNavigationId()
    local id = "bao_navigation_" .. tostring(NavigationSystem.nextNavigationId)

    NavigationSystem.nextNavigationId =
        NavigationSystem.nextNavigationId + 1

    return id
end

--------------------------------------------------
-- HISTORY
--------------------------------------------------

local function AddHistory(navigation)
    if not navigation then
        return
    end

    table.insert(
        NavigationSystem.navigationHistory,
        navigation
    )

    while #NavigationSystem.navigationHistory >
        NavigationSystem.maxHistory do

        table.remove(
            NavigationSystem.navigationHistory,
            1
        )
    end
end

--------------------------------------------------
-- VALIDATION
--------------------------------------------------

local function IsValidNumber(value)
    return type(value) == "number"
end

local function IsValidCharacter(character)
    if character == nil then
        return false
    end

    local characterType = type(character)

    return characterType == "userdata"
        or characterType == "table"
end

--------------------------------------------------
-- TARGET VALIDATION
--------------------------------------------------

function NavigationSystem.ValidateTarget(targetType, target)
    if not targetType then
        return false, "missing_target_type"
    end

    if targetType == NavigationSystem.TARGET_TYPE.LOCATION then

        if type(target) ~= "table" then
            return false, "location_target_must_be_table"
        end

        if not IsValidNumber(target.x)
            or not IsValidNumber(target.y)
            or not IsValidNumber(target.z) then

            return false, "location_requires_xyz"
        end

        return true, nil
    end

    if targetType == NavigationSystem.TARGET_TYPE.CHARACTER then

        if not IsValidCharacter(target) then
            return false, "invalid_character_target"
        end

        return true, nil
    end

    if targetType == NavigationSystem.TARGET_TYPE.SOUND then

        if type(target) ~= "table" then
            return false, "sound_target_must_be_table"
        end

        if not IsValidNumber(target.x)
            or not IsValidNumber(target.y)
            or not IsValidNumber(target.z) then

            return false, "sound_requires_xyz"
        end

        return true, nil
    end

    return false, "unknown_target_type"
end

--------------------------------------------------
-- GET PATHFIND BEHAVIOR
--------------------------------------------------

function NavigationSystem.GetPathFindBehavior(character)
    if not IsValidCharacter(character) then
        return nil
    end

    local success, behavior = pcall(
        function()
            return character:getPathFindBehavior2()
        end
    )

    if success then
        return behavior
    end

    return nil
end

--------------------------------------------------
-- CREATE LOCATION TARGET
--------------------------------------------------

function NavigationSystem.CreateLocationTarget(x, y, z)
    if not IsValidNumber(x)
        or not IsValidNumber(y)
        or not IsValidNumber(z) then

        return nil
    end

    return {
        x = x,
        y = y,
        z = z
    }
end

--------------------------------------------------
-- CREATE SOUND TARGET
--------------------------------------------------

function NavigationSystem.CreateSoundTarget(x, y, z)
    if not IsValidNumber(x)
        or not IsValidNumber(y)
        or not IsValidNumber(z) then

        return nil
    end

    return {
        x = x,
        y = y,
        z = z
    }
end

--------------------------------------------------
-- CREATE NAVIGATION REQUEST
--------------------------------------------------

function NavigationSystem.CreateRequest(
    character,
    targetType,
    target,
    metadata
)

    local valid, reason =
        NavigationSystem.ValidateTarget(
            targetType,
            target
        )

    if not valid then
        return nil, reason
    end

    local request = {
        navigationId = GenerateNavigationId(),

        character = character,

        targetType = targetType,
        target = target,

        metadata = metadata or {},

        state = NavigationSystem.STATE.REQUESTED,
        result = nil,

        createdAt = GetCurrentTime(),
        startedAt = nil,
        completedAt = nil,

        distance = nil,
        pathLength = nil,

        hasStartedMoving = false,
        isMoving = false,

        failureReason = nil
    }

    NavigationSystem.statistics.requests =
        NavigationSystem.statistics.requests + 1

    return request, nil
end

--------------------------------------------------
-- LOCATION REQUEST
--------------------------------------------------

function NavigationSystem.RequestLocation(
    character,
    x,
    y,
    z,
    metadata
)

    local target =
        NavigationSystem.CreateLocationTarget(
            x,
            y,
            z
        )

    if not target then
        return nil, "invalid_location"
    end

    return NavigationSystem.CreateRequest(
        character,
        NavigationSystem.TARGET_TYPE.LOCATION,
        target,
        metadata
    )
end

--------------------------------------------------
-- CHARACTER REQUEST
--------------------------------------------------

function NavigationSystem.RequestCharacter(
    character,
    targetCharacter,
    metadata
)

    return NavigationSystem.CreateRequest(
        character,
        NavigationSystem.TARGET_TYPE.CHARACTER,
        targetCharacter,
        metadata
    )
end

--------------------------------------------------
-- SOUND REQUEST
--------------------------------------------------

function NavigationSystem.RequestSound(
    character,
    x,
    y,
    z,
    metadata
)

    local target =
        NavigationSystem.CreateSoundTarget(
            x,
            y,
            z
        )

    if not target then
        return nil, "invalid_sound_location"
    end

    return NavigationSystem.CreateRequest(
        character,
        NavigationSystem.TARGET_TYPE.SOUND,
        target,
        metadata
    )
end

--------------------------------------------------
-- PATH TO LOCATION
--------------------------------------------------

local function PathToLocation(
    behavior,
    target
)

    if not behavior then
        return false
    end

    local success =
        pcall(
            function()
                behavior:pathToLocation(
                    target.x,
                    target.y,
                    target.z
                )
            end
        )

    return success
end

--------------------------------------------------
-- PATH TO CHARACTER
--------------------------------------------------

local function PathToCharacter(
    behavior,
    target
)

    if not behavior then
        return false
    end

    local success =
        pcall(
            function()
                behavior:pathToCharacter(target)
            end
        )

    return success
end

--------------------------------------------------
-- PATH TO SOUND
--------------------------------------------------

local function PathToSound(
    behavior,
    target
)

    if not behavior then
        return false
    end

    local success =
        pcall(
            function()
                behavior:pathToSound(
                    target.x,
                    target.y,
                    target.z
                )
            end
        )

    return success
end

--------------------------------------------------
-- START NAVIGATION
--------------------------------------------------

function NavigationSystem.Start(navigation)

    if not navigation then
        return false, "missing_navigation"
    end

    if navigation.state ~=
        NavigationSystem.STATE.REQUESTED then

        return false, "invalid_navigation_state"
    end

    local behavior =
        NavigationSystem.GetPathFindBehavior(
            navigation.character
        )

    if not behavior then
        navigation.state =
            NavigationSystem.STATE.FAILED

        navigation.result =
            NavigationSystem.RESULT.FAILED

        navigation.failureReason =
            "pathfind_behavior_unavailable"

        NavigationSystem.statistics.failed =
            NavigationSystem.statistics.failed + 1

        return false, navigation.failureReason
    end

    local started = false

    if navigation.targetType ==
        NavigationSystem.TARGET_TYPE.LOCATION then

        started =
            PathToLocation(
                behavior,
                navigation.target
            )

    elseif navigation.targetType ==
        NavigationSystem.TARGET_TYPE.CHARACTER then

        started =
            PathToCharacter(
                behavior,
                navigation.target
            )

    elseif navigation.targetType ==
        NavigationSystem.TARGET_TYPE.SOUND then

        started =
            PathToSound(
                behavior,
                navigation.target
            )
    end

    if not started then
        navigation.state =
            NavigationSystem.STATE.FAILED

        navigation.result =
            NavigationSystem.RESULT.FAILED

        navigation.failureReason =
            "path_request_failed"

        NavigationSystem.statistics.failed =
            NavigationSystem.statistics.failed + 1

        return false, navigation.failureReason
    end

    navigation.state =
        NavigationSystem.STATE.PATHFINDING

    navigation.result =
        NavigationSystem.RESULT.WORKING

    navigation.startedAt =
        GetCurrentTime()

    NavigationSystem.statistics.started =
        NavigationSystem.statistics.started + 1

    NavigationSystem.currentNavigation =
        navigation

    return true, nil
end

--------------------------------------------------
-- UPDATE MOVEMENT INFORMATION
--------------------------------------------------

function NavigationSystem.UpdateMovementInfo(
    navigation
)

    if not navigation then
        return
    end

    local character =
        navigation.character

    if not IsValidCharacter(character) then
        return
    end

    local behavior =
        NavigationSystem.GetPathFindBehavior(
            character
        )

    if not behavior then
        return
    end

    pcall(
        function()

            navigation.pathLength =
                behavior:getPathLength()

            navigation.isMoving =
                behavior:isMovingUsingPathFind()

            navigation.hasStartedMoving =
                behavior:hasStartedMoving()

        end
    )
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

function NavigationSystem.Update(navigation)

    if not navigation then
        return NavigationSystem.RESULT.FAILED
    end

    if navigation.state ==
        NavigationSystem.STATE.CANCELLED then

        return NavigationSystem.RESULT.CANCELLED
    end

    if navigation.state ==
        NavigationSystem.STATE.COMPLETED then

        return NavigationSystem.RESULT.SUCCESS
    end

    if navigation.state ==
        NavigationSystem.STATE.FAILED then

        return NavigationSystem.RESULT.FAILED
    end

    local behavior =
        NavigationSystem.GetPathFindBehavior(
            navigation.character
        )

    if not behavior then

        navigation.state =
            NavigationSystem.STATE.FAILED

        navigation.result =
            NavigationSystem.RESULT.FAILED

        navigation.failureReason =
            "pathfind_behavior_unavailable"

        NavigationSystem.statistics.failed =
            NavigationSystem.statistics.failed + 1

        return NavigationSystem.RESULT.FAILED
    end

    NavigationSystem.UpdateMovementInfo(
        navigation
    )

    local behaviorResult = nil

    pcall(
        function()
            behaviorResult =
                behavior:getResult()
        end
    )

    if behaviorResult ==
        NavigationSystem.PATH_RESULT.SUCCEEDED then

        navigation.state =
            NavigationSystem.STATE.ARRIVED

        navigation.result =
            NavigationSystem.RESULT.SUCCESS

        navigation.completedAt =
            GetCurrentTime()

        NavigationSystem.lastNavigation =
            navigation

        NavigationSystem.currentNavigation =
            nil

        NavigationSystem.statistics.completed =
            NavigationSystem.statistics.completed + 1

        AddHistory(navigation)

        return NavigationSystem.RESULT.SUCCESS
    end

    if behaviorResult ==
        NavigationSystem.PATH_RESULT.FAILED then

        navigation.state =
            NavigationSystem.STATE.FAILED

        navigation.result =
            NavigationSystem.RESULT.FAILED

        navigation.failureReason =
            "pathfind_failed"

        navigation.completedAt =
            GetCurrentTime()

        NavigationSystem.lastNavigation =
            navigation

        NavigationSystem.currentNavigation =
            nil

        NavigationSystem.statistics.failed =
            NavigationSystem.statistics.failed + 1

        AddHistory(navigation)

        return NavigationSystem.RESULT.FAILED
    end

    if navigation.hasStartedMoving then

        navigation.state =
            NavigationSystem.STATE.MOVING
    else
        navigation.state =
            NavigationSystem.STATE.PATHFINDING
    end

    navigation.result =
        NavigationSystem.RESULT.WORKING

    return NavigationSystem.RESULT.WORKING
end

--------------------------------------------------
-- CANCEL
--------------------------------------------------

function NavigationSystem.Cancel(
    navigation,
    reason
)

    if not navigation then
        return false
    end

    navigation.state =
        NavigationSystem.STATE.CANCELLED

    navigation.result =
        NavigationSystem.RESULT.CANCELLED

    navigation.failureReason =
        reason or "cancelled"

    navigation.completedAt =
        GetCurrentTime()

    NavigationSystem.lastNavigation =
        navigation

    if NavigationSystem.currentNavigation ==
        navigation then

        NavigationSystem.currentNavigation =
            nil
    end

    NavigationSystem.statistics.cancelled =
        NavigationSystem.statistics.cancelled + 1

    AddHistory(navigation)

    return true
end

--------------------------------------------------
-- GET CURRENT
--------------------------------------------------

function NavigationSystem.GetCurrentNavigation()
    return NavigationSystem.currentNavigation
end

--------------------------------------------------
-- GET LAST
--------------------------------------------------

function NavigationSystem.GetLastNavigation()
    return NavigationSystem.lastNavigation
end

--------------------------------------------------
-- GET HISTORY
--------------------------------------------------

function NavigationSystem.GetNavigationHistory()
    return NavigationSystem.navigationHistory
end

--------------------------------------------------
-- GET STATISTICS
--------------------------------------------------

function NavigationSystem.GetStatistics()
    return NavigationSystem.statistics
end

--------------------------------------------------
-- GET STATUS
--------------------------------------------------

function NavigationSystem.GetStatus()

    return {
        version = NavigationSystem.VERSION,

        initialized =
            NavigationSystem.initialized,

        attempts =
            NavigationSystem.attempts,

        currentNavigation =
            NavigationSystem.currentNavigation,

        lastNavigation =
            NavigationSystem.lastNavigation,

        historyCount =
            #NavigationSystem.navigationHistory,

        statistics =
            NavigationSystem.statistics
    }
end

--------------------------------------------------
-- RESET
--------------------------------------------------

function NavigationSystem.Reset()

    NavigationSystem.currentNavigation = nil
    NavigationSystem.lastNavigation = nil

    NavigationSystem.navigationHistory = {}

    NavigationSystem.statistics = {
        requests = 0,
        started = 0,
        completed = 0,
        failed = 0,
        cancelled = 0
    }

    NavigationSystem.nextNavigationId = 1
end

--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

function NavigationSystem.Initialize()

    NavigationSystem.attempts =
        NavigationSystem.attempts + 1

    Log(
        "Initialize attempt #"
        .. tostring(NavigationSystem.attempts)
    )

    if NavigationSystem.initialized then
        return true
    end

    NavigationSystem.initialized = true

    Log(
        "Navigation System initialized V"
        .. NavigationSystem.VERSION
    )

    return true
end

--------------------------------------------------
-- GAME START
--------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            Log("OnGameStart")

            NavigationSystem.Initialize()

        end
    )

end

--------------------------------------------------
-- TICK
--------------------------------------------------

if Events and Events.OnTick then

    Events.OnTick.Add(
        function()

            if not NavigationSystem.initialized then
                return
            end

            local navigation =
                NavigationSystem.currentNavigation

            if navigation then
                NavigationSystem.Update(
                    navigation
                )
            end

        end
    )

end

--------------------------------------------------
-- EXPORT
--------------------------------------------------

BAO = BAO or {}

BAO.NavigationSystem =
    NavigationSystem

Log(
    "Navigation System V"
    .. NavigationSystem.VERSION
    .. " module loaded"
)

return NavigationSystem