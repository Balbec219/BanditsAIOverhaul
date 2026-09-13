
---@diagnostic disable: undefined-global

BAO = BAO or {}
BAO.PlayerDiagnostics = BAO.PlayerDiagnostics or {}

local Diagnostics = BAO.PlayerDiagnostics

-- Защита от повторной диагностики.
-- Нам достаточно один раз получить данные игрока
-- для текущего теста.
Diagnostics.Completed = false


--------------------------------------------------
-- LOG
--------------------------------------------------

local function Log(message)
    print("[BAO][PlayerDiagnostics] " .. tostring(message))
end


--------------------------------------------------
-- ПРОВЕРКА МЕТОДА
--------------------------------------------------
-- Не вызывает метод.
-- Только проверяет, существует ли он у объекта.
--------------------------------------------------

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


--------------------------------------------------
-- АНАЛИЗ ИГРОКА
--------------------------------------------------

function Diagnostics.InspectPlayer(player)

    if Diagnostics.Completed then
        return
    end

    Log("========================================")
    Log("Player diagnostics started")


    --------------------------------------------------
    -- Проверяем объект игрока
    --------------------------------------------------

    if player == nil then
        Log("ERROR: player is nil")
        return
    end

    Log("Player object found")
    Log("Player object: " .. tostring(player))


    --------------------------------------------------
    -- Проверяем основные методы IsoPlayer
    --------------------------------------------------

    CheckMethod(player, "getUsername")
    CheckMethod(player, "getDisplayName")
    CheckMethod(player, "getDescriptor")
    CheckMethod(player, "getPerkLevel")
    CheckMethod(player, "getCharacterTraits")
    CheckMethod(player, "getBodyDamage")
    CheckMethod(player, "getInventory")
    CheckMethod(player, "getMaxWeight")
    CheckMethod(player, "getAlreadyReadBook")
    CheckMethod(player, "getHoursSurvived")


    --------------------------------------------------
    -- Имя игрока
    --------------------------------------------------

    local successUsername, username = pcall(function()
        return player:getUsername()
    end)

    if successUsername then
        Log("Username: " .. tostring(username))
    else
        Log("Username: unable to read")
    end


    --------------------------------------------------
    -- Descriptor
    --------------------------------------------------

    local descriptor = nil

    local successDescriptor, descriptorResult = pcall(function()
        return player:getDescriptor()
    end)

    if successDescriptor and descriptorResult ~= nil then

        descriptor = descriptorResult

        Log("Descriptor access: successful")
        Log("Descriptor object found")

    else

        Log("Descriptor access: failed")

    end


    --------------------------------------------------
    -- ПРОФЕССИЯ
    --------------------------------------------------
    -- В B42 профессия берётся через:
    --
    -- descriptor:getCharacterProfession()
    --
    -- Возвращается объект CharacterProfession.
    --------------------------------------------------

    if descriptor ~= nil then

        CheckMethod(descriptor, "getCharacterProfession")

        local professionSuccess, profession = pcall(function()
            return descriptor:getCharacterProfession()
        end)

        if professionSuccess and profession ~= nil then

            Log("CharacterProfession object found")
            Log("Profession object: " .. tostring(profession))

            --------------------------------------------------
            -- Проверяем методы объекта профессии
            --------------------------------------------------

            CheckMethod(profession, "getName")
            CheckMethod(profession, "toString")

            --------------------------------------------------
            -- Получаем внутреннее имя профессии
            --------------------------------------------------

            local nameSuccess, professionName = pcall(function()
                return profession:getName()
            end)

            if nameSuccess then
                Log("Profession name: " .. tostring(professionName))
            else
                Log("Profession name: unable to read")
            end

            --------------------------------------------------
            -- Дополнительное строковое представление
            --------------------------------------------------

            local stringSuccess, professionString = pcall(function()
                return profession:toString()
            end)

            if stringSuccess then
                Log("Profession string: " .. tostring(professionString))
            else
                Log("Profession string: unable to read")
            end

        else

            Log("Profession: unable to read")

        end

    else

        Log("Descriptor object is nil")

    end


    --------------------------------------------------
    -- TRAITS
    --------------------------------------------------
    -- В B42 traits находятся через:
    --
    -- player:getCharacterTraits()
    --
    -- Объект CharacterTraits предоставляет:
    -- getTraits()
    -- getKnownTraits()
    -- get(...)
    --------------------------------------------------

    local traitsObject = nil

    local traitsObjectSuccess, traitsObjectResult = pcall(function()
        return player:getCharacterTraits()
    end)

    if traitsObjectSuccess and traitsObjectResult ~= nil then

        traitsObject = traitsObjectResult

        Log("CharacterTraits object found")
        Log("CharacterTraits object: " .. tostring(traitsObject))

        --------------------------------------------------
        -- Проверяем методы CharacterTraits
        --------------------------------------------------

        CheckMethod(traitsObject, "getTraits")
        CheckMethod(traitsObject, "getKnownTraits")
        CheckMethod(traitsObject, "get")

        --------------------------------------------------
        -- Получаем карту traits
        --------------------------------------------------

        local getTraitsSuccess, traitsMap = pcall(function()
            return traitsObject:getTraits()
        end)

        if getTraitsSuccess and traitsMap ~= nil then

            Log("Traits map found")
            Log("Traits map: " .. tostring(traitsMap))

        else

            Log("Traits map: unable to read")

        end


        --------------------------------------------------
        -- Получаем известные traits
        --------------------------------------------------

        local knownTraitsSuccess, knownTraits = pcall(function()
            return traitsObject:getKnownTraits()
        end)

        if knownTraitsSuccess and knownTraits ~= nil then

            Log("Known traits collection found")
            Log("Known traits: " .. tostring(knownTraits))

            --------------------------------------------------
            -- Пытаемся пройти по списку известных traits.
            --
            -- Не предполагаем заранее, сколько их.
            --------------------------------------------------

            local countSuccess, count = pcall(function()
                return knownTraits:size()
            end)

            if countSuccess and count ~= nil then

                Log("Known traits count: " .. tostring(count))

                for i = 0, count - 1 do

                    local traitSuccess, trait = pcall(function()
                        return knownTraits:get(i)
                    end)

                    if traitSuccess and trait ~= nil then

                        Log(
                            "Known trait "
                            .. tostring(i)
                            .. ": "
                            .. tostring(trait)
                        )

                        --------------------------------------------------
                        -- Дополнительно проверяем getName().
                        --------------------------------------------------

                        local traitNameSuccess, traitName = pcall(function()
                            return trait:getName()
                        end)

                        if traitNameSuccess then

                            Log(
                                "Known trait "
                                .. tostring(i)
                                .. " name: "
                                .. tostring(traitName)
                            )

                        end

                    else

                        Log(
                            "Known trait "
                            .. tostring(i)
                            .. ": unable to read"
                        )

                    end

                end

            else

                Log("Known traits count: unable to read")

            end

        else

            Log("Known traits collection: unable to read")

        end

    else

        Log("CharacterTraits object: unable to read")

    end


    --------------------------------------------------
    -- НАВЫКИ
    --------------------------------------------------
    -- Пока проверяем основные навыки.
    -- Позже сделаем автоматический сбор всех доступных
    -- Perks/навыков, включая добавленные модами.
    --------------------------------------------------

    local skills = {
        "Aiming",
        "Fitness",
        "Strength",
        "Cooking",
        "Farming",
        "FirstAid",
        "Mechanics",
        "MetalWelding",
        "Carpentry",
        "Woodwork",
        "Electrical",
        "Tailoring",
        "Reloading",
        "Maintenance"
    }


    for _, skillName in ipairs(skills) do

        local skillSuccess, level = pcall(function()
            return player:getPerkLevel(
                Perks[skillName]
            )
        end)

        if skillSuccess then

            Log(
                "Skill "
                .. tostring(skillName)
                .. ": "
                .. tostring(level)
            )

        else

            Log(
                "Skill "
                .. tostring(skillName)
                .. ": unable to read"
            )

        end

    end


    --------------------------------------------------
    -- Максимальный переносимый вес
    --------------------------------------------------

    local weightSuccess, maxWeight = pcall(function()
        return player:getMaxWeight()
    end)

    if weightSuccess then

        Log(
            "Max carry weight: "
            .. tostring(maxWeight)
        )

    else

        Log("Max carry weight: unable to read")

    end


    --------------------------------------------------
    -- Завершение
    --------------------------------------------------

    Diagnostics.Completed = true

    Log("Player diagnostics finished")
    Log("========================================")

end


--------------------------------------------------
-- ПОИСК ИГРОКА
--------------------------------------------------
-- Эта функция используется несколькими событиями.
-- Как только игрок существует — запускаем диагностику.
--------------------------------------------------

local function TryInspectPlayer()

    if Diagnostics.Completed then
        return true
    end


    local success, player = pcall(function()
        return getPlayer()
    end)


    if not success then

        Log("getPlayer() call failed")
        return false

    end


    if player == nil then

        Log("getPlayer() returned nil")
        return false

    end


    Log("getPlayer() returned a player")

    Diagnostics.InspectPlayer(player)

    return true

end


--------------------------------------------------
-- ON CREATE PLAYER
--------------------------------------------------

if Events and Events.OnCreatePlayer then

    Events.OnCreatePlayer.Add(function(playerIndex, player)

        Log("OnCreatePlayer event received")
        Log("Player index: " .. tostring(playerIndex))

        if player ~= nil then

            Diagnostics.InspectPlayer(player)

        else

            TryInspectPlayer()

        end

    end)

    Log("OnCreatePlayer handler registered")

else

    Log("WARNING: OnCreatePlayer event is not available")

end


--------------------------------------------------
-- ON GAME START
--------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(function()

        Log("OnGameStart event received")

        TryInspectPlayer()

    end)

    Log("OnGameStart handler registered")

else

    Log("WARNING: OnGameStart event is not available")

end


--------------------------------------------------
-- ON PLAYER UPDATE
--------------------------------------------------
-- Резервный вариант.
--
-- Событие вызывается во время игры.
-- Как только игрок существует,
-- диагностика выполнится один раз.
--------------------------------------------------

if Events and Events.OnPlayerUpdate then

    Events.OnPlayerUpdate.Add(function(player)

        if Diagnostics.Completed then
            return
        end

        if player ~= nil then

            Log("OnPlayerUpdate found player")

            Diagnostics.InspectPlayer(player)

        end

    end)

    Log("OnPlayerUpdate handler registered")

else

    Log("WARNING: OnPlayerUpdate event is not available")

end


--------------------------------------------------
-- МОДУЛЬ ЗАГРУЖЕН
--------------------------------------------------

Log("Player diagnostics module loaded")