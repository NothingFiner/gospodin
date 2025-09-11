-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/defaultGenerators.lua

local Utils = require('src.systems.mapGenerators.mapGeneratorUtils')
local ROT = require('libs.rotLove.rot')
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

-- Default generator for sewers and alien lair
function DefaultGenerators.default(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)
    local dungeon = ROT.Map.Uniform(mapWidth, mapHeight, { timeLimit = 5000 })
    return DefaultGenerators._generateFromROTMap(dungeon, floorIndex, map, mapWidth, mapHeight)
end

-- Shared logic for processing a rotLove map object
function DefaultGenerators._generateFromROTMap(dungeon, floorIndex, map, mapWidth, mapHeight)
    -- 3. Manually carve the map from the generated rooms and corridors.
    -- This is more robust than the digCallback, ensuring the map data matches the room data.
    dungeon:create() -- This must be called to generate the internal data.
    
    -- 4. Get room and corridor data for entity placement and carving.
    local rooms = {}
    local dungeonRooms = dungeon:getRooms()

    for i, room in ipairs(dungeonRooms) do
        local r = {
            x = room:getLeft() + 1,
            y = room:getTop() + 1,
            width = room:getRight() - room:getLeft() + 1,
            height = room:getBottom() - room:getTop() + 1
        }
        table.insert(rooms, r)
    end
    
    -- Carve rooms and corridors
    dungeon:create(function(x, y, value)
        if value == 0 then map[y+1][x+1] = 1 end
    end)

    -- Place stairs based on floor configuration
    local transitions = config.floorData[floorIndex].transitions
    Utils.placeStairs(map, rooms, transitions.up, transitions.down)

    return map, rooms
end

return DefaultGenerators