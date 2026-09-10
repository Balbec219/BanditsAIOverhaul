---@diagnostic disable: undefined-global

BAO = BAO or {}
BAO.PlayerDiagnostics = BAO.PlayerDiagnostics or {}

local Diagnostics = BAO.PlayerDiagnostics

local function Log(message)
    print("[BAO][PlayerDiagnostics] " .. tostring(message))
end

local function CheckMethod(object, methodName)
    if object == nil then
        Log(methodName .. ": object is nil")
        return false
    end

    local success, result = pcall(function()
        return object[methodName]
    end)

    if not success then
        Log(methodName .. ": access error")
        return false
    end

    Log(methodName .. ": " .. tostring(result))
    return result ~= nil
end

function Diagnostics.InspectPlayer(player)
    Log("========================================")
    Log("Player diagnostics started")

    if player == nil then
        Log("ERROR: player is nil")
        return
    end

    Log("Player object found")
    Log("Player class: " .. tostring(player))

    CheckMethod(player, "getUsername")
    CheckMethod(player, "getDisplayName")
    CheckMethod(player, "getDescriptor")
    CheckMethod(player, "getPerkLevel")
    CheckMethod(player, "HasTrait")
    CheckMethod(player, "getTraits")
    CheckMethod(player, "getBodyDamage")
    CheckMethod(player, "getInventory")

    local descriptor = nil

    local descriptorSuccess, descriptorResult = pcall(function()
        return player:getDescriptor()
    end)

    if descriptorSuccess then
        descriptor = descriptorResult
        Log("Descriptor access: successful")
    else
        Log("Descriptor access: failed")
    end

    if descriptor ~= nil then
        CheckMethod(descriptor, "getProfession")
        CheckMethod(descriptor, "getTraits")
        CheckMethod(descriptor, "getCharacterProfession")
    end

    Log("Player diagnostics finished")
    Log("========================================")
end

if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(playerIndex, player)
        Log("OnCreatePlayer event received")
        Log("Player index: " .. tostring(playerIndex))

        if player ~= nil then
            Diagnostics.InspectPlayer(player)
        else
            Log("ERROR: player argument is nil")
        end
    end)
else
    Log("WARNING: OnCreatePlayer event is not available")
end

Log("Player diagnostics module loaded")