-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/DungeonGenerator.lua

local config = require('src.config')

-- This file is now a dispatcher that loads the appropriate generator module.
local generators = {
    manor = require('src.systems.mapGenerators.manorGenerator'),
    village = require('src.systems.mapGenerators.villageGenerator'),
    grounds = require('src.systems.mapGenerators.groundsGenerator'),
    audience_chamber = require('src.systems.mapGenerators.defaultGenerators'),
    default = require('src.systems.mapGenerators.defaultGenerators')
}

-- Main dispatcher function
local function generateFloor(floorIndex, mapWidth, mapHeight)
    local floorInfo = config.floorData[floorIndex]
    local generatorModule = generators[floorInfo.generator] or generators.default
    
    local generatorFunc
    if floorInfo.generator == "manor" or floorInfo.generator == "village" or floorInfo.generator == "grounds" then
        generatorFunc = generatorModule.generate
    else -- For defaultGenerators which contains multiple functions
        generatorFunc = generatorModule[floorInfo.generator] or generatorModule.default
    end

    return generatorFunc(floorIndex, mapWidth, mapHeight)
end

return generateFloor