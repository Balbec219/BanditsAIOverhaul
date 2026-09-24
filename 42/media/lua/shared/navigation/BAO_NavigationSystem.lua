-----------------------------------------------------------
-- BanditsAIOverhaul
-- Navigation System V1.1
--
-- Real character movement layer.
--
-- Architecture:
-- Decision
--     ↓
-- Action
--     ↓
-- ActionExecutor
--     ↓
-- NavigationSystem
--     ↓
-- PathFindBehavior2
--     ↓
-- Real character movement
-----------------------------------------------------------

local NavigationSystem = {}

-----------------------------------------------------------
-- VERSION
-----------------------------------------------------------

NavigationSystem.VERSION = "1.1"

-----------------------------------------------------------
-- STATES
-----------------------------------------------------------

NavigationSystem.STATES = {
    IDLE = "IDLE",
    REQUESTED = "REQUESTED",
    PATHFINDING = "PATHFINDING",
    MOVING = "MOVING",
    ARRIVED = "ARRIVED",
    FAILED = "FAILED",
    CANCELLED = "CANCELLED"
}

-----------------------------------------------------------
-- RESULTS
-----------------------------------------------------------

NavigationSystem.RESULTS = {
    SUCCESS = "SUCCESS",
    WORKING = "WORKING",
    FAILED = "FAILED",
    CANCELLED = "CANCELLED"
}

-----------------------------------------------------------
-- TARGET TYPES
-----------------------------------------------------------

NavigationSystem.TARGET_TYPES = {
    LOCATION = "LOCATION",
    CHARACTER = "CHARACTER",
    SOUND = "SOUND"
}

-----------------------------------------------------------
-- PATHFINDING RESULTS
-----------------------------------------------------------

NavigationSystem.PATH_RESULTS = {
    WORKING = "Working",
    SUCCEEDED = "Succeeded",
    FAILED = "Failed"
}

-----------------------------------------------------------
-- RUNTIME
-----------------------------------------------------------

NavigationSystem.runtime = {
    initialized = false,
    attempts = 0,

    currentNavigation = nil,
    lastNavigation = nil,

    navigationHistory = {},
    maxHistory = 20,

    nextNavigationId = 1,

    statistics = {
        requests = 0,
        started = 0,
        completed = 0,
        failed = 0,
        cancelled = 0
    }
}

-----------------------------------------------------------
-- LOG
-----------------------------------------------------------

local function Log(message)
    print(
        "[BAO][BAO_NavigationSystem] "
        .. tostring(message)
    )
end

-----------------------------------------------------------
-- TIME
-----------------------------------------------------------

local function GetCurrentTime()
    return os.time() * 1000
end

-----------------------------------------------------------
-- ID
-----------------------------------------------------------

local function GenerateNavigationId()
    local id =
        "bao_navigation_"
        .. tostring(
            NavigationSystem.runtime.nextNavigationId
        )

    NavigationSystem.runtime.nextNavigationId =
        NavigationSystem.runtime.nextNavigationId + 1

    return id
end

-----------------------------------------------------------
-- HISTORY
-----------------------------------------------------------

local function AddHistory(navigation)
    if not navigation then
        return
    end

    table.insert(
        NavigationSystem.runtime.navigationHistory,
        navigation
    )

    while #NavigationSystem.runtime.navigationHistory
        > NavigationSystem.runtime.maxHistory do

        table.remove(
            NavigationSystem.runtime.navigationHistory,
            1
        )
    end
end

-----------------------------------------------------------
-- NUMBER VALIDATION
-----------------------------------------------------------

local function IsValidNumber(value)
    return type(value) == "number"
end

-----------------------------------------------------------
-- CHARACTER VALIDATION
-----------------------------------------------------------

local function IsValidCharacter(character)
    if character == nil then
        return false
    end

    if type(character) ~= "userdata" then
        return false
    end

    if character.getX == nil then
        return false
    end

    if character.getY == nil then
        return false
    end

    if character.getZ == nil then
        return false
    end

    return true
end

-----------------------------------------------------------
-- TARGET VALIDATION
-----------------------------------------------------------

function NavigationSystem.ValidateTarget(target)

    if target == nil then
        return false
    end

    if target.type == nil then
        return false
    end

    if target.type == NavigationSystem.TARGET_TYPES.LOCATION then

        return
            IsValidNumber(target.x)
            and IsValidNumber(target.y)
            and IsValidNumber(target.z)

    elseif target.type == NavigationSystem.TARGET_TYPES.CHARACTER then

        return IsValidCharacter(target.character)

    elseif target.type == NavigationSystem.TARGET_TYPES.SOUND then

        return
            IsValidNumber(target.x)
            and IsValidNumber(target.y)
            and IsValidNumber(target.z)
    end

    return false
end

-----------------------------------------------------------
-- PATHFIND BEHAVIOR
-----------------------------------------------------------

function NavigationSystem.GetPathFindBehavior(character)

    if not IsValidCharacter(character) then
        return nil
    end

    if character.getPathFindBehavior2 == nil then
        return nil
    end

    local success, behavior =
        pcall(
            function()
                return character:getPathFindBehavior2()
            end
        )

    if not success then
        Log(
            "GetPathFindBehavior2 failed: "
            .. tostring(behavior)
        )

        return nil
    end

    return behavior
end

-----------------------------------------------------------
-- LOCATION TARGET
-----------------------------------------------------------

function NavigationSystem.CreateLocationTarget(
    x,
    y,
    z
)

    if not IsValidNumber(x)
        or not IsValidNumber(y)
        or not IsValidNumber(z) then

        return nil
    end

    return {
        type = NavigationSystem.TARGET_TYPES.LOCATION,

        x = x,
        y = y,
        z = z
    }
end

-----------------------------------------------------------
-- CHARACTER TARGET
-----------------------------------------------------------

function NavigationSystem.CreateCharacterTarget(character)

    if not IsValidCharacter(character) then
        return nil
    end

    return {
        type = NavigationSystem.TARGET_TYPES.CHARACTER,

        character = character
    }
end

-----------------------------------------------------------
-- SOUND TARGET
-----------------------------------------------------------

function NavigationSystem.CreateSoundTarget(
    x,
    y,
    z
)

    if not IsValidNumber(x)
        or not IsValidNumber(y)
        or not IsValidNumber(z) then

        return nil
    end

    return {
        type = NavigationSystem.TARGET_TYPES.SOUND,

        x = x,
        y = y,
        z = z
    }
end

-----------------------------------------------------------
-- REQUEST
-----------------------------------------------------------

function NavigationSystem.CreateRequest(
    character,
    target,
    metadata
)

    if not IsValidCharacter(character) then
        return nil
    end

    if not NavigationSystem.ValidateTarget(target) then
        return nil
    end

    local request = {
        id = GenerateNavigationId(),

        character = character,

        target = target,

        metadata = metadata or {},

        state = NavigationSystem.STATES.REQUESTED,

        result = nil,

        reason = nil,

        createdAt = GetCurrentTime(),

        startedAt = nil,

        completedAt = nil,

        failedAt = nil,

        cancelledAt = nil,

        distance = nil,

        pathResult = nil
    }

    NavigationSystem.runtime.statistics.requests =
        NavigationSystem.runtime.statistics.requests + 1

    return request
end

-----------------------------------------------------------
-- REQUEST LOCATION
-----------------------------------------------------------

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

    if target == nil then
        return nil
    end

    return NavigationSystem.CreateRequest(
        character,
        target,
        metadata
    )
end

-----------------------------------------------------------
-- REQUEST CHARACTER
-----------------------------------------------------------

function NavigationSystem.RequestCharacter(
    character,
    targetCharacter,
    metadata
)

    local target =
        NavigationSystem.CreateCharacterTarget(
            targetCharacter
        )

    if target == nil then
        return nil
    end

    return NavigationSystem.CreateRequest(
        character,
        target,
        metadata
    )
end

-----------------------------------------------------------
-- REQUEST SOUND
-----------------------------------------------------------

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

    if target == nil then
        return nil
    end

    return NavigationSystem.CreateRequest(
        character,
        target,
        metadata
    )
end

-----------------------------------------------------------
-- DISTANCE
-----------------------------------------------------------

function NavigationSystem.GetDistanceToTarget(navigation)

    if navigation == nil then
        return nil
    end

    local character = navigation.character

    if not IsValidCharacter(character) then
        return nil
    end

    local target = navigation.target

    if target == nil then
        return nil
    end

    local targetX = nil
    local targetY = nil
    local targetZ = nil

    if target.type == NavigationSystem.TARGET_TYPES.LOCATION
        or target.type == NavigationSystem.TARGET_TYPES.SOUND then

        targetX = target.x
        targetY = target.y
        targetZ = target.z

    elseif target.type == NavigationSystem.TARGET_TYPES.CHARACTER then

        local targetCharacter = target.character

        if not IsValidCharacter(targetCharacter) then
            return nil
        end

        targetX = targetCharacter:getX()
        targetY = targetCharacter:getY()
        targetZ = targetCharacter:getZ()
    end

    if targetX == nil
        or targetY == nil
        or targetZ == nil then

        return nil
    end

    local dx = character:getX() - targetX
    local dy = character:getY() - targetY
    local dz = character:getZ() - targetZ

    return math.sqrt(
        dx * dx
        + dy * dy
        + dz * dz
    )
end

-----------------------------------------------------------
-- PATH TO LOCATION
-----------------------------------------------------------

local function PathToLocation(
    navigation,
    behavior
)

    local target = navigation.target

    if target == nil then
        return false
    end

    local success, result =
        pcall(
            function()
                return behavior:pathToLocation(
                    target.x,
                    target.y,
                    target.z
                )
            end
        )

    if not success then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "pathToLocation_error"

        navigation.failedAt =
            GetCurrentTime()

        Log(
            "pathToLocation failed: "
            .. tostring(result)
        )

        return false
    end

    navigation.pathResult = result

    return true
end

-----------------------------------------------------------
-- PATH TO CHARACTER
-----------------------------------------------------------

local function PathToCharacter(
    navigation,
    behavior
)

    local targetCharacter =
        navigation.target.character

    if not IsValidCharacter(targetCharacter) then
        return false
    end

    local success, result =
        pcall(
            function()
                return behavior:pathToCharacter(
                    targetCharacter
                )
            end
        )

    if not success then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "pathToCharacter_error"

        navigation.failedAt =
            GetCurrentTime()

        Log(
            "pathToCharacter failed: "
            .. tostring(result)
        )

        return false
    end

    navigation.pathResult = result

    return true
end

-----------------------------------------------------------
-- PATH TO SOUND
-----------------------------------------------------------

local function PathToSound(
    navigation,
    behavior
)

    local target = navigation.target

    local success, result =
        pcall(
            function()
                return behavior:pathToSound(
                    target.x,
                    target.y,
                    target.z
                )
            end
        )

    if not success then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "pathToSound_error"

        navigation.failedAt =
            GetCurrentTime()

        Log(
            "pathToSound failed: "
            .. tostring(result)
        )

        return false
    end

    navigation.pathResult = result

    return true
end

-----------------------------------------------------------
-- START
-----------------------------------------------------------

function NavigationSystem.Start(navigation)

    if navigation == nil then
        return false
    end

    if not IsValidCharacter(navigation.character) then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "invalid_character"

        return false
    end

    if not NavigationSystem.ValidateTarget(
        navigation.target
    ) then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "invalid_target"

        return false
    end

    local behavior =
        NavigationSystem.GetPathFindBehavior(
            navigation.character
        )

    if behavior == nil then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "pathfind_behavior_unavailable"

        navigation.failedAt =
            GetCurrentTime()

        Log(
            "PathFindBehavior2 unavailable"
        )

        return false
    end

    navigation.state =
        NavigationSystem.STATES.PATHFINDING

    navigation.startedAt =
        GetCurrentTime()

    NavigationSystem.runtime.statistics.started =
        NavigationSystem.runtime.statistics.started + 1

    local started = false

    if navigation.target.type
        == NavigationSystem.TARGET_TYPES.LOCATION then

        started =
            PathToLocation(
                navigation,
                behavior
            )

    elseif navigation.target.type
        == NavigationSystem.TARGET_TYPES.CHARACTER then

        started =
            PathToCharacter(
                navigation,
                behavior
            )

    elseif navigation.target.type
        == NavigationSystem.TARGET_TYPES.SOUND then

        started =
            PathToSound(
                navigation,
                behavior
            )
    end

    if not started then
        return false
    end

    NavigationSystem.runtime.currentNavigation =
        navigation

    return true
end

-----------------------------------------------------------
-- UPDATE MOVEMENT INFO
-----------------------------------------------------------

function NavigationSystem.UpdateMovementInfo(
    navigation
)

    if navigation == nil then
        return
    end

    local distance =
        NavigationSystem.GetDistanceToTarget(
            navigation
        )

    navigation.distance = distance

    if distance ~= nil
        and distance <= 1.0 then

        navigation.state =
            NavigationSystem.STATES.ARRIVED

        navigation.result =
            NavigationSystem.RESULTS.SUCCESS

        navigation.completedAt =
            GetCurrentTime()

        NavigationSystem.runtime.statistics.completed =
            NavigationSystem.runtime.statistics.completed + 1

        NavigationSystem.runtime.lastNavigation =
            navigation

        AddHistory(navigation)

        NavigationSystem.runtime.currentNavigation =
            nil

        Log(
            "Navigation arrived: "
            .. tostring(navigation.id)
        )

        return
    end
end

-----------------------------------------------------------
-- UPDATE
-----------------------------------------------------------

function NavigationSystem.Update()

    local navigation =
        NavigationSystem.runtime.currentNavigation

    if navigation == nil then
        return
    end

    if navigation.state
        == NavigationSystem.STATES.CANCELLED then

        NavigationSystem.runtime.currentNavigation =
            nil

        return
    end

    if navigation.state
        == NavigationSystem.STATES.FAILED then

        NavigationSystem.runtime.currentNavigation =
            nil

        return
    end

    if not IsValidCharacter(
        navigation.character
    ) then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "character_invalidated"

        navigation.failedAt =
            GetCurrentTime()

        NavigationSystem.runtime.statistics.failed =
            NavigationSystem.runtime.statistics.failed + 1

        NavigationSystem.runtime.lastNavigation =
            navigation

        AddHistory(navigation)

        NavigationSystem.runtime.currentNavigation =
            nil

        return
    end

    local behavior =
        NavigationSystem.GetPathFindBehavior(
            navigation.character
        )

    if behavior == nil then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "pathfind_behavior_lost"

        navigation.failedAt =
            GetCurrentTime()

        NavigationSystem.runtime.statistics.failed =
            NavigationSystem.runtime.statistics.failed + 1

        NavigationSystem.runtime.lastNavigation =
            navigation

        AddHistory(navigation)

        NavigationSystem.runtime.currentNavigation =
            nil

        return
    end

    -------------------------------------------------------
    -- UPDATE PATHFIND BEHAVIOR
    -------------------------------------------------------

    local success, result =
        pcall(
            function()
                return behavior:update()
            end
        )

    if not success then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "pathfind_update_error"

        navigation.failedAt =
            GetCurrentTime()

        NavigationSystem.runtime.statistics.failed =
            NavigationSystem.runtime.statistics.failed + 1

        NavigationSystem.runtime.lastNavigation =
            navigation

        AddHistory(navigation)

        NavigationSystem.runtime.currentNavigation =
            nil

        Log(
            "PathFindBehavior2:update failed: "
            .. tostring(result)
        )

        return
    end

    navigation.pathResult = result

    -------------------------------------------------------
    -- CHECK DISTANCE
    -------------------------------------------------------

    NavigationSystem.UpdateMovementInfo(
        navigation
    )

    if navigation.state
        == NavigationSystem.STATES.ARRIVED then

        return
    end

    -------------------------------------------------------
    -- INTERPRET PATH RESULT
    -------------------------------------------------------

    local resultString =
        tostring(result)

    if resultString
        == NavigationSystem.PATH_RESULTS.SUCCEEDED then

        navigation.state =
            NavigationSystem.STATES.MOVING

    elseif resultString
        == NavigationSystem.PATH_RESULTS.FAILED then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.reason =
            "pathfinding_failed"

        navigation.failedAt =
            GetCurrentTime()

        NavigationSystem.runtime.statistics.failed =
            NavigationSystem.runtime.statistics.failed + 1

        NavigationSystem.runtime.lastNavigation =
            navigation

        AddHistory(navigation)

        NavigationSystem.runtime.currentNavigation =
            nil

    else

        navigation.state =
            NavigationSystem.STATES.PATHFINDING
    end
end

-----------------------------------------------------------
-- CANCEL
-----------------------------------------------------------

function NavigationSystem.Cancel(reason)

    local navigation =
        NavigationSystem.runtime.currentNavigation

    if navigation == nil then
        return false
    end

    navigation.state =
        NavigationSystem.STATES.CANCELLED

    navigation.result =
        NavigationSystem.RESULTS.CANCELLED

    navigation.reason =
        reason or "cancelled"

    navigation.cancelledAt =
        GetCurrentTime()

    NavigationSystem.runtime.statistics.cancelled =
        NavigationSystem.runtime.statistics.cancelled + 1

    NavigationSystem.runtime.lastNavigation =
        navigation

    AddHistory(navigation)

    NavigationSystem.runtime.currentNavigation =
        nil

    Log(
        "Navigation cancelled: "
        .. tostring(navigation.id)
    )

    return true
end

-----------------------------------------------------------
-- GETTERS
-----------------------------------------------------------

function NavigationSystem.GetCurrentNavigation()
    return NavigationSystem.runtime.currentNavigation
end

function NavigationSystem.GetLastNavigation()
    return NavigationSystem.runtime.lastNavigation
end

function NavigationSystem.GetNavigationHistory()
    return NavigationSystem.runtime.navigationHistory
end

function NavigationSystem.GetStatistics()
    return NavigationSystem.runtime.statistics
end

function NavigationSystem.GetStatus()

    return {
        version = NavigationSystem.VERSION,

        initialized =
            NavigationSystem.runtime.initialized,

        attempts =
            NavigationSystem.runtime.attempts,

        currentNavigation =
            NavigationSystem.runtime.currentNavigation,

        lastNavigation =
            NavigationSystem.runtime.lastNavigation,

        historyCount =
            #NavigationSystem.runtime.navigationHistory,

        statistics =
            NavigationSystem.runtime.statistics
    }
end

-----------------------------------------------------------
-- RESET
-----------------------------------------------------------

function NavigationSystem.Reset()

    NavigationSystem.runtime.currentNavigation =
        nil

    NavigationSystem.runtime.lastNavigation =
        nil

    NavigationSystem.runtime.navigationHistory =
        {}

    NavigationSystem.runtime.nextNavigationId =
        1

    NavigationSystem.runtime.statistics = {
        requests = 0,
        started = 0,
        completed = 0,
        failed = 0,
        cancelled = 0
    }

    NavigationSystem.runtime.initialized =
        false
end

-----------------------------------------------------------
-- INITIALIZE
-----------------------------------------------------------

function NavigationSystem.Initialize()

    NavigationSystem.runtime.attempts =
        NavigationSystem.runtime.attempts + 1

    Log(
        "Initialize attempt #"
        .. tostring(
            NavigationSystem.runtime.attempts
        )
    )

    NavigationSystem.runtime.initialized =
        true

    Log(
        "Navigation System initialized V"
        .. NavigationSystem.VERSION
    )

    return true
end

-----------------------------------------------------------
-- GAME START
-----------------------------------------------------------

if Events then

    Events.OnGameStart.Add(
        function()

            Log("OnGameStart")

            if not NavigationSystem.runtime.initialized then
                NavigationSystem.Initialize()
            end
        end
    )

    -------------------------------------------------------
    -- TICK
    -------------------------------------------------------

    if Events.OnTick then

        Events.OnTick.Add(
            function()

                if NavigationSystem.runtime.initialized then
                    NavigationSystem.Update()
                end
            end
        )
    end
end

-----------------------------------------------------------
-- EXPORT
-----------------------------------------------------------

BAO = BAO or {}

BAO.NavigationSystem =
    NavigationSystem

Log(
    "Navigation System V"
    .. NavigationSystem.VERSION
    .. " module loaded"
)