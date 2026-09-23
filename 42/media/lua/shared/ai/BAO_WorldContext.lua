---@diagnostic disable: undefined-global

BAO = BAO or {}
BAO.WorldContext = BAO.WorldContext or {}

local WorldContext = BAO.WorldContext

--------------------------------------------------
-- LOG
--------------------------------------------------

local function Log(message)
    print("[BAO][WorldContext] " .. tostring(message))
end

--------------------------------------------------
-- SAFE HELPERS
--------------------------------------------------

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

--------------------------------------------------
-- PLAYER
--------------------------------------------------

function WorldContext.GetPlayer()
    if not getPlayer then
        return nil
    end

    local success, player = pcall(getPlayer, 0)

    if success then
        return player
    end

    return nil
end

--------------------------------------------------
-- HEALTH
--------------------------------------------------

function WorldContext.GetHealth(player)
    if not player then
        return 100
    end

    local bodyDamage = SafeCall(player, "getBodyDamage")

    if not bodyDamage then
        return 100
    end

    local health = SafeCall(
        bodyDamage,
        "getOverallBodyHealth"
    )

    return Clamp(health, 0, 100)
end

--------------------------------------------------
-- HUNGER
--------------------------------------------------

function WorldContext.GetHunger(player)
    if not player then
        return 0
    end

    local stats = SafeCall(player, "getStats")

    if not stats then
        return 0
    end

    local hunger = SafeCall(
        stats,
        "getHunger"
    )

    return Clamp(hunger, 0, 1)
end

--------------------------------------------------
-- THIRST
--------------------------------------------------

function WorldContext.GetThirst(player)
    if not player then
        return 0
    end

    local stats = SafeCall(player, "getStats")

    if not stats then
        return 0
    end

    local thirst = SafeCall(
        stats,
        "getThirst"
    )

    return Clamp(thirst, 0, 1)
end

--------------------------------------------------
-- FATIGUE
--------------------------------------------------

function WorldContext.GetFatigue(player)
    if not player then
        return 0
    end

    local stats = SafeCall(player, "getStats")

    if not stats then
        return 0
    end

    local fatigue = SafeCall(
        stats,
        "getFatigue"
    )

    return Clamp(fatigue, 0, 1)
end

--------------------------------------------------
-- PANIC
--------------------------------------------------

function WorldContext.GetPanic(player)
    if not player then
        return 0
    end

    local stats = SafeCall(player, "getStats")

    if not stats then
        return 0
    end

    local panic = SafeCall(
        stats,
        "getPanic"
    )

    return Clamp(panic, 0, 100)
end

--------------------------------------------------
-- PAIN
--------------------------------------------------

function WorldContext.GetPain(player)
    if not player then
        return 0
    end

    local bodyDamage = SafeCall(
        player,
        "getBodyDamage"
    )

    if not bodyDamage then
        return 0
    end

    local health =
        SafeCall(
            bodyDamage,
            "getOverallBodyHealth"
        )

    if health == nil then
        return 0
    end

    return Clamp(100 - health, 0, 100)
end

--------------------------------------------------
-- POSITION
--------------------------------------------------

function WorldContext.GetPosition(player)
    if not player then
        return {
            X = 0,
            Y = 0,
            Z = 0
        }
    end

    return {
        X = tonumber(
            SafeCall(player, "getX")
        ) or 0,

        Y = tonumber(
            SafeCall(player, "getY")
        ) or 0,

        Z = tonumber(
            SafeCall(player, "getZ")
        ) or 0
    }
end

--------------------------------------------------
-- MOVEMENT
--------------------------------------------------

function WorldContext.IsMoving(player)
    if not player then
        return false
    end

    return SafeCall(
        player,
        "isMoving"
    ) == true
end

--------------------------------------------------
-- WEAPON
--------------------------------------------------

function WorldContext.GetWeaponState(player)

    local result = {
        HasWeapon = false,
        IsRanged = false,
        HasAmmo = false,
        WeaponName = nil
    }

    if not player then
        return result
    end

    local weapon =
        SafeCall(
            player,
            "getPrimaryHandItem"
        )

    if not weapon then
        return result
    end

    result.HasWeapon = true

    local weaponType =
        SafeCall(
            weapon,
            "getType"
        )

    if weaponType then
        result.WeaponName =
            tostring(weaponType)
    end

    local isRanged =
        SafeCall(
            weapon,
            "isRanged"
        )

    if isRanged == true then
        result.IsRanged = true
    end

    return result
end

--------------------------------------------------
-- ZOMBIES
--------------------------------------------------

function WorldContext.GetNearbyZombieCount(
    player,
    radius
)

    if not player then
        return 0
    end

    radius =
        tonumber(radius) or 15

    local cell = getCell()

    if not cell then
        return 0
    end

    local zombies =
        SafeCall(
            cell,
            "getZombieList"
        )

    if not zombies then
        return 0
    end

    local playerX =
        tonumber(
            SafeCall(player, "getX")
        ) or 0

    local playerY =
        tonumber(
            SafeCall(player, "getY")
        ) or 0

    local count = 0

    for i = 0, zombies:size() - 1 do

        local zombie =
            zombies:get(i)

        if zombie then

            local zombieX =
                tonumber(
                    SafeCall(
                        zombie,
                        "getX"
                    )
                ) or 0

            local zombieY =
                tonumber(
                    SafeCall(
                        zombie,
                        "getY"
                    )
                ) or 0

            local dx =
                zombieX - playerX

            local dy =
                zombieY - playerY

            local distanceSquared =
                dx * dx + dy * dy

            if distanceSquared <=
                radius * radius then

                count =
                    count + 1
            end
        end
    end

    return count
end

--------------------------------------------------
-- TIME
--------------------------------------------------

function WorldContext.GetTime()

    local result = {
        Hour = 0,
        Minutes = 0,
        IsNight = false
    }

    local gameTime =
        getGameTime()

    if not gameTime then
        return result
    end

    result.Hour =
        tonumber(
            SafeCall(
                gameTime,
                "getHour"
            )
        ) or 0

    result.Minutes =
        tonumber(
            SafeCall(
                gameTime,
                "getMinutes"
            )
        ) or 0

    result.IsNight =
        result.Hour < 6
        or result.Hour >= 21

    return result
end

--------------------------------------------------
-- BUILD CONTEXT
--------------------------------------------------

function WorldContext.Build(player)

    player =
        player or
        WorldContext.GetPlayer()

    if not player then
        return nil
    end

    local context = {}

    context.Health =
        WorldContext.GetHealth(player)

    context.Hunger =
        WorldContext.GetHunger(player)

    context.Thirst =
        WorldContext.GetThirst(player)

    context.Fatigue =
        WorldContext.GetFatigue(player)

    context.Panic =
        WorldContext.GetPanic(player)

    context.Pain =
        WorldContext.GetPain(player)

    context.Position =
        WorldContext.GetPosition(player)

    context.Movement = {
        IsMoving =
            WorldContext.IsMoving(player)
    }

    context.Weapon =
        WorldContext.GetWeaponState(player)

    context.ZombiesNearby =
        WorldContext.GetNearbyZombieCount(
            player,
            15
        )

    context.Time =
        WorldContext.GetTime()

    return context
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

function WorldContext.Update()

    local player =
        WorldContext.GetPlayer()

    if not player then
        return false
    end

    local context =
        WorldContext.Build(player)

    if not context then
        return false
    end

    BAO.WorldContext.Current =
        context

    return true
end

--------------------------------------------------
-- DIAGNOSTICS
--------------------------------------------------

function WorldContext.Print(context)

    if not context then
        Log("Context is nil")
        return
    end

    Log("===== WORLD CONTEXT =====")

    Log(
        "Health: "
        .. tostring(context.Health)
    )

    Log(
        "Hunger: "
        .. tostring(context.Hunger)
    )

    Log(
        "Thirst: "
        .. tostring(context.Thirst)
    )

    Log(
        "Fatigue: "
        .. tostring(context.Fatigue)
    )

    Log(
        "Panic: "
        .. tostring(context.Panic)
    )

    Log(
        "Pain: "
        .. tostring(context.Pain)
    )

    if context.Position then

        Log(
            "Position: "
            .. tostring(context.Position.X)
            .. ", "
            .. tostring(context.Position.Y)
            .. ", "
            .. tostring(context.Position.Z)
        )

    end

    if context.Movement then

        Log(
            "Moving: "
            .. tostring(
                context.Movement.IsMoving
            )
        )

    end

    if context.Weapon then

        Log(
            "Weapon: "
            .. tostring(
                context.Weapon.WeaponName
            )
            .. " | HasWeapon="
            .. tostring(
                context.Weapon.HasWeapon
            )
            .. " | Ranged="
            .. tostring(
                context.Weapon.IsRanged
            )
        )

    end

    Log(
        "Zombies nearby: "
        .. tostring(
            context.ZombiesNearby
        )
    )

    if context.Time then

        Log(
            "Time: "
            .. tostring(
                context.Time.Hour
            )
            .. ":"
            .. tostring(
                context.Time.Minutes
            )
            .. " | Night="
            .. tostring(
                context.Time.IsNight
            )
        )

    end

    Log("=========================")
end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

local initialized = false
local initializationAttempts = 0

function WorldContext.TryInitialize()

    if initialized then
        return
    end

    initializationAttempts =
        initializationAttempts + 1

    local player =
        WorldContext.GetPlayer()

    if not player then
        return
    end

    local context =
        WorldContext.Build(player)

    if not context then
        return
    end

    BAO.WorldContext.Current =
        context

    initialized = true

    Log(
        "World Context V1 initialized "
        .. "(attempt "
        .. tostring(
            initializationAttempts
        )
        .. ")"
    )

    WorldContext.Print(context)
end

--------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------

local updateTimer = 0

local UPDATE_INTERVAL = 180

function WorldContext.OnTick()

    if not initialized then
        WorldContext.TryInitialize()
        return
    end

    updateTimer =
        updateTimer + 1

    if updateTimer <
        UPDATE_INTERVAL then

        return
    end

    updateTimer = 0

    local updated =
        WorldContext.Update()

    if updated then
        Log(
            "World Context updated"
        )
    end
end

--------------------------------------------------
-- EVENTS
--------------------------------------------------

if Events and Events.OnGameStart then

    Events.OnGameStart.Add(
        function()

            Log(
                "OnGameStart event received"
            )

            Log(
                "Waiting for player..."
            )

        end
    )

    Log(
        "OnGameStart handler registered"
    )
end

if Events and Events.OnTick then

    Events.OnTick.Add(
        WorldContext.OnTick
    )

    Log(
        "OnTick update handler registered"
    )
end

--------------------------------------------------
-- MODULE LOADED
--------------------------------------------------

Log(
    "World Context V1.1 module loaded"
)