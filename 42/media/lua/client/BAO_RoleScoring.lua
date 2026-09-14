---@diagnostic disable: undefined-global

------------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_RoleScoring.lua
--
-- ROLE SCORING SYSTEM
--
-- Архитектура:
--
-- Player / NPC Profile
--        ↓
-- Characteristics
--        +
-- Profession
--        +
-- Traits
--        +
-- Skills
--        +
-- Behavior
--        ↓
-- Role Scores
--        ↓
-- Primary Role
-- Secondary Role
--
-- ВАЖНО:
--
-- Этот модуль пока НЕ назначает специализацию.
--
-- Пример:
--
-- Role:
--     Recon
--
-- Specialization:
--     Scout
--
-- Specialization будет отдельным следующим слоем.
------------------------------------------------------------

BAO = BAO or {}
BAO.RoleScoring = BAO.RoleScoring or {}

local RoleScoring = BAO.RoleScoring

------------------------------------------------------------
-- LOGGING
------------------------------------------------------------

local function Log(message)
    print("[BAO][RoleScoring] " .. tostring(message))
end

local function Warning(message)
    print("[BAO][RoleScoring][WARNING] " .. tostring(message))
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
-- TRAIT CHECK
------------------------------------------------------------

local function HasTrait(profile, traitName)

    if not profile then
        return false
    end

    if not profile.Traits then
        return false
    end

    return profile.Traits[traitName] == true
end

------------------------------------------------------------
-- CHARACTERISTIC
------------------------------------------------------------

local function GetCharacteristic(profile, name)

    if not profile then
        return 0
    end

    if not profile.Characteristics then
        return 0
    end

    return tonumber(
        profile.Characteristics[name]
    ) or 0
end

------------------------------------------------------------
-- SKILL
------------------------------------------------------------

local function GetSkill(profile, name)

    if not profile then
        return 0
    end

    if not profile.Skills then
        return 0
    end

    return tonumber(
        profile.Skills[name]
    ) or 0
end

------------------------------------------------------------
-- BEHAVIOR
------------------------------------------------------------

local function GetBehavior(profile, name)

    if not profile then
        return 50
    end

    if not profile.Behavior then
        return 50
    end

    return tonumber(
        profile.Behavior[name]
    ) or 50
end

------------------------------------------------------------
-- PROFESSION
------------------------------------------------------------

local function GetProfession(profile)

    if not profile then
        return "unknown"
    end

    if not profile.Profession then
        return "unknown"
    end

    return string.lower(
        tostring(
            profile.Profession.ID or "unknown"
        )
    )
end

------------------------------------------------------------
-- ROLE DEFINITIONS
--
-- Здесь находятся ВСЕ основные роли.
--
-- Позже можно будет расширить список,
-- не ломая существующую систему.
------------------------------------------------------------

RoleScoring.Roles = {

    --------------------------------------------------------
    -- COMBAT
    --
    -- Боевые бойцы.
    --------------------------------------------------------

    Combat = {

        ID = "combat",

        Name = "Combat",

        Description =
            "Основной боевой боец.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- RECON
    --
    -- Разведка, наблюдение, поиск.
    --------------------------------------------------------

    Recon = {

        ID = "recon",

        Name = "Recon",

        Description =
            "Разведчик и наблюдатель.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- SECURITY
    --
    -- Охрана базы, ворот, периметра.
    --------------------------------------------------------

    Security = {

        ID = "security",

        Name = "Security",

        Description =
            "Охрана территории и объектов.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- MEDICAL
    --------------------------------------------------------

    Medical = {

        ID = "medical",

        Name = "Medical",

        Description =
            "Медицинский персонал.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- ENGINEERING
    --
    -- Механика, электричество, сварка.
    --------------------------------------------------------

    Engineering = {

        ID = "engineering",

        Name = "Engineering",

        Description =
            "Инженер и технический специалист.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- CONSTRUCTION
    --
    -- Строительство и ремонт сооружений.
    --------------------------------------------------------

    Construction = {

        ID = "construction",

        Name = "Construction",

        Description =
            "Строитель и специалист по укреплениям.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- LOGISTICS
    --
    -- Груз, транспорт, снабжение.
    --------------------------------------------------------

    Logistics = {

        ID = "logistics",

        Name = "Logistics",

        Description =
            "Логистика, снабжение и транспорт.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- AGRICULTURE
    --
    -- Фермы, растения, производство еды.
    --------------------------------------------------------

    Agriculture = {

        ID = "agriculture",

        Name = "Agriculture",

        Description =
            "Сельское хозяйство и производство еды.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- SURVIVAL
    --
    -- Жизнь вне базы, добыча ресурсов.
    --------------------------------------------------------

    Survival = {

        ID = "survival",

        Name = "Survival",

        Description =
            "Выживание и добыча ресурсов.",

        BaseScore = 0
    },

    --------------------------------------------------------
    -- COMMAND
    --
    -- Командование.
    --------------------------------------------------------

    Command = {

        ID = "command",

        Name = "Command",

        Description =
            "Командование подразделением.",

        BaseScore = 0
    }
}

------------------------------------------------------------
-- PROFESSION AFFINITY
--
-- ВАЖНО:
--
-- Профессия НЕ меняет характеристики.
--
-- Она только говорит:
--
-- "этот человек имеет профессиональную
-- склонность к такой деятельности".
--
-- Это позволяет:
--
-- mechanic + слабая механика
-- НЕ становится автоматически инженером.
--
-- Но mechanic + хорошая механика
-- получает дополнительное преимущество.
------------------------------------------------------------

RoleScoring.ProfessionAffinity = {

    mechanic = {

        engineering = 25,
        logistics = 8
    },

    electrician = {

        engineering = 25
    },

    carpenter = {

        construction = 25,
        logistics = 5
    },

    metalworker = {

        engineering = 20,
        construction = 15
    },

    farmer = {

        agriculture = 30,
        survival = 10
    },

    fisherman = {

        survival = 25,
        agriculture = 5
    },

    doctor = {

        medical = 40
    },

    nurse = {

        medical = 35
    },

    veteran = {

        combat = 20,
        security = 15,
        command = 10
    },

    police = {

        security = 25,
        combat = 15
    },

    policeofficer = {

        security = 25,
        combat = 15
    },

    burglar = {

        recon = 10,
        survival = 10
    },

    ranger = {

        recon = 25,
        survival = 20
    },

    park_ranger = {

        recon = 25,
        survival = 20
    },

    fireofficer = {

        combat = 15,
        security = 10,
        construction = 10
    },

    constructionworker = {

        construction = 25,
        logistics = 5
    },

    unemployed = {

        -- Никакого профессионального бонуса.
    }
}

------------------------------------------------------------
-- TRAIT ROLE BONUSES
--
-- Traits напрямую влияют на склонность к ролям.
------------------------------------------------------------

RoleScoring.TraitBonuses = {

    --------------------------------------------------------
    -- COMBAT
    --------------------------------------------------------

    brawler = {
        combat = 15
    },

    marksman = {
        combat = 20,
        security = 10
    },

    brave = {
        combat = 8,
        security = 8,
        command = 8
    },

    desensitized = {
        combat = 8,
        security = 8
    },

    target_shooter = {
        combat = 20,
        security = 10
    },

    --------------------------------------------------------
    -- RECON
    --------------------------------------------------------

    keenhearing = {
        recon = 15,
        security = 10
    },

    eagleeyed = {
        recon = 15,
        security = 10
    },

    outdoorsman = {
        recon = 12,
        survival = 15
    },

    hiker = {
        recon = 12,
        survival = 12
    },

    hunter = {
        recon = 15,
        survival = 20
    },

    former_scout = {
        recon = 25
    },

    formerscout = {
        recon = 25
    },

    --------------------------------------------------------
    -- MEDICAL
    --------------------------------------------------------

    firstaid = {
        medical = 25
    },

    --------------------------------------------------------
    -- ENGINEERING
    --------------------------------------------------------

    inventive = {
        engineering = 12
    },

    tinkerer = {
        engineering = 15
    },

    handy = {
        engineering = 8,
        construction = 10
    },

    blacksmith = {
        engineering = 15,
        construction = 10
    },

    --------------------------------------------------------
    -- CONSTRUCTION
    --------------------------------------------------------

    mason = {
        construction = 20
    },

    --------------------------------------------------------
    -- AGRICULTURE
    --------------------------------------------------------

    gardener = {
        agriculture = 25
    },

    --------------------------------------------------------
    -- SURVIVAL
    --------------------------------------------------------

    wildernessknowledge = {
        survival = 20,
        recon = 10
    },

    herbalist = {
        survival = 15,
        medical = 5
    },

    --------------------------------------------------------
    -- LOGISTICS
    --------------------------------------------------------

    organized = {
        logistics = 15,
        command = 5
    },

    disorganized = {
        logistics = -15
    },

    --------------------------------------------------------
    -- COMMAND
    --------------------------------------------------------

    leadership = {
        command = 20
    }
}

------------------------------------------------------------
-- SCORE HELPERS
------------------------------------------------------------

local function AddScore(scores, role, amount)

    if scores[role] == nil then
        scores[role] = 0
    end

    scores[role] =
        scores[role] + amount
end

------------------------------------------------------------
-- CHARACTERISTIC SCORING
------------------------------------------------------------

local function ApplyCharacteristics(
    profile,
    scores
)

    --------------------------------------------------------
    -- COMBAT
    --------------------------------------------------------

    AddScore(
        scores,
        "combat",
        GetCharacteristic(
            profile,
            "CombatPotential"
        ) * 0.70
    )

    AddScore(
        scores,
        "combat",
        GetCharacteristic(
            profile,
            "PhysicalPower"
        ) * 0.10
    )

    --------------------------------------------------------
    -- RECON
    --------------------------------------------------------

    AddScore(
        scores,
        "recon",
        GetCharacteristic(
            profile,
            "ReconAbility"
        ) * 0.75
    )

    AddScore(
        scores,
        "recon",
        GetCharacteristic(
            profile,
            "SurvivalAbility"
        ) * 0.15
    )

    --------------------------------------------------------
    -- SECURITY
    --------------------------------------------------------

    AddScore(
        scores,
        "security",
        GetCharacteristic(
            profile,
            "SecurityAbility"
        ) * 0.70
    )

    AddScore(
        scores,
        "security",
        GetCharacteristic(
            profile,
            "CombatPotential"
        ) * 0.20
    )

    --------------------------------------------------------
    -- MEDICAL
    --------------------------------------------------------

    AddScore(
        scores,
        "medical",
        GetCharacteristic(
            profile,
            "MedicalAbility"
        ) * 0.90
    )

    --------------------------------------------------------
    -- ENGINEERING
    --------------------------------------------------------

    AddScore(
        scores,
        "engineering",
        GetCharacteristic(
            profile,
            "TechnicalAbility"
        ) * 0.85
    )

    --------------------------------------------------------
    -- CONSTRUCTION
    --------------------------------------------------------

    AddScore(
        scores,
        "construction",
        GetCharacteristic(
            profile,
            "ConstructionAbility"
        ) * 0.90
    )

    --------------------------------------------------------
    -- LOGISTICS
    --------------------------------------------------------

    AddScore(
        scores,
        "logistics",
        GetCharacteristic(
            profile,
            "LogisticsAbility"
        ) * 0.80
    )

    AddScore(
        scores,
        "logistics",
        GetCharacteristic(
            profile,
            "PhysicalPower"
        ) * 0.10
    )

    --------------------------------------------------------
    -- AGRICULTURE
    --------------------------------------------------------

    AddScore(
        scores,
        "agriculture",
        GetCharacteristic(
            profile,
            "AgricultureAbility"
        ) * 0.90
    )

    AddScore(
        scores,
        "agriculture",
        GetCharacteristic(
            profile,
            "SurvivalAbility"
        ) * 0.10
    )

    --------------------------------------------------------
    -- SURVIVAL
    --------------------------------------------------------

    AddScore(
        scores,
        "survival",
        GetCharacteristic(
            profile,
            "SurvivalAbility"
        ) * 0.80
    )

    AddScore(
        scores,
        "survival",
        GetCharacteristic(
            profile,
            "ReconAbility"
        ) * 0.15
    )

    --------------------------------------------------------
    -- COMMAND
    --------------------------------------------------------

    AddScore(
        scores,
        "command",
        GetCharacteristic(
            profile,
            "LeadershipAbility"
        ) * 0.80
    )

    AddScore(
        scores,
        "command",
        GetCharacteristic(
            profile,
            "SecurityAbility"
        ) * 0.10
    )
end

------------------------------------------------------------
-- SKILL SCORING
--
-- Навыки дают дополнительный небольшой бонус.
--
-- Почему небольшой?
--
-- Потому что характеристики уже построены
-- на основе навыков.
--
-- Здесь навыки используются как "специализированный
-- сигнал", а не как двойное масштабирование.
------------------------------------------------------------

local function ApplySkills(
    profile,
    scores
)

    --------------------------------------------------------
    -- COMBAT
    --------------------------------------------------------

    AddScore(
        scores,
        "combat",
        GetSkill(
            profile,
            "Aiming"
        ) * 1.5
    )

    AddScore(
        scores,
        "combat",
        GetSkill(
            profile,
            "Reloading"
        ) * 0.8
    )

    --------------------------------------------------------
    -- ENGINEERING
    --------------------------------------------------------

    AddScore(
        scores,
        "engineering",
        GetSkill(
            profile,
            "Mechanics"
        ) * 1.5
    )

    AddScore(
        scores,
        "engineering",
        GetSkill(
            profile,
            "Electrical"
        ) * 1.2
    )

    AddScore(
        scores,
        "engineering",
        GetSkill(
            profile,
            "MetalWelding"
        ) * 1.2
    )

    --------------------------------------------------------
    -- CONSTRUCTION
    --------------------------------------------------------

    AddScore(
        scores,
        "construction",
        GetSkill(
            profile,
            "Carpentry"
        ) * 1.2
    )

    AddScore(
        scores,
        "construction",
        GetSkill(
            profile,
            "Woodwork"
        ) * 1.2
    )

    --------------------------------------------------------
    -- MEDICAL
    --------------------------------------------------------

    AddScore(
        scores,
        "medical",
        GetSkill(
            profile,
            "FirstAid"
        ) * 1.5
    )

    --------------------------------------------------------
    -- AGRICULTURE
    --------------------------------------------------------

    AddScore(
        scores,
        "agriculture",
        GetSkill(
            profile,
            "Farming"
        ) * 1.5
    )

    --------------------------------------------------------
    -- SURVIVAL
    --------------------------------------------------------

    AddScore(
        scores,
        "survival",
        GetSkill(
            profile,
            "Fishing"
        ) * 1.2
    )

    AddScore(
        scores,
        "survival",
        GetSkill(
            profile,
            "Cooking"
        ) * 0.8
    )

    --------------------------------------------------------
    -- LOGISTICS
    --------------------------------------------------------

    AddScore(
        scores,
        "logistics",
        GetSkill(
            profile,
            "Mechanics"
        ) * 0.5
    )

    AddScore(
        scores,
        "logistics",
        GetSkill(
            profile,
            "Maintenance"
        ) * 0.8
    )
end

------------------------------------------------------------
-- TRAIT SCORING
------------------------------------------------------------

local function ApplyTraits(
    profile,
    scores
)

    local traits = profile.Traits

    if not traits then
        return
    end

    for traitName, active in pairs(traits) do

        if active then

            local bonuses =
                RoleScoring.TraitBonuses[
                    traitName
                ]

            if bonuses then

                for role, amount in pairs(bonuses) do

                    AddScore(
                        scores,
                        role,
                        amount
                    )
                end
            end
        end
    end
end

------------------------------------------------------------
-- PROFESSION SCORING
------------------------------------------------------------

local function ApplyProfession(
    profile,
    scores
)

    local profession =
        GetProfession(profile)

    local bonuses =
        RoleScoring.ProfessionAffinity[
            profession
        ]

    if not bonuses then
        return
    end

    for role, amount in pairs(bonuses) do

        AddScore(
            scores,
            role,
            amount
        )
    end
end

------------------------------------------------------------
-- BEHAVIOR SCORING
------------------------------------------------------------

local function ApplyBehavior(
    profile,
    scores
)

    --------------------------------------------------------
    -- AGGRESSION
    --
    -- Агрессивный NPC немного больше склоняется
    -- к Combat/Security.
    --------------------------------------------------------

    local aggression =
        GetBehavior(
            profile,
            "Aggression"
        )

    if aggression > 60 then

        local bonus =
            (aggression - 60) * 0.20

        AddScore(
            scores,
            "combat",
            bonus
        )

        AddScore(
            scores,
            "security",
            bonus * 0.5
        )
    end

    --------------------------------------------------------
    -- COURAGE
    --------------------------------------------------------

    local courage =
        GetBehavior(
            profile,
            "Courage"
        )

    if courage > 60 then

        local bonus =
            (courage - 60) * 0.20

        AddScore(
            scores,
            "combat",
            bonus
        )

        AddScore(
            scores,
            "security",
            bonus
        )

        AddScore(
            scores,
            "command",
            bonus * 0.5
        )
    end

    --------------------------------------------------------
    -- DISCIPLINE
    --------------------------------------------------------

    local discipline =
        GetBehavior(
            profile,
            "Discipline"
        )

    if discipline > 60 then

        local bonus =
            (discipline - 60) * 0.20

        AddScore(
            scores,
            "security",
            bonus
        )

        AddScore(
            scores,
            "logistics",
            bonus
        )

        AddScore(
            scores,
            "command",
            bonus
        )
    end

    --------------------------------------------------------
    -- CURIOSITY
    --
    -- Любопытный NPC немного чаще подходит
    -- для разведки/поиска.
    --------------------------------------------------------

    local curiosity =
        GetBehavior(
            profile,
            "Curiosity"
        )

    if curiosity > 60 then

        local bonus =
            (curiosity - 60) * 0.25

        AddScore(
            scores,
            "recon",
            bonus
        )

        AddScore(
            scores,
            "survival",
            bonus * 0.5
        )
    end

    --------------------------------------------------------
    -- PLAYER HOSTILITY
    --------------------------------------------------------

    local hostility =
        GetBehavior(
            profile,
            "PlayerHostility"
        )

    if hostility > 65 then

        AddScore(
            scores,
            "combat",
            (hostility - 65) * 0.20
        )

        AddScore(
            scores,
            "security",
            (hostility - 65) * 0.15
        )
    end
end

------------------------------------------------------------
-- INITIALIZE SCORES
------------------------------------------------------------

local function InitializeScores()

    local scores = {}

    for _, role in pairs(RoleScoring.Roles) do

        scores[role.ID] =
            role.BaseScore or 0
    end

    return scores
end

------------------------------------------------------------
-- SORT SCORES
------------------------------------------------------------

local function SortScores(scores)

    local result = {}

    for role, score in pairs(scores) do

        table.insert(
            result,
            {
                Role = role,
                Score = Clamp(
                    score,
                    0,
                    100
                )
            }
        )
    end

    table.sort(
        result,
        function(a, b)
            return a.Score > b.Score
        end
    )

    return result
end

------------------------------------------------------------
-- CALCULATE
--
-- Главная функция системы.
------------------------------------------------------------

function RoleScoring.Calculate(profile)

    if not profile then

        Warning(
            "Cannot calculate role scores: profile is nil"
        )

        return nil
    end

    Log("Calculating role scores...")

    --------------------------------------------------------
    -- INITIAL SCORES
    --------------------------------------------------------

    local scores =
        InitializeScores()

    --------------------------------------------------------
    -- APPLY ALL FACTORS
    --------------------------------------------------------

    ApplyCharacteristics(
        profile,
        scores
    )

    ApplySkills(
        profile,
        scores
    )

    ApplyTraits(
        profile,
        scores
    )

    ApplyProfession(
        profile,
        scores
    )

    ApplyBehavior(
        profile,
        scores
    )

    --------------------------------------------------------
    -- SORT
    --------------------------------------------------------

    local sorted =
        SortScores(scores)

    --------------------------------------------------------
    -- PRIMARY ROLE
    --------------------------------------------------------

    local primaryRole = nil

    if sorted[1] then
        primaryRole = sorted[1]
    end

    --------------------------------------------------------
    -- SECONDARY ROLE
    --------------------------------------------------------

    local secondaryRole = nil

    if sorted[2] then
        secondaryRole = sorted[2]
    end

    --------------------------------------------------------
    -- RESULT
    --------------------------------------------------------

    local result = {

        Scores = scores,

        Sorted = sorted,

        PrimaryRole =
            primaryRole,

        SecondaryRole =
            secondaryRole
    }

    --------------------------------------------------------
    -- LOG
    --------------------------------------------------------

    Log("----------------------------------------")
    Log("ROLE SCORING RESULT")
    Log("----------------------------------------")

    for index, entry in ipairs(sorted) do

        Log(
            tostring(index) ..
            ". " ..
            tostring(entry.Role) ..
            " = " ..
            tostring(entry.Score)
        )
    end

    Log("----------------------------------------")

    if primaryRole then

        Log(
            "Primary Role: " ..
            tostring(primaryRole.Role) ..
            " (" ..
            tostring(primaryRole.Score) ..
            ")"
        )
    end

    if secondaryRole then

        Log(
            "Secondary Role: " ..
            tostring(secondaryRole.Role) ..
            " (" ..
            tostring(secondaryRole.Score) ..
            ")"
        )
    end

    Log("----------------------------------------")

    return result
end

------------------------------------------------------------
-- CALCULATE CURRENT PLAYER
------------------------------------------------------------

function RoleScoring.CalculateCurrentPlayer()

    if not BAO.PlayerProfile then

        Warning(
            "BAO.PlayerProfile unavailable"
        )

        return nil
    end

    local profile =
        BAO.PlayerProfile.Get()

    if not profile then

        Warning(
            "Current PlayerProfile unavailable"
        )

        return nil
    end

    local result =
        RoleScoring.Calculate(
            profile
        )

    if result then

        profile.RoleScoring =
            result

        ----------------------------------------------------
        -- Пока Primary Role НЕ записываем в Role.
        --
        -- Это специально.
        --
        -- Позже будет отдельная система,
        -- которая учитывает потребности squad/faction.
        ----------------------------------------------------

    end

    return result
end

------------------------------------------------------------
-- PRINT CURRENT ROLE SCORES
------------------------------------------------------------

function RoleScoring.PrintCurrent()

    local profile =
        BAO.PlayerProfile.Get()

    if not profile then

        Warning(
            "No current PlayerProfile"
        )

        return
    end

    if not profile.RoleScoring then

        Warning(
            "Role scores have not been calculated"
        )

        return
    end

    local result =
        profile.RoleScoring

    Log("========================================")
    Log("CURRENT ROLE SCORES")
    Log("========================================")

    for index, entry in ipairs(result.Sorted) do

        Log(
            tostring(index) ..
            ". " ..
            tostring(entry.Role) ..
            " = " ..
            tostring(entry.Score)
        )
    end

    Log("========================================")
end

------------------------------------------------------------
-- GAME START
--
-- Пока используем OnGameStart только для тестирования.
--
-- Позже этот автоматический расчёт будет перенесён
-- в полноценную NPC initialization pipeline.
------------------------------------------------------------

local function OnGameStart()

    Log("OnGameStart event received")

    if not BAO.PlayerProfile then

        Warning(
            "PlayerProfile module unavailable"
        )

        return
    end

    local profile =
        BAO.PlayerProfile.Get()

    if not profile then

        Warning(
            "PlayerProfile not ready"
        )

        return
    end

    Log(
        "PlayerProfile detected. Starting role scoring."
    )

    RoleScoring.CalculateCurrentPlayer()
end

------------------------------------------------------------
-- EVENT REGISTRATION
------------------------------------------------------------

if Events then

    if Events.OnGameStart then

        Events.OnGameStart.Add(
            OnGameStart
        )

        Log(
            "OnGameStart handler registered"
        )

    else

        Warning(
            "Events.OnGameStart unavailable"
        )
    end

else

    Warning(
        "Events object unavailable"
    )
end

------------------------------------------------------------
-- MODULE LOADED
------------------------------------------------------------

Log("Role Scoring module loaded")