--[[
    BanditsAIOverhaul
    Navigation Movement Test V1.2

    Проверяет реальное движение игрока через:
        Player
            ↓
        NavigationSystem
            ↓
        PathFindBehavior2
            ↓
        Project Zomboid movement

    Тест не использует getSpecificPlayer().
    Игрок получается через Events.OnCreatePlayer.

    Результат:
        ARRIVED = навигация реально довела игрока до точки
        FAILED  = PathFindBehavior2 сообщил ошибку
        TIMEOUT = движение не завершилось за заданное время
]]

local Test = {}

Test.VERSION = "1.2"

Test.player = nil
Test.started = false
Test.finished = false

Test.navigation = nil
Test.targetX = nil
Test.targetY = nil
Test.targetZ = nil

Test.startTime = nil
Test.timeoutSeconds = 30

Test.startX = nil
Test.startY = nil
Test.startZ = nil

Test.lastLogTime = 0

------------------------------------------------------------
-- Logging
------------------------------------------------------------

local function Log(message)
    print("[BAO NavigationMovementTest V1.2] " .. tostring(message))
end

------------------------------------------------------------
-- Player cache
------------------------------------------------------------

local function CachePlayer(player)
    if player == nil then
        return
    end

    Test.player = player

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
-- Events
------------------------------------------------------------

if Events then

    if Events.OnCreatePlayer then

        Events.OnCreatePlayer.Add(function(playerIndex, player)

            Log(
                "OnCreatePlayer received. " ..
                "index=" .. tostring(playerIndex)
            )

            CachePlayer(player)

        end)

    else
        Log("WARNING: Events.OnCreatePlayer is unavailable")
    end

else
    Log("WARNING: Events object is unavailable")
end

------------------------------------------------------------
-- Dependency check
------------------------------------------------------------

local function CheckNavigationSystem()

    if BAO == nil then
        Log("FAIL: BAO namespace is unavailable")
        return false
    end

    if BAO.NavigationSystem == nil then
        Log("FAIL: BAO.NavigationSystem is unavailable")
        return false
    end

    Log(
        "NavigationSystem detected. " ..
        "Version=" ..
        tostring(BAO.NavigationSystem.VERSION)
    )

    return true
end

------------------------------------------------------------
-- Start navigation test
------------------------------------------------------------

local function StartTest()

    if Test.started then
        return
    end

    if Test.finished then
        return
    end

    if Test.player == nil then

        Log("Waiting for player...")

        return

    end

    local Navigation = BAO.NavigationSystem

    if Navigation == nil then
        Log("FAIL: NavigationSystem unavailable")
        Test.finished = true
        return
    end

    local player = Test.player

    --------------------------------------------------------
    -- Start position
    --------------------------------------------------------

    Test.startX = player:getX()
    Test.startY = player:getY()
    Test.startZ = player:getZ()

    --------------------------------------------------------
    -- Target
    --
    -- 8 cells diagonally from player.
    --------------------------------------------------------

    Test.targetX = Test.startX + 8
    Test.targetY = Test.startY + 8
    Test.targetZ = Test.startZ

    Log("========================================")
    Log("STARTING REAL NAVIGATION TEST")
    Log("========================================")

    Log(
        "Start position: " ..
        tostring(Test.startX) .. ", " ..
        tostring(Test.startY) .. ", " ..
        tostring(Test.startZ)
    )

    Log(
        "Target position: " ..
        tostring(Test.targetX) .. ", " ..
        tostring(Test.targetY) .. ", " ..
        tostring(Test.targetZ)
    )

    --------------------------------------------------------
    -- Create navigation request
    --------------------------------------------------------

    local request =
        Navigation.RequestLocation(
            player,
            Test.targetX,
            Test.targetY,
            Test.targetZ,
            {
                source = "BAO_NavigationMovementTest",
                testVersion = Test.VERSION
            }
        )

    if request == nil then

        Log("FAIL: RequestLocation returned nil")

        Test.finished = true

        return

    end

    Test.navigation = request

    Log(
        "Navigation request created. " ..
        "ID=" .. tostring(request.id)
    )

    --------------------------------------------------------
    -- Start navigation
    --------------------------------------------------------

    local started = Navigation.Start(request)

    if not started then

        Log("FAIL: Navigation.Start() returned false")

        Test.finished = true

        return

    end

    Test.started = true
    Test.startTime = os.time()

    Log(
        "Navigation started successfully. " ..
        "State=" .. tostring(request.state)
    )

    Log("========================================")

end

------------------------------------------------------------
-- Distance
------------------------------------------------------------

local function GetDistanceToTarget()

    if Test.player == nil then
        return nil
    end

    if Test.targetX == nil then
        return nil
    end

    local x = Test.player:getX()
    local y = Test.player:getY()

    local dx = x - Test.targetX
    local dy = y - Test.targetY

    return math.sqrt(
        (dx * dx) +
        (dy * dy)
    )

end

------------------------------------------------------------
-- Progress logging
------------------------------------------------------------

local function LogProgress()

    if not Test.started then
        return
    end

    if Test.finished then
        return
    end

    local now = os.time()

    if Test.lastLogTime ~= 0 and
       (now - Test.lastLogTime) < 2 then

        return
    end

    Test.lastLogTime = now

    local player = Test.player

    if player == nil then
        return
    end

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()

    local distance = GetDistanceToTarget()

    local state = "UNKNOWN"

    if Test.navigation ~= nil then
        state = tostring(Test.navigation.state)
    end

    Log(
        "Progress: " ..
        "state=" .. state ..
        " position=(" ..
        tostring(x) .. ", " ..
        tostring(y) .. ", " ..
        tostring(z) .. ")" ..
        " distance=" ..
        tostring(distance)
    )

end

------------------------------------------------------------
-- Finish
------------------------------------------------------------

local function Finish(result, message)

    if Test.finished then
        return
    end

    Test.finished = true

    Log("========================================")
    Log("NAVIGATION MOVEMENT TEST FINISHED")
    Log("RESULT: " .. tostring(result))

    if message ~= nil then
        Log("DETAIL: " .. tostring(message))
    end

    if Test.player ~= nil then

        local x = Test.player:getX()
        local y = Test.player:getY()
        local z = Test.player:getZ()

        Log(
            "Final position: " ..
            tostring(x) .. ", " ..
            tostring(y) .. ", " ..
            tostring(z)
        )

        local distance = GetDistanceToTarget()

        Log(
            "Final distance to target: " ..
            tostring(distance)
        )

    end

    if Test.navigation ~= nil then

        Log(
            "Navigation ID: " ..
            tostring(Test.navigation.id)
        )

        Log(
            "Navigation state: " ..
            tostring(Test.navigation.state)
        )

        Log(
            "Navigation result: " ..
            tostring(Test.navigation.result)
        )

        Log(
            "Path result: " ..
            tostring(Test.navigation.pathResult)
        )

    end

    Log("========================================")

end

------------------------------------------------------------
-- Update test
------------------------------------------------------------

local function UpdateTest()

    if Test.finished then
        return
    end

    --------------------------------------------------------
    -- Wait for player
    --------------------------------------------------------

    if not Test.started then

        StartTest()

        return

    end

    --------------------------------------------------------
    -- Player safety
    --------------------------------------------------------

    if Test.player == nil then

        Finish(
            "FAILED",
            "Player reference was lost"
        )

        return

    end

    --------------------------------------------------------
    -- Navigation safety
    --------------------------------------------------------

    if Test.navigation == nil then

        Finish(
            "FAILED",
            "Navigation request was lost"
        )

        return

    end

    --------------------------------------------------------
    -- Progress
    --------------------------------------------------------

    LogProgress()

    --------------------------------------------------------
    -- State checks
    --------------------------------------------------------

    local state = Test.navigation.state

    if state == BAO.NavigationSystem.STATES.ARRIVED then

        local distance = GetDistanceToTarget()

        Finish(
            "SUCCESS",
            "Navigation reached ARRIVED state"
        )

        return

    end

    if state == BAO.NavigationSystem.STATES.FAILED then

        Finish(
            "FAILED",
            "Navigation entered FAILED state"
        )

        return

    end

    if state == BAO.NavigationSystem.STATES.CANCELLED then

        Finish(
            "CANCELLED",
            "Navigation was cancelled"
        )

        return

    end

    --------------------------------------------------------
    -- Timeout
    --------------------------------------------------------

    if Test.startTime ~= nil then

        local elapsed =
            os.time() - Test.startTime

        if elapsed >= Test.timeoutSeconds then

            Finish(
                "TIMEOUT",
                "Navigation did not finish within " ..
                tostring(Test.timeoutSeconds) ..
                " seconds"
            )

            return

        end

    end

end

------------------------------------------------------------
-- Game start
------------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(function()

        Log("========================================")
        Log("Navigation Movement Test V1.2 loaded")
        Log("OnGameStart received")

        if CheckNavigationSystem() then

            Log(
                "NavigationSystem is ready. " ..
                "Waiting for player..."
            )

        end

        Log("========================================")

    end)

else

    Log("WARNING: Events.OnGameStart unavailable")

end

------------------------------------------------------------
-- Tick
------------------------------------------------------------

if Events and Events.OnTick then

    Events.OnTick.Add(function()

        UpdateTest()

    end)

else

    Log("WARNING: Events.OnTick unavailable")

end

------------------------------------------------------------
-- Export
------------------------------------------------------------

BAO = BAO or {}

BAO.NavigationMovementTest = Test

Log(
    "Navigation Movement Test V1.2 loaded"
)