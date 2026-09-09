-----------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_SquadsTest.lua
--
-- Проверяет систему отрядов.
--
-- Этот файл пока не создаёт настоящих NPC.
-- Он проверяет только данные:
-- - существует ли отряд;
-- - кто входит в отряд;
-- - кто командир;
-- - какое состояние у отряда;
-- - какая у него цель.
-----------------------------------------------------------

BAO = BAO or {}


-----------------------------------------------------------
-- ОСНОВНАЯ ФУНКЦИЯ ТЕСТА
-----------------------------------------------------------

function BAO.RunSquadTest()

BAO.Log("Squad test started")


-------------------------------------------------------
-- Проверяем наличие системы отрядов
-------------------------------------------------------

if not BAO.Squads then

BAO.Log("ERROR: BAO.Squads is missing")

return
end


-------------------------------------------------------
-- Получаем тестовый отряд
-------------------------------------------------------

-- Этот отряд создаётся в:
--
-- BAO.Squads.InitializeDefaults()
--
-- Его идентификатор:
-- bandit_patrol_001
local patrol = BAO.Squads.Get("bandit_patrol_001")


if not patrol then

BAO.Log(
"ERROR: Default squad was not created"
)

return

end


BAO.Log("Default squad found")


-------------------------------------------------------
-- Проверяем основные данные отряда
-------------------------------------------------------

BAO.Log(
"Squad name: "
.. tostring(patrol.name)
)

BAO.Log(
"Squad faction: "
.. tostring(patrol.factionId)
)

BAO.Log(
"Squad state: "
.. tostring(patrol.state)
)

BAO.Log(
"Squad commander: "
.. tostring(patrol.commanderId)
)

BAO.Log(
"Squad target: "
.. tostring(patrol.targetId)
)


-------------------------------------------------------
-- Проверяем участников
-------------------------------------------------------

-- Здесь мы просто проверяем, есть ли в таблице
-- нужные идентификаторы участников.
if patrol.members["bandit_npc_001"] then

BAO.Log("Squad member 001 found")

else

BAO.Log("ERROR: Squad member 001 is missing")

end


if patrol.members["bandit_npc_002"] then

BAO.Log("Squad member 002 found")

else

BAO.Log("ERROR: Squad member 002 is missing")

end


if patrol.members["bandit_npc_003"] then

BAO.Log("Squad member 003 found")

else

BAO.Log("ERROR: Squad member 003 is missing")

end


-------------------------------------------------------
-- Проверяем командира
-------------------------------------------------------

if patrol.commanderId == "bandit_npc_001" then

BAO.Log("Squad commander check passed")

else

BAO.Log("ERROR: Squad commander check failed")

end


-------------------------------------------------------
-- Проверяем состояние отряда
-------------------------------------------------------

if patrol.state == BAO.Squads.States.PATROL then

BAO.Log("Squad state check passed")

else

BAO.Log("ERROR: Squad state check failed")

end


-------------------------------------------------------
-- Проверяем цель отряда
-------------------------------------------------------

if patrol.targetId == "patrol_zone_001" then

BAO.Log("Squad target check passed")

else

BAO.Log("ERROR: Squad target check failed")

end


BAO.Log("Squad test finished")

end


-----------------------------------------------------------
-- ЗАПУСК ТЕСТА ПОСЛЕ ЗАПУСКА ИГРЫ
-----------------------------------------------------------

-- Project Zomboid предоставляет глобальную таблицу Events.
-- VS Code не знает об API игры, поэтому отключаем
-- предупреждение undefined-global для этого файла.
---@diagnostic disable: undefined-global

if Events and Events.OnGameBoot then

Events.OnGameBoot.Add(function()

BAO.Log("Running squad test")

BAO.RunSquadTest()

end)

else

BAO.Log(
"WARNING: Cannot register squad test"
)

end