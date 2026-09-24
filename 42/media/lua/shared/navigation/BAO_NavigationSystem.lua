--[[
    BanditsAIOverhaul
    Navigation System V1.2

    Navigation abstraction layer for Project Zomboid B42.

    Architecture:

        AI Decision
             ↓
        Action
             ↓
        ActionExecutor
             ↓
        NavigationSystem
             ↓
        IsoGameCharacter:pathToLocationF()
             ↓
        Project Zomboid pathfinding
             ↓
        Character movement

    IMPORTANT:

    NavigationSystem does NOT manually call
    PathFindBehavior2:update().

    Project Zomboid owns the character/pathfinding lifecycle.

    NavigationSystem requests navigation and observes its state.
]]

local NavigationSystem = {}

NavigationSystem.VERSION = "1.2"

------------------------------------------------------------
-- States
------------------------------------------------------------

NavigationSystem.STATES = {

    IDLE = "IDLE",

    REQUESTED = "REQUESTED",

    PATHFINDING = "PATHFINDING",

    MOVING = "MOVING",

    ARRIVED = "ARRIVED",

    FAILED = "FAILED",

    CANCELLED = "CANCELLED"

}

------------------------------------------------------------
-- Results
------------------------------------------------------------

NavigationSystem.RESULTS = {

    SUCCESS = "SUCCESS",

    WORKING = "WORKING",

    FAILED = "FAILED",

    CANCELLED = "CANCELLED"

}

------------------------------------------------------------
-- Target types
------------------------------------------------------------

NavigationSystem.TARGET_TYPES = {

    LOCATION = "LOCATION",

    CHARACTER = "CHARACTER",

    SOUND = "SOUND"

}

------------------------------------------------------------
-- Path results
------------------------------------------------------------

NavigationSystem.PATH_RESULTS = {

    WORKING = "Working",

    SUCCEEDED = "Succeeded",

    FAILED = "Failed"

}

------------------------------------------------------------
-- Runtime
------------------------------------------------------------

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

------------------------------------------------------------
-- Logging
------------------------------------------------------------

local function Log(message)

    print(
        "[BAO][NavigationSystem] " ..
        tostring(message)
    )

end

------------------------------------------------------------
-- Time
------------------------------------------------------------

local function GetCurrentTime()

    return os.time() * 1000

end

------------------------------------------------------------
-- Character validation
------------------------------------------------------------

function NavigationSystem.IsValidCharacter(character)

    if character == nil then
        return false
    end

    local successX, x =
        pcall(
            function()
                return character:getX()
            end
        )

    local successY, y =
        pcall(
            function()
                return character:getY()
            end
        )

    local successZ, z =
        pcall(
            function()
                return character:getZ()
            end
        )

    if not successX or
       not successY or
       not successZ then

        return false

    end

    return x ~= nil and
           y ~= nil and
           z ~= nil

end

------------------------------------------------------------
-- Target validation
------------------------------------------------------------

function NavigationSystem.ValidateTarget(target)

    if target == nil then
        return false
    end

    if target.type == NavigationSystem.TARGET_TYPES.LOCATION then

        return target.x ~= nil and
               target.y ~= nil and
               target.z ~= nil

    end

    if target.type == NavigationSystem.TARGET_TYPES.CHARACTER then

        return NavigationSystem.IsValidCharacter(
            target.character
        )

    end

    if target.type == NavigationSystem.TARGET_TYPES.SOUND then

        return target.x ~= nil and
               target.y ~= nil and
               target.z ~= nil

    end

    return false

end

------------------------------------------------------------
-- Target constructors
------------------------------------------------------------

function NavigationSystem.CreateLocationTarget(
    x,
    y,
    z
)

    return {

        type = NavigationSystem.TARGET_TYPES.LOCATION,

        x = x,

        y = y,

        z = z

    }

end

------------------------------------------------------------

function NavigationSystem.CreateCharacterTarget(
    character
)

    if not NavigationSystem.IsValidCharacter(character) then

        return nil

    end

    return {

        type = NavigationSystem.TARGET_TYPES.CHARACTER,

        character = character

    }

end

------------------------------------------------------------

function NavigationSystem.CreateSoundTarget(
    x,
    y,
    z
)

    return {

        type = NavigationSystem.TARGET_TYPES.SOUND,

        x = x,

        y = y,

        z = z

    }

end

------------------------------------------------------------
-- Create request
------------------------------------------------------------

function NavigationSystem.CreateRequest(
    character,
    target,
    metadata
)

    if not NavigationSystem.IsValidCharacter(character) then

        Log(
            "CreateRequest rejected: invalid character"
        )

        return nil

    end

    if not NavigationSystem.ValidateTarget(target) then

        Log(
            "CreateRequest rejected: invalid target"
        )

        return nil

    end

    local id =
        "bao_navigation_" ..
        tostring(
            NavigationSystem.runtime.nextNavigationId
        )

    NavigationSystem.runtime.nextNavigationId =
        NavigationSystem.runtime.nextNavigationId + 1

    local request = {

        id = id,

        character = character,

        target = target,

        metadata = metadata or {},

        state = NavigationSystem.STATES.REQUESTED,

        result = NavigationSystem.RESULTS.WORKING,

        createdAt = GetCurrentTime(),

        startedAt = nil,

        completedAt = nil,

        distance = nil,

        pathResult = nil,

        lastX = nil,

        lastY = nil,

        lastZ = nil,

        diagnostics = {

            pathing = nil,

            movingUsingPathFind = nil,

            hasStartedMoving = nil,

            shouldBeMoving = nil,

            goalLocation = nil,

            pathLength = nil,

            coordinateChanged = false

        }

    }

    NavigationSystem.runtime.statistics.requests =
        NavigationSystem.runtime.statistics.requests + 1

    return request

end

------------------------------------------------------------
-- Helper: location
------------------------------------------------------------

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

    return NavigationSystem.CreateRequest(
        character,
        target,
        metadata
    )

end

------------------------------------------------------------
-- Helper: character
------------------------------------------------------------

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

------------------------------------------------------------
-- Helper: sound
------------------------------------------------------------

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

    return NavigationSystem.CreateRequest(
        character,
        target,
        metadata
    )

end

------------------------------------------------------------
-- Distance
------------------------------------------------------------

function NavigationSystem.GetDistanceToTarget(
    navigation
)

    if navigation == nil then
        return nil
    end

    local character =
        navigation.character

    if not NavigationSystem.IsValidCharacter(
        character
    ) then

        return nil

    end

    local target =
        navigation.target

    if target == nil then
        return nil
    end

    local targetX = nil
    local targetY = nil

    if target.type ==
       NavigationSystem.TARGET_TYPES.LOCATION then

        targetX = target.x
        targetY = target.y

    elseif target.type ==
           NavigationSystem.TARGET_TYPES.SOUND then

        targetX = target.x
        targetY = target.y

    elseif target.type ==
           NavigationSystem.TARGET_TYPES.CHARACTER then

        if not NavigationSystem.IsValidCharacter(
            target.character
        ) then

            return nil

        end

        targetX = target.character:getX()
        targetY = target.character:getY()

    end

    if targetX == nil or targetY == nil then
        return nil
    end

    local dx =
        character:getX() - targetX

    local dy =
        character:getY() - targetY

    return math.sqrt(
        (dx * dx) +
        (dy * dy)
    )

end

------------------------------------------------------------
-- PathFindBehavior2
--
-- This is diagnostics only.
-- We do NOT call update().
------------------------------------------------------------

function NavigationSystem.GetPathFindBehavior(
    character
)

    if not NavigationSystem.IsValidCharacter(
        character
    ) then

        return nil

    end

    local success, behavior =
        pcall(
            function()

                return character:getPathFindBehavior2()

            end
        )

    if success then
        return behavior
    end

    return nil

end

------------------------------------------------------------
-- Diagnostics
------------------------------------------------------------

local function ReadBehaviorDiagnostics(
    navigation
)

    if navigation == nil then
        return
    end

    local character =
        navigation.character

    local behavior =
        NavigationSystem.GetPathFindBehavior(
            character
        )

    if behavior == nil then

        return

    end

    --------------------------------------------------------
    -- isMovingUsingPathFind
    --------------------------------------------------------

    local successMoving, moving =
        pcall(
            function()
                return behavior:isMovingUsingPathFind()
            end
        )

    if successMoving then

        navigation.diagnostics.movingUsingPathFind =
            moving

    end

    --------------------------------------------------------
    -- hasStartedMoving
    --------------------------------------------------------

    local successStarted, started =
        pcall(
            function()
                return behavior:hasStartedMoving()
            end
        )

    if successStarted then

        navigation.diagnostics.hasStartedMoving =
            started

    end

    --------------------------------------------------------
    -- shouldBeMoving
    --------------------------------------------------------

    local successShould, shouldMove =
        pcall(
            function()
                return behavior:shouldBeMoving()
            end
        )

    if successShould then

        navigation.diagnostics.shouldBeMoving =
            shouldMove

    end

    --------------------------------------------------------
    -- isGoalLocation
    --------------------------------------------------------

    local successGoal, goal =
        pcall(
            function()
                return behavior:isGoalLocation()
            end
        )

    if successGoal then

        navigation.diagnostics.goalLocation =
            goal

    end

    --------------------------------------------------------
    -- getPathLength
    --------------------------------------------------------

    local successLength, pathLength =
        pcall(
            function()
                return behavior:getPathLength()
            end
        )

    if successLength then

        navigation.diagnostics.pathLength =
            pathLength

    end

end

------------------------------------------------------------
-- Coordinate tracking
------------------------------------------------------------

local function UpdateCoordinateTracking(
    navigation
)

    if navigation == nil then
        return
    end

    local character =
        navigation.character

    if not NavigationSystem.IsValidCharacter(
        character
    ) then

        return

    end

    local x = character:getX()
    local y = character:getY()
    local z = character:getZ()

    if navigation.lastX ~= nil and
       navigation.lastY ~= nil then

        if math.abs(x - navigation.lastX) > 0.01 or
           math.abs(y - navigation.lastY) > 0.01 then

            navigation.diagnostics.coordinateChanged =
                true

        end

    end

    navigation.lastX = x
    navigation.lastY = y
    navigation.lastZ = z

end

------------------------------------------------------------
-- Request path
------------------------------------------------------------

local function RequestPath(
    navigation
)

    local character =
        navigation.character

    local target =
        navigation.target

    if not NavigationSystem.IsValidCharacter(
        character
    ) then

        return false

    end

    if not NavigationSystem.ValidateTarget(
        target
    ) then

        return false

    end

    --------------------------------------------------------
    -- Location
    --------------------------------------------------------

    if target.type ==
       NavigationSystem.TARGET_TYPES.LOCATION then

        local success =
            pcall(
                function()

                    character:pathToLocationF(
                        target.x,
                        target.y,
                        target.z
                    )

                end
            )

        return success

    end

    --------------------------------------------------------
    -- Character
    --------------------------------------------------------

    if target.type ==
       NavigationSystem.TARGET_TYPES.CHARACTER then

        if not NavigationSystem.IsValidCharacter(
            target.character
        ) then

            return false

        end

        local success =
            pcall(
                function()

                    character:pathToCharacter(
                        target.character
                    )

                end
            )

        return success

    end

    --------------------------------------------------------
    -- Sound
    --------------------------------------------------------

    if target.type ==
       NavigationSystem.TARGET_TYPES.SOUND then

        local success =
            pcall(
                function()

                    character:pathToSound(
                        target.x,
                        target.y,
                        target.z
                    )

                end
            )

        return success

    end

    return false

end

------------------------------------------------------------
-- Start
------------------------------------------------------------

function NavigationSystem.Start(
    navigation
)

    if navigation == nil then

        Log("Start rejected: navigation is nil")

        return false

    end

    if NavigationSystem.runtime.currentNavigation ~= nil then

        Log(
            "Start rejected: another navigation is active"
        )

        return false

    end

    if not NavigationSystem.IsValidCharacter(
        navigation.character
    ) then

        Log(
            "Start rejected: invalid character"
        )

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        return false

    end

    navigation.startedAt =
        GetCurrentTime()

    navigation.state =
        NavigationSystem.STATES.PATHFINDING

    navigation.result =
        NavigationSystem.RESULTS.WORKING

    local success =
        RequestPath(navigation)

    if not success then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        navigation.completedAt =
            GetCurrentTime()

        NavigationSystem.runtime.statistics.failed =
            NavigationSystem.runtime.statistics.failed + 1

        return false

    end

    NavigationSystem.runtime.currentNavigation =
        navigation

    NavigationSystem.runtime.statistics.started =
        NavigationSystem.runtime.statistics.started + 1

    Log(
        "Navigation started: " ..
        tostring(navigation.id)
    )

    return true

end

------------------------------------------------------------
-- Update state
------------------------------------------------------------

local function UpdateNavigationState(
    navigation
)

    if navigation == nil then
        return
    end

    local character =
        navigation.character

    if not NavigationSystem.IsValidCharacter(
        character
    ) then

        navigation.state =
            NavigationSystem.STATES.FAILED

        navigation.result =
            NavigationSystem.RESULTS.FAILED

        return

    end

    UpdateCoordinateTracking(
        navigation
    )

    ReadBehaviorDiagnostics(
        navigation
    )

    local distance =
        NavigationSystem.GetDistanceToTarget(
            navigation
        )

    navigation.distance = distance

    --------------------------------------------------------
    -- Arrival
    --------------------------------------------------------

    if distance ~= nil and
       distance <= 1.0 then

        navigation.state =
            NavigationSystem.STATES.ARRIVED

        navigation.result =
            NavigationSystem.RESULTS.SUCCESS

        navigation.completedAt =
            GetCurrentTime()

        NavigationSystem.runtime.statistics.completed =
            NavigationSystem.runtime.statistics.completed + 1

        return

    end

    --------------------------------------------------------
    -- Movement detection
    --------------------------------------------------------

    if navigation.diagnostics.coordinateChanged then

        navigation.state =
            NavigationSystem.STATES.MOVING

        return

    end

    --------------------------------------------------------
    -- Pathfinding state
    --------------------------------------------------------

    navigation.state =
        NavigationSystem.STATES.PATHFINDING

end

------------------------------------------------------------
-- Store completed navigation
------------------------------------------------------------

local function StoreNavigation(
    navigation
)

    if navigation == nil then
        return
    end

    NavigationSystem.runtime.lastNavigation =
        navigation

    table.insert(
        NavigationSystem.runtime.navigationHistory,
        navigation
    )

    while #NavigationSystem.runtime.navigationHistory >
          NavigationSystem.runtime.maxHistory do

        table.remove(
            NavigationSystem.runtime.navigationHistory,
            1
        )

    end

    if NavigationSystem.runtime.currentNavigation ==
       navigation then

        NavigationSystem.runtime.currentNavigation =
            nil

    end

end

------------------------------------------------------------
-- Update
------------------------------------------------------------

function NavigationSystem.Update()

    local navigation =
        NavigationSystem.runtime.currentNavigation

    if navigation == nil then
        return
    end

    UpdateNavigationState(
        navigation
    )

    if navigation.state ==
       NavigationSystem.STATES.ARRIVED then

        StoreNavigation(
            navigation
        )

        return

    end

    if navigation.state ==
       NavigationSystem.STATES.FAILED then

        NavigationSystem.runtime.statistics.failed =
            NavigationSystem.runtime.statistics.failed + 1

        navigation.completedAt =
            GetCurrentTime()

        StoreNavigation(
            navigation
        )

        return

    end

    if navigation.state ==
       NavigationSystem.STATES.CANCELLED then

        NavigationSystem.runtime.statistics.cancelled =
            NavigationSystem.runtime.statistics.cancelled + 1

        navigation.completedAt =
            GetCurrentTime()

        StoreNavigation(
            navigation
        )

        return

    end

end

------------------------------------------------------------
-- Cancel
------------------------------------------------------------

function NavigationSystem.Cancel(
    reason
)

    local navigation =
        NavigationSystem.runtime.currentNavigation

    if navigation == nil then

        return false

    end

    navigation.state =
        NavigationSystem.STATES.CANCELLED

    navigation.result =
        NavigationSystem.RESULTS.CANCELLED

    navigation.cancelReason =
        reason or "cancelled"

    navigation.completedAt =
        GetCurrentTime()

    StoreNavigation(
        navigation
    )

    return true

end

------------------------------------------------------------
-- Get current
------------------------------------------------------------

function NavigationSystem.GetCurrentNavigation()

    return NavigationSystem.runtime.currentNavigation

end

------------------------------------------------------------
-- Get last
------------------------------------------------------------

function NavigationSystem.GetLastNavigation()

    return NavigationSystem.runtime.lastNavigation

end

------------------------------------------------------------
-- Get history
------------------------------------------------------------

function NavigationSystem.GetNavigationHistory()

    return NavigationSystem.runtime.navigationHistory

end

------------------------------------------------------------
-- Statistics
------------------------------------------------------------

function NavigationSystem.GetStatistics()

    return NavigationSystem.runtime.statistics

end

------------------------------------------------------------
-- Status
------------------------------------------------------------

function NavigationSystem.GetStatus()

    local navigation =
        NavigationSystem.runtime.currentNavigation

    if navigation == nil then

        return NavigationSystem.STATES.IDLE

    end

    return navigation.state

end

------------------------------------------------------------
-- Reset
------------------------------------------------------------

function NavigationSystem.Reset()

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

end

------------------------------------------------------------
-- Initialize
------------------------------------------------------------

function NavigationSystem.Initialize()

    if NavigationSystem.runtime.initialized then

        return true

    end

    NavigationSystem.runtime.initialized =
        true

    NavigationSystem.runtime.attempts =
        NavigationSystem.runtime.attempts + 1

    Log(
        "NavigationSystem initialized. Version=" ..
        tostring(NavigationSystem.VERSION)
    )

    return true

end

------------------------------------------------------------
-- OnGameStart
------------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            NavigationSystem.Initialize()

        end
    )

end

------------------------------------------------------------
-- OnTick
------------------------------------------------------------

if Events and Events.OnTick then

    Events.OnTick.Add(
        function()

            NavigationSystem.Update()

        end
    )

end

------------------------------------------------------------
-- Export
------------------------------------------------------------

BAO = BAO or {}

BAO.NavigationSystem =
    NavigationSystem

Log(
    "NavigationSystem V1.2 loaded"
)