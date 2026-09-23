---@diagnostic disable: undefined-global

------------------------------------------------------------
-- BanditsAIOverhaul
-- BAO_Specialization.lua
--
-- Specialization Scoring V1
--
-- Архитектура:
--
-- PlayerProfile
--      ↓
-- RoleScoring
--      ↓
-- SpecializationScoring
--      ↓
-- Primary Specialization
-- Secondary Specialization
--
-- ВАЖНО:
-- Этот модуль определяет естественную специализацию NPC.
-- Позже Squad/Faction AI сможет временно переопределять
-- назначение NPC в зависимости от потребностей отряда.
------------------------------------------------------------

BAO = BAO or {}
BAO.Specialization = BAO.Specialization or {}

local Specialization = BAO.Specialization


------------------------------------------------------------
-- LOGGING
------------------------------------------------------------

local function Log(message)
    print("[BAO][Specialization] " .. tostring(message))
end


------------------------------------------------------------
-- SAFE CALL
------------------------------------------------------------

local function SafeCall(func, default)
    local ok, result = pcall(func)

    if ok then
        return result
    end

    return default
end


------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or 0

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end


local function GetCharacteristic(profile, name)
    if not profile then
        return 0
    end

    if not profile.Characteristics then
        return 0
    end

    return tonumber(profile.Characteristics[name]) or 0
end


local function GetSkill(profile, name)
    if not profile then
        return 0
    end

    if not profile.Skills then
        return 0
    end

    return tonumber(profile.Skills[name]) or 0
end


local function GetBehavior(profile, name)
    if not profile then
        return 0
    end

    if not profile.Behavior then
        return 0
    end

    return tonumber(profile.Behavior[name]) or 0
end


local function HasTrait(profile, traitName)
    if not profile then
        return false
    end

    if not profile.Traits then
        return false
    end

    return profile.Traits[traitName] == true
end


local function GetProfession(profile)
    if not profile then
        return ""
    end

    return tostring(profile.Profession or "")
end


------------------------------------------------------------
-- SPECIALIZATION DEFINITIONS
------------------------------------------------------------
--
-- Каждая специализация содержит:
--
-- role
--      Основная роль, внутри которой она существует.
--
-- score
--      Функция расчёта естественной пригодности.
--
-- Позже сюда можно будет добавить:
-- equipmentProfile
-- preferredWeapons
-- preferredTasks
-- squadPosition
-- etc.
------------------------------------------------------------

Specialization.Definitions = {

    --------------------------------------------------------
    -- COMBAT
    --------------------------------------------------------

    rifleman = {
        role = "combat",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "CombatPotential") * 0.55
                + GetCharacteristic(profile, "SecurityAbility") * 0.15
                + GetSkill(profile, "Aiming") * 2.0
                + GetSkill(profile, "Reloading") * 1.0

            if HasTrait(profile, "brave") then
                score = score + 8
            end

            if HasTrait(profile, "brawler") then
                score = score + 5
            end

            if HasTrait(profile, "marksman") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    assault = {
        role = "combat",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "CombatPotential") * 0.60
                + GetCharacteristic(profile, "PhysicalPower") * 0.15
                + GetCharacteristic(profile, "Endurance") * 0.10
                + GetSkill(profile, "Aiming") * 1.5

            if HasTrait(profile, "brawler") then
                score = score + 10
            end

            if HasTrait(profile, "brave") then
                score = score + 10
            end

            if HasTrait(profile, "desensitized") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    marksman = {
        role = "combat",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "CombatPotential") * 0.45
                + GetCharacteristic(profile, "ReconAbility") * 0.25
                + GetCharacteristic(profile, "SecurityAbility") * 0.10
                + GetSkill(profile, "Aiming") * 2.5

            if HasTrait(profile, "marksman") then
                score = score + 20
            end

            if HasTrait(profile, "target_shooter") then
                score = score + 15
            end

            if HasTrait(profile, "eagleeyed") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    heavy_gunner = {
        role = "combat",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "PhysicalPower") * 0.35
                + GetCharacteristic(profile, "CombatPotential") * 0.35
                + GetCharacteristic(profile, "Endurance") * 0.20
                + GetSkill(profile, "Aiming") * 1.2

            if HasTrait(profile, "strong") then
                score = score + 12
            end

            if HasTrait(profile, "stout") then
                score = score + 8
            end

            if HasTrait(profile, "athletic") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    cqb = {
        role = "combat",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "CombatPotential") * 0.45
                + GetCharacteristic(profile, "PhysicalPower") * 0.25
                + GetCharacteristic(profile, "Endurance") * 0.20

            if HasTrait(profile, "brawler") then
                score = score + 15
            end

            if HasTrait(profile, "brave") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    interceptor = {
        role = "combat",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "CombatPotential") * 0.40
                + GetCharacteristic(profile, "Endurance") * 0.25
                + GetCharacteristic(profile, "ReconAbility") * 0.15
                + GetBehavior(profile, "RiskTolerance") * 0.15

            if HasTrait(profile, "athletic") then
                score = score + 10
            end

            if HasTrait(profile, "jogger") then
                score = score + 6
            end

            if HasTrait(profile, "brave") then
                score = score + 6
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- RECON
    --------------------------------------------------------

    scout = {
        role = "recon",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ReconAbility") * 0.60
                + GetCharacteristic(profile, "SurvivalAbility") * 0.15
                + GetSkill(profile, "Aiming") * 1.0
                + GetBehavior(profile, "Curiosity") * 0.10

            if HasTrait(profile, "eagleeyed") then
                score = score + 12
            end

            if HasTrait(profile, "keenhearing") then
                score = score + 10
            end

            if HasTrait(profile, "outdoorsman") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    pathfinder = {
        role = "recon",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ReconAbility") * 0.45
                + GetCharacteristic(profile, "SurvivalAbility") * 0.35
                + GetCharacteristic(profile, "Endurance") * 0.10

            if HasTrait(profile, "outdoorsman") then
                score = score + 15
            end

            if HasTrait(profile, "hiker") then
                score = score + 12
            end

            if HasTrait(profile, "wildernessknowledge") then
                score = score + 15
            end

            return Clamp(score, 0, 100)
        end
    },


    resource_scout = {
        role = "recon",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ReconAbility") * 0.40
                + GetCharacteristic(profile, "SurvivalAbility") * 0.30
                + GetCharacteristic(profile, "LogisticsAbility") * 0.15

            if HasTrait(profile, "outdoorsman") then
                score = score + 10
            end

            if HasTrait(profile, "hunter") then
                score = score + 10
            end

            if HasTrait(profile, "forager") then
                score = score + 15
            end

            return Clamp(score, 0, 100)
        end
    },


    long_range_scout = {
        role = "recon",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ReconAbility") * 0.40
                + GetCharacteristic(profile, "Endurance") * 0.30
                + GetCharacteristic(profile, "SurvivalAbility") * 0.20

            if HasTrait(profile, "outdoorsman") then
                score = score + 12
            end

            if HasTrait(profile, "hiker") then
                score = score + 15
            end

            if HasTrait(profile, "jogger") then
                score = score + 8
            end

            if HasTrait(profile, "athletic") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    forward_observer = {
        role = "recon",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ReconAbility") * 0.45
                + GetCharacteristic(profile, "SecurityAbility") * 0.20
                + GetCharacteristic(profile, "CombatPotential") * 0.20
                + GetBehavior(profile, "Discipline") * 0.10

            if HasTrait(profile, "eagleeyed") then
                score = score + 10
            end

            if HasTrait(profile, "keenhearing") then
                score = score + 8
            end

            if HasTrait(profile, "marksman") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- SECURITY
    --------------------------------------------------------

    gate_guard = {
        role = "security",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SecurityAbility") * 0.65
                + GetCharacteristic(profile, "CombatPotential") * 0.20
                + GetBehavior(profile, "Discipline") * 0.10

            if HasTrait(profile, "keenhearing") then
                score = score + 10
            end

            if HasTrait(profile, "eagleeyed") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    perimeter_guard = {
        role = "security",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SecurityAbility") * 0.50
                + GetCharacteristic(profile, "ReconAbility") * 0.25
                + GetCharacteristic(profile, "Endurance") * 0.10
                + GetBehavior(profile, "Discipline") * 0.10

            if HasTrait(profile, "keenhearing") then
                score = score + 10
            end

            if HasTrait(profile, "outdoorsman") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    watchman = {
        role = "security",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ReconAbility") * 0.40
                + GetCharacteristic(profile, "SecurityAbility") * 0.40
                + GetBehavior(profile, "Discipline") * 0.10

            if HasTrait(profile, "keenhearing") then
                score = score + 15
            end

            if HasTrait(profile, "eagleeyed") then
                score = score + 15
            end

            return Clamp(score, 0, 100)
        end
    },


    patrol_guard = {
        role = "security",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SecurityAbility") * 0.45
                + GetCharacteristic(profile, "CombatPotential") * 0.25
                + GetCharacteristic(profile, "Endurance") * 0.15
                + GetCharacteristic(profile, "ReconAbility") * 0.10

            if HasTrait(profile, "brave") then
                score = score + 8
            end

            if HasTrait(profile, "jogger") then
                score = score + 6
            end

            return Clamp(score, 0, 100)
        end
    },


    security_commander = {
        role = "security",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SecurityAbility") * 0.40
                + GetCharacteristic(profile, "LeadershipAbility") * 0.35
                + GetBehavior(profile, "Discipline") * 0.10
                + GetBehavior(profile, "Courage") * 0.10

            if HasTrait(profile, "leadership") then
                score = score + 20
            end

            if HasTrait(profile, "brave") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- MEDICAL
    --------------------------------------------------------

    medic = {
        role = "medical",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "MedicalAbility") * 0.75
                + GetSkill(profile, "FirstAid") * 2.0

            if HasTrait(profile, "firstaid") then
                score = score + 20
            end

            return Clamp(score, 0, 100)
        end
    },


    field_medic = {
        role = "medical",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "MedicalAbility") * 0.55
                + GetCharacteristic(profile, "CombatPotential") * 0.15
                + GetCharacteristic(profile, "SurvivalAbility") * 0.15
                + GetSkill(profile, "FirstAid") * 2.0

            if HasTrait(profile, "firstaid") then
                score = score + 15
            end

            if HasTrait(profile, "brave") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    medical_support = {
        role = "medical",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "MedicalAbility") * 0.60
                + GetCharacteristic(profile, "LogisticsAbility") * 0.20
                + GetCharacteristic(profile, "SurvivalAbility") * 0.10

            if HasTrait(profile, "organized") then
                score = score + 12
            end

            return Clamp(score, 0, 100)
        end
    },


    medical_coordinator = {
        role = "medical",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "MedicalAbility") * 0.55
                + GetCharacteristic(profile, "LeadershipAbility") * 0.25
                + GetCharacteristic(profile, "LogisticsAbility") * 0.15

            if HasTrait(profile, "leadership") then
                score = score + 15
            end

            if HasTrait(profile, "organized") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- ENGINEERING
    --------------------------------------------------------

    mechanic = {
        role = "engineering",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "TechnicalAbility") * 0.60
                + GetSkill(profile, "Mechanics") * 2.5
                + GetSkill(profile, "Maintenance") * 1.0

            if HasTrait(profile, "handy") then
                score = score + 10
            end

            if HasTrait(profile, "inventive") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    electrician = {
        role = "engineering",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "TechnicalAbility") * 0.60
                + GetSkill(profile, "Electrical") * 2.5

            if HasTrait(profile, "inventive") then
                score = score + 10
            end

            if HasTrait(profile, "tinkerer") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    welder = {
        role = "engineering",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "TechnicalAbility") * 0.55
                + GetSkill(profile, "MetalWelding") * 2.5
                + GetCharacteristic(profile, "PhysicalPower") * 0.10

            if HasTrait(profile, "blacksmith") then
                score = score + 15
            end

            if HasTrait(profile, "handy") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    vehicle_specialist = {
        role = "engineering",

        score = function(profile)

            local score =
                GetSkill(profile, "Mechanics") * 2.5
                + GetSkill(profile, "Maintenance") * 1.5
                + GetCharacteristic(profile, "TechnicalAbility") * 0.45

            if HasTrait(profile, "inventive") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    engineer = {
        role = "engineering",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "TechnicalAbility") * 0.50
                + GetCharacteristic(profile, "ConstructionAbility") * 0.20
                + GetSkill(profile, "Mechanics") * 1.2
                + GetSkill(profile, "Electrical") * 1.2
                + GetSkill(profile, "MetalWelding") * 1.2

            if HasTrait(profile, "inventive") then
                score = score + 15
            end

            if HasTrait(profile, "tinkerer") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- CONSTRUCTION
    --------------------------------------------------------

    builder = {
        role = "construction",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ConstructionAbility") * 0.65
                + GetSkill(profile, "Carpentry") * 2.0
                + GetSkill(profile, "Woodwork") * 1.5

            if HasTrait(profile, "handy") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    fortification_builder = {
        role = "construction",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ConstructionAbility") * 0.55
                + GetCharacteristic(profile, "SecurityAbility") * 0.15
                + GetSkill(profile, "Carpentry") * 1.5
                + GetSkill(profile, "MetalWelding") * 1.0

            if HasTrait(profile, "handy") then
                score = score + 10
            end

            if HasTrait(profile, "mason") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    carpenter = {
        role = "construction",

        score = function(profile)

            local score =
                GetSkill(profile, "Carpentry") * 2.5
                + GetSkill(profile, "Woodwork") * 2.0
                + GetCharacteristic(profile, "ConstructionAbility") * 0.45

            return Clamp(score, 0, 100)
        end
    },


    mason = {
        role = "construction",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ConstructionAbility") * 0.55
                + GetSkill(profile, "Carpentry") * 0.8

            if HasTrait(profile, "mason") then
                score = score + 25
            end

            return Clamp(score, 0, 100)
        end
    },


    repair_specialist = {
        role = "construction",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "ConstructionAbility") * 0.35
                + GetCharacteristic(profile, "TechnicalAbility") * 0.30
                + GetSkill(profile, "Maintenance") * 1.5
                + GetSkill(profile, "Carpentry") * 1.0
                + GetSkill(profile, "Mechanics") * 1.0

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- LOGISTICS
    --------------------------------------------------------

    driver = {
        role = "logistics",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LogisticsAbility") * 0.50
                + GetCharacteristic(profile, "TechnicalAbility") * 0.15
                + GetSkill(profile, "Mechanics") * 1.5
                + GetSkill(profile, "Maintenance") * 1.0

            return Clamp(score, 0, 100)
        end
    },


    transporter = {
        role = "logistics",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LogisticsAbility") * 0.60
                + GetCharacteristic(profile, "PhysicalPower") * 0.20
                + GetSkill(profile, "Maintenance") * 1.0

            if HasTrait(profile, "organized") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    quartermaster = {
        role = "logistics",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LogisticsAbility") * 0.55
                + GetCharacteristic(profile, "LeadershipAbility") * 0.20
                + GetBehavior(profile, "Discipline") * 0.15

            if HasTrait(profile, "organized") then
                score = score + 20
            end

            if HasTrait(profile, "disorganized") then
                score = score - 15
            end

            return Clamp(score, 0, 100)
        end
    },


    supply_runner = {
        role = "logistics",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LogisticsAbility") * 0.40
                + GetCharacteristic(profile, "Endurance") * 0.30
                + GetCharacteristic(profile, "PhysicalPower") * 0.15

            if HasTrait(profile, "jogger") then
                score = score + 8
            end

            if HasTrait(profile, "athletic") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    convoy_specialist = {
        role = "logistics",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LogisticsAbility") * 0.45
                + GetCharacteristic(profile, "TechnicalAbility") * 0.15
                + GetCharacteristic(profile, "SecurityAbility") * 0.15
                + GetSkill(profile, "Mechanics") * 1.0

            if HasTrait(profile, "organized") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- AGRICULTURE
    --------------------------------------------------------

    farmer = {
        role = "agriculture",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "AgricultureAbility") * 0.70
                + GetSkill(profile, "Farming") * 2.5
                + GetSkill(profile, "Cooking") * 0.5

            if HasTrait(profile, "gardener") then
                score = score + 20
            end

            return Clamp(score, 0, 100)
        end
    },


    animal_keeper = {
        role = "agriculture",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "AgricultureAbility") * 0.55
                + GetCharacteristic(profile, "SurvivalAbility") * 0.20

            if HasTrait(profile, "outdoorsman") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    harvester = {
        role = "agriculture",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "AgricultureAbility") * 0.55
                + GetCharacteristic(profile, "Endurance") * 0.20
                + GetCharacteristic(profile, "PhysicalPower") * 0.15

            if HasTrait(profile, "athletic") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    food_producer = {
        role = "agriculture",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "AgricultureAbility") * 0.50
                + GetSkill(profile, "Cooking") * 2.0
                + GetSkill(profile, "Farming") * 1.0

            return Clamp(score, 0, 100)
        end
    },


    agriculture_manager = {
        role = "agriculture",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "AgricultureAbility") * 0.45
                + GetCharacteristic(profile, "LeadershipAbility") * 0.30
                + GetCharacteristic(profile, "LogisticsAbility") * 0.15

            if HasTrait(profile, "organized") then
                score = score + 12
            end

            if HasTrait(profile, "leadership") then
                score = score + 15
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- SURVIVAL
    --------------------------------------------------------

    hunter = {
        role = "survival",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SurvivalAbility") * 0.50
                + GetCharacteristic(profile, "ReconAbility") * 0.25
                + GetSkill(profile, "Aiming") * 1.2
                + GetSkill(profile, "Fishing") * 0.5

            if HasTrait(profile, "hunter") then
                score = score + 25
            end

            if HasTrait(profile, "outdoorsman") then
                score = score + 10
            end

            return Clamp(score, 0, 100)
        end
    },


    forager = {
        role = "survival",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SurvivalAbility") * 0.55
                + GetCharacteristic(profile, "ReconAbility") * 0.25

            if HasTrait(profile, "outdoorsman") then
                score = score + 15
            end

            if HasTrait(profile, "forager") then
                score = score + 25
            end

            return Clamp(score, 0, 100)
        end
    },


    wilderness_scout = {
        role = "survival",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SurvivalAbility") * 0.45
                + GetCharacteristic(profile, "ReconAbility") * 0.30
                + GetCharacteristic(profile, "Endurance") * 0.15

            if HasTrait(profile, "outdoorsman") then
                score = score + 15
            end

            if HasTrait(profile, "hiker") then
                score = score + 12
            end

            if HasTrait(profile, "wildernessknowledge") then
                score = score + 15
            end

            return Clamp(score, 0, 100)
        end
    },


    fisher = {
        role = "survival",

        score = function(profile)

            local score =
                GetSkill(profile, "Fishing") * 3.0
                + GetCharacteristic(profile, "SurvivalAbility") * 0.55

            return Clamp(score, 0, 100)
        end
    },


    survival_specialist = {
        role = "survival",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "SurvivalAbility") * 0.55
                + GetCharacteristic(profile, "ReconAbility") * 0.15
                + GetCharacteristic(profile, "Endurance") * 0.15
                + GetCharacteristic(profile, "TechnicalAbility") * 0.10

            if HasTrait(profile, "outdoorsman") then
                score = score + 15
            end

            if HasTrait(profile, "wildernessknowledge") then
                score = score + 15
            end

            return Clamp(score, 0, 100)
        end
    },


    --------------------------------------------------------
    -- COMMAND
    --------------------------------------------------------

    squad_leader = {
        role = "command",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LeadershipAbility") * 0.50
                + GetCharacteristic(profile, "SecurityAbility") * 0.20
                + GetCharacteristic(profile, "CombatPotential") * 0.10
                + GetBehavior(profile, "Discipline") * 0.10

            if HasTrait(profile, "leadership") then
                score = score + 20
            end

            if HasTrait(profile, "brave") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    patrol_leader = {
        role = "command",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LeadershipAbility") * 0.40
                + GetCharacteristic(profile, "SecurityAbility") * 0.25
                + GetCharacteristic(profile, "ReconAbility") * 0.15
                + GetBehavior(profile, "Discipline") * 0.10

            if HasTrait(profile, "leadership") then
                score = score + 18
            end

            if HasTrait(profile, "brave") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    },


    operations_officer = {
        role = "command",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LeadershipAbility") * 0.35
                + GetCharacteristic(profile, "LogisticsAbility") * 0.25
                + GetCharacteristic(profile, "ReconAbility") * 0.15
                + GetBehavior(profile, "Discipline") * 0.15

            if HasTrait(profile, "organized") then
                score = score + 12
            end

            if HasTrait(profile, "leadership") then
                score = score + 15
            end

            return Clamp(score, 0, 100)
        end
    },


    faction_commander = {
        role = "command",

        score = function(profile)

            local score =
                GetCharacteristic(profile, "LeadershipAbility") * 0.50
                + GetCharacteristic(profile, "SecurityAbility") * 0.15
                + GetCharacteristic(profile, "LogisticsAbility") * 0.15
                + GetBehavior(profile, "Courage") * 0.10
                + GetBehavior(profile, "Discipline") * 0.10

            if HasTrait(profile, "leadership") then
                score = score + 25
            end

            if HasTrait(profile, "brave") then
                score = score + 8
            end

            return Clamp(score, 0, 100)
        end
    }
}


------------------------------------------------------------
-- ROLE → SPECIALIZATIONS
------------------------------------------------------------

Specialization.RoleSpecializations = {

    combat = {
        "rifleman",
        "assault",
        "marksman",
        "heavy_gunner",
        "cqb",
        "interceptor"
    },

    recon = {
        "scout",
        "pathfinder",
        "resource_scout",
        "long_range_scout",
        "forward_observer"
    },

    security = {
        "gate_guard",
        "perimeter_guard",
        "watchman",
        "patrol_guard",
        "security_commander"
    },

    medical = {
        "medic",
        "field_medic",
        "medical_support",
        "medical_coordinator"
    },

    engineering = {
        "mechanic",
        "electrician",
        "welder",
        "vehicle_specialist",
        "engineer"
    },

    construction = {
        "builder",
        "fortification_builder",
        "carpenter",
        "mason",
        "repair_specialist"
    },

    logistics = {
        "driver",
        "transporter",
        "quartermaster",
        "supply_runner",
        "convoy_specialist"
    },

    agriculture = {
        "farmer",
        "animal_keeper",
        "harvester",
        "food_producer",
        "agriculture_manager"
    },

    survival = {
        "hunter",
        "forager",
        "wilderness_scout",
        "fisher",
        "survival_specialist"
    },

    command = {
        "squad_leader",
        "patrol_leader",
        "operations_officer",
        "faction_commander"
    }
}


------------------------------------------------------------
-- SPECIALIZATION NAMES
------------------------------------------------------------

Specialization.Names = {

    rifleman = "Rifleman",
    assault = "Assault",
    marksman = "Marksman",
    heavy_gunner = "Heavy Gunner",
    cqb = "CQB",
    interceptor = "Interceptor",

    scout = "Scout",
    pathfinder = "Pathfinder",
    resource_scout = "Resource Scout",
    long_range_scout = "Long Range Scout",
    forward_observer = "Forward Observer",

    gate_guard = "Gate Guard",
    perimeter_guard = "Perimeter Guard",
    watchman = "Watchman",
    patrol_guard = "Patrol Guard",
    security_commander = "Security Commander",

    medic = "Medic",
    field_medic = "Field Medic",
    medical_support = "Medical Support",
    medical_coordinator = "Medical Coordinator",

    mechanic = "Mechanic",
    electrician = "Electrician",
    welder = "Welder",
    vehicle_specialist = "Vehicle Specialist",
    engineer = "Engineer",

    builder = "Builder",
    fortification_builder = "Fortification Builder",
    carpenter = "Carpenter",
    mason = "Mason",
    repair_specialist = "Repair Specialist",

    driver = "Driver",
    transporter = "Transporter",
    quartermaster = "Quartermaster",
    supply_runner = "Supply Runner",
    convoy_specialist = "Convoy Specialist",

    farmer = "Farmer",
    animal_keeper = "Animal Keeper",
    harvester = "Harvester",
    food_producer = "Food Producer",
    agriculture_manager = "Agriculture Manager",

    hunter = "Hunter",
    forager = "Forager",
    wilderness_scout = "Wilderness Scout",
    fisher = "Fisher",
    survival_specialist = "Survival Specialist",

    squad_leader = "Squad Leader",
    patrol_leader = "Patrol Leader",
    operations_officer = "Operations Officer",
    faction_commander = "Faction Commander"
}


------------------------------------------------------------
-- CALCULATE SPECIALIZATIONS
------------------------------------------------------------

function Specialization.Calculate(profile, roleName)

    if not profile then
        Log("ERROR: profile is nil")
        return nil
    end


    --------------------------------------------------------
    -- Safety:
    -- roleName may come from RoleScoring as a table.
    --
    -- Example:
    -- {
    --     Role = "survival",
    --     Score = 39.75
    -- }
    --------------------------------------------------------

    if type(roleName) == "table" then

        roleName = roleName.Role

    end


    if not roleName or roleName == "" then
        Log("ERROR: roleName is nil")
        return nil
    end


    roleName = tostring(roleName)

    local roleSpecializations =
        Specialization.RoleSpecializations[roleName]

    if not roleSpecializations then
        Log("ERROR: No specializations for role: " .. tostring(roleName))
        return nil
    end

    local results = {}

    for _, specializationName in ipairs(roleSpecializations) do

        local definition =
            Specialization.Definitions[specializationName]

        if definition and definition.score then

            local score = SafeCall(function()
                return definition.score(profile)
            end, 0)

            score = Clamp(score, 0, 100)

            table.insert(results, {
                ID = specializationName,
                Name = Specialization.Names[specializationName]
                    or specializationName,
                Role = definition.role,
                Score = score
            })
        end
    end


    --------------------------------------------------------
    -- SORT
    --------------------------------------------------------

    table.sort(results, function(a, b)
        return a.Score > b.Score
    end)


    --------------------------------------------------------
    -- STORE
    --------------------------------------------------------

    local result = {
        Role = roleName,
        Specializations = results,
        Primary = results[1],
        Secondary = results[2],

        -- Естественная специализация NPC.
        -- Эти значения описывают врождённую пригодность персонажа
        -- и позже не будут напрямую зависеть от текущего задания.
        NaturalRole = roleName,
        NaturalSpecialization = results[1],
        SecondarySpecialization = results[2]
    }

    profile.SpecializationScoring = result

    -- Дублируем основные значения в профиле для удобного доступа
    -- другим системам BAO без необходимости разбирать результат скоринга.
    profile.NaturalRole = roleName
    profile.NaturalSpecialization = results[1]
    profile.SecondarySpecialization = results[2]


    return result
end


------------------------------------------------------------
-- CALCULATE FROM PROFILE
------------------------------------------------------------

function Specialization.CalculateFromProfile(profile)

    if not profile then
        Log("ERROR: profile is nil")
        return nil
    end

    if not profile.RoleScoring then
        Log("ERROR: RoleScoring not found in profile")
        return nil
    end

    local primaryRole =
        profile.RoleScoring.PrimaryRole

    if not primaryRole then
        Log("ERROR: PrimaryRole not found")
        return nil
    end


    --------------------------------------------------------
    -- RoleScoring stores PrimaryRole as a table:
    --
    -- {
    --     Role = "survival",
    --     Score = 39.75
    -- }
    --
    -- Specialization system needs the role ID:
    --
    -- "survival"
    --------------------------------------------------------

    if type(primaryRole) == "table" then

        primaryRole =
            primaryRole.Role

    end


    if not primaryRole then
        Log("ERROR: Could not extract role ID from PrimaryRole")
        return nil
    end


    primaryRole = tostring(primaryRole)

    Log(
        "Primary role detected: "
        .. primaryRole
    )


    return Specialization.Calculate(
        profile,
        primaryRole
    )
end


------------------------------------------------------------
-- CURRENT PLAYER
------------------------------------------------------------

function Specialization.GetPrimary(profile)

    if not profile then
        return nil
    end

    local result = profile.SpecializationScoring

    if not result then
        return nil
    end

    return result.Primary
end


function Specialization.GetSecondary(profile)

    if not profile then
        return nil
    end

    local result = profile.SpecializationScoring

    if not result then
        return nil
    end

    return result.Secondary
end


function Specialization.GetNaturalRole(profile)

    if not profile then
        return nil
    end

    if profile.NaturalRole then
        return profile.NaturalRole
    end

    local result = profile.SpecializationScoring

    if result and result.NaturalRole then
        return result.NaturalRole
    end

    return result and result.Role or nil
end


function Specialization.GetNaturalSpecialization(profile)

    if not profile then
        return nil
    end

    if profile.NaturalSpecialization then
        return profile.NaturalSpecialization
    end

    local result = profile.SpecializationScoring

    if result and result.NaturalSpecialization then
        return result.NaturalSpecialization
    end

    return result and result.Primary or nil
end


function Specialization.GetSecondarySpecialization(profile)

    if not profile then
        return nil
    end

    if profile.SecondarySpecialization then
        return profile.SecondarySpecialization
    end

    local result = profile.SpecializationScoring

    if result and result.SecondarySpecialization then
        return result.SecondarySpecialization
    end

    return result and result.Secondary or nil
end


function Specialization.PrintNaturalProfile(profile)

    if not profile then
        Log("ERROR: Profile not found")
        return
    end

    local naturalRole =
        Specialization.GetNaturalRole(profile)

    local naturalSpecialization =
        Specialization.GetNaturalSpecialization(profile)

    local secondarySpecialization =
        Specialization.GetSecondarySpecialization(profile)

    Log("========================================")
    Log("NATURAL PROFILE")
    Log("========================================")

    Log(
        "Role: "
        .. tostring(naturalRole)
    )

    if naturalSpecialization then
        Log(
            "Primary Specialization: "
            .. tostring(naturalSpecialization.ID)
            .. " ("
            .. string.format(
                "%.2f",
                tonumber(naturalSpecialization.Score) or 0
            )
            .. ")"
        )
    else
        Log("Primary Specialization: none")
    end

    if secondarySpecialization then
        Log(
            "Secondary Specialization: "
            .. tostring(secondarySpecialization.ID)
            .. " ("
            .. string.format(
                "%.2f",
                tonumber(secondarySpecialization.Score) or 0
            )
            .. ")"
        )
    else
        Log("Secondary Specialization: none")
    end

    Log("========================================")
end


------------------------------------------------------------
-- CURRENT PLAYER
------------------------------------------------------------

function Specialization.CalculateCurrentPlayer()

    if not BAO.PlayerProfile then
        Log("ERROR: PlayerProfile module not loaded")
        return nil
    end

    if not BAO.PlayerProfile.Get then
        Log("ERROR: PlayerProfile.Get not found")
        return nil
    end

    local profile =
        BAO.PlayerProfile.Get()

    if not profile then
        Log("ERROR: Current player profile not found")
        return nil
    end

    if not profile.RoleScoring then

        if BAO.RoleScoring
            and BAO.RoleScoring.CalculateCurrentPlayer then

            Log("RoleScoring missing. Calculating RoleScoring now.")

            BAO.RoleScoring.CalculateCurrentPlayer()
        end
    end

    return Specialization.CalculateFromProfile(profile)
end


------------------------------------------------------------
-- PRINT RESULT
------------------------------------------------------------

function Specialization.PrintCurrent()

    local profile =
        BAO.PlayerProfile
        and BAO.PlayerProfile.Get
        and BAO.PlayerProfile.Get()

    if not profile then
        Log("ERROR: Player profile not found")
        return
    end

    local result =
        profile.SpecializationScoring

    if not result then
        Log("No specialization result found")
        return
    end


    Log("========================================")
    Log("SPECIALIZATION SCORING RESULT")
    Log("========================================")

    Log("Role: " .. tostring(result.Role))

    for index, specialization in ipairs(result.Specializations) do

        Log(
            tostring(index)
            .. ". "
            .. tostring(specialization.ID)
            .. " = "
            .. string.format("%.2f", specialization.Score)
        )
    end


    if result.Primary then

        Log(
            "Primary Specialization: "
            .. tostring(result.Primary.ID)
            .. " ("
            .. string.format("%.2f", result.Primary.Score)
            .. ")"
        )
    end


    if result.Secondary then

        Log(
            "Secondary Specialization: "
            .. tostring(result.Secondary.ID)
            .. " ("
            .. string.format("%.2f", result.Secondary.Score)
            .. ")"
        )
    end

    Log("========================================")
end


------------------------------------------------------------
-- GAME START
------------------------------------------------------------

function Specialization.OnGameStart()

    Log("OnGameStart event received")

    if not BAO.PlayerProfile then
        Log("ERROR: PlayerProfile module unavailable")
        return
    end

    if not BAO.RoleScoring then
        Log("ERROR: RoleScoring module unavailable")
        return
    end

    local profile =
        BAO.PlayerProfile.Get()

    if not profile then
        Log("ERROR: Player Profile not found")
        return
    end

    Log("PlayerProfile detected")

    --------------------------------------------------------
    -- RoleScoring
    --------------------------------------------------------

    if not profile.RoleScoring then

        Log("RoleScoring not found. Calculating.")

        BAO.RoleScoring.CalculateCurrentPlayer()
    end

    --------------------------------------------------------
    -- Specialization
    --------------------------------------------------------

    local result =
        Specialization.CalculateFromProfile(profile)

    if not result then
        Log("ERROR: Specialization calculation failed")
        return
    end

    Specialization.PrintCurrent()

    --------------------------------------------------------
    -- NATURAL PROFILE
    --------------------------------------------------------

    Specialization.PrintNaturalProfile(profile)

    Log("Specialization Scoring V1.1 initialization complete")
end


------------------------------------------------------------
-- EVENT REGISTRATION
------------------------------------------------------------

if Events then

    if Events.OnGameStart then

        Events.OnGameStart.Add(
            Specialization.OnGameStart
        )

        Log("OnGameStart handler registered")

    else

        Log("WARNING: Events.OnGameStart not found")

    end

else

    Log("WARNING: Events object not available")

end


------------------------------------------------------------
-- MODULE LOADED
------------------------------------------------------------

Log("Specialization Scoring module loaded")