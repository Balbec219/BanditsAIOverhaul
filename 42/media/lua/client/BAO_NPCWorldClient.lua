-- Network presentation only. No decisions or paths are calculated here.
BAO = BAO or {}
local Client = { active = {}, removed = {}, lastStatus = nil, hasEntries = false }
local applied = setmetatable({}, { __mode = "k" })
local movement = setmetatable({}, { __mode = "k" })
-- MP movement executor only: server still owns decisions and arrival checks.
-- Installed B42 Bandits ZAMove uses PathFindBehavior2 on the controlling client.
local function DriveRoute(zombie, route)
    local state = movement[zombie]
    if not route and not state then return end
    if not zombie.isRemoteZombie or zombie:isRemoteZombie() then
        movement[zombie] = nil
        return
    end
    if state and (not route or state.id ~= route.id) then
        state.behavior:cancel()
        zombie:setPath2(nil)
        movement[zombie] = nil
        state = nil
    end
    if not route then return end
    if not state then
        local behavior = zombie:getPathFindBehavior2()
        state = {id=route.id,behavior=behavior,finished=false,updates=0}
        movement[zombie] = state
        zombie:pathToLocationF(route.x,route.y,route.z)
        print("[BAO][NPCMovement] start route=" .. route.id)
    end
    if state.finished then return end
    -- Engine-owned GoTo movement; never update the behavior a second time.
    state.updates = state.updates + 1
    if state.updates == 60 then
        print("[BAO][NPCMovement] probe route=" .. state.id
            .. " state=" .. tostring(zombie.getActionStateName and zombie:getActionStateName())
            .. " moving=" .. tostring(zombie.getVariableBoolean and zombie:getVariableBoolean("bMoving"))
            .. " shouldMove=" .. tostring(state.behavior.shouldBeMoving and state.behavior:shouldBeMoving())
            .. " x=" .. tostring(zombie:getX()) .. " y=" .. tostring(zombie:getY()))
    end

end
BAO.NPCWorldClient = Client
function Client.Request(spawn, player, target)
    if not player then return false, "player_unavailable" end
    if _G["isClient"] and isClient() then
        sendClientCommand(player, "BAO_Debug", spawn and "world_spawn" or "world_remove", target or {})
        return true, "request_sent"
    end
    if spawn then return BAO.NPCWorldAdapter.SpawnTestNPC(player, target) end
    return BAO.NPCWorldAdapter.RemoveTestNPC()
end
-- Kahlua does not expose the standard Lua next() global.
-- Stop at the first entry; only used on snapshots or tombstone expiry.
local function HasEntries(entries)
    for _ in pairs(entries) do return true end
    return false
end
local function Key(identity) return identity.online end
function Client.GetNPCList()
    local list = {}
    if _G["isClient"] and isClient() then
        for _, identity in pairs(Client.active) do list[#list+1] = identity end
    elseif BAO.NPCWorldAdapter then list = BAO.NPCWorldAdapter.GetSnapshot() end
    table.sort(list, function(a,b) return a.id < b.id end)
    return list
end
function Client.CommandNPC(player, command, args)
    if not player then return false, "player_unavailable" end
    if _G["isClient"] and isClient() then
        sendClientCommand(player, "BAO_Debug", command, args)
        return true, "request_sent"
    end
    local success, reason, detail = BAO.NPCWorldAdapter.CommandNPC(player, command, args)
    Client.OnServerCommand("BAO_Debug", "world_status", {success=success, reason=reason, npcId=args.id, detail=detail})
    return success, reason
end
local function Now() return _G["getTimestampMs"] and getTimestampMs() / 1000 or os.time() end
function Client.OnServerCommand(module, command, args)
    if module ~= "BAO_Debug" or command ~= "world_status" or type(args) ~= "table" then return end
    if args.snapshot then
        Client.active = {}
        for _, identity in ipairs(args.active or {}) do Client.active[Key(identity)] = identity end
    end
    local now = Now()
    for key, notice in pairs(Client.removed) do if notice.expiry <= now then Client.removed[key] = nil end end
    for _, identity in ipairs(args.removed or {}) do
        Client.removed[Key(identity)] = { outfit = identity.outfit, expiry = now + 60 }
    end
    -- A currently active network identity takes precedence over old cleanup notices.
    for key in pairs(Client.active) do Client.removed[key] = nil end
    Client.hasEntries = HasEntries(Client.active) or HasEntries(Client.removed)
    Client.lastStatus = args
    if BAO.DebugUI and BAO.DebugUI.ReceiveNPCStatus then BAO.DebugUI.ReceiveNPCStatus(args) end
    print("[BAO][NPCWorldClient] success=" .. tostring(args.success) .. " reason=" .. tostring(args.reason)
        .. " spawned=" .. tostring(args.spawned or 0))
    if args.npcId then
        local detail = args.detail or {}
        print("[BAO][NPCCommand] id=" .. tostring(args.npcId) .. " state=" .. tostring(detail.state)
            .. " reason=" .. tostring(detail.reason or args.reason)
            .. " x=" .. tostring(detail.x) .. " y=" .. tostring(detail.y)
            .. " route=" .. tostring(detail.routeId) .. " elapsed=" .. tostring(detail.elapsed)
            .. " distance=" .. tostring(detail.distance) .. " pathIssued=" .. tostring(detail.pathIssued)
            .. " pathStopped=" .. tostring(detail.pathStopped)
            .. " target=" .. tostring(detail.targetX) .. "," .. tostring(detail.targetY))
    end
end
function Client.OnZombieUpdate(zombie)
    local identity
    if _G["isClient"] and isClient() then
        if not Client.hasEntries and not applied[zombie] then return end
        local key = zombie:getOnlineID()
        local notice = Client.removed[key]
        if notice then
            if notice.expiry > Now() then
                if zombie:getPersistentOutfitID() == notice.outfit then
                    DriveRoute(zombie, nil); zombie:removeFromWorld(); zombie:removeFromSquare(); return
                end
            else
                Client.removed[key] = nil
                Client.hasEntries = HasEntries(Client.active) or HasEntries(Client.removed)
            end
        end
        identity = Client.active[key]
        if identity and zombie:getPersistentOutfitID() ~= identity.outfit then identity = nil end
    else
        local adapter = BAO.NPCWorldAdapter
        identity = adapter and adapter.byCharacter[zombie]
    end
    if not identity then
        DriveRoute(zombie, nil)
        if applied[zombie] then zombie:setVariable("BAOHuman", false); applied[zombie] = nil end
        return
    end
    if zombie:isDead() then DriveRoute(zombie, nil); return end
    if applied[zombie] ~= identity.id then
        zombie:setVariable("BAOHuman", true)
        applied[zombie] = identity.id
    end
    -- Enable only the local route owner; idle and remote NPCs stay suppressed.
    local isMP = _G["isClient"] and isClient()
    local state = movement[zombie]
    local canMove = isMP and identity.route and zombie.isRemoteZombie and not zombie:isRemoteZombie()
        and not (state and state.id == identity.route.id and state.finished)
    zombie:setUseless(not canMove)
    if zombie.setWalkType then zombie:setWalkType("BAOWalk") end
    zombie:setTarget(nil)
    if _G["isClient"] and isClient() then DriveRoute(zombie, identity.route) end
end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(Client.OnServerCommand) end
if Events and Events.OnZombieUpdate then Events.OnZombieUpdate.Add(Client.OnZombieUpdate) end
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(_, player)
        if _G["isClient"] and isClient() then sendClientCommand(player, "BAO_Debug", "world_state", {}) end
    end)
end
