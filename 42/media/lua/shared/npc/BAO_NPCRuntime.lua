-- BanditsAIOverhaul NPC Runtime V1.0.
-- Keeps transient world objects separate from persistent NPCData records.
-- This module has no OnTick work and never spawns or removes a world character.
local Runtime = { VERSION = "1.0" }

local function NewState()
    return {
        bindings = {},
        order = {},
        nextGeneration = 1,
        statistics = { bound = 0, unbound = 0, rejected = 0, refreshes = 0 }
    }
end

Runtime.state = Runtime.state or NewState()

local function Log(message)
    print("[BAO][NPCRuntime] " .. tostring(message))
end

local function Number(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function IsPlayer(character)
    if character == nil then return false end
    if type(character) == "table" and character.__baoTestPlayer == true then return true end
    if type(character) ~= "userdata" or not _G["instanceof"] then return false end
    local ok, result = pcall(_G["instanceof"], character, "IsoPlayer")
    return ok and result == true
end

local function Position(character)
    if character == nil then return nil end
    local kind = type(character)
    if kind ~= "table" and kind ~= "userdata" then return nil end
    local ok, x, y, z = pcall(function()
        if not character.getX or not character.getY or not character.getZ then return nil end
        return character:getX(), character:getY(), character:getZ()
    end)
    if ok and Number(x) and Number(y) and Number(z) then return x, y, z end
    return nil
end

local function Reject(reason)
    Runtime.state.statistics.rejected = Runtime.state.statistics.rejected + 1
    return false, reason
end

local function NPCRecord(npcId)
    if type(npcId) ~= "string" or npcId == "" then return nil end
    if not BAO or not BAO.NPCData or not BAO.NPCData.Get then return nil end
    return BAO.NPCData.Get(npcId)
end

function Runtime.IsValidCharacter(character)
    if IsPlayer(character) then return false, "player_not_supported" end
    if Position(character) == nil then return false, "invalid_character" end
    return true
end

function Runtime.Bind(npcId, character, options)
    local npc = NPCRecord(npcId)
    if not npc then return Reject("npc_not_found") end

    local valid, reason = Runtime.IsValidCharacter(character)
    if not valid then return Reject(reason) end

    local existing = Runtime.state.bindings[npcId]
    if existing then
        if existing.character == character then return true, existing end
        return Reject("npc_already_bound")
    end

    for _, boundId in ipairs(Runtime.state.order) do
        local binding = Runtime.state.bindings[boundId]
        if binding and binding.character == character then
            return Reject("character_already_bound")
        end
    end

    options = options or {}
    local x, y, z = Position(character)
    local binding = {
        npcId = npcId,
        character = character,
        generation = Runtime.state.nextGeneration,
        source = options.source or "external",
        ownedByBAO = options.ownedByBAO == true,
        active = options.active ~= false,
        state = "BOUND",
        lastX = x,
        lastY = y,
        lastZ = z
    }
    Runtime.state.nextGeneration = Runtime.state.nextGeneration + 1
    Runtime.state.bindings[npcId] = binding
    Runtime.state.order[#Runtime.state.order + 1] = npcId
    Runtime.state.statistics.bound = Runtime.state.statistics.bound + 1
    npc.isActive = binding.active
    Log("Bound NPC " .. npcId .. " generation=" .. tostring(binding.generation))
    return true, binding
end

function Runtime.Unbind(npcId, expectedCharacter, reason)
    local binding = Runtime.state.bindings[npcId]
    if not binding then return false, "not_bound" end
    if expectedCharacter and binding.character ~= expectedCharacter then
        return false, "character_mismatch"
    end

    Runtime.state.bindings[npcId] = nil
    for index, boundId in ipairs(Runtime.state.order) do
        if boundId == npcId then
            table.remove(Runtime.state.order, index)
            break
        end
    end
    binding.active = false
    binding.state = "UNBOUND"
    binding.reason = reason or "unbound"
    binding.character = nil
    Runtime.state.statistics.unbound = Runtime.state.statistics.unbound + 1
    local npc = NPCRecord(npcId)
    if npc then npc.isActive = false end
    Log("Unbound NPC " .. npcId .. " reason=" .. tostring(binding.reason))
    return true, binding
end

function Runtime.Refresh(npcId)
    local binding = Runtime.state.bindings[npcId]
    if not binding then return false, "not_bound" end
    Runtime.state.statistics.refreshes = Runtime.state.statistics.refreshes + 1
    local x, y, z = Position(binding.character)
    if x == nil then
        binding.active = false
        binding.state = "INVALID"
        local npc = NPCRecord(npcId)
        if npc then npc.isActive = false end
        return false, "invalid_character"
    end
    binding.lastX, binding.lastY, binding.lastZ = x, y, z
    binding.state = "BOUND"
    return true, binding
end

function Runtime.SetActive(npcId, active)
    local binding = Runtime.state.bindings[npcId]
    if not binding then return false, "not_bound" end
    if active == true then
        local valid, reason = Runtime.IsValidCharacter(binding.character)
        if not valid then return false, reason end
    end
    binding.active = active == true
    local npc = NPCRecord(npcId)
    if npc then npc.isActive = binding.active end
    return true, binding
end

function Runtime.Get(npcId)
    return Runtime.state.bindings[npcId]
end

function Runtime.GetCharacter(npcId)
    local binding = Runtime.Get(npcId)
    return binding and binding.character or nil
end

function Runtime.GetByCharacter(character)
    if character == nil then return nil end
    -- Only used on explicit lookup; no world scan and no per-tick cost.
    for _, npcId in ipairs(Runtime.state.order) do
        local binding = Runtime.state.bindings[npcId]
        if binding and binding.character == character then return binding end
    end
    return nil
end

function Runtime.IsBound(npcId)
    return Runtime.state.bindings[npcId] ~= nil
end

function Runtime.Count()
    return #Runtime.state.order
end

function Runtime.GetBindings()
    local result = {}
    for _, npcId in ipairs(Runtime.state.order) do
        local binding = Runtime.state.bindings[npcId]
        if binding then result[#result + 1] = binding end
    end
    return result
end

function Runtime.GetStatistics()
    return Runtime.state.statistics
end

function Runtime.Reset()
    for _, npcId in ipairs(Runtime.state.order) do
        local npc = NPCRecord(npcId)
        if npc then npc.isActive = false end
    end
    Runtime.state = NewState()
    return true
end

BAO = BAO or {}
BAO.NPCRuntime = Runtime
Log("NPC Runtime V1.0 loaded")
