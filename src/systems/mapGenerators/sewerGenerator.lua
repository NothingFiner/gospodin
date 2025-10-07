-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/sewerGenerator.lua

local Utils = require('src.systems.mapGenerators.mapGeneratorUtils')
local ROT = require('libs.rotLove.rot')
local Assets = require('src.assets')
local config = require('src.config')

local SewerGenerator = {}

function SewerGenerator.generate(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)
    local dungeon = ROT.Map.Uniform(mapWidth, mapHeight, { timeLimit = 5000 })

    dungeon:create(function(x, y, value)
        -- Add boundary checks to prevent writing outside the map array
        if y+1 >= 1 and y+1 <= mapHeight and x+1 >= 1 and x+1 <= mapWidth then
            if value == 0 then
                -- Sewer Floor tile
                map[y+1][x+1] = {type = 1, variant = love.math.random(#Assets.sprites.sewers_floor_tiles)}
            else
                -- Sewer Wall tile
                map[y+1][x+1] = {type = 0, variant = love.math.random(#Assets.sprites.sewers_wall_tiles)}
            end
        end
    end)

    local rooms = {}
    for _, room in ipairs(dungeon:getRooms()) do
        table.insert(rooms, {x = room:getLeft()+1, y = room:getTop()+1, width = room:getRight()-room:getLeft()+1, height = room:getBottom()-room:getTop()+1})
    end

    local transitions = config.floorData[floorIndex].transitions
    Utils.placeStairs(map, rooms, transitions.up, transitions.down)
    return map, rooms
end

return SewerGenerator