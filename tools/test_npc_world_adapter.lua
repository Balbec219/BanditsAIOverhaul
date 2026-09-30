-- Offline only: engine doubles and fault injection. Never loaded by PZ.
local adapter = BAO.NPCWorldAdapter
BAO.Log = function() end
local count, worldRemoves, squareRemoves = 0, 0, 0
local blocked, failRemoval = false, false
local square = {
    getX = function() return 12 end, getY = function() return 10 end,
    getZ = function() return 0 end,
    isFree = function() return not blocked end, TreatAsSolidFloor = function() return true end
}
getCell = function() return { getGridSquare = function() return square end } end
isClient = function() return false end
isServer = function() return false end
local player = { getX = function() return 10 end, getY = function() return 10 end,
    getZ = function() return 0 end }
SurvivorFactory = {
    CreateSurvivor = function() return {} end,
    InstansiateInCell = function()
        count = count + 1
        return {
            setUseless = function() end, setTarget = function() end,
            getModData = function() return {} end,
            getX = square.getX, getY = square.getY, getZ = square.getZ,
            removeFromWorld = function() worldRemoves = worldRemoves + 1 end,
            removeFromSquare = function()
                if failRemoval then error('offline cleanup failure') end
                squareRemoves = squareRemoves + 1
            end
        }
    end
}
addZombiesInOutfit = function(...)
    local actor = SurvivorFactory.InstansiateInCell(...)
    return { size = function() return actor and 1 or 0 end, get = function() return actor end }
end
assert(adapter.SpawnTestNPC(player))
assert(BAO.NPCRuntime.GetCharacter('bao_world_test_001') == adapter.owned.character)
assert(not adapter.SpawnTestNPC(player) and count == 1)
failRemoval = true
assert(not adapter.RemoveTestNPC() and adapter.owned ~= nil)
assert(not adapter.SpawnTestNPC(player) and count == 1)
failRemoval = false
assert(adapter.RemoveTestNPC())
assert(worldRemoves == 1 and squareRemoves == 1)
assert(not BAO.NPCData.Exists('bao_world_test_001') and adapter.owned == nil)
assert(not adapter.RemoveTestNPC())
blocked = true
assert(not adapter.SpawnTestNPC(player) and count == 1)
blocked = false
isClient = function() return true end
assert(not adapter.SpawnTestNPC(player) and count == 1)
isClient = function() return false end
assert(adapter.SpawnTestNPC(player))
local character = adapter.owned.character
local oldGet = BAO.NavigationSystem.GetCurrentNavigation
BAO.NavigationSystem.GetCurrentNavigation = function() return { character = character } end
assert(not adapter.RemoveTestNPC() and adapter.owned.character == character)
BAO.NavigationSystem.GetCurrentNavigation = oldGet
assert(adapter.RemoveTestNPC())
assert(count == 2 and worldRemoves == 2 and squareRemoves == 2)
local queried
getCell = function() return { getGridSquare = function(_, x, y, z)
    queried = {x,y,z}; return square
end } end
assert(adapter.SpawnTestNPC(player, { x=30, y=40, z=1 }))
assert(queried[1] == 30 and queried[2] == 40 and queried[3] == 1)
assert(adapter.RemoveTestNPC())
assert(not adapter.SpawnTestNPC(player, { x=0/0, y=40, z=1 }))
assert(adapter.SpawnTestNPC(player))
local dead = adapter.owned.character
local oldRemoves = worldRemoves
assert(not adapter.ReleaseDeadNPC({}), 'Foreign death released owned actor')
assert(adapter.ReleaseDeadNPC(dead))
assert(adapter.owned == nil and worldRemoves == oldRemoves, 'Death removed corpse/world object')
assert(not adapter.ReleaseDeadNPC(dead), 'Duplicate death processed')
assert(adapter.SpawnTestNPC(player), 'Death did not release spawn slot')
adapter.owned.character.isDead = function() return true end
assert(adapter.SpawnTestNPC(player), 'Missed death event fallback failed')
assert(worldRemoves == oldRemoves, 'Fallback removed corpse')
assert(adapter.RemoveTestNPC())
SurvivorFactory.InstansiateInCell = function() return nil end
assert(not adapter.SpawnTestNPC(player) and adapter.owned == nil)
assert(not BAO.NPCData.Exists('bao_world_test_001'))
print('NPC world adapter lifecycle: PASS')
