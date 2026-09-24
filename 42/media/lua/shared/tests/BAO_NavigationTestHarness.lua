--[[
    BanditsAIOverhaul
    Navigation Test Harness V1.0

    Tests Navigation System without requiring
    a live NPC for every test.

    Build target:
        Project Zomboid Build 42.20
]]

local Harness = {}

Harness.VERSION = "1.0"

local total = 0
local pass = 0
local fail = 0

--------------------------------------------------
-- LOG
--------------------------------------------------

local function Log(message)
    print("[BAO][BAO_NavigationTestHarness] "
        .. tostring(message))
end

--------------------------------------------------
-- ASSERT
--------------------------------------------------

local function Test(name, condition)

    total = total + 1

    if condition then

        pass = pass + 1

        Log(
            "[PASS] "
            .. tostring(name)
        )

    else

        fail = fail + 1

        Log(
            "[FAIL] "
            .. tostring(name)
        )

    end

end

--------------------------------------------------
-- GET SYSTEM
--------------------------------------------------

local function GetNavigationSystem()

    if BAO and BAO.NavigationSystem then
        return BAO.NavigationSystem
    end

    return nil
end

--------------------------------------------------
-- TEST
--------------------------------------------------

function Harness.Run()

    Log("==============================")
    Log("Navigation System Test V"
        .. Harness.VERSION)
    Log("==============================")

    local Navigation =
        GetNavigationSystem()

    --------------------------------------------------
    -- 1. DEPENDENCY
    --------------------------------------------------

    Test(
        "NavigationSystem available",
        Navigation ~= nil
    )

    if not Navigation then

        Log("NavigationSystem unavailable")
        Log("TEST ABORTED")

        return

    end

    --------------------------------------------------
    -- 2. VERSION
    --------------------------------------------------

    Test(
        "Version is 1.0",
        Navigation.VERSION == "1.0"
    )

    --------------------------------------------------
    -- 3. STATES
    --------------------------------------------------

    Test(
        "IDLE state exists",
        Navigation.STATE.IDLE == "idle"
    )

    Test(
        "PATHFINDING state exists",
        Navigation.STATE.PATHFINDING == "pathfinding"
    )

    Test(
        "MOVING state exists",
        Navigation.STATE.MOVING == "moving"
    )

    Test(
        "ARRIVED state exists",
        Navigation.STATE.ARRIVED == "arrived"
    )

    Test(
        "FAILED state exists",
        Navigation.STATE.FAILED == "failed"
    )

    Test(
        "CANCELLED state exists",
        Navigation.STATE.CANCELLED == "cancelled"
    )

    --------------------------------------------------
    -- 4. TARGET TYPES
    --------------------------------------------------

    Test(
        "LOCATION target exists",
        Navigation.TARGET_TYPE.LOCATION == "location"
    )

    Test(
        "CHARACTER target exists",
        Navigation.TARGET_TYPE.CHARACTER == "character"
    )

    Test(
        "SOUND target exists",
        Navigation.TARGET_TYPE.SOUND == "sound"
    )

    --------------------------------------------------
    -- 5. LOCATION TARGET
    --------------------------------------------------

    local locationTarget =
        Navigation.CreateLocationTarget(
            100,
            200,
            0
        )

    Test(
        "Location target created",
        locationTarget ~= nil
    )

    if locationTarget then

        Test(
            "Location X correct",
            locationTarget.x == 100
        )

        Test(
            "Location Y correct",
            locationTarget.y == 200
        )

        Test(
            "Location Z correct",
            locationTarget.z == 0
        )

    else

        Test(
            "Location X correct",
            false
        )

        Test(
            "Location Y correct",
            false
        )

        Test(
            "Location Z correct",
            false
        )

    end

    --------------------------------------------------
    -- 6. SOUND TARGET
    --------------------------------------------------

    local soundTarget =
        Navigation.CreateSoundTarget(
            300,
            400,
            0
        )

    Test(
        "Sound target created",
        soundTarget ~= nil
    )

    if soundTarget then

        Test(
            "Sound X correct",
            soundTarget.x == 300
        )

        Test(
            "Sound Y correct",
            soundTarget.y == 400
        )

        Test(
            "Sound Z correct",
            soundTarget.z == 0
        )

    else

        Test(
            "Sound X correct",
            false
        )

        Test(
            "Sound Y correct",
            false
        )

        Test(
            "Sound Z correct",
            false
        )

    end

    --------------------------------------------------
    -- 7. TARGET VALIDATION
    --------------------------------------------------

    local validLocation =
        Navigation.ValidateTarget(
            Navigation.TARGET_TYPE.LOCATION,
            locationTarget
        )

    Test(
        "Valid location accepted",
        validLocation == true
    )

    local invalidLocation =
        Navigation.ValidateTarget(
            Navigation.TARGET_TYPE.LOCATION,
            {
                x = 100,
                y = 200
            }
        )

    Test(
        "Invalid location rejected",
        invalidLocation == false
    )

    local invalidType =
        Navigation.ValidateTarget(
            "unknown_target",
            locationTarget
        )

    Test(
        "Unknown target rejected",
        invalidType == false
    )

    --------------------------------------------------
    -- 8. REQUEST CREATION
    --------------------------------------------------

    local request =
        Navigation.CreateRequest(
            nil,
            Navigation.TARGET_TYPE.LOCATION,
            locationTarget,
            {
                source = "NavigationTestHarness"
            }
        )

    Test(
        "Navigation request created",
        request ~= nil
    )

    if request then

        Test(
            "Request has ID",
            request.navigationId ~= nil
        )

        Test(
            "Request state is REQUESTED",
            request.state ==
                Navigation.STATE.REQUESTED
        )

        Test(
            "Request result initially nil",
            request.result == nil
        )

        Test(
            "Request metadata preserved",
            request.metadata ~= nil
            and request.metadata.source ==
                "NavigationTestHarness"
        )

    else

        Test(
            "Request has ID",
            false
        )

        Test(
            "Request state is REQUESTED",
            false
        )

        Test(
            "Request result initially nil",
            false
        )

        Test(
            "Request metadata preserved",
            false
        )

    end

    --------------------------------------------------
    -- 9. LOCATION REQUEST HELPER
    --------------------------------------------------

    local locationRequest =
        Navigation.RequestLocation(
            nil,
            500,
            600,
            0,
            {
                source = "helper_test"
            }
        )

    Test(
        "RequestLocation works",
        locationRequest ~= nil
    )

    if locationRequest then

        Test(
            "RequestLocation target type correct",
            locationRequest.targetType ==
                Navigation.TARGET_TYPE.LOCATION
        )

        Test(
            "RequestLocation coordinates correct",
            locationRequest.target ~= nil
            and locationRequest.target.x == 500
            and locationRequest.target.y == 600
            and locationRequest.target.z == 0
        )

    else

        Test(
            "RequestLocation target type correct",
            false
        )

        Test(
            "RequestLocation coordinates correct",
            false
        )

    end

    --------------------------------------------------
    -- 10. SOUND REQUEST HELPER
    --------------------------------------------------

    local soundRequest =
        Navigation.RequestSound(
            nil,
            700,
            800,
            0
        )

    Test(
        "RequestSound works",
        soundRequest ~= nil
    )

    if soundRequest then

        Test(
            "RequestSound target type correct",
            soundRequest.targetType ==
                Navigation.TARGET_TYPE.SOUND
        )

    else

        Test(
            "RequestSound target type correct",
            false
        )

    end

    --------------------------------------------------
    -- 11. CHARACTER REQUEST VALIDATION
    --------------------------------------------------

    local invalidCharacterRequest =
        Navigation.RequestCharacter(
            nil,
            nil
        )

    Test(
        "Invalid character request rejected",
        invalidCharacterRequest == nil
    )

    --------------------------------------------------
    -- 12. INITIALIZATION
    --------------------------------------------------

    local initialized =
        Navigation.Initialize()

    Test(
        "Initialize returns true",
        initialized == true
    )

    Test(
        "System initialized",
        Navigation.initialized == true
    )

    --------------------------------------------------
    -- 13. STATUS
    --------------------------------------------------

    local status =
        Navigation.GetStatus()

    Test(
        "Status available",
        status ~= nil
    )

    if status then

        Test(
            "Status version correct",
            status.version == "1.0"
        )

        Test(
            "Status initialized",
            status.initialized == true
        )

    else

        Test(
            "Status version correct",
            false
        )

        Test(
            "Status initialized",
            false
        )

    end

    --------------------------------------------------
    -- 14. HISTORY
    --------------------------------------------------

    local history =
        Navigation.GetNavigationHistory()

    Test(
        "History available",
        history ~= nil
    )

    Test(
        "History is table",
        type(history) == "table"
    )

    --------------------------------------------------
    -- 15. STATISTICS
    --------------------------------------------------

    local statistics =
        Navigation.GetStatistics()

    Test(
        "Statistics available",
        statistics ~= nil
    )

    if statistics then

        Test(
            "Statistics requests available",
            statistics.requests ~= nil
        )

        Test(
            "Statistics started available",
            statistics.started ~= nil
        )

        Test(
            "Statistics completed available",
            statistics.completed ~= nil
        )

        Test(
            "Statistics failed available",
            statistics.failed ~= nil
        )

        Test(
            "Statistics cancelled available",
            statistics.cancelled ~= nil
        )

    else

        Test(
            "Statistics requests available",
            false
        )

        Test(
            "Statistics started available",
            false
        )

        Test(
            "Statistics completed available",
            false
        )

        Test(
            "Statistics failed available",
            false
        )

        Test(
            "Statistics cancelled available",
            false
        )

    end

    --------------------------------------------------
    -- 16. CANCEL
    --------------------------------------------------

    local cancelRequest =
        Navigation.RequestLocation(
            nil,
            900,
            1000,
            0
        )

    Test(
        "Cancel request created",
        cancelRequest ~= nil
    )

    if cancelRequest then

        local cancelled =
            Navigation.Cancel(
                cancelRequest,
                "test_cancel"
            )

        Test(
            "Cancel returns true",
            cancelled == true
        )

        Test(
            "Cancelled state correct",
            cancelRequest.state ==
                Navigation.STATE.CANCELLED
        )

        Test(
            "Cancelled result correct",
            cancelRequest.result ==
                Navigation.RESULT.CANCELLED
        )

        Test(
            "Cancel reason stored",
            cancelRequest.failureReason ==
                "test_cancel"
        )

    else

        Test(
            "Cancel returns true",
            false
        )

        Test(
            "Cancelled state correct",
            false
        )

        Test(
            "Cancelled result correct",
            false
        )

        Test(
            "Cancel reason stored",
            false
        )

    end

    --------------------------------------------------
    -- 17. RESET
    --------------------------------------------------

    Navigation.Reset()

    local currentAfterReset =
        Navigation.GetCurrentNavigation()

    local lastAfterReset =
        Navigation.GetLastNavigation()

    local historyAfterReset =
        Navigation.GetNavigationHistory()

    Test(
        "Reset clears current navigation",
        currentAfterReset == nil
    )

    Test(
        "Reset clears last navigation",
        lastAfterReset == nil
    )

    Test(
        "Reset clears history",
        historyAfterReset ~= nil
        and #historyAfterReset == 0
    )

    local resetStatistics =
        Navigation.GetStatistics()

    Test(
        "Reset clears statistics",
        resetStatistics ~= nil
        and resetStatistics.requests == 0
        and resetStatistics.started == 0
        and resetStatistics.completed == 0
        and resetStatistics.failed == 0
        and resetStatistics.cancelled == 0
    )

    --------------------------------------------------
    -- 18. REINITIALIZATION
    --------------------------------------------------

    local reinitialized =
        Navigation.Initialize()

    Test(
        "Reinitialize returns true",
        reinitialized == true
    )

    Test(
        "System remains initialized",
        Navigation.initialized == true
    )

    --------------------------------------------------
    -- FINAL REPORT
    --------------------------------------------------

    Log("==============================")
    Log("Navigation Test Results")
    Log("==============================")

    Log("TOTAL: " .. tostring(total))
    Log("PASS: " .. tostring(pass))
    Log("FAIL: " .. tostring(fail))

    if fail == 0 then

        Log(
            "STATUS: ALL TESTS PASSED"
        )

    else

        Log(
            "STATUS: TESTS FAILED"
        )

    end

    Log("==============================")

    return {
        total = total,
        pass = pass,
        fail = fail,
        success = fail == 0
    }
end

--------------------------------------------------
-- GAME START
--------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            Log("OnGameStart")

            Harness.Run()

        end
    )

end

--------------------------------------------------
-- EXPORT
--------------------------------------------------

BAO = BAO or {}

BAO.NavigationTestHarness =
    Harness

Log(
    "Navigation Test Harness V"
    .. Harness.VERSION
    .. " module loaded"
)

return Harness