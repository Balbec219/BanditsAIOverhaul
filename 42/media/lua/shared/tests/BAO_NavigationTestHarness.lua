--[[
    BanditsAIOverhaul
    Navigation Test Harness V1.2

    Tests NavigationSystem V1.2.

    This harness validates the public NavigationSystem API
    without requiring a real character movement test.

    Real movement is tested separately by:
        BAO_NavigationMovementTest.lua
]]

local Harness = {}

Harness.VERSION = "1.2"

Harness.total = 0
Harness.passed = 0
Harness.failed = 0

------------------------------------------------------------
-- Logging
------------------------------------------------------------

local function Log(message)

    print(
        "[BAO][NavigationTestHarness V1.2] " ..
        tostring(message)
    )

end

------------------------------------------------------------
-- Test helpers
------------------------------------------------------------

local function Pass(name)

    Harness.total = Harness.total + 1
    Harness.passed = Harness.passed + 1

    Log(
        "PASS: " ..
        tostring(name)
    )

end

------------------------------------------------------------

local function Fail(name, details)

    Harness.total = Harness.total + 1
    Harness.failed = Harness.failed + 1

    Log(
        "FAIL: " ..
        tostring(name)
    )

    if details ~= nil then

        Log(
            "      " ..
            tostring(details)
        )

    end

end

------------------------------------------------------------

local function AssertTrue(name, value)

    if value then

        Pass(name)

    else

        Fail(
            name,
            "Expected true, got " ..
            tostring(value)
        )

    end

end

------------------------------------------------------------

local function AssertFalse(name, value)

    if not value then

        Pass(name)

    else

        Fail(
            name,
            "Expected false, got " ..
            tostring(value)
        )

    end

end

------------------------------------------------------------

local function AssertEqual(name, actual, expected)

    if actual == expected then

        Pass(name)

    else

        Fail(
            name,
            "Expected " ..
            tostring(expected) ..
            ", got " ..
            tostring(actual)
        )

    end

end

------------------------------------------------------------

local function AssertNotNil(name, value)

    if value ~= nil then

        Pass(name)

    else

        Fail(
            name,
            "Expected non-nil value"
        )

    end

end

------------------------------------------------------------

local function AssertNil(name, value)

    if value == nil then

        Pass(name)

    else

        Fail(
            name,
            "Expected nil value"
        )

    end

end

------------------------------------------------------------
-- Dependency
------------------------------------------------------------

local function GetNavigation()

    if BAO == nil then

        return nil

    end

    return BAO.NavigationSystem

end

------------------------------------------------------------
-- Tests
------------------------------------------------------------

local function RunTests()

    local Navigation =
        GetNavigation()

    Log("========================================")
    Log("Navigation Test Harness V1.2")
    Log("========================================")

    --------------------------------------------------------
    -- 1. Dependency
    --------------------------------------------------------

    AssertNotNil(
        "NavigationSystem dependency",
        Navigation
    )

    if Navigation == nil then

        Log("NavigationSystem unavailable.")
        Log("Tests aborted.")

        return

    end

    --------------------------------------------------------
    -- 2. Version
    --------------------------------------------------------

    AssertEqual(
        "NavigationSystem version",
        Navigation.VERSION,
        "1.2"
    )

    --------------------------------------------------------
    -- 3. States
    --------------------------------------------------------

    AssertNotNil(
        "STATES table",
        Navigation.STATES
    )

    AssertEqual(
        "STATES.IDLE",
        Navigation.STATES.IDLE,
        "IDLE"
    )

    AssertEqual(
        "STATES.REQUESTED",
        Navigation.STATES.REQUESTED,
        "REQUESTED"
    )

    AssertEqual(
        "STATES.PATHFINDING",
        Navigation.STATES.PATHFINDING,
        "PATHFINDING"
    )

    AssertEqual(
        "STATES.MOVING",
        Navigation.STATES.MOVING,
        "MOVING"
    )

    AssertEqual(
        "STATES.ARRIVED",
        Navigation.STATES.ARRIVED,
        "ARRIVED"
    )

    AssertEqual(
        "STATES.FAILED",
        Navigation.STATES.FAILED,
        "FAILED"
    )

    AssertEqual(
        "STATES.CANCELLED",
        Navigation.STATES.CANCELLED,
        "CANCELLED"
    )

    --------------------------------------------------------
    -- 4. Results
    --------------------------------------------------------

    AssertNotNil(
        "RESULTS table",
        Navigation.RESULTS
    )

    AssertEqual(
        "RESULTS.SUCCESS",
        Navigation.RESULTS.SUCCESS,
        "SUCCESS"
    )

    AssertEqual(
        "RESULTS.WORKING",
        Navigation.RESULTS.WORKING,
        "WORKING"
    )

    AssertEqual(
        "RESULTS.FAILED",
        Navigation.RESULTS.FAILED,
        "FAILED"
    )

    AssertEqual(
        "RESULTS.CANCELLED",
        Navigation.RESULTS.CANCELLED,
        "CANCELLED"
    )

    --------------------------------------------------------
    -- 5. Target types
    --------------------------------------------------------

    AssertNotNil(
        "TARGET_TYPES table",
        Navigation.TARGET_TYPES
    )

    AssertEqual(
        "TARGET_TYPES.LOCATION",
        Navigation.TARGET_TYPES.LOCATION,
        "LOCATION"
    )

    AssertEqual(
        "TARGET_TYPES.CHARACTER",
        Navigation.TARGET_TYPES.CHARACTER,
        "CHARACTER"
    )

    AssertEqual(
        "TARGET_TYPES.SOUND",
        Navigation.TARGET_TYPES.SOUND,
        "SOUND"
    )

    --------------------------------------------------------
    -- 6. Path results
    --------------------------------------------------------

    AssertNotNil(
        "PATH_RESULTS table",
        Navigation.PATH_RESULTS
    )

    AssertEqual(
        "PATH_RESULTS.WORKING",
        Navigation.PATH_RESULTS.WORKING,
        "Working"
    )

    AssertEqual(
        "PATH_RESULTS.SUCCEEDED",
        Navigation.PATH_RESULTS.SUCCEEDED,
        "Succeeded"
    )

    AssertEqual(
        "PATH_RESULTS.FAILED",
        Navigation.PATH_RESULTS.FAILED,
        "Failed"
    )

    --------------------------------------------------------
    -- 7. Location target
    --------------------------------------------------------

    local locationTarget =
        Navigation.CreateLocationTarget(
            500,
            600,
            0
        )

    AssertNotNil(
        "CreateLocationTarget",
        locationTarget
    )

    if locationTarget ~= nil then

        AssertEqual(
            "Location target type",
            locationTarget.type,
            Navigation.TARGET_TYPES.LOCATION
        )

        AssertEqual(
            "Location target X",
            locationTarget.x,
            500
        )

        AssertEqual(
            "Location target Y",
            locationTarget.y,
            600
        )

        AssertEqual(
            "Location target Z",
            locationTarget.z,
            0
        )

        AssertTrue(
            "Validate location target",
            Navigation.ValidateTarget(
                locationTarget
            )
        )

    end

    --------------------------------------------------------
    -- 8. Sound target
    --------------------------------------------------------

    local soundTarget =
        Navigation.CreateSoundTarget(
            700,
            800,
            0
        )

    AssertNotNil(
        "CreateSoundTarget",
        soundTarget
    )

    if soundTarget ~= nil then

        AssertEqual(
            "Sound target type",
            soundTarget.type,
            Navigation.TARGET_TYPES.SOUND
        )

        AssertTrue(
            "Validate sound target",
            Navigation.ValidateTarget(
                soundTarget
            )
        )

    end

    --------------------------------------------------------
    -- 9. Invalid targets
    --------------------------------------------------------

    AssertFalse(
        "Validate nil target",
        Navigation.ValidateTarget(
            nil
        )
    )

    AssertFalse(
        "Validate invalid target type",
        Navigation.ValidateTarget(
            {
                type = "INVALID"
            }
        )
    )

    AssertFalse(
        "Validate incomplete location target",
        Navigation.ValidateTarget(
            {
                type =
                    Navigation.TARGET_TYPES.LOCATION,

                x = 100,

                y = 200

                -- z missing
            }
        )
    )

    --------------------------------------------------------
    -- 10. Invalid character request
    --------------------------------------------------------

    local invalidRequest =
        Navigation.CreateRequest(
            nil,
            locationTarget,
            {
                source = "NavigationTestHarness"
            }
        )

    AssertNil(
        "CreateRequest rejects nil character",
        invalidRequest
    )

    --------------------------------------------------------
    -- 11. Helper rejects nil character
    --------------------------------------------------------

    local invalidLocationRequest =
        Navigation.RequestLocation(
            nil,
            500,
            600,
            0,
            {
                source = "NavigationTestHarness"
            }
        )

    AssertNil(
        "RequestLocation rejects nil character",
        invalidLocationRequest
    )

    --------------------------------------------------------

    local invalidSoundRequest =
        Navigation.RequestSound(
            nil,
            700,
            800,
            0,
            {
                source = "NavigationTestHarness"
            }
        )

    AssertNil(
        "RequestSound rejects nil character",
        invalidSoundRequest
    )

    --------------------------------------------------------
    -- 12. Initialize
    --------------------------------------------------------

    local initialized =
        Navigation.Initialize()

    AssertTrue(
        "Navigation.Initialize()",
        initialized
    )

    --------------------------------------------------------
    -- 13. Runtime structure
    --------------------------------------------------------

    AssertNotNil(
        "Navigation runtime",
        Navigation.runtime
    )

    if Navigation.runtime ~= nil then

        AssertTrue(
            "Runtime initialized",
            Navigation.runtime.initialized
        )

        AssertTrue(
            "Runtime attempts >= 1",
            Navigation.runtime.attempts >= 1
        )

        ----------------------------------------------------
        -- IMPORTANT:
        -- After Initialize() there is no active navigation
        -- request yet, so currentNavigation must be nil.
        --
        -- There is also no completed/previous navigation,
        -- so lastNavigation must be nil.
        ----------------------------------------------------

        AssertNil(
            "Runtime currentNavigation field",
            Navigation.runtime.currentNavigation
        )

        AssertNil(
            "Runtime lastNavigation field",
            Navigation.runtime.lastNavigation
        )

        AssertNotNil(
            "Runtime navigationHistory",
            Navigation.runtime.navigationHistory
        )

        AssertNotNil(
            "Runtime statistics",
            Navigation.runtime.statistics
        )

    end

    --------------------------------------------------------
    -- 14. Status
    --------------------------------------------------------

    local status =
        Navigation.GetStatus()

    AssertEqual(
        "GetStatus without active navigation",
        status,
        Navigation.STATES.IDLE
    )

    --------------------------------------------------------
    -- 15. Get current
    --------------------------------------------------------

    AssertNil(
        "GetCurrentNavigation without active request",
        Navigation.GetCurrentNavigation()
    )

    --------------------------------------------------------
    -- 16. Get last
    --------------------------------------------------------

    AssertNil(
        "GetLastNavigation initially",
        Navigation.GetLastNavigation()
    )

    --------------------------------------------------------
    -- 17. History
    --------------------------------------------------------

    local history =
        Navigation.GetNavigationHistory()

    AssertNotNil(
        "GetNavigationHistory",
        history
    )

    if history ~= nil then

        AssertEqual(
            "Initial history count",
            #history,
            0
        )

    end

    --------------------------------------------------------
    -- 18. Statistics
    --------------------------------------------------------

    local statistics =
        Navigation.GetStatistics()

    AssertNotNil(
        "GetStatistics",
        statistics
    )

    if statistics ~= nil then

        AssertTrue(
            "Statistics requests field",
            statistics.requests ~= nil
        )

        AssertTrue(
            "Statistics started field",
            statistics.started ~= nil
        )

        AssertTrue(
            "Statistics completed field",
            statistics.completed ~= nil
        )

        AssertTrue(
            "Statistics failed field",
            statistics.failed ~= nil
        )

        AssertTrue(
            "Statistics cancelled field",
            statistics.cancelled ~= nil
        )

        AssertEqual(
            "Initial requests",
            statistics.requests,
            0
        )

    end

    --------------------------------------------------------
    -- 19. Distance without navigation
    --------------------------------------------------------

    AssertNil(
        "GetDistanceToTarget(nil)",
        Navigation.GetDistanceToTarget(
            nil
        )
    )

    --------------------------------------------------------
    -- 20. PathFindBehavior invalid character
    --------------------------------------------------------

    AssertNil(
        "GetPathFindBehavior(nil)",
        Navigation.GetPathFindBehavior(
            nil
        )
    )

    --------------------------------------------------------
    -- 21. Cancel without active navigation
    --------------------------------------------------------

    local cancelled =
        Navigation.Cancel(
            "test_cancel"
        )

    AssertFalse(
        "Cancel without active navigation",
        cancelled
    )

    --------------------------------------------------------
    -- 22. Reset
    --------------------------------------------------------

    Navigation.Reset()

    AssertFalse(
        "Reset clears initialized",
        Navigation.runtime.initialized
    )

    AssertEqual(
        "Reset clears attempts",
        Navigation.runtime.attempts,
        0
    )

    AssertNil(
        "Reset clears current navigation",
        Navigation.runtime.currentNavigation
    )

    AssertNil(
        "Reset clears last navigation",
        Navigation.runtime.lastNavigation
    )

    AssertNotNil(
        "Reset creates navigation history",
        Navigation.runtime.navigationHistory
    )

    if Navigation.runtime.navigationHistory ~= nil then

        AssertEqual(
            "Reset clears navigation history",
            #Navigation.runtime.navigationHistory,
            0
        )

    end

    --------------------------------------------------------
    -- 23. Reinitialize
    --------------------------------------------------------

    local reinitialized =
        Navigation.Initialize()

    AssertTrue(
        "Reinitialize after reset",
        reinitialized
    )

    AssertTrue(
        "Runtime initialized after reinitialize",
        Navigation.runtime.initialized
    )

    --------------------------------------------------------
    -- Final report
    --------------------------------------------------------

    Log("========================================")
    Log("NAVIGATION TEST REPORT")
    Log("========================================")

    Log(
        "TOTAL: " ..
        tostring(Harness.total)
    )

    Log(
        "PASS: " ..
        tostring(Harness.passed)
    )

    Log(
        "FAIL: " ..
        tostring(Harness.failed)
    )

    if Harness.failed == 0 then

        Log(
            "STATUS: ALL TESTS PASSED"
        )

    else

        Log(
            "STATUS: TESTS FAILED"
        )

    end

    Log("========================================")

end

------------------------------------------------------------
-- Run after game start
------------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            RunTests()

        end
    )

else

    Log(
        "WARNING: Events.OnGameStart unavailable"
    )

end

------------------------------------------------------------
-- Export
------------------------------------------------------------

BAO = BAO or {}

BAO.NavigationTestHarness =
    Harness

Log(
    "Navigation Test Harness V1.2 loaded"
)