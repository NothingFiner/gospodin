-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/Game.lua

local ROT = require('libs.rotLove.rot')
local config = require('src.config')
local createEnemy = require('src.entities.EnemyFactory')
local Assets = require('src.assets')
local GameLogSystem = require('src.systems.GameLogSystem')
local MessageLog = require('src.ui.MessageLog')

local Game = {
    player = nil,
    currentFloor = 1,
    floors = {},
    entities = {},
    turnQueue = {},
    uniqueEnemiesSpawned = {},
    fovMap = {},
    fovEnabled = true, -- New flag to control FOV
    currentTurnIndex = 1,
    mapWidth = 80,
    mapHeight = 25,
    camera = {x = 0, y = 0},
    tileSize = 32,
    playerVisionRadius = 8,
    lastPlayerAttacker = nil,
    states = {}, -- To hold state instances
    lastLoadout = nil
}

function Game.updateCamera()
    -- The camera should center the player in the map viewport, not the full screen.
    -- The map viewport is 80% of the screen width and 90% of the height.
    local mapViewWidth = love.graphics.getWidth() * 0.8
    local mapViewHeight = love.graphics.getHeight() * 0.9

    local tilesVisibleX = mapViewWidth / Game.tileSize
    local tilesVisibleY = mapViewHeight / Game.tileSize

    if Game.player then
        -- Center the camera on the player within the map viewport
        Game.camera.x = Game.player.x - (tilesVisibleX / 2)
        Game.camera.y = Game.player.y - (tilesVisibleY / 2)
    end
end

function Game.getEntitiesAt(x, y)
    local foundEntities = {}
    for _, entity in ipairs(Game.entities) do
        if entity.x == x and entity.y == y and entity ~= Game.player then
            table.insert(foundEntities, entity)
        end
    end
    return foundEntities
end

function Game.getEntityAt(x, y)
    local entitiesAtLocation = Game.getEntitiesAt(x, y)
    for _, entity in ipairs(entitiesAtLocation) do
        if entity.blocksMovement then
            return entity
        end
    end
    return nil
end

function Game.rebuildTurnQueue()
    Game.turnQueue = {}
    local Actor = require('src.entities.Actor')

    -- The player always goes first in the queue
    table.insert(Game.turnQueue, Game.player)

    -- Add all other actors (enemies) to the queue
    for _, entity in ipairs(Game.entities) do
        if is_a(entity, Actor) and entity ~= Game.player then
            table.insert(Game.turnQueue, entity)
        end
    end
end

function Game.getCurrentEntity()
    return Game.turnQueue[Game.currentTurnIndex]
end

function Game.nextTurn()
    -- This loop ensures we always land on a living entity's turn.
    repeat
        -- Move to next entity
        Game.currentTurnIndex = Game.currentTurnIndex + 1
        if Game.currentTurnIndex > #Game.turnQueue then
            Game.currentTurnIndex = 1
            -- New round - reset everyone's action points
            Game.player:tickCooldowns() -- Tick player ability cooldowns
            local Actor = require('src.entities.Actor')
            for _, entity in ipairs(Game.entities) do
                if is_a(entity, Actor) then
                    entity:resetActionPoints()
                end
            end
        end
        
        local currentEntity = Game.getCurrentEntity()
        -- Stop when we find a living entity, or if the queue is somehow empty.
        -- This prevents an infinite loop if all entities are dead.
    until not currentEntity or currentEntity.health > 0 or #Game.turnQueue == 0
end

function Game.dropItem(dropTable, x, y)
    if not dropTable then return end
    local ItemFactory = require('src.entities.Item')

    for _, itemDrop in ipairs(dropTable) do
        if love.math.random() < itemDrop.chance then
            local itemData = config.items[itemDrop.name]
            if itemData then
                local itemEntity = ItemFactory.create(x, y, itemDrop.name)
                table.insert(Game.entities, itemEntity)
            end
        end
    end
end

function Game.getDrops(dropTable)
    if not dropTable then return {} end
    local Item = require('src.entities.Item')
    
    local droppedItems = {}
    for _, itemDrop in ipairs(dropTable) do
        if love.math.random() < itemDrop.chance then
            local itemData = config.items[itemDrop.name]
            if itemData then
                local itemEntity = Item:new(0, 0, itemData.char, itemData.color, itemData.name, itemData)
                table.insert(droppedItems, itemEntity)
            end
        end
    end
    return droppedItems
end

function Game.computeFov()
    -- Reset all tiles to not visible before recalculating
    for y = 1, Game.mapHeight do
        for x = 1, Game.mapWidth do
            Game.fovMap[y][x] = 0 -- Store visibility level (0 to 1)
        end
    end

    -- The FOV algorithm needs 0-indexed coordinates
    local playerX_0, playerY_0 = Game.player.x - 1, Game.player.y - 1

    -- The rotLove FOV callback passes itself as the first argument, which we can ignore.
    local fovPassable = function(self, x_0, y_0)
        local x, y = x_0 + 1, y_0 + 1
        if x < 1 or y < 1 or x > Game.mapWidth or y > Game.mapHeight then
            return false
        end
        -- A tile is passable for FOV if it's not a wall (value is not 0)
        return Game.floors[Game.currentFloor].map[y][x] ~= 0
    end

    -- Use rotLove's Precise Shadowcasting algorithm
    local fov = ROT.FOV.Precise:new(fovPassable)

    -- Compute the FOV and update our maps
    fov:compute(playerX_0, playerY_0, Game.playerVisionRadius, function(x_0, y_0, r, visibility)
        local x, y = x_0 + 1, y_0 + 1
        if x >= 1 and x <= Game.mapWidth and y >= 1 and y <= Game.mapHeight then
            Game.fovMap[y][x] = visibility
            Game.floors[Game.currentFloor].exploredMap[y][x] = true -- Mark as explored
        end
    end)
end

function Game.changeFloor(direction)
    local Actor = require('src.entities.Actor')
    local newFloorIndex = Game.currentFloor + direction

    -- Check if the new floor is valid
    if direction ~= 0 and not config.floorData[newFloorIndex] then
        GameLogSystem.logCantGoThatWay()
        return false -- Indicate that the floor change failed
    end

    -- 1. Store the state of the current floor before leaving
    if Game.floors[Game.currentFloor] then
        local currentFloorEntities = {}
        for _, entity in ipairs(Game.entities) do
            if not is_a(entity, Actor) or entity ~= Game.player then
                table.insert(currentFloorEntities, entity)
            end
        end
        Game.floors[Game.currentFloor].entities = currentFloorEntities
    end

    -- Update current floor
    Game.currentFloor = newFloorIndex
    local floorInfo = config.floorData[Game.currentFloor]

    -- Update map dimensions based on the new floor's data
    Game.mapWidth = floorInfo.width or 80
    Game.mapHeight = floorInfo.height or 25
    -- Reset and re-initialize FOV map for the new dimensions
    Game.fovMap = {}
    for y = 1, Game.mapHeight do
        Game.fovMap[y] = {}
        for x = 1, Game.mapWidth do
            Game.fovMap[y][x] = 0
        end
    end

    -- 2. Check cache or generate a new floor if it's the first visit
    if not Game.floors[Game.currentFloor] then
        local generateFloor = require('src.systems.DungeonGenerator')
        local map, rooms, largeProps = generateFloor(Game.currentFloor, Game.mapWidth, Game.mapHeight)
        local newEntities = {}

        -- Spawn unique enemies for the floor if they haven't been spawned yet
        if floorInfo.uniqueSpawns then
            for _, uniqueType in ipairs(floorInfo.uniqueSpawns) do
                if not Game.uniqueEnemiesSpawned[uniqueType] then
                    local enemyX, enemyY
                    if #rooms > 0 then
                        -- Place unique enemy in the last room for dramatic effect
                        local room = rooms[#rooms]
                        enemyX = room.x + math.floor((room.width - 1) / 2)
                        enemyY = room.y + math.floor((room.height - 1) / 2)
                    else
                        -- Fallback: If no rooms were generated, spawn in the center of the map.
                        enemyX = math.floor(Game.mapWidth / 2)
                        enemyY = math.floor(Game.mapHeight / 2)
                    end
                    local enemy = createEnemy(uniqueType, enemyX, enemyY)
                    if enemy then
                        table.insert(newEntities, enemy)
                        Game.uniqueEnemiesSpawned[uniqueType] = true
                    end
                end
            end
        end

        -- Spawn new enemies for the floor
        -- Cap the number of spawn attempts to prevent over-population on levels with many small "rooms" (like the village)
        local maxSpawnAttempts = math.min(#rooms, 20) 
        for i = 1, maxSpawnAttempts do
            -- Pick a random "room" or tile to attempt a spawn in.
            local room = rooms[love.math.random(#rooms)]
            if room then
                if love.math.random() < 0.7 then
                    local enemyX = room.x + love.math.random(1, math.max(1, room.width - 2))
                    local enemyY = room.y + love.math.random(1, math.max(1, room.height - 2))
                    local enemyType = floorInfo.enemies[love.math.random(1, #floorInfo.enemies)]
                    local enemy = createEnemy(enemyType, enemyX, enemyY)
                    if enemy then table.insert(newEntities, enemy) end
                end
            end
        end

        -- Create an empty exploredMap for the new floor
        local newExploredMap = {}
        for y = 1, Game.mapHeight do
            newExploredMap[y] = {}
            for x = 1, Game.mapWidth do
                newExploredMap[y][x] = false
            end
        end

        -- Store the newly generated floor in the cache
        Game.floors[Game.currentFloor] = { map = map, rooms = rooms, entities = newEntities, exploredMap = newExploredMap, largeProps = largeProps or {} }
    end

    -- 3. Load the new floor's data from the cache
    local floorData = Game.floors[Game.currentFloor]
    local map = floorData.map
    local rooms = floorData.rooms

    -- 4. Determine player's new position
    local newPlayerX, newPlayerY
    if direction == 0 then
        -- Special case for first-time game initialization: fixed spawn point in Audience Room.
        newPlayerX = 5
        newPlayerY = 3
    else
        -- Normal level transition: find the corresponding stairs
        local targetStairType = (direction == 1) and 3 or 2
        -- Special case for leaving the Audience Room (floor 1)
        if Game.currentFloor == 2 and newFloorIndex == 1 then
            newPlayerX, newPlayerY = 5, 3 -- Place player back in the Audience Room
            targetStairType = nil -- Skip stair search
        end
        local possibleStartPositions = {}
        for y = 1, Game.mapHeight do
            for x = 1, Game.mapWidth do
                local tileType = type(map[y][x]) == "table" and map[y][x].type or map[y][x]
                if tileType == targetStairType then
                    table.insert(possibleStartPositions, {x = x, y = y})
                end
            end
        end

        if #possibleStartPositions > 0 then
            local startPos = possibleStartPositions[love.math.random(1, #possibleStartPositions)]
            newPlayerX, newPlayerY = startPos.x, startPos.y
        else
            -- Fallback: If no stairs are found, find a random walkable tile.
            local walkableTiles = {}
            for y = 1, Game.mapHeight do
                for x = 1, Game.mapWidth do
                    local tileType = type(map[y][x]) == "table" and map[y][x].type or map[y][x]
                    if tileType == 1 or tileType == 4 then -- Floor or Town Square
                        table.insert(walkableTiles, {x=x, y=y})
                    end
                end
            end
            local randomTile = walkableTiles[love.math.random(#walkableTiles)]
            newPlayerX, newPlayerY = randomTile.x, randomTile.y
            GameLogSystem.logNoStairsFound()
        end
    end

    -- 5. Populate the active game state with the new floor's data
    Game.entities = {}
    Game.player.x = newPlayerX
    Game.player.y = newPlayerY
    -- Add player and all other entities to the main list
    Game.entities = {Game.player, unpack(floorData.entities)}

    -- Rebuild turn queue
    Game.rebuildTurnQueue()
    Game.currentTurnIndex = 1
    
    -- 6. Final updates
    Game.computeFov()
    Game.updateCamera()
    GameLogSystem.logEnterFloor(floorInfo.name)
    return true -- Indicate success
end

function Game.goToFloor(floorIndex)
    if not config.floorData[floorIndex] then
        GameLogSystem.logMessage("Invalid floor index: " .. floorIndex, "info")
        return false
    end
    -- This is a simplified transition that doesn't look for corresponding stairs.
    -- It's suitable for a debug warp command.
    return Game.changeFloor(floorIndex - Game.currentFloor)
end

function Game.initialize(loadout)
    local ItemFactory = require('src.entities.Item')
    local Player = require('src.entities.Player')
    Game.entities = {}
    Game.currentFloor = 1
    Game.turnQueue = {}
    Game.uniqueEnemiesSpawned = {}
    Game.currentTurnIndex = 1

    -- Clear the message log for a fresh start
    MessageLog.clear()

    Game.lastLoadout = loadout -- Store the selected loadout for fast restarts

    -- Create the player object. Its position will be set by changeFloor.
    Game.player = Player:new(0, 0, "@", {1, 1, 1}, "Player")

    -- Apply the chosen loadout and starting gear
    Game.player:applyLoadout(loadout)
    
    -- Set up the first floor by calling changeFloor with a direction of 0.
    -- This will generate the map, spawn enemies, and place the player correctly.
    Game.changeFloor(0)
end

return Game