-- ============================================================
-- BanditsAIOverhaul
-- BAO_NavigationNPCTest.lua
-- Version: 1.1
--
-- Purpose:
--   Real NPC navigation integration test.
--
-- Test flow:
--   1. Get player.
--   2. Find free spawn square near player.
--   3. Find free target square.
--   4. Create a real Survivor NPC through SurvivorFactory.
--   5. Create Navigation request.
--   6. Start navigation.
--   7. Observe PathFindBehavior2 / NPC movement.
--   8. Report SUCCESS / FAILED / TIMEOUT.
--
-- IMPORTANT:
--   This test is diagnostic.
--   It does not replace the player movement.
-- ============================================================

local Test = {}

Test.VERSION = "1.1"

Test.runtime = {
    initialized = false,

    player = nil,
    npc = nil,

    spawnX = nil,
    spawnY = nil,
    spawnZ = nil,

    targetX = nil,
    targetY = nil,
    targetZ = nil,

    navigation = nil,

    startedAt = nil,
    finishedAt = nil,

    finished = false,
    result = nil,
    detail = nil,

    diagnosticCounter = 0,
    diagnosticInterval = 30,

    timeoutMs = 30000
}

-- ============================================================
-- Logging
-- ============================================================

local function Log(message)
    print("[BAO][NavigationNPCTest] " .. tostring(message))
end

local function GetTimeMs()
    return os.time() * 1000
end

-- ============================================================
-- Safe global access
--
-- Using _G avoids false VS Code "undefined-global" warnings
-- for Project Zomboid globals/classes supplied by Java/Lua.
-- ============================================================

local function GetSpecificPlayer(index)
    local fn = _G["getSpecificPlayer"]

    if fn == nil then
        return nil
    end

    local ok, player = pcall(fn, index)

    if not ok then
        Log("WARNING: getSpecificPlayer failed: " .. tostring(player))
        return nil
    end

    return player
end

local function GetSurvivorFactory()
    local factory = _G["SurvivorFactory"]

    if factory == nil then
        return nil
    end

    return factory
end

-- ============================================================
-- Player
-- ============================================================

function Test.SetPlayer(player)
    if player == nil then
        return
    end

    Test.runtime.player = player

    Log(
        "Player cached. " ..
        "x=" .. tostring(player:getX()) ..
        " y=" .. tostring(player:getY()) ..
        " z=" .. tostring(player:getZ())
    )
end

function Test.GetPlayer()
    if Test.runtime.player ~= nil then
        return Test.runtime.player
    end

    local player = GetSpecificPlayer(0)

    if player ~= nil then
        Test.SetPlayer(player)
    end

    return player
end

-- ============================================================
-- Square helpers
-- ============================================================

function Test.GetCell()
    local getCellFunction = _G["getCell"]

    if getCellFunction == nil then
        Log("ERROR: getCell unavailable.")
        return nil
    end

    local ok, cell = pcall(
        function()
            return getCellFunction()
        end
    )

    if not ok then
        Log("ERROR: getCell failed: " .. tostring(cell))
        return nil
    end

    return cell
end

function Test.GetSquare(x, y, z)
    local cell = Test.GetCell()

    if cell == nil then
        return nil
    end

    local ok, square = pcall(
        function()
            return cell:getGridSquare(x, y, z)
        end
    )

    if not ok then
        return nil
    end

    return square
end

function Test.IsSquareFree(square)
    if square == nil then
        return false
    end

    -- Do not spawn directly on occupied squares.
    local movingObjects = square:getMovingObjects()

    if movingObjects ~= nil then
        local count = movingObjects:size()

        if count > 0 then
            return false
        end
    end

    return true
end

-- ============================================================
-- Find free square
-- ============================================================

function Test.FindFreeSquareNear(
    centerX,
    centerY,
    centerZ,
    minDistance,
    maxDistance
)
    for distance = minDistance, maxDistance do

        local candidates = {
            { centerX + distance, centerY, centerZ },
            { centerX - distance, centerY, centerZ },
            { centerX, centerY + distance, centerZ },
            { centerX, centerY - distance, centerZ },

            { centerX + distance, centerY + distance, centerZ },
            { centerX - distance, centerY + distance, centerZ },
            { centerX + distance, centerY - distance, centerZ },
            { centerX - distance, centerY - distance, centerZ }
        }

        for i = 1, #candidates do
            local candidate = candidates[i]

            local x = math.floor(candidate[1])
            local y = math.floor(candidate[2])
            local z = math.floor(candidate[3])

            local square = Test.GetSquare(x, y, z)

            if Test.IsSquareFree(square) then
                return square
            end
        end
    end

    return nil
end

-- ============================================================
-- NPC creation
-- ============================================================

function Test.CreateNPC(spawnX, spawnY, spawnZ)
    local factory = GetSurvivorFactory()

    if factory == nil then
        Log("ERROR: SurvivorFactory unavailable.")
        return nil
    end

    Log("Creating SurvivorDesc...")

    local okDesc, desc = pcall(
        function()
            return factory.CreateSurvivor()
        end
    )

    if not okDesc then
        Log(
            "ERROR: SurvivorFactory.CreateSurvivor failed: " ..
            tostring(desc)
        )

        return nil
    end

    if desc == nil then
        Log("ERROR: SurvivorFactory.CreateSurvivor returned nil.")
        return nil
    end

    -- Give the NPC a recognizable test name.
    pcall(
        function()
            desc:setForename("BAO_Test_NPC")
            desc:setSurname("Navigation")
        end
    )

    Log(
        "Instantiating NPC at " ..
        tostring(spawnX) .. ", " ..
        tostring(spawnY) .. ", " ..
        tostring(spawnZ)
    )

    local cell = Test.GetCell()

    if cell == nil then
        Log("ERROR: IsoCell unavailable.")
        return nil
    end

    local okCreate, npc = pcall(
        function()
            return factory.InstansiateInCell(
                desc,
                cell,
                spawnX,
                spawnY,
                spawnZ
            )
        end
    )

    if not okCreate then
        Log(
            "ERROR: SurvivorFactory.InstansiateInCell failed: " ..
            tostring(npc)
        )

        return nil
    end

    if npc == nil then
        Log(
            "ERROR: InstansiateInCell returned nil."
        )

        return nil
    end

    Log("NPC created successfully.")

    return npc
end

-- ============================================================
-- NPC diagnostics
-- ============================================================

function Test.GetNPCPathingState()
    local npc = Test.runtime.npc

    if npc == nil then
        return nil
    end

    local result = {}

    result.isPathing = nil
    result.path2 = nil
    result.pathLength = nil

    pcall(
        function()
            result.isPathing = npc:isPathing()
        end
    )

    pcall(
        function()
            result.path2 = npc:getPath2()
        end
    )

    if result.path2 ~= nil then
        pcall(
            function()
                result.pathLength = result.path2:getLength()
            end
        )
    end

    return result
end

function Test.LogDiagnostics()
    local npc = Test.runtime.npc
    local navigation = Test.runtime.navigation

    if npc == nil then
        Log("DIAGNOSTIC: NPC=nil")
        return
    end

    local npcX = nil
    local npcY = nil
    local npcZ = nil

    pcall(function() npcX = npc:getX() end)
    pcall(function() npcY = npc:getY() end)
    pcall(function() npcZ = npc:getZ() end)

    local distance = nil

    if navigation ~= nil then
        local Navigation = BAO and BAO.NavigationSystem

        if Navigation ~= nil
            and Navigation.GetDistanceToTarget ~= nil then

            local okDistance, value = pcall(
                function()
                    return Navigation.GetDistanceToTarget(navigation)
                end
            )

            if okDistance then
                distance = value
            end
        end
    end

    local pathInfo = Test.GetNPCPathingState()

    Log("--------------------------------------------------")
    Log("NPC NAVIGATION DIAGNOSTIC")
    Log(
        "NPC position: " ..
        tostring(npcX) .. ", " ..
        tostring(npcY) .. ", " ..
        tostring(npcZ)
    )

    Log(
        "Target position: " ..
        tostring(Test.runtime.targetX) .. ", " ..
        tostring(Test.runtime.targetY) .. ", " ..
        tostring(Test.runtime.targetZ)
    )

    Log("Distance: " .. tostring(distance))

    if pathInfo ~= nil then
        Log(
            "npc:isPathing() = " ..
            tostring(pathInfo.isPathing)
        )

        Log(
            "npc:getPath2() = " ..
            tostring(pathInfo.path2)
        )

        Log(
            "Path length = " ..
            tostring(pathInfo.pathLength)
        )
    end

    if navigation ~= nil then
        Log(
            "Navigation state = " ..
            tostring(navigation.state)
        )

        Log(
            "Navigation result = " ..
            tostring(navigation.result)
        )

        Log(
            "Navigation pathResult = " ..
            tostring(navigation.pathResult)
        )

        Log(
            "Navigation id = " ..
            tostring(navigation.id)
        )
    else
        Log("Navigation request = nil")
    end

    Log("--------------------------------------------------")
end

-- ============================================================
-- Navigation
-- ============================================================

function Test.CreateNavigationRequest()
    local Navigation = BAO and BAO.NavigationSystem

    if Navigation == nil then
        Log("ERROR: BAO.NavigationSystem unavailable.")
        return nil
    end

    if Navigation.RequestLocation == nil then
        Log("ERROR: Navigation.RequestLocation unavailable.")
        return nil
    end

    local npc = Test.runtime.npc

    if npc == nil then
        Log("ERROR: NPC unavailable.")
        return nil
    end

    Log(
        "Creating navigation request to " ..
        tostring(Test.runtime.targetX) .. ", " ..
        tostring(Test.runtime.targetY) .. ", " ..
        tostring(Test.runtime.targetZ)
    )

    local metadata = {
        source = "BAO_NavigationNPCTest",
        testVersion = Test.VERSION,
        purpose = "real_npc_navigation"
    }

    local ok, request = pcall(
        function()
            return Navigation.RequestLocation(
                npc,
                Test.runtime.targetX,
                Test.runtime.targetY,
                Test.runtime.targetZ,
                metadata
            )
        end
    )

    if not ok then
        Log(
            "ERROR: RequestLocation failed: " ..
            tostring(request)
        )

        return nil
    end

    if request == nil then
        Log("ERROR: RequestLocation returned nil.")
        return nil
    end

    Log(
        "Navigation request created. " ..
        "id=" .. tostring(request.id)
    )

    return request
end

function Test.StartNavigation(request)
    local Navigation = BAO and BAO.NavigationSystem

    if Navigation == nil then
        Log("ERROR: NavigationSystem unavailable.")
        return false
    end

    if Navigation.Start == nil then
        Log("ERROR: Navigation.Start unavailable.")
        return false
    end

    Log(
        "Starting navigation request #" ..
        tostring(request.id)
    )

    local ok, result = pcall(
        function()
            return Navigation.Start(request)
        end
    )

    if not ok then
        Log(
            "ERROR: Navigation.Start failed: " ..
            tostring(result)
        )

        return false
    end

    if result == false then
        Log("ERROR: Navigation.Start returned false.")
        return false
    end

    Test.runtime.navigation = request
    Test.runtime.startedAt = GetTimeMs()

    Log("Navigation started successfully.")

    return true
end

-- ============================================================
-- Finish
-- ============================================================

function Test.Finish(result, detail)
    if Test.runtime.finished then
        return
    end

    Test.runtime.finished = true
    Test.runtime.finishedAt = GetTimeMs()
    Test.runtime.result = result
    Test.runtime.detail = detail

    Log("==================================================")
    Log("NAVIGATION NPC TEST FINISHED")
    Log("RESULT: " .. tostring(result))
    Log("DETAIL: " .. tostring(detail))
    Log("==================================================")
end

-- ============================================================
-- Check navigation state
-- ============================================================

function Test.CheckResult()
    if Test.runtime.finished then
        return
    end

    local npc = Test.runtime.npc
    local navigation = Test.runtime.navigation

    if npc == nil then
        return
    end

    if navigation == nil then
        return
    end

    local Navigation = BAO and BAO.NavigationSystem

    if Navigation == nil then
        return
    end

    local distance = nil

    if Navigation.GetDistanceToTarget ~= nil then
        local ok, value = pcall(
            function()
                return Navigation.GetDistanceToTarget(navigation)
            end
        )

        if ok then
            distance = value
        end
    end

    -- Distance check is the most important physical result.
    if distance ~= nil and distance <= 1.0 then
        Test.Finish(
            "SUCCESS",
            "NPC reached target. Distance=" .. tostring(distance)
        )

        return
    end

    -- Navigation state result.
    if navigation.state == Navigation.STATES.ARRIVED then
        Test.Finish(
            "SUCCESS",
            "Navigation state ARRIVED."
        )

        return
    end

    if navigation.state == Navigation.STATES.FAILED then
        Test.Finish(
            "FAILED",
            "Navigation state FAILED. PathResult=" ..
            tostring(navigation.pathResult)
        )

        return
    end

    if navigation.state == Navigation.STATES.CANCELLED then
        Test.Finish(
            "FAILED",
            "Navigation was cancelled."
        )

        return
    end

    -- Timeout.
    if Test.runtime.startedAt ~= nil then
        local elapsed =
            GetTimeMs() - Test.runtime.startedAt

        if elapsed >= Test.runtime.timeoutMs then
            Test.Finish(
                "TIMEOUT",
                "NPC did not reach target within " ..
                tostring(Test.runtime.timeoutMs) ..
                " ms."
            )

            return
        end
    end
end

-- ============================================================
-- Update
-- ============================================================

function Test.Update()
    if not Test.runtime.initialized then
        return
    end

    if Test.runtime.finished then
        return
    end

    if Test.runtime.navigation == nil then
        return
    end

    Test.CheckResult()

    if Test.runtime.finished then
        return
    end

    Test.runtime.diagnosticCounter =
        Test.runtime.diagnosticCounter + 1

    if Test.runtime.diagnosticCounter >=
        Test.runtime.diagnosticInterval then

        Test.runtime.diagnosticCounter = 0

        Test.LogDiagnostics()
    end
end

-- ============================================================
-- Start test
-- ============================================================

function Test.Start()
    if Test.runtime.initialized then
        Log("Test already initialized.")
        return
    end

    Log("==================================================")
    Log(
        "BAO Navigation NPC Test V" ..
        tostring(Test.VERSION)
    )
    Log("==================================================")

    local player = Test.GetPlayer()

    if player == nil then
        Log("ERROR: Player unavailable.")
        Log("NPC test will retry on next game start/update.")

        return
    end

    local playerX = math.floor(player:getX())
    local playerY = math.floor(player:getY())
    local playerZ = math.floor(player:getZ())

    Log(
        "Player position: " ..
        tostring(playerX) .. ", " ..
        tostring(playerY) .. ", " ..
        tostring(playerZ)
    )

    -- ========================================================
    -- Find NPC spawn square
    -- ========================================================

    local spawnSquare = Test.FindFreeSquareNear(
        playerX,
        playerY,
        playerZ,
        3,
        6
    )

    if spawnSquare == nil then
        Log("ERROR: Could not find free NPC spawn square.")
        return
    end

    local spawnX = spawnSquare:getX()
    local spawnY = spawnSquare:getY()
    local spawnZ = spawnSquare:getZ()

    Test.runtime.spawnX = spawnX
    Test.runtime.spawnY = spawnY
    Test.runtime.spawnZ = spawnZ

    Log(
        "NPC spawn square: " ..
        tostring(spawnX) .. ", " ..
        tostring(spawnY) .. ", " ..
        tostring(spawnZ)
    )

    -- ========================================================
    -- Find target square
    -- ========================================================

    local targetSquare = Test.FindFreeSquareNear(
        spawnX,
        spawnY,
        spawnZ,
        8,
        14
    )

    if targetSquare == nil then
        Log("ERROR: Could not find free target square.")
        return
    end

    local targetX = targetSquare:getX()
    local targetY = targetSquare:getY()
    local targetZ = targetSquare:getZ()

    Test.runtime.targetX = targetX
    Test.runtime.targetY = targetY
    Test.runtime.targetZ = targetZ

    Log(
        "Navigation target: " ..
        tostring(targetX) .. ", " ..
        tostring(targetY) .. ", " ..
        tostring(targetZ)
    )

    -- ========================================================
    -- Create NPC
    -- ========================================================

    local npc = Test.CreateNPC(
        spawnX,
        spawnY,
        spawnZ
    )

    if npc == nil then
        Log("ERROR: Failed to create NPC.")
        return
    end

    Test.runtime.npc = npc

    -- ========================================================
    -- Navigation initialization
    -- ========================================================

    local Navigation = BAO and BAO.NavigationSystem

    if Navigation == nil then
        Log("ERROR: NavigationSystem unavailable.")
        return
    end

    if Navigation.Initialize ~= nil then
        local ok, result = pcall(
            function()
                return Navigation.Initialize()
            end
        )

        if not ok then
            Log(
                "ERROR: Navigation.Initialize failed: " ..
                tostring(result)
            )

            return
        end
    end

    -- ========================================================
    -- Create request
    -- ========================================================

    local request = Test.CreateNavigationRequest()

    if request == nil then
        Log("ERROR: Could not create navigation request.")
        return
    end

    -- ========================================================
    -- Start navigation
    -- ========================================================

    if not Test.StartNavigation(request) then
        Log("ERROR: Could not start navigation.")
        return
    end

    Test.runtime.initialized = true

    Log("==================================================")
    Log("NPC NAVIGATION TEST ACTIVE")
    Log("==================================================")

    Test.LogDiagnostics()
end

-- ============================================================
-- Events
-- ============================================================

if Events then

    Events.OnCreatePlayer.Add(
        function(playerIndex, player)
            if player ~= nil then
                Test.SetPlayer(player)
            end
        end
    )

    Events.OnGameStart.Add(
        function()
            Log("OnGameStart received.")

            -- Delay actual creation slightly so the world,
            -- cell and player are fully initialized.
            local player = Test.GetPlayer()

            if player ~= nil then
                Test.Start()
            else
                Log("Player not ready at OnGameStart.")
            end
        end
    )

    Events.OnTick.Add(
        function()
            Test.Update()
        end
    )

else
    Log("WARNING: Events object unavailable.")
end

-- ============================================================
-- Export
-- ============================================================

BAO = BAO or {}
BAO.NavigationNPCTest = Test

Log(
    "NavigationNPCTest V" ..
    tostring(Test.VERSION) ..
    " loaded."
)