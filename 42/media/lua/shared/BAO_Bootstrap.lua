-----------------------------------------------------------
-- Bandits AI Overhaul
-- BAO_Bootstrap.lua
--
-- Главная точка запуска нашего мода.
-----------------------------------------------------------

-- Project Zomboid предоставляет глобальную таблицу Events.
-- Lua-анализатор VS Code не знает об API игры,
-- поэтому отключаем предупреждение undefined-global
-- для этого файла.
---@diagnostic disable: undefined-global

-- Создаём общую таблицу мода.
BAO = BAO or {}

-- Версия всего мода.
BAO.Version = "0.1.0"


-----------------------------------------------------------
-- ФУНКЦИЯ ЛОГИРОВАНИЯ
-----------------------------------------------------------

-- Все сообщения нашего мода будут начинаться с [BAO].
--
-- Благодаря этому в огромном логе Project Zomboid
-- будет легко находить сообщения именно нашего мода.
function BAO.Log(message)
    print("[BAO] " .. tostring(message))
end


-----------------------------------------------------------
-- ИНИЦИАЛИЗАЦИЯ МОДА
-----------------------------------------------------------

-- Эта функция запускает основные системы BAO.
function BAO.Initialize()

    BAO.Log("Initialization started")

    -- Проверяем, загрузилась ли система фракций.
    if BAO.Factions and BAO.Factions.InitializeDefaults then

        BAO.Factions.InitializeDefaults()

        BAO.Log("Faction system initialized")

    else

        BAO.Log("ERROR: Faction system is not available")

    end

    BAO.Log("Initialization finished")
end


-----------------------------------------------------------
-- ПОДКЛЮЧЕНИЕ К СОБЫТИЮ ИГРЫ
-----------------------------------------------------------

-- OnGameBoot вызывается после запуска игры.
--
-- Это надёжнее, чем запускать инициализацию сразу
-- при чтении Lua-файла.
if Events and Events.OnGameBoot then

    Events.OnGameBoot.Add(function()

        BAO.Log("OnGameBoot event received")

        BAO.Initialize()

    end)

else

    BAO.Log("WARNING: OnGameBoot event is not available")

end

BAO.Log("Bootstrap loaded")