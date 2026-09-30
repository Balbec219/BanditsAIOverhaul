-- Extend vanilla B42 Horde Manager; BAO options never reach createhorde2.
require "DebugUIs/ISSpawnHordeUI"
require "ISUI/ISModalDialog"
local UI = ISSpawnHordeUI
if not UI.BAOIntegrationInstalled then
    UI.BAOIntegrationInstalled = true
    local createChildren, onSpawn = UI.createChildren, UI.onSpawn
    local spawnKey, removeKey = "__BAO_TEST_NPC__", "__BAO_REMOVE_TEST_NPC__"
    local function Notice(message)
        print("[BAO][HordeManager] " .. message)
        local modal = ISModalDialog:new(0, 0, 520, 170, message, false, nil, nil)
        modal:initialise()
        modal:addToUIManager()
    end
    function UI:createChildren()
        createChildren(self)
        self.outfit:addOptionWithData("BAO: создать тестовую NPC-оболочку", spawnKey)
        self.outfit:addOptionWithData("BAO: удалить тестового NPC", removeKey)
    end
    function UI:onSpawn()
        local selected = self:getOutfit()
        if selected ~= spawnKey and selected ~= removeKey then return onSpawn(self) end
        local adapter = BAO and BAO.NPCWorldAdapter
        if not adapter then Notice("BAO: адаптер NPC не загружен."); return end
        local ok, success, reason = pcall(function()
            if not BAO.NPCWorldClient then return false, "client_module_unavailable" end
            if selected == removeKey then return BAO.NPCWorldClient.Request(false, self.chr) end
            if self:getZombiesNumber() ~= 1 or self:getHeightOffset() ~= 0 then
                return false, "use_count_1_height_0"
            end
            return BAO.NPCWorldClient.Request(true, self.chr,
                { x = self.selectX, y = self.selectY, z = self.selectZ })
        end)
        if not ok then
            print("[BAO][HordeManager] " .. tostring(success))
            Notice("BAO: ошибка вызова. Подробности в console.txt.")
            return
        end
        local messages = {
            request_sent = "BAO: запрос отправлен серверу. Результат — в console.txt.",
            spawned = "BAO: фабрика вернула NPC. Проверь выбранную клетку.",
            removed = "BAO: тестовый NPC удалён.",
            test_npc_exists = "BAO: тестовый NPC уже создан. Сначала удали его.",
            no_test_npc = "BAO: созданного тестового NPC нет.",
            no_free_square = "BAO: клетка занята, не загружена или без пола.",
            use_count_1_height_0 = "BAO: установи количество 1 и смещение высоты 0."
        }
        Notice(messages[reason] or ("BAO: " .. tostring(reason)))
    end
end
