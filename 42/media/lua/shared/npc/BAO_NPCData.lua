---@diagnostic disable: undefined-global

BAO = BAO or {}
BAO.NPCData = BAO.NPCData or {}

--------------------------------------------------
-- Состояния NPC
--------------------------------------------------

BAO.NPCData.States = {
IDLE = "idle",
FOLLOW = "follow",
PATROL = "patrol",
GUARD = "guard",
SEARCH = "search",
COMBAT = "combat",
FLEE = "flee",
REST = "rest",
WORK = "work",
DEAD = "dead",
}

--------------------------------------------------
-- Роли NPC
--------------------------------------------------

BAO.NPCData.Roles = {
NONE = "none",
COMMANDER = "commander",
ASSAULT = "assault",
SCOUT = "scout",
SNIPER = "sniper",
MEDIC = "medic",
MECHANIC = "mechanic",
CARRY = "carry",
GUARD = "guard",
DRIVER = "driver",
TRADER = "trader",
}

--------------------------------------------------
-- Создание нового NPC
--------------------------------------------------
-- Здесь мы пока только создаём данные.
-- Настоящий персонаж в мире ещё не появляется.
--------------------------------------------------

function BAO.NPCData.Create(npcId, name, factionId)
if not npcId or npcId == "" then
BAO.Log("ERROR: Cannot create NPC without ID")
return nil
end

if BAO.NPCData.Exists(npcId) then
BAO.Log("ERROR: NPC already exists: " .. tostring(npcId))
return nil
end

local npc = {
-- Основная информация
id = npcId,
name = name or "Unnamed NPC",
factionId = factionId or nil,

-- Отряд
squadId = nil,

-- Профессия и роль
profession = nil,
role = BAO.NPCData.Roles.NONE,
specialization = nil,

-- Навыки Project Zomboid
skills = {},

-- Traits и Perks
traits = {},
perks = {},

-- Дополнительные возможности
actions = {},

-- Характер
personality = {},

-- Состояние
state = BAO.NPCData.States.IDLE,
health = 1.0,
morale = 1.0,

-- Служебные данные
isAlive = true,
isActive = false,
createdAt = nil,
}

BAO.NPCData[npcId] = npc

BAO.Log("NPC data created: " .. tostring(npcId))

return npc
end

--------------------------------------------------
-- Получение NPC по ID
--------------------------------------------------

function BAO.NPCData.Get(npcId)
if not npcId then
return nil
end

return BAO.NPCData[npcId]
end

--------------------------------------------------
-- Проверка существования NPC
--------------------------------------------------

function BAO.NPCData.Exists(npcId)
return BAO.NPCData[npcId] ~= nil
end

--------------------------------------------------
-- Удаление NPC из системы данных
--------------------------------------------------

function BAO.NPCData.Remove(npcId)
if not BAO.NPCData.Exists(npcId) then
BAO.Log("ERROR: Cannot remove missing NPC: " .. tostring(npcId))
return false
end

BAO.NPCData[npcId] = nil

BAO.Log("NPC data removed: " .. tostring(npcId))

return true
end

--------------------------------------------------
-- Назначение профессии
--------------------------------------------------

function BAO.NPCData.SetProfession(npcId, professionId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

npc.profession = professionId

BAO.Log(
"NPC profession changed: "
.. tostring(npcId)
.. " = "
.. tostring(professionId)
)

return true
end

--------------------------------------------------
-- Назначение роли
--------------------------------------------------

function BAO.NPCData.SetRole(npcId, roleId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

npc.role = roleId or BAO.NPCData.Roles.NONE

BAO.Log(
"NPC role changed: "
.. tostring(npcId)
.. " = "
.. tostring(npc.role)
)

return true
end

--------------------------------------------------
-- Назначение специализации
--------------------------------------------------

function BAO.NPCData.SetSpecialization(npcId, specializationId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

npc.specialization = specializationId

BAO.Log(
"NPC specialization changed: "
.. tostring(npcId)
.. " = "
.. tostring(specializationId)
)

return true
end

--------------------------------------------------
-- Добавление навыка
--------------------------------------------------

function BAO.NPCData.SetSkill(npcId, skillId, level)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

if not skillId or skillId == "" then
BAO.Log("ERROR: Cannot add skill without ID")
return false
end

npc.skills[skillId] = level or 0

BAO.Log(
"NPC skill changed: "
.. tostring(npcId)
.. " -> "
.. tostring(skillId)
.. " = "
.. tostring(npc.skills[skillId])
)

return true
end

--------------------------------------------------
-- Добавление Trait
--------------------------------------------------

function BAO.NPCData.AddTrait(npcId, traitId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

if not traitId or traitId == "" then
BAO.Log("ERROR: Cannot add trait without ID")
return false
end

npc.traits[traitId] = true

BAO.Log(
"NPC trait added: "
.. tostring(npcId)
.. " -> "
.. tostring(traitId)
)

return true
end

--------------------------------------------------
-- Добавление Perk
--------------------------------------------------

function BAO.NPCData.AddPerk(npcId, perkId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

if not perkId or perkId == "" then
BAO.Log("ERROR: Cannot add perk without ID")
return false
end

npc.perks[perkId] = true

BAO.Log(
"NPC perk added: "
.. tostring(npcId)
.. " -> "
.. tostring(perkId)
)

return true
end

--------------------------------------------------
-- Добавление доступного действия
--------------------------------------------------

function BAO.NPCData.AddAction(npcId, actionId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

if not actionId or actionId == "" then
BAO.Log("ERROR: Cannot add action without ID")
return false
end

npc.actions[actionId] = true

BAO.Log(
"NPC action added: "
.. tostring(npcId)
.. " -> "
.. tostring(actionId)
)

return true
end

--------------------------------------------------
-- Изменение состояния NPC
--------------------------------------------------

function BAO.NPCData.SetState(npcId, stateId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

npc.state = stateId or BAO.NPCData.States.IDLE

BAO.Log(
"NPC state changed: "
.. tostring(npcId)
.. " = "
.. tostring(npc.state)
)

return true
end

--------------------------------------------------
-- Назначение NPC в отряд
--------------------------------------------------

function BAO.NPCData.SetSquad(npcId, squadId)
local npc = BAO.NPCData.Get(npcId)

if not npc then
BAO.Log("ERROR: NPC not found: " .. tostring(npcId))
return false
end

npc.squadId = squadId

BAO.Log(
"NPC squad changed: "
.. tostring(npcId)
.. " -> "
.. tostring(squadId)
)

return true
end

--------------------------------------------------
-- Создание тестового NPC
--------------------------------------------------

function BAO.NPCData.InitializeDefaults()
if BAO.NPCData.Exists("test_npc_data_001") then
BAO.Log("Default NPC data already initialized")
return
end

local npc = BAO.NPCData.Create(
"test_npc_data_001",
"Test Bandit",
"bandits"
)

if not npc then
BAO.Log("ERROR: Failed to create default NPC")
return
end

BAO.NPCData.SetProfession(
"test_npc_data_001",
"unemployed"
)

BAO.NPCData.SetRole(
"test_npc_data_001",
BAO.NPCData.Roles.ASSAULT
)

BAO.NPCData.SetSpecialization(
"test_npc_data_001",
"basic_bandit"
)

-- Пока это тестовые значения.
-- Позже они будут получаться из реального персонажа,
-- его профессии, навыков и Traits.
BAO.NPCData.SetSkill(
"test_npc_data_001",
"Aiming",
3
)

BAO.NPCData.SetSkill(
"test_npc_data_001",
"Fitness",
5
)

BAO.NPCData.SetSkill(
"test_npc_data_001",
"Strength",
4
)

BAO.NPCData.AddTrait(
"test_npc_data_001",
"Strong"
)

BAO.NPCData.AddPerk(
"test_npc_data_001",
"basic_combat_training"
)

BAO.NPCData.AddAction(
"test_npc_data_001",
"basic_combat"
)

BAO.NPCData.SetSquad(
"test_npc_data_001",
"bandit_patrol_001"
)

BAO.Log("Default NPC data initialized")
end