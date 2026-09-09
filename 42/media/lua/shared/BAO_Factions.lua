-----------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_Factions.lua
--
-- Система фракций.
--
-- Здесь мы пока НЕ создаём настоящих NPC.
-- Мы только описываем фракции:
-- - кто они;
-- - к какому типу относятся;
-- - насколько они агрессивны;
-- - с кем дружат или воюют;
-- - какие базы и машины им принадлежат.
-----------------------------------------------------------

-- Создаём глобальную таблицу BAO, если её ещё нет.
--
-- Глобальная таблица нужна для того, чтобы разные Lua-файлы
-- нашего мода могли обращаться к одной общей системе.
BAO = BAO or {}

-- Создаём раздел Factions внутри BAO.
--
-- Если BAO.Factions уже существует, оператор or сохранит
-- существующую таблицу и не сотрёт данные.
BAO.Factions = BAO.Factions or {}

-- Версия именно системы фракций.
BAO.Factions.Version = "0.1.0"


-----------------------------------------------------------
-- ТИПЫ ФРАКЦИЙ
-----------------------------------------------------------

-- Здесь находятся возможные категории фракций.
--
-- Например, вместо написания вручную строки "bandit"
-- мы сможем использовать:
--
-- BAO.Factions.Types.BANDIT
--
-- Это уменьшает количество опечаток в дальнейшем коде.
BAO.Factions.Types = {
BANDIT = "bandit",
MILITARY = "military",
SURVIVOR = "survivor",
RAIDER = "raider",
TRADER = "trader"
}


-----------------------------------------------------------
-- ОТНОШЕНИЯ МЕЖДУ ФРАКЦИЯМИ
-----------------------------------------------------------

-- Возможные отношения между двумя фракциями.
--
-- Например:
-- survivors -> bandits = hostile
--
-- Это означает, что выжившие считают бандитов врагами.
BAO.Factions.Relations = {
ALLIED = "allied",
FRIENDLY = "friendly",
NEUTRAL = "neutral",
HOSTILE = "hostile"
}


-----------------------------------------------------------
-- СОЗДАНИЕ ФРАКЦИИ
-----------------------------------------------------------

-- Создаёт новую фракцию.
--
-- id:
-- Внутреннее уникальное имя фракции.
-- Например: "bandits".
--
-- name:
-- Отображаемое название.
-- Например: "Бандиты".
--
-- factionType:
-- Тип фракции из BAO.Factions.Types.
--
-- Функция возвращает созданную фракцию.
-- Если фракция уже существует, возвращается существующая.
function BAO.Factions.Create(id, name, factionType)

-- Проверяем, передали ли мы идентификатор.
--
-- Без id фракцию невозможно нормально найти
-- в других частях мода.
if not id or id == "" then
BAO.Log("Cannot create faction: empty id")
return nil
end

-- Не создаём одну и ту же фракцию повторно.
--
-- Это важно, потому что инициализация может быть вызвана
-- больше одного раза.
if BAO.Factions[id] then
BAO.Log("Faction already exists: " .. tostring(id))
return BAO.Factions[id]
end

-- Создаём таблицу с данными фракции.
local faction = {
-- Уникальный внутренний идентификатор.
id = id,

-- Название для будущего интерфейса и логов.
name = name or id,

-- Тип фракции.
type = factionType or BAO.Factions.Types.BANDIT,

-- Репутация фракции.
--
-- Позже сюда можно будет добавить отношение игрока,
-- влияние фракции и изменение репутации.
reputation = 0,

-- Участники фракции.
--
-- Пока здесь будут храниться условные идентификаторы.
-- Настоящих NPC мы подключим позже.
members = {},

-- Базы, принадлежащие фракции.
bases = {},

-- Машины, принадлежащие фракции.
vehicles = {},

-- Отношения с другими фракциями.
--
-- Пример:
-- relations["survivors"] = "hostile"
relations = {},

-- Настройки поведения фракции.
settings = {
-- Агрессивна ли фракция по умолчанию.
aggressive = false,

-- Может ли фракция торговать.
canTrade = false,

-- Может ли фракция принимать новых участников.
canRecruit = false,

-- Может ли фракция использовать транспорт.
canUseVehicles = true
}
}

-- Сохраняем фракцию в общем списке.
--
-- После этого её можно получить через:
-- BAO.Factions.Get("bandits")
BAO.Factions[id] = faction

BAO.Log("Faction created: " .. tostring(id))

return faction
end


-----------------------------------------------------------
-- ПОЛУЧЕНИЕ ФРАКЦИИ
-----------------------------------------------------------

-- Возвращает фракцию по её id.
--
-- Пример:
-- local bandits = BAO.Factions.Get("bandits")
function BAO.Factions.Get(id)
return BAO.Factions[id]
end


-----------------------------------------------------------
-- ПРОВЕРКА СУЩЕСТВОВАНИЯ ФРАКЦИИ
-----------------------------------------------------------

-- Возвращает true, если фракция существует.
--
-- Пример:
-- if BAO.Factions.Exists("bandits") then
-- ...
-- end
function BAO.Factions.Exists(id)
return BAO.Factions[id] ~= nil
end


-----------------------------------------------------------
-- УСТАНОВКА ОТНОШЕНИЙ
-----------------------------------------------------------

-- Устанавливает отношение одной фракции к другой.
--
-- Например:
-- BAO.Factions.SetRelation(
-- "survivors",
-- "bandits",
-- BAO.Factions.Relations.HOSTILE
-- )
--
-- Пока отношение одностороннее:
-- survivors могут ненавидеть bandits,
-- а bandits могут иметь другое отношение к survivors.
function BAO.Factions.SetRelation(firstId, secondId, relation)

-- Получаем первую фракцию.
local firstFaction = BAO.Factions.Get(firstId)

-- Если первой фракции нет, устанавливать отношение нельзя.
if not firstFaction then
BAO.Log(
"Cannot set relation: faction not found: "
.. tostring(firstId)
)

return false
end

-- Записываем отношение.
firstFaction.relations[secondId] = relation

BAO.Log(
"Relation changed: "
.. tostring(firstId)
.. " -> "
.. tostring(secondId)
.. " = "
.. tostring(relation)
)

return true
end


-----------------------------------------------------------
-- ПОЛУЧЕНИЕ ОТНОШЕНИЯ
-----------------------------------------------------------

-- Возвращает отношение одной фракции к другой.
--
-- Если отношение ещё не задано, возвращается NEUTRAL.
function BAO.Factions.GetRelation(firstId, secondId)

local firstFaction = BAO.Factions.Get(firstId)

-- Если фракция не найдена, считаем отношение нейтральным.
if not firstFaction then
return BAO.Factions.Relations.NEUTRAL
end

-- Если конкретное отношение отсутствует,
-- возвращаем нейтральное.
return firstFaction.relations[secondId]
or BAO.Factions.Relations.NEUTRAL
end


-----------------------------------------------------------
-- ДОБАВЛЕНИЕ УЧАСТНИКА
-----------------------------------------------------------

-- Добавляет участника во фракцию.
--
-- memberId пока является просто идентификатором.
-- Позже сюда можно будет передавать ID NPC или игрока.
function BAO.Factions.AddMember(factionId, memberId)

local faction = BAO.Factions.Get(factionId)

if not faction then
BAO.Log(
"Cannot add member: faction not found: "
.. tostring(factionId)
)

return false
end

-- Используем memberId как ключ таблицы.
--
-- Например:
-- faction.members["npc_001"] = true
faction.members[memberId] = true

BAO.Log(
"Member added: "
.. tostring(memberId)
.. " -> "
.. tostring(factionId)
)

return true
end


-----------------------------------------------------------
-- УДАЛЕНИЕ УЧАСТНИКА
-----------------------------------------------------------

-- Удаляет участника из фракции.
function BAO.Factions.RemoveMember(factionId, memberId)

local faction = BAO.Factions.Get(factionId)

if not faction then
BAO.Log(
"Cannot remove member: faction not found: "
.. tostring(factionId)
)

return false
end

-- Удаление значения из таблицы.
faction.members[memberId] = nil

BAO.Log(
"Member removed: "
.. tostring(memberId)
.. " <- "
.. tostring(factionId)
)

return true
end


-----------------------------------------------------------
-- ДОБАВЛЕНИЕ БАЗЫ
-----------------------------------------------------------

-- Привязывает базу к фракции.
--
-- baseId пока является условным идентификатором.
-- Например: "base_raven_creek_001".
function BAO.Factions.AddBase(factionId, baseId)

local faction = BAO.Factions.Get(factionId)

if not faction then
BAO.Log(
"Cannot add base: faction not found: "
.. tostring(factionId)
)

return false
end

faction.bases[baseId] = true

BAO.Log(
"Base added: "
.. tostring(baseId)
.. " -> "
.. tostring(factionId)
)

return true
end


-----------------------------------------------------------
-- ДОБАВЛЕНИЕ МАШИНЫ
-----------------------------------------------------------

-- Привязывает машину к фракции.
--
-- vehicleId пока является условным идентификатором.
-- Позже здесь будет использоваться реальный автомобиль PZ.
function BAO.Factions.AddVehicle(factionId, vehicleId)

local faction = BAO.Factions.Get(factionId)

if not faction then
BAO.Log(
"Cannot add vehicle: faction not found: "
.. tostring(factionId)
)

return false
end

faction.vehicles[vehicleId] = true

BAO.Log(
"Vehicle added: "
.. tostring(vehicleId)
.. " -> "
.. tostring(factionId)
)

return true
end


-----------------------------------------------------------
-- СОЗДАНИЕ СТАНДАРТНЫХ ФРАКЦИЙ
-----------------------------------------------------------

-- Создаёт базовый набор фракций для тестирования.
--
-- В дальнейшем этот список можно будет вынести
-- в отдельный конфигурационный файл.
function BAO.Factions.InitializeDefaults()

-- Создаём фракцию выживших.
local survivors = BAO.Factions.Create(
"survivors",
"Выжившие",
BAO.Factions.Types.SURVIVOR
)

-- Создаём фракцию обычных бандитов.
local bandits = BAO.Factions.Create(
"bandits",
"Бандиты",
BAO.Factions.Types.BANDIT
)

-- Создаём военную фракцию.
local military = BAO.Factions.Create(
"military",
"Военные",
BAO.Factions.Types.MILITARY
)

-- Создаём фракцию рейдеров.
local raiders = BAO.Factions.Create(
"raiders",
"Рейдеры",
BAO.Factions.Types.RAIDER
)

-------------------------------------------------------
-- НАСТРОЙКИ ВЫЖИВШИХ
-------------------------------------------------------

-- Проверка нужна для Lua-анализатора и безопасности.
--
-- Если Create() по какой-то причине вернёт nil,
-- мы не получим ошибку при обращении к settings.
if survivors then
survivors.settings.canTrade = true
survivors.settings.canRecruit = true
end

-------------------------------------------------------
-- НАСТРОЙКИ БАНДИТОВ
-------------------------------------------------------

if bandits then
bandits.settings.aggressive = true
bandits.settings.canUseVehicles = true
end

-------------------------------------------------------
-- НАСТРОЙКИ ВОЕННЫХ
-------------------------------------------------------

if military then
military.settings.aggressive = false
military.settings.canUseVehicles = true
end

-------------------------------------------------------
-- НАСТРОЙКИ РЕЙДЕРОВ
-------------------------------------------------------

if raiders then
raiders.settings.aggressive = true
raiders.settings.canUseVehicles = true
end

-------------------------------------------------------
-- ОТНОШЕНИЯ ВЫЖИВШИХ
-------------------------------------------------------

BAO.Factions.SetRelation(
"survivors",
"bandits",
BAO.Factions.Relations.HOSTILE
)

BAO.Factions.SetRelation(
"survivors",
"military",
BAO.Factions.Relations.NEUTRAL
)

BAO.Factions.SetRelation(
"survivors",
"raiders",
BAO.Factions.Relations.HOSTILE
)

-------------------------------------------------------
-- ОТНОШЕНИЯ БАНДИТОВ
-------------------------------------------------------

BAO.Factions.SetRelation(
"bandits",
"raiders",
BAO.Factions.Relations.HOSTILE
)

BAO.Factions.SetRelation(
"bandits",
"military",
BAO.Factions.Relations.HOSTILE
)

BAO.Log("Default factions initialized")
end