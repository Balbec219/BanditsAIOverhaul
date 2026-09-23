-----------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_Squads.lua
--
-- Система отрядов.
--
-- Фракция — это большая организация.
-- Отряд — небольшая группа внутри фракции.
--
-- Например:
-- Фракция "bandits"
-- └── Отряд "bandit_patrol_001"
-----------------------------------------------------------

BAO = BAO or {}
BAO.Squads = BAO.Squads or {}


-----------------------------------------------------------
-- СОСТОЯНИЯ ОТРЯДА
-----------------------------------------------------------

-- Состояние определяет, чем сейчас занимается отряд.
--
-- Пока это только значения.
-- Реальное поведение мы подключим позже.
BAO.Squads.States = {
IDLE = "idle",
PATROL = "patrol",
SEARCH = "search",
ATTACK = "attack",
RETREAT = "retreat",
GUARD = "guard",
TRAVEL = "travel"
}


-----------------------------------------------------------
-- СОЗДАНИЕ ОТРЯДА
-----------------------------------------------------------

-- Создаёт новый отряд.
--
-- squadId:
-- Уникальный идентификатор отряда.
--
-- factionId:
-- Идентификатор фракции, которой принадлежит отряд.
--
-- name:
-- Название отряда.
--
-- Пример:
-- BAO.Squads.Create(
-- "bandit_patrol_001",
-- "bandits",
-- "Патруль у базы"
-- )
function BAO.Squads.Create(squadId, factionId, name)

-- Проверяем идентификатор отряда.
if not squadId or squadId == "" then
BAO.Log("Cannot create squad: empty squad id")
return nil
end

-- Проверяем, не существует ли такой отряд.
if BAO.Squads[squadId] then
BAO.Log("Squad already exists: " .. tostring(squadId))
return BAO.Squads[squadId]
end

-- Проверяем, существует ли указанная фракция.
if not BAO.Factions or not BAO.Factions.Exists(factionId) then
BAO.Log(
"Cannot create squad: faction not found: "
.. tostring(factionId)
)

return nil
end

-- Создаём таблицу отряда.
local squad = {
-- Уникальный идентификатор.
id = squadId,

-- Идентификатор родительской фракции.
factionId = factionId,

-- Название отряда.
name = name or squadId,

-- Текущее состояние.
state = BAO.Squads.States.IDLE,

-- Участники отряда.
members = {},

-- Идентификатор командира.
commanderId = nil,

-- Текущая цель.
targetId = nil,

-- Идентификатор базы, откуда отряд вышел.
homeBaseId = nil,

-- Точка назначения.
destination = nil,

-- Общие настройки отряда.
settings = {
canUseVehicles = true,
canRecruit = false,
canLoot = true,
canAttack = true
}
}

-- Сохраняем отряд в общей таблице.
BAO.Squads[squadId] = squad

-- Также добавляем отряд в список родительской фракции.
local faction = BAO.Factions.Get(factionId)

if faction then
faction.squads = faction.squads or {}
faction.squads[squadId] = true
end

BAO.Log(
"Squad created: "
.. tostring(squadId)
.. " -> "
.. tostring(factionId)
)

return squad
end


-----------------------------------------------------------
-- ПОЛУЧЕНИЕ ОТРЯДА
-----------------------------------------------------------

-- Возвращает отряд по его идентификатору.
function BAO.Squads.Get(squadId)
return BAO.Squads[squadId]
end


-----------------------------------------------------------
-- ПРОВЕРКА СУЩЕСТВОВАНИЯ ОТРЯДА
-----------------------------------------------------------

function BAO.Squads.Exists(squadId)
return BAO.Squads[squadId] ~= nil
end


-----------------------------------------------------------
-- ДОБАВЛЕНИЕ УЧАСТНИКА В ОТРЯД
-----------------------------------------------------------

function BAO.Squads.AddMember(squadId, memberId)

local squad = BAO.Squads.Get(squadId)

if not squad then
BAO.Log(
"Cannot add squad member: squad not found: "
.. tostring(squadId)
)

return false
end

squad.members[memberId] = true

BAO.Log(
"Squad member added: "
.. tostring(memberId)
.. " -> "
.. tostring(squadId)
)

return true
end


-----------------------------------------------------------
-- УДАЛЕНИЕ УЧАСТНИКА ИЗ ОТРЯДА
-----------------------------------------------------------

function BAO.Squads.RemoveMember(squadId, memberId)

local squad = BAO.Squads.Get(squadId)

if not squad then
BAO.Log(
"Cannot remove squad member: squad not found: "
.. tostring(squadId)
)

return false
end

squad.members[memberId] = nil

-- Если удаляемый участник был командиром,
-- командир сбрасывается.
if squad.commanderId == memberId then
squad.commanderId = nil
end

BAO.Log(
"Squad member removed: "
.. tostring(memberId)
.. " <- "
.. tostring(squadId)
)

return true
end


-----------------------------------------------------------
-- НАЗНАЧЕНИЕ КОМАНДИРА
-----------------------------------------------------------

function BAO.Squads.SetCommander(squadId, memberId)

local squad = BAO.Squads.Get(squadId)

if not squad then
BAO.Log(
"Cannot set commander: squad not found: "
.. tostring(squadId)
)

return false
end

-- Командир должен быть участником этого отряда.
if not squad.members[memberId] then
BAO.Log(
"Cannot set commander: member is not in squad: "
.. tostring(memberId)
)

return false
end

squad.commanderId = memberId

BAO.Log(
"Squad commander set: "
.. tostring(memberId)
.. " -> "
.. tostring(squadId)
)

return true
end


-----------------------------------------------------------
-- ИЗМЕНЕНИЕ СОСТОЯНИЯ ОТРЯДА
-----------------------------------------------------------

function BAO.Squads.SetState(squadId, newState)

local squad = BAO.Squads.Get(squadId)

if not squad then
BAO.Log(
"Cannot change squad state: squad not found: "
.. tostring(squadId)
)

return false
end

squad.state = newState

BAO.Log(
"Squad state changed: "
.. tostring(squadId)
.. " = "
.. tostring(newState)
)

return true
end


-----------------------------------------------------------
-- УСТАНОВКА ЦЕЛИ ОТРЯДА
-----------------------------------------------------------

function BAO.Squads.SetTarget(squadId, targetId)

local squad = BAO.Squads.Get(squadId)

if not squad then
BAO.Log(
"Cannot set squad target: squad not found: "
.. tostring(squadId)
)

return false
end

squad.targetId = targetId

BAO.Log(
"Squad target changed: "
.. tostring(squadId)
.. " -> "
.. tostring(targetId)
)

return true
end


-----------------------------------------------------------
-- СОЗДАНИЕ ТЕСТОВОГО ОТРЯДА
-----------------------------------------------------------

function BAO.Squads.InitializeDefaults()

-- Проверяем, что фракция бандитов уже создана.
if not BAO.Factions or not BAO.Factions.Exists("bandits") then

BAO.Log(
"Cannot initialize squads: bandits faction is missing"
)

return
end

-- Создаём тестовый отряд.
local patrol = BAO.Squads.Create(
"bandit_patrol_001",
"bandits",
"Патруль бандитов"
)

if not patrol then
BAO.Log("ERROR: Failed to create default squad")
return
end

-- Добавляем условных участников.
BAO.Squads.AddMember(
"bandit_patrol_001",
"bandit_npc_001"
)

BAO.Squads.AddMember(
"bandit_patrol_001",
"bandit_npc_002"
)

BAO.Squads.AddMember(
"bandit_patrol_001",
"bandit_npc_003"
)

-- Назначаем первого участника командиром.
BAO.Squads.SetCommander(
"bandit_patrol_001",
"bandit_npc_001"
)

-- Устанавливаем состояние патрулирования.
BAO.Squads.SetState(
"bandit_patrol_001",
BAO.Squads.States.PATROL
)

-- Условная цель патруля.
BAO.Squads.SetTarget(
"bandit_patrol_001",
"patrol_zone_001"
)

BAO.Log("Default squads initialized")
end