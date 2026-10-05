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
        self.outfit:addOptionWithData("BAO: создать NPC (1–20, всего до 50)", spawnKey)
        self.outfit:addOptionWithData("BAO: удалить всех тестовых NPC", removeKey)
        self.baoCommands = {}
        local client = BAO and BAO.NPCWorldClient
        for _, identity in ipairs(client and client.GetNPCList() or {}) do
            for _, item in ipairs({{"npc_patrol", "патруль к выбранной клетке"},
                {"npc_stop", "остановить"}, {"npc_status", "состояние в лог"}}) do
                local key = "__BAO_" .. item[1] .. "_" .. identity.id
                self.baoCommands[key] = {command=item[1], id=identity.id}
                self.outfit:addOptionWithData("BAO: " .. identity.id .. " — " .. item[2], key)
            end
        end
    end
    function UI:onSpawn()
        local selected = self:getOutfit()
        local npcCommand = self.baoCommands and self.baoCommands[selected]
        if selected ~= spawnKey and selected ~= removeKey and not npcCommand then return onSpawn(self) end
        local adapter = BAO and BAO.NPCWorldAdapter
        if not adapter then Notice("BAO: адаптер NPC не загружен."); return end
        local ok, success, reason = pcall(function()
            if not BAO.NPCWorldClient then return false, "client_module_unavailable" end
            if npcCommand then
                return BAO.NPCWorldClient.CommandNPC(self.chr, npcCommand.command,
                    {id=npcCommand.id, x=self.selectX, y=self.selectY, z=self.selectZ})
            end
            if selected == removeKey then return BAO.NPCWorldClient.Request(false, self.chr) end
            if self:getZombiesNumber() > 20 or self:getHeightOffset() ~= 0 then
                return false, "use_count_20_height_0"
            end
            return BAO.NPCWorldClient.Request(true, self.chr,
                { x = self.selectX, y = self.selectY, z = self.selectZ,
                    count = self:getZombiesNumber(), radius = self:getRadius() })
        end)
        if not ok then
            print("[BAO][HordeManager] " .. tostring(success))
            Notice("BAO: ошибка вызова. Подробности в console.txt.")
            return
        end
        local messages = {
            request_sent = "BAO: запрос отправлен серверу. Результат — в console.txt.",
            spawned = "BAO: фабрика вернула NPC. Проверь выбранную клетку.",
            patrol_started = "BAO: патруль назначен. Это ещё не подтверждение прибытия.",
            npc_stopped = "BAO: NPC остановлен.",
            npc_status = "BAO: состояние выбранного NPC записано в console.txt.",
            removed = "BAO: тестовые NPC удалены.",
            partial_cleanup = "BAO: часть NPC не удалена. Повтори удаление; подробности в логе.",
            use_count_20_height_0 = "BAO: количество до 20, смещение высоты 0.",
            invalid_count_or_radius = "BAO: количество 1–20, радиус в интерфейсе 1–11.",
            active_limit_50 = "BAO: лимит 50 активных тестовых NPC.",
            test_npc_exists = "BAO: тестовый NPC уже создан. Сначала удали его.",
            no_test_npc = "BAO: созданного тестового NPC нет.",
            no_free_square = "BAO: клетка занята, не загружена или без пола.",
            use_count_1_height_0 = "BAO: установи количество 1 и смещение высоты 0."
        }
        Notice(messages[reason] or ("BAO: " .. tostring(reason)))
    end
end
