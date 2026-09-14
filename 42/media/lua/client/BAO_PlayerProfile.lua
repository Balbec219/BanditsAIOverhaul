---@diagnostic disable: undefined-global

------------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_PlayerProfile.lua
--
-- Player Profile V2
--
-- Архитектура:
--
-- Player
--   ↓
-- Raw Data
--   ├── Profession
--   ├── Traits
--   ├── Skills
--   └── MaxWeight
--          ↓
--   Characteristics
--          ↓
--   Behavioral Profile
--          ↓
--   Future:
--   Role → Specialization → Equipment → Task → AI
------------------------------------------------------------

BAO = BAO or {}
BAO.PlayerProfile = BAO.PlayerProfile or {}

local PlayerProfile = BAO.PlayerProfile

------------------------------------------------------------
-- DEBUG / LOGGING
------------------------------------------------------------

local function Log(message)
    print("[BAO][PlayerProfile] " .. tostring(message))
end

local function Warning(message)
    print("[BAO][PlayerProfile][WARNING] " .. tostring(message))
end

local function Error(message)
    print("[BAO][PlayerProfile][ERROR] " .. tostring(message))
end

------------------------------------------------------------
-- SAFE CALL
--
-- Позволяет безопасно обращаться к API B42.
-- Если вызов вызывает ошибку или возвращает nil,
-- возвращается defaultValue.
------------------------------------------------------------

local function SafeCall(callback, defaultValue)
    local success, result = pcall(callback)

    if success then
        if result ~= nil then
            return result
        end
    end

    return defaultValue
end

------------------------------------------------------------
-- CLAMP
------------------------------------------------------------

local function Clamp(value, minimum, maximum)
    value = tonumber(value) or 0

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

------------------------------------------------------------
-- GET PLAYER
------------------------------------------------------------

local function GetPlayer()
    return SafeCall(function()
        return getPlayer()
    end, nil)
end

------------------------------------------------------------
-- GET USERNAME
------------------------------------------------------------

local function GetUsername(player)
    if not player then
        return "unknown"
    end

    return SafeCall(function()
        return player:getUsername()
    end, "unknown")
end

------------------------------------------------------------
-- GET DISPLAY NAME
------------------------------------------------------------

local function GetDisplayName(player)
    if not player then
        return "unknown"
    end

    return SafeCall(function()
        return player:getDisplayName()
    end, GetUsername(player))
end

------------------------------------------------------------
-- PROFESSION
--
-- B42:
-- player:getDescriptor()
--      ↓
-- SurvivorDesc
--      ↓
-- getCharacterProfession()
--      ↓
-- CharacterProfession
------------------------------------------------------------

local function GetProfession(player)

    local result = {
        ID = "unknown",
        Name = "Unknown",
        String = "unknown"
    }

    if not player then
        return result
    end

    local descriptor = SafeCall(function()
        return player:getDescriptor()
    end, nil)

    if not descriptor then
        Warning("Player descriptor unavailable")
        return result
    end

    local profession = SafeCall(function()
        return descriptor:getCharacterProfession()
    end, nil)

    if not profession then
        Warning("CharacterProfession unavailable")
        return result
    end

    local name = SafeCall(function()
        return profession:getName()
    end, nil)

    local professionString = SafeCall(function()
        return profession:toString()
    end, nil)

    if name then
        result.ID = tostring(name)
        result.Name = tostring(name)
    end

    if professionString then
        result.String = tostring(professionString)
    else
        result.String = result.ID
    end

    Log("Profession detected: " .. tostring(result.ID))

    return result
end

------------------------------------------------------------
-- TRAITS
--
-- IMPORTANT:
--
-- player:getCharacterTraits()
--      ↓
-- CharacterTraits
--
-- characterTraits:getKnownTraits()
--      ↓
-- Java collection
--
-- НЕЛЬЗЯ:
--
-- for _, trait in pairs(knownTraits) do
--
-- Используем:
--
-- knownTraits:size()
-- knownTraits:get(index)
--
------------------------------------------------------------

local function GetTraits(player)

    local traits = {}

    if not player then
        return traits
    end

    local characterTraits = SafeCall(function()
        return player:getCharacterTraits()
    end, nil)

    if not characterTraits then
        Warning("CharacterTraits unavailable")
        return traits
    end

    local knownTraits = SafeCall(function()
        return characterTraits:getKnownTraits()
    end, nil)

    if not knownTraits then
        Warning("KnownTraits collection unavailable")
        return traits
    end

    local count = SafeCall(function()
        return knownTraits:size()
    end, 0)

    count = tonumber(count) or 0

    if count <= 0 then
        Log("No active traits found")
        return traits
    end

    Log("Collecting active traits: " .. tostring(count))

    for i = 0, count - 1 do

        local trait = SafeCall(function()
            return knownTraits:get(i)
        end, nil)

        if trait then

            local traitName = SafeCall(function()
                return trait:getName()
            end, nil)

            if traitName then

                traitName = tostring(traitName)

                traits[traitName] = true

                Log("Active trait: " .. traitName)
            end
        end
    end

    Log("Active traits collected: " .. tostring(count))

    return traits
end

------------------------------------------------------------
-- TRAIT CHECK
------------------------------------------------------------

local function HasTrait(traits, traitName)

    if not traits then
        return false
    end

    return traits[traitName] == true
end

------------------------------------------------------------
-- SKILL
--
-- player:getPerkLevel(Perks[skillName])
------------------------------------------------------------

local function GetSkill(player, skillName)

    if not player then
        return 0
    end

    local perk = SafeCall(function()
        return Perks[skillName]
    end, nil)

    if not perk then
        return 0
    end

    local level = SafeCall(function()
        return player:getPerkLevel(perk)
    end, 0)

    return tonumber(level) or 0
end

------------------------------------------------------------
-- COLLECT SKILLS
------------------------------------------------------------

local function GetSkills(player)

    local skills = {}

    skills.Aiming = GetSkill(player, "Aiming")
    skills.Reloading = GetSkill(player, "Reloading")
    skills.Maintenance = GetSkill(player, "Maintenance")

    skills.Fitness = GetSkill(player, "Fitness")
    skills.Strength = GetSkill(player, "Strength")

    skills.Cooking = GetSkill(player, "Cooking")
    skills.Farming = GetSkill(player, "Farming")
    skills.Fishing = GetSkill(player, "Fishing")

    skills.FirstAid = GetSkill(player, "FirstAid")

    skills.Mechanics = GetSkill(player, "Mechanics")
    skills.Electrical = GetSkill(player, "Electrical")
    skills.MetalWelding = GetSkill(player, "MetalWelding")

    skills.Carpentry = GetSkill(player, "Carpentry")
    skills.Woodwork = GetSkill(player, "Woodwork")

    skills.Tailoring = GetSkill(player, "Tailoring")

    return skills
end

------------------------------------------------------------
-- MAX WEIGHT
------------------------------------------------------------

local function GetMaxWeight(player)

    if not player then
        return 0
    end

    return tonumber(
        SafeCall(function()
            return player:getMaxWeight()
        end, 0)
    ) or 0
end

------------------------------------------------------------
-- CHARACTERISTICS
--
-- Все характеристики:
-- 0 - 100
--
-- ВАЖНО:
--
-- Профессия здесь НЕ даёт прямой бонус.
--
-- Профессия будет использоваться позднее
-- как professional affinity при выборе роли.
--
-- Это позволяет избежать:
--
-- mechanic = автоматически механик
--
-- вместо:
--
-- mechanic + traits + skills
--      ↓
-- technical ability
--      ↓
-- role scoring
------------------------------------------------------------

local function CalculateCharacteristics(skills, traits)

    local s = skills or {}
    local t = traits or {}

    --------------------------------------------------------
    -- Безопасное получение навыка
    --------------------------------------------------------

    local function Skill(skillName)

        local value = s[skillName]

        if value == nil then
            return 0
        end

        return tonumber(value) or 0
    end

    --------------------------------------------------------
    -- PHYSICAL POWER
    --------------------------------------------------------

    local physicalPower =
        Skill("Strength") * 10

    if HasTrait(t, "strong") then
        physicalPower = physicalPower + 15
    end

    if HasTrait(t, "stout") then
        physicalPower = physicalPower + 8
    end

    if HasTrait(t, "weak") then
        physicalPower = physicalPower - 15
    end

    if HasTrait(t, "feeble") then
        physicalPower = physicalPower - 25
    end

    --------------------------------------------------------
    -- ENDURANCE
    --------------------------------------------------------

    local endurance =
        Skill("Fitness") * 10

    if HasTrait(t, "jogger") then
        endurance = endurance + 10
    end

    if HasTrait(t, "athletic") then
        endurance = endurance + 15
    end

    if HasTrait(t, "fit") then
        endurance = endurance + 8
    end

    if HasTrait(t, "unfit") then
        endurance = endurance - 15
    end

    if HasTrait(t, "out of shape") then
        endurance = endurance - 20
    end

    --------------------------------------------------------
    -- COMBAT POTENTIAL
    --------------------------------------------------------

    local combatPotential =
        Skill("Aiming") * 5 +
        Skill("Reloading") * 3 +
        Skill("Maintenance") * 2 +
        Skill("Strength") * 2 +
        Skill("Fitness") * 2

    if HasTrait(t, "brave") then
        combatPotential = combatPotential + 8
    end

    if HasTrait(t, "brawler") then
        combatPotential = combatPotential + 8
    end

    if HasTrait(t, "marksman") then
        combatPotential = combatPotential + 10
    end

    if HasTrait(t, "pacifist") then
        combatPotential = combatPotential - 15
    end

    --------------------------------------------------------
    -- TECHNICAL ABILITY
    --------------------------------------------------------

    local technicalAbility =
        Skill("Mechanics") * 8 +
        Skill("Electrical") * 5 +
        Skill("MetalWelding") * 5 +
        Skill("Maintenance") * 4

    if HasTrait(t, "inventive") then
        technicalAbility = technicalAbility + 10
    end

    if HasTrait(t, "tinkerer") then
        technicalAbility = technicalAbility + 10
    end

    if HasTrait(t, "handy") then
        technicalAbility = technicalAbility + 8
    end

    --------------------------------------------------------
    -- CONSTRUCTION ABILITY
    --------------------------------------------------------

    local constructionAbility =
        Skill("Carpentry") * 8 +
        Skill("Woodwork") * 8 +
        Skill("MetalWelding") * 4

    if HasTrait(t, "handy") then
        constructionAbility = constructionAbility + 10
    end

    if HasTrait(t, "mason") then
        constructionAbility = constructionAbility + 10
    end

    if HasTrait(t, "blacksmith") then
        constructionAbility = constructionAbility + 5
    end

    --------------------------------------------------------
    -- MEDICAL ABILITY
    --------------------------------------------------------

    local medicalAbility =
        Skill("FirstAid") * 10

    if HasTrait(t, "firstaid") then
        medicalAbility = medicalAbility + 15
    end

    --------------------------------------------------------
    -- SURVIVAL ABILITY
    --------------------------------------------------------

    local survivalAbility =
        Skill("Farming") * 3 +
        Skill("Cooking") * 3 +
        Skill("Fishing") * 3 +
        Skill("Fitness") * 2

    if HasTrait(t, "outdoorsman") then
        survivalAbility = survivalAbility + 15
    end

    if HasTrait(t, "hunter") then
        survivalAbility = survivalAbility + 10
    end

    if HasTrait(t, "hiker") then
        survivalAbility = survivalAbility + 8
    end

    if HasTrait(t, "wildernessknowledge") then
        survivalAbility = survivalAbility + 10
    end

    --------------------------------------------------------
    -- LOGISTICS ABILITY
    --------------------------------------------------------

    local logisticsAbility =
        Skill("Strength") * 4 +
        Skill("Maintenance") * 3 +
        Skill("Mechanics") * 2

    if HasTrait(t, "organized") then
        logisticsAbility = logisticsAbility + 10
    end

    if HasTrait(t, "disorganized") then
        logisticsAbility = logisticsAbility - 10
    end

    --------------------------------------------------------
    -- RECON ABILITY
    --------------------------------------------------------

    local reconAbility =
        Skill("Fitness") * 3 +
        Skill("Aiming") * 2 +
        Skill("Maintenance") * 2

    if HasTrait(t, "keenhearing") then
        reconAbility = reconAbility + 10
    end

    if HasTrait(t, "eagleeyed") then
        reconAbility = reconAbility + 10
    end

    if HasTrait(t, "outdoorsman") then
        reconAbility = reconAbility + 10
    end

    if HasTrait(t, "hiker") then
        reconAbility = reconAbility + 8
    end

    --------------------------------------------------------
    -- AGRICULTURE ABILITY
    --------------------------------------------------------

    local agricultureAbility =
        Skill("Farming") * 10 +
        Skill("Cooking") * 2

    if HasTrait(t, "gardener") then
        agricultureAbility = agricultureAbility + 15
    end

    --------------------------------------------------------
    -- SECURITY ABILITY
    --------------------------------------------------------

    local securityAbility =
        Skill("Aiming") * 5 +
        Skill("Fitness") * 3 +
        Skill("Strength") * 2

    if HasTrait(t, "keenhearing") then
        securityAbility = securityAbility + 10
    end

    if HasTrait(t, "eagleeyed") then
        securityAbility = securityAbility + 10
    end

    if HasTrait(t, "brave") then
        securityAbility = securityAbility + 8
    end

    --------------------------------------------------------
    -- LEADERSHIP ABILITY
    --------------------------------------------------------

    local leadershipAbility =
        Skill("Aiming") * 2 +
        Skill("Fitness") * 2 +
        Skill("Strength") * 2

    if HasTrait(t, "brave") then
        leadershipAbility = leadershipAbility + 10
    end

    if HasTrait(t, "desensitized") then
        leadershipAbility = leadershipAbility + 5
    end

    --------------------------------------------------------
    -- FINAL CHARACTERISTICS
    --------------------------------------------------------

    local characteristics = {

        PhysicalPower = Clamp(
            physicalPower,
            0,
            100
        ),

        Endurance = Clamp(
            endurance,
            0,
            100
        ),

        CombatPotential = Clamp(
            combatPotential,
            0,
            100
        ),

        TechnicalAbility = Clamp(
            technicalAbility,
            0,
            100
        ),

        ConstructionAbility = Clamp(
            constructionAbility,
            0,
            100
        ),

        MedicalAbility = Clamp(
            medicalAbility,
            0,
            100
        ),

        SurvivalAbility = Clamp(
            survivalAbility,
            0,
            100
        ),

        LogisticsAbility = Clamp(
            logisticsAbility,
            0,
            100
        ),

        ReconAbility = Clamp(
            reconAbility,
            0,
            100
        ),

        AgricultureAbility = Clamp(
            agricultureAbility,
            0,
            100
        ),

        SecurityAbility = Clamp(
            securityAbility,
            0,
            100
        ),

        LeadershipAbility = Clamp(
            leadershipAbility,
            0,
            100
        )
    }

    return characteristics
end

------------------------------------------------------------
-- BEHAVIORAL PROFILE
--
-- Это НЕ характеристики.
--
-- Характеристики:
-- "насколько способен"
--
-- Поведение:
-- "как действует"
------------------------------------------------------------

local function CalculateBehavior(characteristics, traits)

    local t = traits or {}
    local c = characteristics or {}

    --------------------------------------------------------
    -- BASE VALUES
    --------------------------------------------------------

    local aggression = 50
    local courage = 50
    local discipline = 50
    local curiosity = 50

    --------------------------------------------------------
    -- AGGRESSION
    --------------------------------------------------------

    if HasTrait(t, "brawler") then
        aggression = aggression + 15
    end

    if HasTrait(t, "brave") then
        aggression = aggression + 8
    end

    if HasTrait(t, "pacifist") then
        aggression = aggression - 25
    end

    --------------------------------------------------------
    -- COURAGE
    --------------------------------------------------------

    if HasTrait(t, "brave") then
        courage = courage + 25
    end

    if HasTrait(t, "cowardly") then
        courage = courage - 30
    end

    if HasTrait(t, "desensitized") then
        courage = courage + 10
    end

    --------------------------------------------------------
    -- DISCIPLINE
    --------------------------------------------------------

    if HasTrait(t, "organized") then
        discipline = discipline + 15
    end

    if HasTrait(t, "disorganized") then
        discipline = discipline - 15
    end

    --------------------------------------------------------
    -- CURIOSITY
    --------------------------------------------------------

    if HasTrait(t, "inventive") then
        curiosity = curiosity + 10
    end

    if HasTrait(t, "outdoorsman") then
        curiosity = curiosity + 8
    end

    --------------------------------------------------------
    -- CLAMP BASIC VALUES
    --------------------------------------------------------

    aggression = Clamp(
        aggression,
        0,
        100
    )

    courage = Clamp(
        courage,
        0,
        100
    )

    discipline = Clamp(
        discipline,
        0,
        100
    )

    curiosity = Clamp(
        curiosity,
        0,
        100
    )

    --------------------------------------------------------
    -- FEAR
    --------------------------------------------------------

    local fear = 100 - courage

    --------------------------------------------------------
    -- LOYALTY
    --
    -- Пока базовое значение.
    --
    -- Позже сюда подключим:
    -- faction loyalty
    -- squad loyalty
    -- commander relationship
    -- personal relationships
    --------------------------------------------------------

    local loyalty = 50

    --------------------------------------------------------
    -- RISK TOLERANCE
    --------------------------------------------------------

    local riskTolerance =
        40 +
        aggression * 0.25 +
        courage * 0.25

    --------------------------------------------------------
    -- PLAYER HOSTILITY
    --------------------------------------------------------

    local playerHostility = 50

    if (c.CombatPotential or 0) >= 60 then
        playerHostility = playerHostility + 10
    end

    if HasTrait(t, "pacifist") then
        playerHostility = playerHostility - 20
    end

    --------------------------------------------------------
    -- FINAL BEHAVIOR
    --------------------------------------------------------

    local behavior = {

        Aggression = Clamp(
            aggression,
            0,
            100
        ),

        Courage = Clamp(
            courage,
            0,
            100
        ),

        Fear = Clamp(
            fear,
            0,
            100
        ),

        Discipline = Clamp(
            discipline,
            0,
            100
        ),

        Loyalty = Clamp(
            loyalty,
            0,
            100
        ),

        RiskTolerance = Clamp(
            riskTolerance,
            0,
            100
        ),

        Curiosity = Clamp(
            curiosity,
            0,
            100
        ),

        PlayerHostility = Clamp(
            playerHostility,
            0,
            100
        )
    }

    return behavior
end

------------------------------------------------------------
-- CREATE PROFILE
------------------------------------------------------------

function PlayerProfile.Create(player)

    if not player then
        Error("Cannot create profile: player is nil")
        return nil
    end

    Log("Creating Player Profile V2")

    --------------------------------------------------------
    -- BASIC DATA
    --------------------------------------------------------

    local username = GetUsername(player)
    local displayName = GetDisplayName(player)

    --------------------------------------------------------
    -- RAW DATA
    --------------------------------------------------------

    local profession = GetProfession(player)
    local traits = GetTraits(player)
    local skills = GetSkills(player)
    local maxWeight = GetMaxWeight(player)

    --------------------------------------------------------
    -- CHARACTERISTICS
    --------------------------------------------------------

    local characteristics =
        CalculateCharacteristics(
            skills,
            traits
        )

    --------------------------------------------------------
    -- BEHAVIOR
    --------------------------------------------------------

    local behavior =
        CalculateBehavior(
            characteristics,
            traits
        )

    --------------------------------------------------------
    -- PROFILE
    --------------------------------------------------------

    local profile = {

        Version = 2,

        Username = username,

        DisplayName = displayName,

        Profession = profession,

        Traits = traits,

        Skills = skills,

        MaxWeight = maxWeight,

        Characteristics = characteristics,

        Behavior = behavior,

        ----------------------------------------------------
        -- FUTURE SYSTEMS
        ----------------------------------------------------

        Role = nil,

        Specialization = nil,

        EquipmentProfile = nil,

        CurrentTask = nil,

        SquadID = nil,

        FactionID = nil,

        ----------------------------------------------------
        -- FUTURE MEMORY SYSTEM
        ----------------------------------------------------

        Memory = {},

        Relationships = {},

        ThreatAssessment = {}
    }

    --------------------------------------------------------
    -- LOG PROFILE
    --------------------------------------------------------

    Log("----------------------------------------")
    Log("PLAYER PROFILE V2 CREATED")
    Log("----------------------------------------")

    Log(
        "Username: " ..
        tostring(profile.Username)
    )

    Log(
        "DisplayName: " ..
        tostring(profile.DisplayName)
    )

    Log(
        "Profession: " ..
        tostring(profile.Profession.ID)
    )

    Log(
        "MaxWeight: " ..
        tostring(profile.MaxWeight)
    )

    --------------------------------------------------------
    -- CHARACTERISTICS LOG
    --------------------------------------------------------

    Log("Characteristics:")

    for name, value in pairs(profile.Characteristics) do

        Log(
            "  " ..
            tostring(name) ..
            " = " ..
            tostring(value)
        )
    end

    --------------------------------------------------------
    -- BEHAVIOR LOG
    --------------------------------------------------------

    Log("Behavior:")

    for name, value in pairs(profile.Behavior) do

        Log(
            "  " ..
            tostring(name) ..
            " = " ..
            tostring(value)
        )
    end

    --------------------------------------------------------
    -- STORE
    --------------------------------------------------------

    PlayerProfile.Current = profile

    Log("----------------------------------------")
    Log("Player Profile V2 initialization complete")
    Log("----------------------------------------")

    return profile
end

------------------------------------------------------------
-- GET CURRENT PROFILE
------------------------------------------------------------

function PlayerProfile.Get()

    return PlayerProfile.Current
end

------------------------------------------------------------
-- GET CHARACTERISTIC
------------------------------------------------------------

function PlayerProfile.GetCharacteristic(name)

    local profile = PlayerProfile.Current

    if not profile then
        return nil
    end

    if not profile.Characteristics then
        return nil
    end

    return profile.Characteristics[name]
end

------------------------------------------------------------
-- GET BEHAVIOR VALUE
------------------------------------------------------------

function PlayerProfile.GetBehavior(name)

    local profile = PlayerProfile.Current

    if not profile then
        return nil
    end

    if not profile.Behavior then
        return nil
    end

    return profile.Behavior[name]
end

------------------------------------------------------------
-- GET TRAIT
------------------------------------------------------------

function PlayerProfile.HasTrait(traitName)

    local profile = PlayerProfile.Current

    if not profile then
        return false
    end

    return HasTrait(
        profile.Traits,
        traitName
    )
end

------------------------------------------------------------
-- GET SKILL
------------------------------------------------------------

function PlayerProfile.GetSkill(skillName)

    local profile = PlayerProfile.Current

    if not profile then
        return 0
    end

    if not profile.Skills then
        return 0
    end

    return profile.Skills[skillName] or 0
end

------------------------------------------------------------
-- PRINT PROFILE
--
-- Удобная функция для будущего админ-HUD.
------------------------------------------------------------

function PlayerProfile.PrintProfile()

    local profile = PlayerProfile.Current

    if not profile then
        Warning("No current player profile")
        return
    end

    Log("========================================")
    Log("CURRENT PLAYER PROFILE")
    Log("========================================")

    Log(
        "Username: " ..
        tostring(profile.Username)
    )

    Log(
        "Profession: " ..
        tostring(profile.Profession.ID)
    )

    Log("")

    Log("Traits:")

    for traitName, active in pairs(profile.Traits) do

        if active then
            Log(
                "  " ..
                tostring(traitName)
            )
        end
    end

    Log("")

    Log("Skills:")

    for skillName, level in pairs(profile.Skills) do

        Log(
            "  " ..
            tostring(skillName) ..
            " = " ..
            tostring(level)
        )
    end

    Log("")

    Log("Characteristics:")

    for name, value in pairs(profile.Characteristics) do

        Log(
            "  " ..
            tostring(name) ..
            " = " ..
            tostring(value)
        )
    end

    Log("")

    Log("Behavior:")

    for name, value in pairs(profile.Behavior) do

        Log(
            "  " ..
            tostring(name) ..
            " = " ..
            tostring(value)
        )
    end

    Log("========================================")
end

------------------------------------------------------------
-- GAME START
------------------------------------------------------------

local function OnGameStart()

    Log("OnGameStart event received")

    local player = GetPlayer()

    if not player then
        Error("Player unavailable during OnGameStart")
        return
    end

    PlayerProfile.Create(player)
end

------------------------------------------------------------
-- PLAYER CREATED
--
-- В мультиплеере игрок может создаваться отдельно
-- от OnGameStart, поэтому здесь профиль тоже
-- можно пересоздать.
------------------------------------------------------------

local function OnCreatePlayer(playerIndex, player)

    Log("OnCreatePlayer event received")

    if not player then
        Warning("OnCreatePlayer received nil player")
        return
    end

    local username = GetUsername(player)

    Log(
        "Creating profile for player: " ..
        tostring(username)
    )

    PlayerProfile.Create(player)
end

------------------------------------------------------------
-- EVENT REGISTRATION
------------------------------------------------------------

if Events then

    if Events.OnGameStart then

        Events.OnGameStart.Add(
            OnGameStart
        )

        Log("OnGameStart handler registered")

    else

        Warning("Events.OnGameStart unavailable")

    end

    if Events.OnCreatePlayer then

        Events.OnCreatePlayer.Add(
            OnCreatePlayer
        )

        Log("OnCreatePlayer handler registered")

    else

        Warning("Events.OnCreatePlayer unavailable")

    end

else

    Error("Events object unavailable")
end

------------------------------------------------------------
-- MODULE LOADED
------------------------------------------------------------

Log("Player Profile V2 module loaded")