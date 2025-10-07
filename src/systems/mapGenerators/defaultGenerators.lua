-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/defaultGenerators.lua

local Utils = require('src.systems.mapGenerators.mapGeneratorUtils')
local ROT = require('libs.rotLove.rot')
local Assets = require('src.assets')
local config = require('src.config')

local DefaultGenerators = {}

-- Generator for the first floor: a single, large room
function DefaultGenerators.audience_chamber(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)
    local rooms = {}

    -- Create a fixed 7x14 room at the top-left of the map.
    local roomW, roomH = 7, 14
    local roomX, roomY = 2, 2 -- Start at (2,2) to ensure a border wall

    -- Carve the room
    for y = roomY, roomY + roomH - 1 do
        for x = roomX, roomX + roomW - 1 do
            map[y][x] = 1
        end
    end
    table.insert(rooms, {x = roomX, y = roomY, width = roomW, height = roomH})

    -- Place a single "door" (down-stair) at the middle of the bottom wall
    local doorX = roomX + math.floor(roomW / 2)
    local doorY = roomY + roomH - 1
    map[doorY][doorX] = 2

    return map, rooms
end

-- Generator for the Alien Lair using Cellular Automata
function DefaultGenerators.alien_lair(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)
    local cellular = ROT.Map.Cellular(mapWidth, mapHeight)
    
    -- Randomize the initial map
    cellular:randomize(0.5)
    
    -- Run the simulation a few times to create cave-like structures
    for i = 1, 3 do cellular:create() end
 
    -- The create() callback populates the map. The final pass connects any disjointed areas.
    cellular:create(function(x, y, value) map[y][x] = value == 0 and 1 or 0 end)

    -- Cellular maps don't have "rooms". We'll collect all walkable tiles for spawning.
    local spawnableTiles = {}
    for y = 1, mapHeight do
        for x = 1, mapWidth do
            if map[y][x] == 1 then -- 1 is a floor tile
                table.insert(spawnableTiles, {x=x, y=y, width=1, height=1})
            end
        end
    end
    return map, spawnableTiles
end

-- The default generator is now a fallback that creates a simple dungeon.
function DefaultGenerators.default(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)
    local dungeon = ROT.Map.Uniform(mapWidth, mapHeight, { timeLimit = 5000 })
    
    dungeon:create(function(x, y, value)
        if value == 0 then map[y+1][x+1] = 1 else map[y+1][x+1] = 0 end
    end)

    local rooms = {}
    for _, room in ipairs(dungeon:getRooms()) do
        table.insert(rooms, {x = room:getLeft()+1, y = room:getTop()+1, width = room:getRight()-room:getLeft()+1, height = room:getBottom()-room:getTop()+1})
    end

    local transitions = config.floorData[floorIndex].transitions
    Utils.placeStairs(map, rooms, transitions.up, transitions.down)
    return map, rooms
end

return DefaultGenerators