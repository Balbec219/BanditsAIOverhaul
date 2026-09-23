-----------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_FactionTest.lua
--
-- Тестирует систему фракций.
--
-- Этот файл ничего не создаёт в мире игры.
-- Он только проверяет, правильно ли работают наши таблицы,
-- функции и отношения между фракциями.
---@diagnostic disable: undefined-global
-----------------------------------------------------------

BAO = BAO or {}


-----------------------------------------------------------
-- ОСНОВНАЯ ФУНКЦИЯ ТЕСТА
-----------------------------------------------------------

function BAO.RunFactionTest()

BAO.Log("Faction test started")


-------------------------------------------------------
-- Проверяем, существует ли система фракций
-------------------------------------------------------

if not BAO.Factions then

BAO.Log("ERROR: BAO.Factions is missing")

return
end


-------------------------------------------------------
-- Получаем фракцию бандитов
-------------------------------------------------------

-- Функция Get() ищет фракцию по её внутреннему id.
--
-- В нашем случае id равен "bandits".
local bandits = BAO.Factions.Get("bandits")


-- Если фракция найдена, выводим информацию о ней.
if bandits then

BAO.Log("Bandit faction found")

BAO.Log(
"Bandit faction name: "
.. tostring(bandits.name)
)

BAO.Log(
"Bandit faction type: "
.. tostring(bandits.type)
)

else

BAO.Log("ERROR: Bandit faction was not created")

end


-------------------------------------------------------
-- Создаём временную тестовую фракцию
-------------------------------------------------------

-- Эта фракция нужна только для проверки функции Create().
local testFaction = BAO.Factions.Create(
"test_faction",
"Тестовая фракция",
BAO.Factions.Types.SURVIVOR
)


if testFaction then

BAO.Log("Test faction created successfully")

else

BAO.Log("ERROR: Test faction was not created")

end


-------------------------------------------------------
-- Проверяем отношения между фракциями
-------------------------------------------------------

-- Устанавливаем враждебное отношение:
--
-- test_faction считает bandits врагами.
BAO.Factions.SetRelation(
"test_faction",
"bandits",
BAO.Factions.Relations.HOSTILE
)


-- Получаем установленное отношение.
local relation = BAO.Factions.GetRelation(
"test_faction",
"bandits"
)


BAO.Log(
"Test faction relation to bandits: "
.. tostring(relation)
)


-------------------------------------------------------
-- Проверяем добавление участника
-------------------------------------------------------

-- Пока это не настоящий NPC.
-- Мы просто проверяем, может ли фракция хранить
-- идентификатор своего участника.
BAO.Factions.AddMember(
"test_faction",
"test_npc_001"
)


-------------------------------------------------------
-- Проверяем добавление базы
-------------------------------------------------------

-- Пока это условный идентификатор базы.
BAO.Factions.AddBase(
"test_faction",
"test_base_001"
)


-------------------------------------------------------
-- Проверяем добавление машины
-------------------------------------------------------

-- Пока это условный идентификатор транспорта.
BAO.Factions.AddVehicle(
"test_faction",
"test_vehicle_001"
)


BAO.Log("Faction test finished")

end


-----------------------------------------------------------
-- Запуск теста после загрузки игры
-----------------------------------------------------------

-- Project Zomboid предоставляет глобальную таблицу Events.
-- VS Code не знает об API игры, поэтому предупреждение
-- undefined-global отключено для этого файла.
---@diagnostic disable: undefined-global

if Events and Events.OnGameBoot then

Events.OnGameBoot.Add(function()

BAO.Log("Running faction test")

BAO.RunFactionTest()

end)

else

BAO.Log("WARNING: Cannot register faction test")

end