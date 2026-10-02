----------------------------------------------------------------
-- BanditsAIOverhaul
-- BAO Debug Server
-- Version: 1.1
--
-- Server-side backend for BAO Debug UI.
--
-- Architecture:
-- Client Debug UI
--      ↓
-- sendClientCommand
--      ↓
-- BAO Debug Server
--      ↓
-- Test NPC
--      ↓
-- BAO NavigationSystem
----------------------------------------------------------------

if not BAO then
    BAO = {}
end

local DebugServer = {}

DebugServer.VERSION = "1.1"
DebugServer.MODULE = "BAO_Debug"

DebugServer.runtime = {
    initialized = false,

    player = nil,
    npc = nil,

    spawnPosition = nil,
    targetPosition = nil,

    navigation = nil,

    status = "IDLE",
    result = nil,
    detail = "",

    startTime = nil,
    lastUpdate = nil
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function GetTimeMs()
    return os.time() * 1000
end

local function GetCell()
    local getCellFunction = _G["getCell"]

    if not getCellFunction then
        return nil
    end

    local success, cell = pcall(getCellFunction)

    if success then
        return cell
    end

    return nil
end

local function GetSquare(x, y, z)
    local cell = GetCell()

    if not cell then
        return nil
    end

    local success, square = pcall(
        cell.getGridSquare,
        cell,
        x,
        y,
        z
    )

    if success then
        return square
    end

    return nil
end

local function IsSquareFree(square)
    if not square then
        return false
    end

    local success, result = pcall(
        square.isFree,
        square
    )

    if success then
        return result == true
    end

    return false
end

local function FindFreeSquareNear(x, y, z, radius)
    radius = radius or 10

    for dx = -radius, radius do
        for dy = -radius, radius do

            local square = GetSquare(
                x + dx,
                y + dy,
                z
            )

            if square and IsSquareFree(square) then
                return square
            end
        end
    end

    return nil
end

local function GetSurvivorFactory()
    return _G["SurvivorFactory"]
end

local function GetSpecificPlayer(index)
    local getSpecificPlayerFunction = _G["getSpecificPlayer"]

    if not getSpecificPlayerFunction then
        return nil
    end

    local success, player = pcall(
        getSpecificPlayerFunction,
        index
    )

    if success then
        return player
    end

    return nil
end

----------------------------------------------------------------
-- NPC Creation
----------------------------------------------------------------

function DebugServer.CreateNPC(player)
    if not player then
        return false, "Player is nil"
    end

    local factory = GetSurvivorFactory()

    if not factory then
        return false, "SurvivorFactory unavailable"
    end

    if not factory.CreateSurvivor then
        return false, "SurvivorFactory.CreateSurvivor unavailable"
    end

    if not factory.InstansiateInCell then
        return false, "SurvivorFactory.InstansiateInCell unavailable"
    end

    local successDesc, descriptor = pcall(
        factory.CreateSurvivor
    )

    if not successDesc or not descriptor then
        return false, "Failed to create SurvivorDesc"
    end

    local x = player:getX() + 3
    local y = player:getY()
    local z = player:getZ()

    local square = FindFreeSquareNear(
        math.floor(x),
        math.floor(y),
        math.floor(z),
        10
    )

    if not square then
        return false, "No free square found"
    end

    local successNPC, npc = pcall(
        factory.InstansiateInCell,
        descriptor,
        square,
        nil
    )

    if not successNPC or not npc then
        return false, "Failed to instantiate NPC"
    end

    DebugServer.runtime.npc = npc

    DebugServer.runtime.spawnPosition = {
        x = npc:getX(),
        y = npc:getY(),
        z = npc:getZ()
    }

    DebugServer.runtime.status = "NPC_SPAWNED"
    DebugServer.runtime.result = nil
    DebugServer.runtime.detail = "Test NPC created"

    return true, "NPC created"
end

function DebugServer.SpawnTestNPC(player)
    if not player then
        return false, "Player is nil"
    end

    if DebugServer.runtime.npc then
        return false, "Test NPC already exists"
    end

    return DebugServer.CreateNPC(player)
end

----------------------------------------------------------------
-- Navigation
----------------------------------------------------------------

function DebugServer.StartNavigation(player)
    local npc = DebugServer.runtime.npc

    if not npc then
        return false, "Test NPC does not exist"
    end

    if not player then
        return false, "Player is nil"
    end

    local Navigation = BAO.NavigationSystem

    if not Navigation then
        return false, "NavigationSystem unavailable"
    end

    local targetX = player:getX()
    local targetY = player:getY()
    local targetZ = player:getZ()

    DebugServer.runtime.targetPosition = {
        x = targetX,
        y = targetY,
        z = targetZ
    }

    local target = Navigation.CreateLocationTarget(
        targetX,
        targetY,
        targetZ
    )

    if not target then
        return false, "Failed to create navigation target"
    end

    local navigation, errorMessage = Navigation.CreateRequest(
        npc,
        target,
        {
            source = "BAO_DebugUI",
            test = "NPC_NAVIGATION"
        }
    )

    if not navigation then
        return false, errorMessage or "Failed to create navigation request"
    end

    local started, startError = Navigation.Start(
        navigation
    )

    if not started then
        return false, startError or "Navigation failed to start"
    end

    DebugServer.runtime.navigation = navigation
    DebugServer.runtime.status = "NAVIGATION_STARTED"
    DebugServer.runtime.result = nil
    DebugServer.runtime.detail = "Navigation started"
    DebugServer.runtime.startTime = GetTimeMs()

    return true, "Navigation started"
end

----------------------------------------------------------------
-- Status
----------------------------------------------------------------

function DebugServer.GetStatus()
    local navigation = DebugServer.runtime.navigation

    local data = {
        version = DebugServer.VERSION,

        status = DebugServer.runtime.status,
        result = DebugServer.runtime.result,
        detail = DebugServer.runtime.detail,

        npcExists = DebugServer.runtime.npc ~= nil,
        navigationExists = navigation ~= nil
    }

    if navigation then
        data.navigationState = navigation.state
        data.navigationResult = navigation.result
        data.navigationId = navigation.id
        data.distance = navigation.distance
        data.pathResult = navigation.pathResult
    end

    local npc = DebugServer.runtime.npc

    if npc then
        data.npcX = npc:getX()
        data.npcY = npc:getY()
        data.npcZ = npc:getZ()
    end

    return data
end

function DebugServer.SendStatus(player)
    if not player then
        return
    end

    local sendServerCommandFunction =
        _G["sendServerCommand"]

    if not sendServerCommandFunction then
        return
    end

    local data = DebugServer.GetStatus()

    pcall(
        sendServerCommandFunction,
        player,
        DebugServer.MODULE,
        "status",
        data
    )
end

----------------------------------------------------------------
-- Cancel
----------------------------------------------------------------

function DebugServer.CancelNavigation(player)
    local navigation = DebugServer.runtime.navigation

    if not navigation then
        return false, "No active navigation"
    end

    local Navigation = BAO.NavigationSystem

    if not Navigation then
        return false, "NavigationSystem unavailable"
    end

    local success, errorMessage = Navigation.Cancel(
        "Debug UI cancellation"
    )

    if not success then
        return false, errorMessage or "Navigation cancellation failed"
    end

    DebugServer.runtime.status = "NAVIGATION_CANCELLED"
    DebugServer.runtime.result = "CANCELLED"
    DebugServer.runtime.detail = "Navigation cancelled"

    return true, "Navigation cancelled"
end

----------------------------------------------------------------
-- Destroy NPC
----------------------------------------------------------------

function DebugServer.DestroyNPC(player)
    local npc = DebugServer.runtime.npc

    if not npc then
        return false, "No test NPC exists"
    end

    local removed = false

    local removeFunction = npc.removeFromWorld

    if removeFunction then
        local success = pcall(
            removeFunction,
            npc
        )

        if success then
            removed = true
        end
    end

    local removeFromSquareFunction =
        npc.removeFromSquare

    if removeFromSquareFunction then
        pcall(
            removeFromSquareFunction,
            npc
        )
    end

    DebugServer.runtime.npc = nil
    DebugServer.runtime.navigation = nil
    DebugServer.runtime.spawnPosition = nil
    DebugServer.runtime.targetPosition = nil

    DebugServer.runtime.status = "IDLE"
    DebugServer.runtime.result = nil
    DebugServer.runtime.detail =
        removed and
        "Test NPC destroyed" or
        "Test NPC reference cleared"

    return true, DebugServer.runtime.detail
end

----------------------------------------------------------------
-- Navigation monitoring
----------------------------------------------------------------

function DebugServer.UpdateNavigation()
    local navigation = DebugServer.runtime.navigation

    if not navigation then
        return
    end

    local Navigation = BAO.NavigationSystem

    if not Navigation then
        return
    end

    local npc = DebugServer.runtime.npc

    if not npc then
        return
    end

    local distance = nil

    if Navigation.GetDistanceToTarget then
        local success, value = pcall(
            Navigation.GetDistanceToTarget,
            navigation
        )

        if success then
            distance = value
        end
    end

    navigation.distance = distance

    local state = navigation.state
    local result = navigation.result

    if state == Navigation.STATES.ARRIVED then

        DebugServer.runtime.status =
            "NAVIGATION_COMPLETED"

        DebugServer.runtime.result =
            "SUCCESS"

        DebugServer.runtime.detail =
            "NPC reached target"

        DebugServer.runtime.navigation = nil

        return
    end

    if state == Navigation.STATES.FAILED then

        DebugServer.runtime.status =
            "NAVIGATION_FAILED"

        DebugServer.runtime.result =
            "FAILED"

        DebugServer.runtime.detail =
            "Navigation failed"

        DebugServer.runtime.navigation = nil

        return
    end

    if state == Navigation.STATES.CANCELLED then

        DebugServer.runtime.status =
            "NAVIGATION_CANCELLED"

        DebugServer.runtime.result =
            "CANCELLED"

        DebugServer.runtime.detail =
            "Navigation cancelled"

        DebugServer.runtime.navigation = nil

        return
    end

    if result == Navigation.RESULTS.SUCCESS then

        DebugServer.runtime.status =
            "NAVIGATION_COMPLETED"

        DebugServer.runtime.result =
            "SUCCESS"

        DebugServer.runtime.detail =
            "Navigation succeeded"

        DebugServer.runtime.navigation = nil

        return
    end

    DebugServer.runtime.lastUpdate =
        GetTimeMs()

    -- Safety timeout:
    -- 60 seconds.
    if DebugServer.runtime.startTime then

        local elapsed =
            GetTimeMs() -
            DebugServer.runtime.startTime

        if elapsed > 60000 then

            pcall(
                Navigation.Cancel,
                "Debug navigation timeout"
            )

            DebugServer.runtime.status =
                "NAVIGATION_TIMEOUT"

            DebugServer.runtime.result =
                "TIMEOUT"

            DebugServer.runtime.detail =
                "Navigation timeout"

            DebugServer.runtime.navigation = nil
        end
    end
end

----------------------------------------------------------------
-- Main update
----------------------------------------------------------------

function DebugServer.Update()
    if not DebugServer.runtime.initialized then
        return
    end

    DebugServer.UpdateNavigation()
end

----------------------------------------------------------------
-- Client commands
----------------------------------------------------------------

function DebugServer.OnClientCommand(
    module,
    command,
    player,
    args
)

    if module ~= DebugServer.MODULE then
        return
    end

    if not player then
        return
    end

    args = args or {}

    -- All world mutation is server-authorized; state requests are read-only.
    local function Reply(result, broadcast)
        if broadcast then sendServerCommand(DebugServer.MODULE, "world_status", result)
        else sendServerCommand(player, DebugServer.MODULE, "world_status", result) end
    end
    if command ~= "world_state" and (_G["isServer"] and isServer())
        and player:getAccessLevel() ~= "admin" then
        Reply({ success = false, reason = "admin_required" })
        return
    end
    if command == "world_spawn" or command == "spawn_npc" or command == "world_remove"
        or command == "destroy_npc" or command == "world_state" then
        local adapter = BAO.NPCWorldAdapter
        if not adapter then Reply({success=false, reason="adapter_unavailable"}); return end
        local success, reason, spawned, removed = true, "state", 0, {}
        if command == "world_spawn" or command == "spawn_npc" then
            local target = { count = args.count, radius = args.radius }
            if args.x ~= nil or args.y ~= nil or args.z ~= nil then
                for _, key in ipairs({"x", "y", "z"}) do
                    local value = args[key]
                    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
                        Reply({success=false, reason="invalid_target"}); return
                    end
                end
                if math.abs(args.x - player:getX()) > 50 or math.abs(args.y - player:getY()) > 50
                    or math.floor(args.z) ~= math.floor(player:getZ()) then
                    Reply({success=false, reason="target_too_far"}); return
                end
                target.x, target.y, target.z = args.x, args.y, args.z
            end
            local ok
            ok, success, reason, spawned = pcall(adapter.SpawnTestNPC, player, target)
            if not ok then success, reason, spawned = false, "spawn_exception", 0 end
        elseif command ~= "world_state" then
            local ok
            ok, success, reason, removed = pcall(adapter.RemoveTestNPC)
            if not ok then success, reason, removed = false, "cleanup_exception", {} end
        end
        Reply({ success = success, reason = reason, spawned = spawned, removed = removed,
            snapshot = true, active = adapter.GetSnapshot() }, command ~= "world_state")
        print("[BAO][DebugServer] " .. command .. " success=" .. tostring(success)
            .. " reason=" .. tostring(reason) .. " spawned=" .. tostring(spawned))
        return
    end

    if command == "spawn_npc" then

        local success, message =
            DebugServer.SpawnTestNPC(player)

        DebugServer.runtime.detail =
            message

        DebugServer.SendStatus(player)

        return
    end

    if command == "start_navigation" then

        local success, message =
            DebugServer.StartNavigation(player)

        DebugServer.runtime.detail =
            message

        DebugServer.SendStatus(player)

        return
    end

    if command == "get_status" then

        DebugServer.SendStatus(player)

        return
    end

    if command == "cancel_navigation" then

        local success, message =
            DebugServer.CancelNavigation(player)

        DebugServer.runtime.detail =
            message

        DebugServer.SendStatus(player)

        return
    end

    if command == "destroy_npc" then

        local success, message =
            DebugServer.DestroyNPC(player)

        DebugServer.runtime.detail =
            message

        DebugServer.SendStatus(player)

        return
    end
end

----------------------------------------------------------------
-- Initialization
----------------------------------------------------------------

function DebugServer.Initialize()
    if DebugServer.runtime.initialized then
        return
    end

    DebugServer.runtime.initialized = true
    DebugServer.runtime.status = "READY"

    print(
        "[BAO][DebugServer] Version " ..
        DebugServer.VERSION ..
        " initialized"
    )
end

----------------------------------------------------------------
-- Events
----------------------------------------------------------------

local EventsTable = _G["Events"]

if EventsTable then

    if EventsTable.OnClientCommand then

        EventsTable.OnClientCommand.Add(
            DebugServer.OnClientCommand
        )

    end

    if EventsTable.OnGameStart then

        EventsTable.OnGameStart.Add(
            DebugServer.Initialize
        )

    end

    if EventsTable.OnTick then

        EventsTable.OnTick.Add(
            DebugServer.Update
        )

    end
end

----------------------------------------------------------------
-- Export
----------------------------------------------------------------

BAO.DebugServer = DebugServer

print(
    "[BAO][DebugServer] V" ..
    DebugServer.VERSION ..
    " loaded"
)
