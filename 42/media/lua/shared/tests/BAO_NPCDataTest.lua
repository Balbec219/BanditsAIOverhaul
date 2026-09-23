---@diagnostic disable: undefined-global

BAO = BAO or {}

--------------------------------------------------
-- Тест системы данных NPC
--------------------------------------------------

function BAO.RunNPCDataTest()
BAO.Log("Running NPC data test")
BAO.Log("NPC data test started")

if not BAO.NPCData then
BAO.Log("ERROR: NPC data system is not available")
return
end

local npc = BAO.NPCData.Get("test_npc_data_001")

if not npc then
BAO.Log("ERROR: Test NPC was not found")
return
end

BAO.Log("Test NPC found")
BAO.Log("NPC ID: " .. tostring(npc.id))
BAO.Log("NPC name: " .. tostring(npc.name))
BAO.Log("NPC faction: " .. tostring(npc.factionId))
BAO.Log("NPC profession: " .. tostring(npc.profession))
BAO.Log("NPC role: " .. tostring(npc.role))
BAO.Log("NPC specialization: " .. tostring(npc.specialization))
BAO.Log("NPC state: " .. tostring(npc.state))
BAO.Log("NPC squad: " .. tostring(npc.squadId))

if npc.skills["Aiming"] == 3 then
BAO.Log("Aiming skill check passed")
else
BAO.Log("ERROR: Aiming skill check failed")
end

if npc.skills["Fitness"] == 5 then
BAO.Log("Fitness skill check passed")
else
BAO.Log("ERROR: Fitness skill check failed")
end

if npc.skills["Strength"] == 4 then
BAO.Log("Strength skill check passed")
else
BAO.Log("ERROR: Strength skill check failed")
end

if npc.traits["Strong"] == true then
BAO.Log("Trait check passed")
else
BAO.Log("ERROR: Trait check failed")
end

if npc.perks["basic_combat_training"] == true then
BAO.Log("Perk check passed")
else
BAO.Log("ERROR: Perk check failed")
end

if npc.actions["basic_combat"] == true then
BAO.Log("Action check passed")
else
BAO.Log("ERROR: Action check failed")
end

BAO.Log("NPC data test finished")
end

--------------------------------------------------
-- Запуск теста после загрузки игры
--------------------------------------------------

if Events and Events.OnGameBoot then
Events.OnGameBoot.Add(function()
BAO.RunNPCDataTest()
end)
else
BAO.Log("WARNING: OnGameBoot event is not available")
end