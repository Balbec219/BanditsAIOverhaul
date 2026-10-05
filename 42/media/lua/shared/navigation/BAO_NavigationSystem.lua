-- Each instance closes over its own dependencies and state; default instance keeps legacy events.
local function CreateInstance(BAO, Events)
local print = BAO.InstanceLog or print
-- BanditsAIOverhaul Navigation V1.3: request once, observe engine-owned movement.
-- Never calls PathFindBehavior2:update() or changes character coordinates.
local NavigationSystem = { VERSION = "1.3", PollInterval = 0.1 }
NavigationSystem.STATES = {
    IDLE = "IDLE", REQUESTED = "REQUESTED", PATHFINDING = "PATHFINDING",
    MOVING = "MOVING", ARRIVED = "ARRIVED", FAILED = "FAILED", CANCELLED = "CANCELLED"
}
NavigationSystem.RESULTS = { SUCCESS = "SUCCESS", WORKING = "WORKING", FAILED = "FAILED", CANCELLED = "CANCELLED" }
NavigationSystem.TARGET_TYPES = { LOCATION = "LOCATION", CHARACTER = "CHARACTER", SOUND = "SOUND" }
NavigationSystem.PATH_RESULTS = { WORKING = "Working", SUCCEEDED = "Succeeded", FAILED = "Failed" }

local function NewRuntime()
    return {
        initialized = false, attempts = 0, currentNavigation = nil, lastNavigation = nil,
        navigationHistory = {}, maxHistory = 20, nextNavigationId = 1, accumulated = 0,
        statistics = { requests = 0, started = 0, completed = 0, failed = 0,
            cancelled = 0, polls = 0, positionReads = 0, pathRequests = 0, diagnosticReads = 0 }
    }
end
NavigationSystem.runtime = NewRuntime()
local function Log(message) print("[BAO][NavigationSystem] " .. tostring(message)) end
local function Now()
    if _G["getTimestampMs"] then return _G["getTimestampMs"]() end
    return os.time() * 1000
end
local function Number(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end
local function Position(character)
    if character == nil then return nil end
    local kind = type(character)
    if kind ~= "table" and kind ~= "userdata" then return nil end
    local ok, x, y, z = pcall(function()
        if not character.getX or not character.getY or not character.getZ then return nil end
        return character:getX(), character:getY(), character:getZ()
    end)
    NavigationSystem.runtime.statistics.positionReads = NavigationSystem.runtime.statistics.positionReads + 1
    if ok and Number(x) and Number(y) and Number(z) then return x, y, z end
    return nil
end
function NavigationSystem.IsValidCharacter(character) return Position(character) ~= nil end
function NavigationSystem.ValidateTarget(target)
    if type(target) ~= "table" then return false end
    if target.type == "CHARACTER" then return NavigationSystem.IsValidCharacter(target.character) end
    return (target.type == "LOCATION" or target.type == "SOUND")
        and Number(target.x) and Number(target.y) and Number(target.z)
end
function NavigationSystem.CreateLocationTarget(x, y, z) return { type = "LOCATION", x = x, y = y, z = z } end
function NavigationSystem.CreateSoundTarget(x, y, z) return { type = "SOUND", x = x, y = y, z = z } end
function NavigationSystem.CreateCharacterTarget(character)
    if not NavigationSystem.IsValidCharacter(character) then return nil end
    return { type = "CHARACTER", character = character }
end
local function TargetPosition(target)
    if target.type == "CHARACTER" then return Position(target.character) end
    if Number(target.x) and Number(target.y) and Number(target.z) then return target.x, target.y, target.z end
end
function NavigationSystem.CreateRequest(character, target, metadata)
    if not NavigationSystem.IsValidCharacter(character) or not NavigationSystem.ValidateTarget(target) then
        return nil
    end
    metadata = metadata or {}
    local timeout = metadata.timeoutSeconds or 30
    local stuckTimeout = metadata.stuckSeconds or 5
    local radius = metadata.arrivalRadius or 0.5
    if not Number(timeout) or timeout <= 0 or not Number(stuckTimeout) or stuckTimeout <= 0
        or not Number(radius) or radius < 0 or radius > 1 then return nil end
    local runtime = NavigationSystem.runtime
    -- Own a target snapshot; external edits must not change the requested path.
    local request = {
        id = (BAO.InstancePrefix or "") .. "bao_navigation_" .. tostring(runtime.nextNavigationId), character = character,
        target = { type = target.type, x = target.x, y = target.y, z = target.z, character = target.character },
        metadata = metadata, state = "REQUESTED", result = "WORKING", createdAt = Now(),
        elapsed = 0, idleElapsed = 0, timeoutSeconds = timeout, stuckSeconds = stuckTimeout,
        arrivalRadius = radius, diagnostics = { coordinateChanged = false }, diagnosticElapsed = 0
    }
    -- The B42 character API takes integer sound coordinates (III), not floats.
    if request.target.type == "SOUND" then
        request.target.x, request.target.y, request.target.z = math.floor(target.x), math.floor(target.y), math.floor(target.z)
    end
    runtime.nextNavigationId = runtime.nextNavigationId + 1
    runtime.statistics.requests = runtime.statistics.requests + 1
    return request
end
function NavigationSystem.RequestLocation(character, x, y, z, metadata)
    return NavigationSystem.CreateRequest(character, NavigationSystem.CreateLocationTarget(x, y, z), metadata)
end
function NavigationSystem.RequestCharacter(character, targetCharacter, metadata)
    return NavigationSystem.CreateRequest(character, NavigationSystem.CreateCharacterTarget(targetCharacter), metadata)
end
function NavigationSystem.RequestSound(character, x, y, z, metadata)
    return NavigationSystem.CreateRequest(character, NavigationSystem.CreateSoundTarget(x, y, z), metadata)
end
function NavigationSystem.GetDistanceToTarget(navigation)
    if not navigation then return nil end
    local x, y = Position(navigation.character)
    local tx, ty = TargetPosition(navigation.target)
    if not x or not tx then return nil end
    return math.sqrt((x - tx) ^ 2 + (y - ty) ^ 2)
end
function NavigationSystem.GetPathFindBehavior(character)
    if not character then return nil end
    local ok, behavior = pcall(function()
        if character.getPathFindBehavior2 then return character:getPathFindBehavior2() end
    end)
    if ok then return behavior end
end

-- B42.21 vanilla: Vehicles/TimedActions/ISPathFindAction.lua stop()/perform().
-- Cache supported methods at Start; do not probe missing Java methods every tick.
local function StopPath(navigation)
    if not navigation.pathIssued or navigation.pathStopped then return true end
    if navigation.metadata.clientDriven then navigation.pathStopped = true; return true end
    local ok, reason = pcall(function()
        navigation.behavior:cancel()
        navigation.character:setPath2(nil)
    end)
    if not ok then
        navigation.stopReason = tostring(reason)
        return false
    end
    navigation.pathStopped = true
    return true
end
local function Finish(navigation, state, reason)
    local runtime = NavigationSystem.runtime
    if navigation._finished then return false end
    if not StopPath(navigation) then
        -- Keep ownership until cleanup can succeed; do not start another path.
        navigation.reason = "path_stop_failed"
        return false
    end
    navigation.state = state
    navigation.reason = reason
    navigation.result = state == "ARRIVED" and "SUCCESS" or (state == "CANCELLED" and "CANCELLED" or "FAILED")
    navigation.completedAt = Now()
    navigation._finished = true
    if state == "CANCELLED" then navigation.cancelReason = reason end
    local key = state == "ARRIVED" and "completed" or (state == "CANCELLED" and "cancelled" or "failed")
    runtime.statistics[key] = runtime.statistics[key] + 1
    runtime.lastNavigation = navigation
    table.insert(runtime.navigationHistory, navigation)
    if #runtime.navigationHistory > runtime.maxHistory then table.remove(runtime.navigationHistory, 1) end
    if runtime.currentNavigation == navigation then runtime.currentNavigation = nil end
    Log(navigation.id .. " " .. state .. " reason=" .. tostring(reason))
    return true
end

function NavigationSystem.Start(navigation)
    local runtime = NavigationSystem.runtime
    if not navigation or navigation.state ~= "REQUESTED" or navigation._finished then return false, "invalid_request" end
    if runtime.currentNavigation then return false, "navigation_busy" end
    -- The player pathfinding lifecycle is a timed-action concern, not this NPC observer.
    if type(navigation.character) == "userdata" and _G["instanceof"]
        and _G["instanceof"](navigation.character, "IsoPlayer") then
        Finish(navigation, "FAILED", "player_navigation_not_supported")
        return false, navigation.reason
    end
    local x, y, z = Position(navigation.character)
    if not x or not NavigationSystem.ValidateTarget(navigation.target) then
        Finish(navigation, "FAILED", "invalid_character_or_target")
        return false, navigation.reason
    end
    navigation.behavior = NavigationSystem.GetPathFindBehavior(navigation.character)
    local character, target, behavior = navigation.character, navigation.target, navigation.behavior
    local method = target.type == "CHARACTER" and "pathToCharacter"
        or (target.type == "SOUND" and "pathToSound" or "pathToLocationF")
    if not behavior or not behavior.cancel or not character.setPath2 or not character[method] then
        Finish(navigation, "FAILED", "navigation_api_unavailable")
        return false, navigation.reason
    end
    navigation.lastX, navigation.lastY, navigation.lastZ = x, y, z
    navigation.progressX, navigation.progressY, navigation.progressZ = x, y, z
    navigation.startedAt = Now()
    runtime.currentNavigation = navigation
    runtime.accumulated = 0
    navigation.pathIssued = true -- Even a rejected request may need engine cleanup.
    runtime.statistics.pathRequests = runtime.statistics.pathRequests + 1
    if navigation.metadata.clientDriven then
        navigation.state = "PATHFINDING"
        runtime.statistics.started = runtime.statistics.started + 1
        return true
    end
    local ok, accepted = pcall(function()
        if target.type == "CHARACTER" then return character:pathToCharacter(target.character) end
        return character[method](character, target.x, target.y, target.z)
    end)
    if not ok or accepted == false then
        Finish(navigation, "FAILED", "path_request_failed")
        return false, navigation.reason
    end
    navigation.state = "PATHFINDING"
    runtime.statistics.started = runtime.statistics.started + 1
    Log("Navigation started: " .. navigation.id)
    return true
end

-- Explicit deltaSeconds is useful to callers/tests. OnTick supplies active game delta.
function NavigationSystem.Update(deltaSeconds)
    local runtime = NavigationSystem.runtime
    local navigation = runtime.currentNavigation
    if not navigation then return end
    local delta = deltaSeconds or NavigationSystem.PollInterval
    if not Number(delta) or delta < 0 then return end
    runtime.statistics.polls = runtime.statistics.polls + 1
    navigation.elapsed = navigation.elapsed + delta
    navigation.idleElapsed = navigation.idleElapsed + delta
    local x, y, z = Position(navigation.character)
    local tx, ty, tz = TargetPosition(navigation.target)
    if not x or not tx then return Finish(navigation, "FAILED", "invalid_character_or_target") end
    local dx, dy = x - tx, y - ty
    local distanceSquared = dx * dx + dy * dy
    navigation.distance = math.sqrt(distanceSquared)
    -- XY coincidence on another floor must never report arrival.
    if math.floor(z) == math.floor(tz) and distanceSquared <= navigation.arrivalRadius ^ 2 then
        return Finish(navigation, "ARRIVED", "arrived")
    end
    local changed = math.abs(x - navigation.lastX) > 0.01 or math.abs(y - navigation.lastY) > 0.01
        or math.abs(z - navigation.lastZ) > 0.01
    navigation.diagnostics.coordinateChanged = changed
    navigation.lastX, navigation.lastY, navigation.lastZ = x, y, z
    -- Accumulate small steps, but don't treat sub-tile jitter as sustained progress.
    if (x - navigation.progressX) ^ 2 + (y - navigation.progressY) ^ 2 >= 0.01
        or math.abs(z - navigation.progressZ) >= 0.1 then
        navigation.idleElapsed = 0
        navigation.progressX, navigation.progressY, navigation.progressZ = x, y, z
    end
    if navigation.elapsed >= navigation.timeoutSeconds then return Finish(navigation, "FAILED", "navigation_timeout") end
    if navigation.idleElapsed >= navigation.stuckSeconds then return Finish(navigation, "FAILED", "navigation_stuck") end
    navigation.state = changed and "MOVING" or "PATHFINDING"
    -- Optional debug probes: at most once a second, never by default.
    if navigation.metadata.diagnostics == true then
        navigation.diagnosticElapsed = navigation.diagnosticElapsed + delta
        if navigation.diagnosticElapsed >= 1 then
            navigation.diagnosticElapsed = 0
            runtime.statistics.diagnosticReads = runtime.statistics.diagnosticReads + 1
            local behavior = navigation.behavior
            if behavior.isMovingUsingPathFind then
                navigation.diagnostics.movingUsingPathFind = behavior:isMovingUsingPathFind()
            end
        end
    end
end
function NavigationSystem.Cancel(reason, expectedNavigation)
    local navigation = NavigationSystem.runtime.currentNavigation
    if not navigation or (expectedNavigation and navigation ~= expectedNavigation) then return false end
    return Finish(navigation, "CANCELLED", reason or "cancelled")
end
function NavigationSystem.GetCurrentNavigation() return NavigationSystem.runtime.currentNavigation end
function NavigationSystem.GetLastNavigation() return NavigationSystem.runtime.lastNavigation end
function NavigationSystem.GetNavigationHistory() return NavigationSystem.runtime.navigationHistory end
function NavigationSystem.GetStatistics() return NavigationSystem.runtime.statistics end
function NavigationSystem.GetStatus()
    local navigation = NavigationSystem.runtime.currentNavigation
    return navigation and navigation.state or "IDLE"
end
function NavigationSystem.Reset()
    if NavigationSystem.runtime and NavigationSystem.runtime.currentNavigation then
        if not NavigationSystem.Cancel("navigation_reset") then return false end
    end
    NavigationSystem.runtime = NewRuntime()
    return true
end
function NavigationSystem.Initialize()
    local runtime = NavigationSystem.runtime
    if runtime.initialized then return true end
    runtime.initialized = true
    runtime.attempts = runtime.attempts + 1
    Log("NavigationSystem initialized. Version=" .. NavigationSystem.VERSION)
    return true
end
function NavigationSystem.OnTick()
    local runtime = NavigationSystem.runtime
    if not runtime.currentNavigation then return end
    -- Vanilla B42.21 ISRestAction uses this game delta; paused time is not a timeout.
    local delta = _G["getGameTime"] and _G["getGameTime"]():getRealworldSecondsSinceLastUpdate() or (1 / 60)
    if not Number(delta) or delta <= 0 then return end
    runtime.accumulated = runtime.accumulated + math.min(delta, 0.25)
    if runtime.accumulated < NavigationSystem.PollInterval then return end
    local elapsed = runtime.accumulated
    runtime.accumulated = 0
    NavigationSystem.Update(elapsed)
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(NavigationSystem.Initialize) end
if Events and Events.OnTick then Events.OnTick.Add(NavigationSystem.OnTick) end
BAO = BAO or {}
BAO.NavigationSystem = NavigationSystem
Log("NavigationSystem V1.3 loaded")

NavigationSystem.CreateInstance = function(context) return CreateInstance(context, nil) end
return NavigationSystem
end

BAO = BAO or {}
CreateInstance(BAO, Events)
