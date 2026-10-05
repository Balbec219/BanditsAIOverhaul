-- BanditsAIOverhaul NPC Runtime V1.0.
-- Keeps transient world objects separate from persistent NPCData records.
-- Only active AI contexts are polled, at UpdateInterval; never spawns world characters.
local Runtime = { VERSION = "1.1", UpdateInterval = 0.1 }

local function NewState()
    return {
        bindings = {}, aiElapsed = 0,
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

    if binding.ai then
        local stopped = Runtime.StopAI(npcId, reason or "unbound")
        if not stopped then return false, "npc_ai_busy" end
        if not binding.ai.NavigationSystem.Reset() then return false, "npc_navigation_busy" end
        binding.ai = nil
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
    elseif binding.ai then
        -- Stop the engine-owned route before suspending our observer.
        if not Runtime.StopAI(npcId, "npc_deactivated") then return false, "npc_ai_busy" end
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
        local binding = Runtime.state.bindings[npcId]
        if binding and binding.ai then
            if not Runtime.StopAI(npcId, "runtime_reset") then return false end
            if not binding.ai.NavigationSystem.Reset() then return false end
        end
    end
    for _, npcId in ipairs(Runtime.state.order) do
        local npc = NPCRecord(npcId)
        if npc then npc.isActive = false end
    end
    Runtime.state = NewState()
    return true
end

-- Explicit per-NPC input: never reads the player's global DecisionSystem.
function Runtime.EnsureAI(npcId)
    if _G["isClient"] and isClient() then return false, "server_authority_required" end
    local binding = Runtime.Get(npcId)
    if not binding or not binding.active then return false, "npc_not_active" end
    if binding.ai then return true, binding.ai end
    local names = { "ActionSystem", "NavigationSystem", "ActionExecutor", "AIController" }
    for _, name in ipairs(names) do
        if not BAO[name] or not BAO[name].CreateInstance then return false, "dependencies_missing" end
    end
    local context = { InstancePrefix = npcId .. ":" .. binding.generation .. ":", InstanceLog = function() end }
    context.DecisionSystem = { GetCurrentDecision = function() return context.decision end }
    for _, name in ipairs(names) do BAO[name].CreateInstance(context) end
    context.NavigationSystem.Initialize()
    if not context.AIController.Initialize() then return false, "initialization_failed" end
    binding.ai = context
    return true, context
end

function Runtime.StartPatrol(npcId, x, y, z, options)
    local ok, context = Runtime.EnsureAI(npcId)
    if not ok then return false, context end
    local binding = Runtime.Get(npcId)
    local set, reason = context.AIController.SetPatrolTarget(binding.character, x, y, z, options)
    if not set then return false, reason end
    context.decision = { ID = "patrol", Score = 60, Priority = 50 }
    -- Same decision after completion requires an explicit retry in the existing controller.
    if context.AIController.GetCurrentDecision() then
        return context.AIController.RestartCurrentDecision()
    end
    return context.AIController.Update()
end

function Runtime.StopAI(npcId, reason)
    local binding = Runtime.Get(npcId)
    if not binding or not binding.ai then return true end
    local context = binding.ai
    if context.AIController.GetCurrentAction()
        and not context.AIController.StopCurrentAction(reason or "npc_stop") then return false end
    local navigation = context.NavigationSystem.GetCurrentNavigation()
    if navigation and not context.NavigationSystem.Cancel(reason or "npc_stop", navigation) then return false end
    context.publishedRoute = false
    context.decision = nil
    if BAO.NPCWorldAdapter and BAO.NPCWorldAdapter.PublishRoutes then BAO.NPCWorldAdapter.PublishRoutes() end
    return true
end

function Runtime.UpdateAI(delta)
    if _G["isClient"] and isClient() then return end
    delta = delta or (_G["getGameTime"] and getGameTime():getRealworldSecondsSinceLastUpdate()) or (1 / 60)
    if not Number(delta) or delta <= 0 then return end
    Runtime.state.aiElapsed = Runtime.state.aiElapsed + math.min(delta, 0.25)
    if Runtime.state.aiElapsed < Runtime.UpdateInterval then return end
    local elapsed = Runtime.state.aiElapsed
    Runtime.state.aiElapsed = 0
    for _, npcId in ipairs(Runtime.state.order) do
        local binding = Runtime.state.bindings[npcId]
        local context = binding and binding.ai
        if context and binding.active and context.decision then
            context.NavigationSystem.Update(elapsed)
            context.ActionExecutor.Update()
            context.AIController.Update()
            local nav = context.NavigationSystem.GetCurrentNavigation()
            local routeId = nav and nav.id or false
            if context.publishedRoute ~= routeId then
                context.publishedRoute = routeId
                if BAO.NPCWorldAdapter and BAO.NPCWorldAdapter.PublishRoutes then BAO.NPCWorldAdapter.PublishRoutes() end
            end
        end
    end
end

if Events and Events.OnTick then Events.OnTick.Add(function() Runtime.UpdateAI() end) end
BAO = BAO or {}
BAO.NPCRuntime = Runtime
Log("NPC Runtime V1.1 loaded")
