---@diagnostic disable: undefined-global

BAO = BAO or {}
BAO.PlayerProfile = BAO.PlayerProfile or {}

local Profile = BAO.PlayerProfile

Profile.Version = 1

local function Log(message)
    print("[BAO][PlayerProfile] " .. tostring(message))
end


------------------------------------------------------------
-- Настройки
------------------------------------------------------------

local SkillNames = {
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


------------------------------------------------------------
-- Создание пустого профиля
------------------------------------------------------------

function Profile.CreateEmpty()
    local profile = {
        Version = Profile.Version,

        Profession = nil,

        Traits = {},

        Skills = {},

        MaxWeight = nil
    }

    return profile
end


------------------------------------------------------------
-- Получение профессии
------------------------------------------------------------

local function ReadProfession(player, profile)

    local successDescriptor, descriptor = pcall(function()
        return player:getDescriptor()
    end)

    if not successDescriptor or descriptor == nil then
        Log("Unable to read player descriptor")
        return
    end

    local successProfession, profession = pcall(function()
        return descriptor:getCharacterProfession()
    end)

    if not successProfession or profession == nil then
        Log("Unable to read CharacterProfession")
        return
    end

    local successName, professionName = pcall(function()
        return profession:getName()
    end)

    if successName then
        profile.Profession = tostring(professionName)
        Log("Profession: " .. tostring(profile.Profession))
    else
        Log("Unable to read profession name")
    end
end


------------------------------------------------------------
-- Получение черт
------------------------------------------------------------

local function ReadTraits(player, profile)

    local successTraitsObject, traitsObject = pcall(function()
        return player:getCharacterTraits()
    end)

    if not successTraitsObject or traitsObject == nil then
        Log("Unable to read CharacterTraits")
        return
    end

    local successKnownTraits, knownTraits = pcall(function()
        return traitsObject:getKnownTraits()
    end)

    if not successKnownTraits or knownTraits == nil then
        Log("Unable to read known traits")
        return
    end

    local successCount, count = pcall(function()
        return knownTraits:size()
    end)

    if not successCount or count == nil then
        Log("Unable to read trait count")
        return
    end

    for i = 0, count - 1 do

        local successTrait, trait = pcall(function()
            return knownTraits:get(i)
        end)

        if successTrait and trait ~= nil then

            local successName, traitName = pcall(function()
                return trait:getName()
            end)

            if successName and traitName ~= nil then
                table.insert(
                    profile.Traits,
                    tostring(traitName)
                )
            end
        end
    end

    Log("Traits count: " .. tostring(#profile.Traits))
end


------------------------------------------------------------
-- Получение навыков
------------------------------------------------------------

local function ReadSkills(player, profile)

    for _, skillName in ipairs(SkillNames) do

        local successLevel, level = pcall(function()
            return player:getPerkLevel(
                Perks[skillName]
            )
        end)

        if successLevel and level ~= nil then

            profile.Skills[skillName] = level

        else

            profile.Skills[skillName] = 0

        end
    end

    Log("Skills collected")
end


------------------------------------------------------------
-- Получение максимального веса
------------------------------------------------------------

local function ReadMaxWeight(player, profile)

    local successWeight, maxWeight = pcall(function()
        return player:getMaxWeight()
    end)

    if successWeight and maxWeight ~= nil then

        profile.MaxWeight = maxWeight

        Log(
            "Max weight: "
            .. tostring(profile.MaxWeight)
        )

    else

        Log("Unable to read max weight")
    end
end


------------------------------------------------------------
-- Создание профиля игрока
------------------------------------------------------------

function Profile.FromPlayer(player)

    if player == nil then
        Log("ERROR: player is nil")
        return nil
    end

    Log("Creating player profile")

    local profile = Profile.CreateEmpty()

    ReadProfession(
        player,
        profile
    )

    ReadTraits(
        player,
        profile
    )

    ReadSkills(
        player,
        profile
    )

    ReadMaxWeight(
        player,
        profile
    )

    Log("Player profile created")

    return profile
end


------------------------------------------------------------
-- Вывод профиля в консоль
------------------------------------------------------------

function Profile.Print(profile)

    if profile == nil then
        Log("Cannot print nil profile")
        return
    end

    Log("========================================")
    Log("PLAYER PROFILE")
    Log("========================================")

    Log(
        "Version: "
        .. tostring(profile.Version)
    )

    Log(
        "Profession: "
        .. tostring(profile.Profession)
    )

    Log(
        "MaxWeight: "
        .. tostring(profile.MaxWeight)
    )


    --------------------------------------------------------
    -- Traits
    --------------------------------------------------------

    Log("Traits:")

    if #profile.Traits == 0 then

        Log("  none")

    else

        for index, traitName in ipairs(profile.Traits) do

            Log(
                "  "
                .. tostring(index)
                .. ": "
                .. tostring(traitName)
            )

        end
    end


    --------------------------------------------------------
    -- Skills
    --------------------------------------------------------

    Log("Skills:")

    for _, skillName in ipairs(SkillNames) do

        Log(
            "  "
            .. tostring(skillName)
            .. ": "
            .. tostring(profile.Skills[skillName])
        )

    end

    Log("========================================")
end


------------------------------------------------------------
-- Тест профиля
------------------------------------------------------------

local function TestPlayerProfile()

    Log("PlayerProfile test started")

    local successPlayer, player = pcall(function()
        return getPlayer()
    end)

    if not successPlayer or player == nil then
        Log("Player not available yet")
        return
    end

    local profile = Profile.FromPlayer(player)

    if profile == nil then
        Log("ERROR: profile creation failed")
        return
    end

    Profile.Print(profile)

    Log("PlayerProfile test finished")
end


------------------------------------------------------------
-- Подключение к OnGameStart
------------------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(function()

        Log("OnGameStart event received")

        TestPlayerProfile()

    end)

    Log("OnGameStart handler registered")

else

    Log(
        "WARNING: OnGameStart event is not available"
    )

end


------------------------------------------------------------
-- Module loaded
------------------------------------------------------------i

Log("PlayerProfile module loaded")