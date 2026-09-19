---@diagnostic disable: undefined-global

------------------------------------------------------------
-- BAO Behavior Profile
-- BanditsAIOverhaul
-- Build 42.20
--
-- Purpose:
-- Creates a unified behavioral/personality profile from:
--   - Characteristics
--   - Skills
--   - Traits
--   - Profession
--   - Role
--   - Specialization
--   - Personality / behavior values
--
-- This module does NOT control NPC actions yet.
-- It only describes HOW the character tends to behave.
------------------------------------------------------------

BAO = BAO or {}
BAO.BehaviorProfile = BAO.BehaviorProfile or {}

local BehaviorProfile = BAO.BehaviorProfile

------------------------------------------------------------
-- LOGGING
------------------------------------------------------------

local function Log(message)
    print("[BAO][BehaviorProfile] " .. tostring(message))
end

------------------------------------------------------------
-- SAFE HELPERS
------------------------------------------------------------

local function SafeCall(object, methodName, ...)
    if not object then
        return nil
    end

    local method = object[methodName]

    if type(method) ~= "function" then
        return nil
    end

    local success, result = pcall(method, object, ...)

    if success then
        return result
    end

    return nil
end

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

local function Round(value)
    return math.floor((value or 0) + 0.5)
end

------------------------------------------------------------
-- PROFILE ACCESS
------------------------------------------------------------

local function GetCharacteristic(profile, name)
    if not profile then
        return 0
    end

    if profile.Characteristics then
        return tonumber(profile.Characteristics[name]) or 0
    end

    return 0
end

local function GetSkill(profile, name)
    if not profile then
        return 0
    end

    if profile.Skills then
        return tonumber(profile.Skills[name]) or 0
    end

    return 0
end

local function GetBehavior(profile, name)
    if not profile then
        return 50
    end

    if profile.Behavior then
        return tonumber(profile.Behavior[name]) or 50
    end

    return 50
end

local function HasTrait(profile, traitName)
    if not profile then
        return false
    end

    if not profile.Traits then
        return false
    end

    for _, trait in ipairs(profile.Traits) do
        if tostring(trait) == traitName then
            return true
        end
    end

    return false
end

local function GetProfession(profile)
    if not profile then
        return "unemployed"
    end

    return tostring(profile.Profession or "unemployed")
end

local function GetNaturalRole(profile)
    if not profile then
        return nil
    end

    return profile.NaturalRole
end

local function GetNaturalSpecialization(profile)
    if not profile then
        return nil
    end

    return profile.NaturalSpecialization
end

local function GetSecondarySpecialization(profile)
    if not profile then
        return nil
    end

    return profile.SecondarySpecialization
end

------------------------------------------------------------
-- BEHAVIOR PROFILE CALCULATION
------------------------------------------------------------

function BehaviorProfile.Calculate(profile)
    if not profile then
        Log("Calculate failed: profile is nil")
        return nil
    end

    --------------------------------------------------------
    -- BASIC DATA
    --------------------------------------------------------

    local naturalRole = GetNaturalRole(profile)
    local naturalSpecialization = GetNaturalSpecialization(profile)
    local secondarySpecialization = GetSecondarySpecialization(profile)

    local profession = GetProfession(profile)

    --------------------------------------------------------
    -- RAW PERSONALITY VALUES
    --------------------------------------------------------

    local aggression = GetBehavior(profile, "Aggression")
    local courage = GetBehavior(profile, "Courage")
    local fear = GetBehavior(profile, "Fear")
    local discipline = GetBehavior(profile, "Discipline")
    local loyalty = GetBehavior(profile, "Loyalty")
    local riskTolerance = GetBehavior(profile, "RiskTolerance")
    local curiosity = GetBehavior(profile, "Curiosity")
    local playerHostility = GetBehavior(profile, "PlayerHostility")

    --------------------------------------------------------
    -- CHARACTERISTICS
    --------------------------------------------------------

    local physicalPower = GetCharacteristic(profile, "PhysicalPower")
    local endurance = GetCharacteristic(profile, "Endurance")
    local combatPotential = GetCharacteristic(profile, "CombatPotential")
    local technicalAbility = GetCharacteristic(profile, "TechnicalAbility")
    local constructionAbility = GetCharacteristic(profile, "ConstructionAbility")
    local medicalAbility = GetCharacteristic(profile, "MedicalAbility")
    local survivalAbility = GetCharacteristic(profile, "SurvivalAbility")
    local logisticsAbility = GetCharacteristic(profile, "LogisticsAbility")
    local reconAbility = GetCharacteristic(profile, "ReconAbility")
    local agricultureAbility = GetCharacteristic(profile, "AgricultureAbility")
    local securityAbility = GetCharacteristic(profile, "SecurityAbility")
    local leadershipAbility = GetCharacteristic(profile, "LeadershipAbility")

    --------------------------------------------------------
    -- SKILLS
    --------------------------------------------------------

    local aiming = GetSkill(profile, "Aiming")
    local fitness = GetSkill(profile, "Fitness")
    local strength = GetSkill(profile, "Strength")
    local cooking = GetSkill(profile, "Cooking")
    local farming = GetSkill(profile, "Farming")
    local firstAid = GetSkill(profile, "FirstAid")
    local mechanics = GetSkill(profile, "Mechanics")
    local metalWelding = GetSkill(profile, "MetalWelding")
    local carpentry = GetSkill(profile, "Carpentry")
    local woodwork = GetSkill(profile, "Woodwork")
    local electrical = GetSkill(profile, "Electrical")
    local tailoring = GetSkill(profile, "Tailoring")
    local reloading = GetSkill(profile, "Reloading")
    local maintenance = GetSkill(profile, "Maintenance")

    --------------------------------------------------------
    -- DERIVED COMBAT PROFILE
    --------------------------------------------------------

    local combatConfidence =
        (combatPotential * 0.45) +
        (aiming * 6) +
        (fitness * 4) +
        (strength * 3) +
        (courage * 0.10) +
        (discipline * 0.05)

    combatConfidence = Clamp(combatConfidence, 0, 100)

    local combatAggression =
        (aggression * 0.45) +
        (courage * 0.20) +
        (riskTolerance * 0.20) +
        (playerHostility * 0.15)

    combatAggression = Clamp(combatAggression, 0, 100)

    local combatDiscipline =
        (discipline * 0.50) +
        (courage * 0.10) +
        (leadershipAbility * 0.20) +
        (securityAbility * 0.20)

    combatDiscipline = Clamp(combatDiscipline, 0, 100)

    --------------------------------------------------------
    -- SURVIVAL PROFILE
    --------------------------------------------------------

    local survivalCapability =
        (survivalAbility * 0.45) +
        (endurance * 0.20) +
        (reconAbility * 0.15) +
        (curiosity * 0.10) +
        (physicalPower * 0.10)

    survivalCapability = Clamp(survivalCapability, 0, 100)

    local wildernessConfidence =
        (survivalAbility * 0.45) +
        (reconAbility * 0.25) +
        (curiosity * 0.15) +
        (riskTolerance * 0.15)

    wildernessConfidence = Clamp(wildernessConfidence, 0, 100)

    --------------------------------------------------------
    -- RECON PROFILE
    --------------------------------------------------------

    local reconCapability =
        (reconAbility * 0.45) +
        (curiosity * 0.20) +
        (riskTolerance * 0.15) +
        (survivalAbility * 0.10) +
        (securityAbility * 0.10)

    reconCapability = Clamp(reconCapability, 0, 100)

    local scoutingConfidence =
        (reconAbility * 0.45) +
        (curiosity * 0.25) +
        (courage * 0.10) +
        (riskTolerance * 0.20)

    scoutingConfidence = Clamp(scoutingConfidence, 0, 100)

    --------------------------------------------------------
    -- SECURITY PROFILE
    --------------------------------------------------------

    local securityCapability =
        (securityAbility * 0.45) +
        (discipline * 0.20) +
        (combatPotential * 0.15) +
        (courage * 0.10) +
        (leadershipAbility * 0.10)

    securityCapability = Clamp(securityCapability, 0, 100)

    --------------------------------------------------------
    -- TECHNICAL PROFILE
    --------------------------------------------------------

    local technicalCapability =
        (technicalAbility * 0.30) +
        (mechanics * 5) +
        (electrical * 5) +
        (metalWelding * 4) +
        (maintenance * 3) +
        (curiosity * 0.10)

    technicalCapability = Clamp(technicalCapability, 0, 100)

    --------------------------------------------------------
    -- CONSTRUCTION PROFILE
    --------------------------------------------------------

    local constructionCapability =
        (constructionAbility * 0.40) +
        (carpentry * 5) +
        (woodwork * 5) +
        (metalWelding * 3) +
        (strength * 2)

    constructionCapability = Clamp(constructionCapability, 0, 100)

    --------------------------------------------------------
    -- MEDICAL PROFILE
    --------------------------------------------------------

    local medicalCapability =
        (medicalAbility * 0.55) +
        (firstAid * 8) +
        (discipline * 0.15) +
        (curiosity * 0.10) +
        (loyalty * 0.10)

    medicalCapability = Clamp(medicalCapability, 0, 100)

    --------------------------------------------------------
    -- LOGISTICS PROFILE
    --------------------------------------------------------

    local logisticsCapability =
        (logisticsAbility * 0.45) +
        (discipline * 0.20) +
        (strength * 3) +
        (maintenance * 3) +
        (curiosity * 0.10)

    logisticsCapability = Clamp(logisticsCapability, 0, 100)

    --------------------------------------------------------
    -- AGRICULTURE PROFILE
    --------------------------------------------------------

    local agricultureCapability =
        (agricultureAbility * 0.50) +
        (farming * 8) +
        (cooking * 2) +
        (survivalAbility * 0.10) +
        (discipline * 0.10)

    agricultureCapability = Clamp(agricultureCapability, 0, 100)

    --------------------------------------------------------
    -- SOCIAL / GROUP PROFILE
    --------------------------------------------------------

    local leadership =
        (leadershipAbility * 0.45) +
        (discipline * 0.20) +
        (courage * 0.10) +
        (loyalty * 0.15) +
        (aggression * 0.10)

    leadership = Clamp(leadership, 0, 100)

    local cooperation =
        (loyalty * 0.40) +
        (discipline * 0.25) +
        (courage * 0.10) +
        ((100 - aggression) * 0.10) +
        ((100 - playerHostility) * 0.15)

    cooperation = Clamp(cooperation, 0, 100)

    --------------------------------------------------------
    -- FEAR / RETREAT PROFILE
    --------------------------------------------------------

    local fearResponse =
        (fear * 0.50) +
        ((100 - courage) * 0.20) +
        ((100 - riskTolerance) * 0.20) +
        ((100 - combatConfidence) * 0.10)

    fearResponse = Clamp(fearResponse, 0, 100)

    local retreatTendency =
        (fear * 0.35) +
        ((100 - courage) * 0.25) +
        ((100 - riskTolerance) * 0.25) +
        ((100 - combatConfidence) * 0.15)

    retreatTendency = Clamp(retreatTendency, 0, 100)

    --------------------------------------------------------
    -- EXPLORATION PROFILE
    --------------------------------------------------------

    local explorationDrive =
        (curiosity * 0.40) +
        (riskTolerance * 0.20) +
        (survivalAbility * 0.15) +
        (reconAbility * 0.15) +
        (courage * 0.10)

    explorationDrive = Clamp(explorationDrive, 0, 100)

    --------------------------------------------------------
    -- RESOURCE BEHAVIOR
    --------------------------------------------------------

    local resourcePriority =
        (survivalAbility * 0.30) +
        (logisticsAbility * 0.20) +
        (curiosity * 0.20) +
        (discipline * 0.15) +
        (agricultureAbility * 0.15)

    resourcePriority = Clamp(resourcePriority, 0, 100)

    --------------------------------------------------------
    -- BUILD FINAL PROFILE
    --------------------------------------------------------

    local result = {

        ----------------------------------------------------
        -- IDENTITY
        ----------------------------------------------------

        Profession = profession,

        NaturalRole = naturalRole,
        NaturalSpecialization = naturalSpecialization,
        SecondarySpecialization = secondarySpecialization,

        ----------------------------------------------------
        -- PERSONALITY
        ----------------------------------------------------

        Personality = {

            Aggression = aggression,
            Courage = courage,
            Fear = fear,
            Discipline = discipline,
            Loyalty = loyalty,
            RiskTolerance = riskTolerance,
            Curiosity = curiosity,
            PlayerHostility = playerHostility
        },

        ----------------------------------------------------
        -- CAPABILITIES
        ----------------------------------------------------

        Capabilities = {

            Combat = Round(combatConfidence),
            Survival = Round(survivalCapability),
            Recon = Round(reconCapability),
            Security = Round(securityCapability),
            Technical = Round(technicalCapability),
            Construction = Round(constructionCapability),
            Medical = Round(medicalCapability),
            Logistics = Round(logisticsCapability),
            Agriculture = Round(agricultureCapability),
            Leadership = Round(leadership)
        },

        ----------------------------------------------------
        -- BEHAVIOR TENDENCIES
        ----------------------------------------------------

        Tendencies = {

            CombatAggression = Round(combatAggression),
            CombatDiscipline = Round(combatDiscipline),

            WildernessConfidence = Round(wildernessConfidence),
            ScoutingConfidence = Round(scoutingConfidence),

            Cooperation = Round(cooperation),

            FearResponse = Round(fearResponse),
            RetreatTendency = Round(retreatTendency),

            ExplorationDrive = Round(explorationDrive),
            ResourcePriority = Round(resourcePriority)
        },

        ----------------------------------------------------
        -- RAW SKILLS
        ----------------------------------------------------

        Skills = {

            Aiming = aiming,
            Fitness = fitness,
            Strength = strength,

            Cooking = cooking,
            Farming = farming,
            FirstAid = firstAid,

            Mechanics = mechanics,
            MetalWelding = metalWelding,
            Carpentry = carpentry,
            Woodwork = woodwork,
            Electrical = electrical,
            Tailoring = tailoring,
            Reloading = reloading,
            Maintenance = maintenance
        },

        ----------------------------------------------------
        -- TRAIT FLAGS
        ----------------------------------------------------

        Traits = {

            Strong = HasTrait(profile, "strong"),
            Outdoorsman = HasTrait(profile, "outdoorsman"),
            Jogger = HasTrait(profile, "jogger"),
            Athletic = HasTrait(profile, "athletic"),
            Brave = HasTrait(profile, "brave"),
            Cowardly = HasTrait(profile, "cowardly"),
            Desensitized = HasTrait(profile, "desensitized"),
            FastLearner = HasTrait(profile, "fastlearner"),
            Hiker = HasTrait(profile, "hiker"),
            Hunter = HasTrait(profile, "hunter"),
            Burglar = HasTrait(profile, "burglar"),
            Handy = HasTrait(profile, "handy"),
            Organized = HasTrait(profile, "organized")
        }
    }

    --------------------------------------------------------
    -- SAVE PROFILE
    --------------------------------------------------------

    profile.BehaviorProfile = result

    Log("----------------------------------------")
    Log("BEHAVIOR PROFILE CREATED")
    Log("----------------------------------------")

    Log("Profession: " .. tostring(result.Profession))
    Log("Natural Role: " .. tostring(result.NaturalRole))
    Log("Natural Specialization: " .. tostring(result.NaturalSpecialization))
    Log("Secondary Specialization: " .. tostring(result.SecondarySpecialization))

    Log("----------------------------------------")
    Log("PERSONALITY")
    Log("----------------------------------------")

    Log("Aggression: " .. result.Personality.Aggression)
    Log("Courage: " .. result.Personality.Courage)
    Log("Fear: " .. result.Personality.Fear)
    Log("Discipline: " .. result.Personality.Discipline)
    Log("Loyalty: " .. result.Personality.Loyalty)
    Log("RiskTolerance: " .. result.Personality.RiskTolerance)
    Log("Curiosity: " .. result.Personality.Curiosity)
    Log("PlayerHostility: " .. result.Personality.PlayerHostility)

    Log("----------------------------------------")
    Log("CAPABILITIES")
    Log("----------------------------------------")

    Log("Combat: " .. result.Capabilities.Combat)
    Log("Survival: " .. result.Capabilities.Survival)
    Log("Recon: " .. result.Capabilities.Recon)
    Log("Security: " .. result.Capabilities.Security)
    Log("Technical: " .. result.Capabilities.Technical)
    Log("Construction: " .. result.Capabilities.Construction)
    Log("Medical: " .. result.Capabilities.Medical)
    Log("Logistics: " .. result.Capabilities.Logistics)
    Log("Agriculture: " .. result.Capabilities.Agriculture)
    Log("Leadership: " .. result.Capabilities.Leadership)

    Log("----------------------------------------")
    Log("TENDENCIES")
    Log("----------------------------------------")

    Log("CombatAggression: " .. result.Tendencies.CombatAggression)
    Log("CombatDiscipline: " .. result.Tendencies.CombatDiscipline)
    Log("WildernessConfidence: " .. result.Tendencies.WildernessConfidence)
    Log("ScoutingConfidence: " .. result.Tendencies.ScoutingConfidence)
    Log("Cooperation: " .. result.Tendencies.Cooperation)
    Log("FearResponse: " .. result.Tendencies.FearResponse)
    Log("RetreatTendency: " .. result.Tendencies.RetreatTendency)
    Log("ExplorationDrive: " .. result.Tendencies.ExplorationDrive)
    Log("ResourcePriority: " .. result.Tendencies.ResourcePriority)

    Log("----------------------------------------")
    Log("Behavior Profile V1 calculation complete")
    Log("----------------------------------------")

    return result
end

------------------------------------------------------------
-- GETTERS
------------------------------------------------------------

function BehaviorProfile.Get(profile)
    if not profile then
        return nil
    end

    return profile.BehaviorProfile
end

function BehaviorProfile.GetPersonality(profile)
    local behavior = BehaviorProfile.Get(profile)

    if not behavior then
        return nil
    end

    return behavior.Personality
end

function BehaviorProfile.GetCapabilities(profile)
    local behavior = BehaviorProfile.Get(profile)

    if not behavior then
        return nil
    end

    return behavior.Capabilities
end

function BehaviorProfile.GetTendencies(profile)
    local behavior = BehaviorProfile.Get(profile)

    if not behavior then
        return nil
    end

    return behavior.Tendencies
end

------------------------------------------------------------
-- CURRENT PLAYER
------------------------------------------------------------

function BehaviorProfile.CalculateCurrentPlayer()
    if not BAO.PlayerProfile then
        Log("PlayerProfile module not available")
        return nil
    end

    local profile = BAO.PlayerProfile.GetCurrent()

    if not profile then
        Log("Current player profile not available")
        return nil
    end

    return BehaviorProfile.Calculate(profile)
end

------------------------------------------------------------
-- PRINT CURRENT PROFILE
------------------------------------------------------------

function BehaviorProfile.PrintCurrent()
    if not BAO.PlayerProfile then
        Log("PlayerProfile module not available")
        return
    end

    local profile = BAO.PlayerProfile.GetCurrent()

    if not profile then
        Log("Current player profile not available")
        return
    end

    local behavior = profile.BehaviorProfile

    if not behavior then
        Log("Behavior profile not calculated")
        return
    end

    Log("========================================")
    Log("CURRENT BEHAVIOR PROFILE")
    Log("========================================")

    Log("Role: " .. tostring(behavior.NaturalRole))
    Log("Specialization: " .. tostring(behavior.NaturalSpecialization))

    Log("Combat: " .. tostring(behavior.Capabilities.Combat))
    Log("Survival: " .. tostring(behavior.Capabilities.Survival))
    Log("Recon: " .. tostring(behavior.Capabilities.Recon))
    Log("Security: " .. tostring(behavior.Capabilities.Security))
    Log("Technical: " .. tostring(behavior.Capabilities.Technical))
    Log("Construction: " .. tostring(behavior.Capabilities.Construction))
    Log("Medical: " .. tostring(behavior.Capabilities.Medical))
    Log("Logistics: " .. tostring(behavior.Capabilities.Logistics))
    Log("Agriculture: " .. tostring(behavior.Capabilities.Agriculture))
    Log("Leadership: " .. tostring(behavior.Capabilities.Leadership))

    Log("========================================")
end

------------------------------------------------------------
-- GAME START
--
-- We use OnTick retry because module load order can differ.
-- This guarantees that PlayerProfile, RoleScoring and
-- Specialization have time to finish first.
------------------------------------------------------------

local initializationAttempts = 0
local maxInitializationAttempts = 300
local initialized = false

function BehaviorProfile.TryInitialize()
    if initialized then
        return
    end

    initializationAttempts = initializationAttempts + 1

    if not BAO.PlayerProfile then
        return
    end

    local profile = BAO.PlayerProfile.GetCurrent()

    if not profile then
        return
    end

    if not profile.RoleScoring then
        return
    end

    if not profile.NaturalRole then
        return
    end

    if not profile.NaturalSpecialization then
        return
    end

    local result = BehaviorProfile.Calculate(profile)

    if result then
        initialized = true

        if Events and Events.OnTick then
            Events.OnTick.Remove(BehaviorProfile.TryInitialize)
        end

        BehaviorProfile.PrintCurrent()

        Log("Behavior Profile V1 initialization complete")
    end
end

------------------------------------------------------------
-- EVENT REGISTRATION
------------------------------------------------------------

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        Log("OnGameStart event received")
        Log("Waiting for PlayerProfile / RoleScoring / Specialization")

        if Events.OnTick then
            Events.OnTick.Add(BehaviorProfile.TryInitialize)
        end
    end)

    Log("OnGameStart handler registered")
end

------------------------------------------------------------
-- MODULE LOADED
------------------------------------------------------------

Log("Behavior Profile module loaded")