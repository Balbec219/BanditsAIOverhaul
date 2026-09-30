-- Isolated NPC Runtime V1.0 tests. Uses synthetic characters and never touches the world.
BAO = BAO or {}
local Harness = { VERSION = "1.0", total = 0, passed = 0, failed = 0 }

local function Log(message)
    print("[BAO][NPCRuntimeTestHarness] " .. tostring(message))
end

local function Test(name, condition)
    Harness.total = Harness.total + 1
    if condition then Harness.passed = Harness.passed + 1 else Harness.failed = Harness.failed + 1 end
    Log((condition and "PASS: " or "FAIL: ") .. name)
end

local function Actor(x, y, z)
    local actor = { x = x or 0, y = y or 0, z = z or 0 }
    actor.getX = function(self) return self.x end
    actor.getY = function(self) return self.y end
    actor.getZ = function(self) return self.z end
    return actor
end

function Harness.Run()
    Harness.total, Harness.passed, Harness.failed = 0, 0, 0
    local runtime, npcData = BAO.NPCRuntime, BAO.NPCData
    if not runtime or not npcData then
        Test("runtime dependencies available", false)
        return false
    end

    local savedState = runtime.state
    local savedLog = BAO.Log
    if not BAO.Log then BAO.Log = function() end end
    runtime.state = {
        bindings = {}, order = {}, nextGeneration = 1,
        statistics = { bound = 0, unbound = 0, rejected = 0, refreshes = 0 }
    }
    local testId = "__bao_runtime_test__"
    local savedNPC = npcData[testId]
    npcData[testId] = { id = testId, isActive = false }

    local actor = Actor(10, 20, 0)
    local ok, binding = runtime.Bind(testId, actor, { source = "harness", ownedByBAO = true })
    Test("binds existing NPC data to character", ok and binding.character == actor)
    Test("binding activates NPC data", npcData[testId].isActive == true)
    Test("stores initial position once", binding.lastX == 10 and binding.lastY == 20 and binding.lastZ == 0)
    Test("idempotent bind returns same binding", select(2, runtime.Bind(testId, actor)) == binding)
    Test("runtime count has no duplicate", runtime.Count() == 1)
    Test("reverse lookup resolves binding", runtime.GetByCharacter(actor) == binding)

    local other = Actor()
    local duplicateOk, duplicateReason = runtime.Bind(testId, other)
    Test("rejects replacing bound NPC implicitly", duplicateOk == false and duplicateReason == "npc_already_bound")
    npcData.__bao_runtime_other__ = { id = "__bao_runtime_other__", isActive = false }
    local reusedOk, reusedReason = runtime.Bind("__bao_runtime_other__", actor)
    Test("rejects one character for two NPCs", reusedOk == false and reusedReason == "character_already_bound")
    local player = Actor()
    player.__baoTestPlayer = true
    local playerOk, playerReason = runtime.Bind("__bao_runtime_other__", player)
    Test("rejects player character", playerOk == false and playerReason == "player_not_supported")

    actor.x, actor.y = 11, 22
    Test("refresh samples position on demand", runtime.Refresh(testId) == true
        and binding.lastX == 11 and binding.lastY == 22)
    Test("no background refresh work exists", runtime.GetStatistics().refreshes == 1)
    Test("can deactivate bound NPC", runtime.SetActive(testId, false) == true
        and binding.active == false and npcData[testId].isActive == false)
    Test("mismatched unbind cannot release binding", runtime.Unbind(testId, other) == false
        and runtime.IsBound(testId))
    local unbound, oldBinding = runtime.Unbind(testId, actor, "test_cleanup")
    Test("explicit unbind releases runtime only", unbound and oldBinding.character == nil
        and oldBinding.state == "UNBOUND" and runtime.Count() == 0)
    Test("unbind deactivates NPC data", npcData[testId].isActive == false)

    local removableId = "__bao_runtime_removable__"
    local savedRemovable = npcData[removableId]
    npcData[removableId] = { id = removableId, isActive = false }
    local removableActor = Actor(1, 2, 0)
    Test("second NPC binds after first cleanup", runtime.Bind(removableId, removableActor) == true)
    Test("removing NPC data also releases runtime binding", npcData.Remove(removableId) == true
        and runtime.IsBound(removableId) == false)
    npcData[removableId] = savedRemovable

    npcData[testId] = savedNPC
    npcData.__bao_runtime_other__ = nil
    runtime.state = savedState
    BAO.Log = savedLog
    Log("NPC RUNTIME V1.0 TOTAL=" .. Harness.total .. " PASS=" .. Harness.passed
        .. " FAIL=" .. Harness.failed)
    Log(Harness.failed == 0 and "STATUS: ALL TESTS PASSED" or "STATUS: TESTS FAILED")
    return Harness.failed == 0
end

function Harness.GetSummary()
    return { Total = Harness.total, Passed = Harness.passed, Failed = Harness.failed,
        Success = Harness.total > 0 and Harness.failed == 0 }
end

BAO.NPCRuntimeTestHarness = Harness
if Events and Events.OnGameStart then Events.OnGameStart.Add(Harness.Run) end
Log("NPC Runtime Test Harness V1.0 loaded")
