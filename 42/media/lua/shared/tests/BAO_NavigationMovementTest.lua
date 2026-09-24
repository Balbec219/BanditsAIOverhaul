--[[
    BanditsAIOverhaul
    Navigation Movement Test V1.4

    SAFE DIAGNOSTIC VERSION

    This version DOES NOT automatically start navigation.

    It inspects the real player and the real
    PathFindBehavior2 instance.

    The purpose is to determine exactly which
    PathFindBehavior2 state/functions are available
    on Project Zomboid Build 42.20.4.

    IMPORTANT:

    Previous test:
        Player -> Navigation -> PathFindBehavior2

    caused:
        walking animation
        no coordinate movement
        player input blocked
        PathFindBehavior2 -> Failed

    Therefore this version intentionally does NOT
    hijack player movement.
]]

local Test = {}

Test.VERSION = "1.4"

Test.player = nil

Test.playerCached = false

Test.diagnosticsComplete = false

Test.lastLogTime = 0

Test.diagnosticInterval = 3

------------------------------------------------------------
-- Logging
------------------------------------------------------------

local function Log(message)

    print(
        "[BAO NavigationMovementTest V1.4] " ..
        tostring(message)
    )

end

------------------------------------------------------------
-- Player cache
------------------------------------------------------------

local function CachePlayer(player)

    if player == nil then
        return
    end

    Test.player = player

    Test.playerCached = true

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()

    Log(
        "Player cached: " ..
        "x=" .. tostring(x) ..
        " y=" .. tostring(y) ..
        " z=" .. tostring(z)
    )

end

------------------------------------------------------------
-- OnCreatePlayer
------------------------------------------------------------

if Events and Events.OnCreatePlayer then

    Events.OnCreatePlayer.Add(
        function(
            playerIndex,
            player
        )

            Log(
                "OnCreatePlayer received. index=" ..
                tostring(playerIndex)
            )

            CachePlayer(player)

        end
    )

else

    Log(
        "WARNING: Events.OnCreatePlayer unavailable"
    )

end

------------------------------------------------------------
-- Navigation dependency
------------------------------------------------------------

local function CheckNavigationSystem()

    if BAO == nil then

        Log(
            "Navigation dependency: BAO unavailable"
        )

        return false

    end

    if BAO.NavigationSystem == nil then

        Log(
            "Navigation dependency: NavigationSystem unavailable"
        )

        return false

    end

    Log(
        "NavigationSystem detected. Version=" ..
        tostring(
            BAO.NavigationSystem.VERSION
        )
    )

    return true

end

------------------------------------------------------------
-- Safe method call helper
------------------------------------------------------------

local function SafeCall(
    object,
    methodName
)

    if object == nil then

        return nil, false

    end

    local method =
        object[methodName]

    if method == nil then

        return nil, false

    end

    local success, result =
        pcall(
            function()

                return method(object)

            end
        )

    if success then

        return result, true

    end

    return nil, false

end

------------------------------------------------------------
-- PathFindBehavior diagnostics
------------------------------------------------------------

local function DiagnosePathFindBehavior()

    if Test.player == nil then

        return

    end

    local Navigation =
        BAO.NavigationSystem

    if Navigation == nil then

        return

    end

    --------------------------------------------------------
    -- Get behavior
    --------------------------------------------------------

    local behavior =
        Navigation.GetPathFindBehavior(
            Test.player
        )

    if behavior == nil then

        Log(
            "PathFindBehavior2: UNAVAILABLE"
        )

        return

    end

    Log(
        "PathFindBehavior2: AVAILABLE"
    )

    --------------------------------------------------------
    -- isMovingUsingPathFind
    --------------------------------------------------------

    local moving, movingOK =
        SafeCall(
            behavior,
            "isMovingUsingPathFind"
        )

    if movingOK then

        Log(
            "isMovingUsingPathFind() = " ..
            tostring(moving)
        )

    else

        Log(
            "isMovingUsingPathFind() = unavailable/error"
        )

    end

    --------------------------------------------------------
    -- hasStartedMoving
    --------------------------------------------------------

    local started, startedOK =
        SafeCall(
            behavior,
            "hasStartedMoving"
        )

    if startedOK then

        Log(
            "hasStartedMoving() = " ..
            tostring(started)
        )

    else

        Log(
            "hasStartedMoving() = unavailable/error"
        )

    end

    --------------------------------------------------------
    -- shouldBeMoving
    --------------------------------------------------------

    local shouldMove, shouldOK =
        SafeCall(
            behavior,
            "shouldBeMoving"
        )

    if shouldOK then

        Log(
            "shouldBeMoving() = " ..
            tostring(shouldMove)
        )

    else

        Log(
            "shouldBeMoving() = unavailable/error"
        )

    end

    --------------------------------------------------------
    -- isGoalLocation
    --------------------------------------------------------

    local goalLocation, goalOK =
        SafeCall(
            behavior,
            "isGoalLocation"
        )

    if goalOK then

        Log(
            "isGoalLocation() = " ..
            tostring(goalLocation)
        )

    else

        Log(
            "isGoalLocation() = unavailable/error"
        )

    end

    --------------------------------------------------------
    -- getPathLength
    --------------------------------------------------------

    local pathLength, lengthOK =
        SafeCall(
            behavior,
            "getPathLength"
        )

    if lengthOK then

        Log(
            "getPathLength() = " ..
            tostring(pathLength)
        )

    else

        Log(
            "getPathLength() = unavailable/error"
        )

    end

end

------------------------------------------------------------
-- Player pathing diagnostics
------------------------------------------------------------

local function DiagnosePlayer()

    if Test.player == nil then

        return

    end

    local player =
        Test.player

    --------------------------------------------------------
    -- Coordinates
    --------------------------------------------------------

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()

    Log(
        "Player position: " ..
        tostring(x) .. ", " ..
        tostring(y) .. ", " ..
        tostring(z)
    )

    --------------------------------------------------------
    -- isPathing
    --------------------------------------------------------

    local pathingOK, pathing =
        pcall(
            function()

                return player:isPathing()

            end
        )

    if pathingOK then

        Log(
            "player:isPathing() = " ..
            tostring(pathing)
        )

    else

        Log(
            "player:isPathing() = unavailable/error"
        )

    end

    --------------------------------------------------------
    -- getPath2
    --------------------------------------------------------

    local path2OK, path2 =
        pcall(
            function()

                return player:getPath2()

            end
        )

    if path2OK then

        if path2 ~= nil then

            Log(
                "player:getPath2() = AVAILABLE"
            )

        else

            Log(
                "player:getPath2() = nil"
            )

        end

    else

        Log(
            "player:getPath2() = unavailable/error"
        )

    end

end

------------------------------------------------------------
-- Full diagnostic
------------------------------------------------------------

local function RunDiagnostics()

    if Test.player == nil then

        return

    end

    Log("========================================")
    Log("PATHFINDING DIAGNOSTIC")
    Log("========================================")

    CheckNavigationSystem()

    DiagnosePlayer()

    DiagnosePathFindBehavior()

    Log("========================================")

    Test.diagnosticsComplete = true

end

------------------------------------------------------------
-- OnGameStart
------------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            Log("========================================")
            Log("Navigation Movement Test V1.4 loaded")
            Log("OnGameStart received")
            Log("SAFE DIAGNOSTIC MODE")
            Log("Player movement will NOT be hijacked.")
            Log("========================================")

            CheckNavigationSystem()

        end
    )

end

------------------------------------------------------------
-- Tick
------------------------------------------------------------

if Events and Events.OnTick then

    Events.OnTick.Add(
        function()

            if Test.player == nil then

                return

            end

            local now = os.time()

            if Test.lastLogTime == 0 or
               (now - Test.lastLogTime) >=
               Test.diagnosticInterval then

                Test.lastLogTime = now

                if not Test.diagnosticsComplete then

                    RunDiagnostics()

                end

            end

        end
    )

end

------------------------------------------------------------
-- Export
------------------------------------------------------------

BAO = BAO or {}

BAO.NavigationMovementTest =
    Test

Log(
    "Navigation Movement Test V1.4 loaded"
)