--[[
    BanditsAIOverhaul
    Navigation NPC Test Harness V1.0

    Validates the API required by:

        BAO_NavigationNPCTest.lua

    This harness does NOT create or move an NPC.

    It only verifies that the NavigationSystem exposes
    the required functionality for a real NPC movement test.
]]

local Harness = {}

Harness.VERSION = "1.0"

Harness.total = 0
Harness.passed = 0
Harness.failed = 0

------------------------------------------------------------
-- Logging
------------------------------------------------------------

local function Log(message)

    print(
        "[BAO][NavigationNPCTestHarness V1.0] " ..
        tostring(message)
    )

end

------------------------------------------------------------
-- Assertions
------------------------------------------------------------

local function Pass(name)

    Harness.total =
        Harness.total + 1

    Harness.passed =
        Harness.passed + 1

    Log(
        "PASS: " ..
        tostring(name)
    )

end

------------------------------------------------------------

local function Fail(name, details)

    Harness.total =
        Harness.total + 1

    Harness.failed =
        Harness.failed + 1

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
-- Navigation dependency
------------------------------------------------------------

local function GetNavigation()

    if BAO == nil then

        return nil

    end

    return BAO.NavigationSystem

end

------------------------------------------------------------
-- Test
------------------------------------------------------------

local function RunTests()

    local Navigation =
        GetNavigation()

    Log("========================================")
    Log("Navigation NPC Test Harness V1.0")
    Log("========================================")

    --------------------------------------------------------
    -- 1. Navigation dependency
    --------------------------------------------------------

    AssertNotNil(
        "NavigationSystem dependency",
        Navigation
    )

    if Navigation == nil then

        Log(
            "NavigationSystem unavailable."
        )

        Log(
            "Tests aborted."
        )

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
    -- 3. Required states
    --------------------------------------------------------

    AssertNotNil(
        "STATES table",
        Navigation.STATES
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

    --------------------------------------------------------
    -- 4. Required target type
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

    --------------------------------------------------------
    -- 5. Required methods
    --------------------------------------------------------

    AssertTrue(
        "RequestLocation function",
        type(Navigation.RequestLocation) == "function"
    )

    AssertTrue(
        "CreateRequest function",
        type(Navigation.CreateRequest) == "function"
    )

    AssertTrue(
        "Start function",
        type(Navigation.Start) == "function"
    )

    AssertTrue(
        "GetCurrentNavigation function",
        type(Navigation.GetCurrentNavigation) == "function"
    )

    AssertTrue(
        "GetDistanceToTarget function",
        type(Navigation.GetDistanceToTarget) == "function"
    )

    --------------------------------------------------------
    -- 6. Target creation
    --------------------------------------------------------

    local target =
        Navigation.CreateLocationTarget(
            100,
            200,
            0
        )

    AssertNotNil(
        "CreateLocationTarget",
        target
    )

    if target ~= nil then

        AssertEqual(
            "NPC target type",
            target.type,
            Navigation.TARGET_TYPES.LOCATION
        )

        AssertEqual(
            "NPC target X",
            target.x,
            100
        )

        AssertEqual(
            "NPC target Y",
            target.y,
            200
        )

        AssertEqual(
            "NPC target Z",
            target.z,
            0
        )

        AssertTrue(
            "NPC target validation",
            Navigation.ValidateTarget(
                target
            )
        )

    end

    --------------------------------------------------------
    -- 7. Navigation initialization
    --------------------------------------------------------

    local initialized =
        Navigation.Initialize()

    AssertTrue(
        "Navigation.Initialize()",
        initialized
    )

    --------------------------------------------------------
    -- 8. Runtime
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
    -- 9. Diagnostics required by NPC test
    --------------------------------------------------------

    AssertTrue(
        "GetPathFindBehavior function",
        type(Navigation.GetPathFindBehavior) == "function"
    )

    --------------------------------------------------------
    -- Final report
    --------------------------------------------------------

    Log("========================================")
    Log("NPC NAVIGATION TEST HARNESS REPORT")
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

BAO.NavigationNPCTestHarness =
    Harness

Log(
    "Navigation NPC Test Harness V1.0 loaded"
)
