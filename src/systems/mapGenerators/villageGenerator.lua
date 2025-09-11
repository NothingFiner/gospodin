-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/villageGenerator.lua

local Utils = require('src.systems.mapGenerators.mapGeneratorUtils')
local config = require('src.config')

local VillageGenerator = {}

-- A leaf size of 5 results in a 3x3 room (5-2=3), ensuring no wall is smaller than 3.
local MIN_LEAF_SIZE = 5 -- The smallest a partition can be before it stops splitting.
local MAX_ASPECT_RATIO = 1.25 -- How stretched a partition can be before we force a split direction.

function VillageGenerator._bspSplit(container, level)
    level = level or 0
    local node = {
        x = container.x, y = container.y,
        width = container.width, height = container.height,
        leftChild = nil, rightChild = nil
    }

    -- Stop splitting if the container is too small or we've recursed too deep.
    if level > 6 or (node.width < MIN_LEAF_SIZE * 2 or node.height < MIN_LEAF_SIZE * 2 ) then
        return node
    end

    local canSplitHorizontal = node.height >= MIN_LEAF_SIZE * 2
    local canSplitVertical = node.width >= MIN_LEAF_SIZE * 2

    if not canSplitHorizontal and not canSplitVertical then
        return node -- Cannot be split further
    end

    local splitHorizontal
    if not canSplitHorizontal then splitHorizontal = false
    elseif not canSplitVertical then splitHorizontal = true
    elseif node.width / node.height > MAX_ASPECT_RATIO then splitHorizontal = false -- Wide, so split vertically
    elseif node.height / node.width > MAX_ASPECT_RATIO then splitHorizontal = true -- Tall, so split horizontally
    else splitHorizontal = love.math.random() > 0.5 end -- It's squarish, so split randomly

    if splitHorizontal then
        local splitY = love.math.random(MIN_LEAF_SIZE, node.height - MIN_LEAF_SIZE)
        node.leftChild = VillageGenerator._bspSplit({x=node.x, y=node.y, width=node.width, height=splitY}, level + 1)
        node.rightChild = VillageGenerator._bspSplit({x=node.x, y=node.y + splitY, width=node.width, height=node.height - splitY}, level + 1)
    else
        local splitX = love.math.random(MIN_LEAF_SIZE, node.width - MIN_LEAF_SIZE)
        node.leftChild = VillageGenerator._bspSplit({x=node.x, y=node.y, width=splitX, height=node.height}, level + 1)
        node.rightChild = VillageGenerator._bspSplit({x=node.x + splitX, y=node.y, width=node.width - splitX, height=node.height}, level + 1)
    end

    return node
end

local function _placeVillageTransitions(map, mapWidth, mapHeight, transitions)
    local floorTiles = {}
    local wallTiles = {}

    for y = 2, mapHeight - 2 do
        for x = 2, mapWidth - 2 do
            local tile = map[y][x]
            local tileType = type(tile) == "table" and tile.type or tile

            if tileType == 1 then -- Street tile
                table.insert(floorTiles, {x = x, y = y})
            elseif tileType == 0 then -- Building wall
                -- Check if it's an outer wall bordering a street
                local isOuterWall = false
                local neighbors = {{0, -1}, {0, 1}, {-1, 0}, {1, 0}}
                for _, offset in ipairs(neighbors) do
                    local nx, ny = x + offset[1], y + offset[2]
                    local neighborTile = map[ny] and map[ny][nx]
                    local neighborType = type(neighborTile) == "table" and neighborTile.type or neighborTile
                    if neighborType == 1 then
                        isOuterWall = true
                        break
                    end
                end
                if isOuterWall then
                    table.insert(wallTiles, {x = x, y = y})
                end
            end
        end
    end

    -- Place "up" transition (to Manor) in a wall
    if transitions.up and transitions.up > 0 and #wallTiles > 0 then
        local pos = wallTiles[love.math.random(#wallTiles)]
        map[pos.y][pos.x] = 3 -- Up stair (door to manor)
    end

    -- Place "down" transition (to Sewers) on the street
    if transitions.down and transitions.down > 0 and #floorTiles > 0 then
        local pos = floorTiles[love.math.random(#floorTiles)]
        map[pos.y][pos.x] = 2 -- Down stair (manhole)
    end
end

function VillageGenerator.generate(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)

    -- 1. Create BSP tree for streets
    local rootContainer = {x=1, y=1, width=mapWidth-1, height=mapHeight-1}
    local streetTree = VillageGenerator._bspSplit(rootContainer)
    
    -- Create a new recursive function to carve streets with variable width
    local function createStreets(node, level)
        if not node.leftChild or not node.rightChild then return end

        createStreets(node.leftChild, level + 1)
        createStreets(node.rightChild, level + 1)

        local function getCenter(subtree)
            return { x = subtree.x + math.floor(subtree.width / 2), y = subtree.y + math.floor(subtree.height / 2) }
        end

        local p1 = getCenter(node.leftChild)
        local p2 = getCenter(node.rightChild)

        local streetWidth
        if level == 0 then streetWidth = 5
        elseif level == 1 then streetWidth = 3
        elseif level == 2 then streetWidth = 2
        else streetWidth = 1 end

        local startOffset = -math.floor((streetWidth - 1) / 2)
        local endOffset = math.floor(streetWidth / 2)

        -- Use a straight-line algorithm to ensure connectivity
        local x, y = p1.x, p1.y
        while x ~= p2.x or y ~= p2.y do
            -- Carve the street with its given width
            for i = startOffset, endOffset do
                for j = startOffset, endOffset do
                    local carveX, carveY = x + i, y + j
                    if carveX > 1 and carveX < mapWidth and carveY > 1 and carveY < mapHeight then
                        map[carveY][carveX] = {type = 1, variant = love.math.random(4)}
                    end
                end
            end

            if x < p2.x then x = x + 1 elseif x > p2.x then x = x - 1 end
            if y < p2.y then y = y + 1 elseif y > p2.y then y = y - 1 end
        end
    end
    createStreets(streetTree, 0)

    -- Place transitions after streets are carved
    local transitions = config.floorData[floorIndex].transitions
    _placeVillageTransitions(map, mapWidth, mapHeight, transitions)

    -- Since this generator doesn't create traditional "rooms", we'll create one large "room"
    -- that encompasses all walkable tiles for the purpose of enemy spawning.
    local allFloorTilesAsOneRoom = {}
    for y=1, mapHeight do
        for x=1, mapWidth do
            if (type(map[y][x]) == "table" and map[y][x].type == 1) or map[y][x] == 4 then
                table.insert(allFloorTilesAsOneRoom, {x=x, y=y, width=1, height=1})
            end
        end
    end

    return map, allFloorTilesAsOneRoom
end

return VillageGenerator