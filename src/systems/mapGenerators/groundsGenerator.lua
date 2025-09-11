-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/groundsGenerator.lua

local Utils = require('src.systems.mapGenerators.mapGeneratorUtils')
local ROT = require('libs.rotLove.rot')
local config = require('src.config')

local GroundsGenerator = {}

function GroundsGenerator.generate(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)
    local rooms = {}

    -- 1. Use rotLove's Maze generator
    local maze = ROT.Map.DividedMaze(mapWidth, mapHeight)
    maze:create(function(x, y, value)
        -- The maze generator uses 0 for passages and 1 for walls.
        -- We'll flip this to match our convention (1 for floor, 0 for wall).
        if value == 0 then
            map[y][x] = 1 -- Floor (path)
        else
            map[y][x] = 0 -- Wall (hedge)
        end
    end)

    -- 2. Create a small entrance room at the bottom (from the village)
    local entranceX = math.floor(mapWidth / 2)
    local entranceY = mapHeight - 2
    for y = entranceY - 1, entranceY + 1 do
        for x = entranceX - 1, entranceX + 1 do
            map[y][x] = 1
        end
    end
    map[mapHeight][entranceX] = 2 -- Down transition to Village (in the wall)
    table.insert(rooms, {x = entranceX - 1, y = entranceY - 1, width = 3, height = 3})

    -- 3. Create a small exit room at the top (to the manor)
    local exitX = math.floor(mapWidth / 2)
    local exitY = 2
    for y = exitY - 1, exitY + 1 do
        for x = exitX - 1, exitX + 1 do
            map[y][x] = 1
        end
    end
    map[1][exitX] = 3 -- Up transition to Manor
    table.insert(rooms, {x = exitX - 1, y = exitY - 1, width = 3, height = 3})

    -- The maze itself doesn't have "rooms", so we just return the two we made.
    return map, rooms
end

return GroundsGenerator