-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/groundsGenerator.lua

local Utils = require('src.systems.mapGenerators.mapGeneratorUtils')
local Assets = require('src.assets')
local ROT = require('libs.rotLove.rot')
local config = require('src.config')

local GroundsGenerator = {}

function GroundsGenerator.generate(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)

    -- 1. Use rotLove's Maze generator
    local maze = ROT.Map.DividedMaze(mapWidth, mapHeight)
    maze:create(function(x, y, value)
        -- The maze generator uses 0 for passages and 1 for walls.
        -- We'll flip this to match our convention (1 for floor, 0 for wall).
        if value == 0 then
            map[y][x] = {type = 1, variant = love.math.random(#Assets.sprites.grounds_floor_tiles)} -- Floor (path)
        else
            map[y][x] = {type = 0, variant = love.math.random(#Assets.sprites.grounds_hedge_tiles)} -- Wall (hedge)
        end
    end)

    -- The maze itself doesn't have "rooms" in the traditional sense.
    -- To allow for enemy spawning, we'll collect all walkable path tiles
    -- and treat them as a single, large "room" area.
    local spawnableTiles = {}
    for y = 1, mapHeight do
        for x = 1, mapWidth do
            if type(map[y][x]) == "table" and map[y][x].type == 1 then
                table.insert(spawnableTiles, {x=x, y=y, width=1, height=1})
            end
        end
    end

    -- 2. Create a small entrance room at the bottom (from the village)
    local entranceX = math.floor(mapWidth / 2)
    local entranceY = mapHeight - 2
    for y = entranceY - 1, entranceY + 1 do
        for x = entranceX - 1, entranceX + 1 do
            map[y][x] = {type = 1, variant = love.math.random(#Assets.sprites.grounds_floor_tiles)}
        end
    end
    map[mapHeight-1][entranceX] = 2 -- Down transition to Village (on the path)

    -- 3. Create a small exit room at the top (to the manor)
    local exitX = math.floor(mapWidth / 2)
    local exitY = 2
    for y = exitY - 1, exitY + 1 do
        for x = exitX - 1, exitX + 1 do
            map[y][x] = {type = 1, variant = love.math.random(#Assets.sprites.grounds_floor_tiles)}
        end
    end
    map[2][exitX] = 3 -- Up transition to Manor

    return map, spawnableTiles
end

return GroundsGenerator