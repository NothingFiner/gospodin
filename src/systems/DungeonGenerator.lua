-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/DungeonGenerator.lua

local ROT = require('libs.rotLove.rot')
local config = require('src.config')

-- Helper function to create a blank map filled with walls
local function createBlankMap(mapWidth, mapHeight)
    local map = {}
    -- 1. Initialize map with all walls
    for y = 1, mapHeight do
        map[y] = {}
        for x = 1, mapWidth do
            map[y][x] = 0 -- wall
        end
    end
    return map
end

-- Helper function to place stairs in random rooms
local function placeStairs(map, rooms, numUp, numDown)
    if #rooms < numUp + numDown then
        -- Fallback for small levels where constraints can't be met
        local shuffledRooms = {}
        for _, room in ipairs(rooms) do table.insert(shuffledRooms, room) end
        for i = #shuffledRooms, 2, -1 do local j = love.math.random(i); shuffledRooms[i], shuffledRooms[j] = shuffledRooms[j], shuffledRooms[i] end
        for i = 1, numUp do if #shuffledRooms > 0 then local r = table.remove(shuffledRooms); map[r.y + math.floor((r.height-1)/2)][r.x + math.floor((r.width-1)/2)] = 3 end end
        for i = 1, numDown do if #shuffledRooms > 0 then local r = table.remove(shuffledRooms); map[r.y + math.floor((r.height-1)/2)][r.x + math.floor((r.width-1)/2)] = 2 end end
        return
    end

    local roomPool = {}
    for _, room in ipairs(rooms) do table.insert(roomPool, room) end

    local upStairRooms = {}
    local downStairRooms = {}

    -- Place Up Stairs first by picking random rooms from the pool
    for i = 1, numUp do
        local roomIndex = love.math.random(#roomPool)
        local room = table.remove(roomPool, roomIndex)
        table.insert(upStairRooms, room)
        local sx = room.x + math.floor((room.width - 1) / 2)
        local sy = room.y + math.floor((room.height - 1) / 2)
        map[sy][sx] = 3 -- Up stair '<'
    end

    -- Now place Down Stairs, ensuring they are a minimum distance from any Up stair
    local MIN_STAIR_DISTANCE = 20 -- Approx. 3 rooms of size 6, plus a buffer

    for i = 1, numDown do
        local candidatePool = {}
        -- Filter the remaining rooms to find ones that are far enough away
        for _, candidateRoom in ipairs(roomPool) do
            local isFarEnough = true
            local candidateCenter = {x = candidateRoom.x + candidateRoom.width/2, y = candidateRoom.y + candidateRoom.height/2}
            
            for _, upRoom in ipairs(upStairRooms) do
                local upCenter = {x = upRoom.x + upRoom.width/2, y = upRoom.y + upRoom.height/2}
                local dist = math.sqrt((candidateCenter.x - upCenter.x)^2 + (candidateCenter.y - upCenter.y)^2)
                if dist < MIN_STAIR_DISTANCE then
                    isFarEnough = false
                    break
                end
            end

            if isFarEnough then
                table.insert(candidatePool, candidateRoom)
            end
        end

        local chosenRoom
        if #candidatePool > 0 then
            -- Pick a random room from the valid, distant candidates
            chosenRoom = candidatePool[love.math.random(#candidatePool)]
        elseif #roomPool > 0 then
            -- Fallback: No rooms met the distance criteria, so just pick any remaining room.
            chosenRoom = roomPool[love.math.random(#roomPool)]
        else
            return -- Should not happen if initial check passes
        end

        -- Remove the chosen room from the main pool so it can't be picked again
        for j, r in ipairs(roomPool) do if r == chosenRoom then table.remove(roomPool, j); break end end

        table.insert(downStairRooms, chosenRoom)
        local sx = chosenRoom.x + math.floor((chosenRoom.width - 1) / 2)
        local sy = chosenRoom.y + math.floor((chosenRoom.height - 1) / 2)
        map[sy][sx] = 2 -- Down stair '>'
    end
end

local generators = {}

-- Generator for the first floor: a single, large room
function generators.audience_chamber(floorIndex, mapWidth, mapHeight)
    local map = createBlankMap(mapWidth, mapHeight)
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

-- Generator for house-like floors with rooms and corridors
-- Implements a Binary Space Partitioning algorithm for a structured, building-like feel.
function generators.manor(floorIndex, mapWidth, mapHeight)
    return generators._generateBspMap(floorIndex, mapWidth, mapHeight)
end

-- BSP Generation Helper Functions
local bspTree
local bspRooms
local bspCorridors

local MIN_LEAF_SIZE = 5 -- The smallest a partition can be before it stops splitting.
local MAX_ASPECT_RATIO = 1.25 -- How stretched a partition can be before we force a split direction.

function generators._bspSplit(container, level)
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
        node.leftChild = generators._bspSplit({x=node.x, y=node.y, width=node.width, height=splitY}, level + 1)
        node.rightChild = generators._bspSplit({x=node.x, y=node.y + splitY, width=node.width, height=node.height - splitY}, level + 1)
    else
        local splitX = love.math.random(MIN_LEAF_SIZE, node.width - MIN_LEAF_SIZE)
        node.leftChild = generators._bspSplit({x=node.x, y=node.y, width=splitX, height=node.height}, level + 1)
        node.rightChild = generators._bspSplit({x=node.x + splitX, y=node.y, width=node.width - splitX, height=node.height}, level + 1)
    end

    return node
end

function generators._getLeaves(node, leaves)
    if node.leftChild or node.rightChild then
        if node.leftChild then generators._getLeaves(node.leftChild, leaves) end
        if node.rightChild then generators._getLeaves(node.rightChild, leaves) end
    else
        table.insert(leaves, node)
    end
end

function generators._createRoomsInLeaves(leaves)
    for _, leaf in ipairs(leaves) do
        -- Make the room fill the entire leaf, leaving a 1-tile border for walls.
        local roomX = leaf.x + 1
        local roomY = leaf.y + 1
        local roomW = leaf.width - 2
        local roomH = leaf.height - 2
        leaf.room = {x=roomX, y=roomY, width=roomW, height=roomH}
        table.insert(bspRooms, leaf.room)
    end
end

function generators._createCorridors(node)
    if not node.leftChild or not node.rightChild then return end

    generators._createCorridors(node.leftChild)
    generators._createCorridors(node.rightChild)

    -- Helper to get a representative room from a subtree
    local function getRoom(subtree)
        if subtree.room then return subtree.room end
        local leaves = {}
        generators._getLeaves(subtree, leaves)
        if #leaves > 0 and leaves[1].room then
            return leaves[1].room
        end
        return nil
    end

    local lRoom = getRoom(node.leftChild)
    local rRoom = getRoom(node.rightChild)

    -- If for some reason a room couldn't be found, we can't connect them.
    if not lRoom or not rRoom then return end

    -- Find the minimum distance between the two rooms
    local min_dist = math.huge
    for x1 = lRoom.x, lRoom.x + lRoom.width - 1 do
        for y1 = lRoom.y, lRoom.y + lRoom.height - 1 do
            for x2 = rRoom.x, rRoom.x + rRoom.width - 1 do
                for y2 = rRoom.y, rRoom.y + rRoom.height - 1 do
                    local dist = (x1 - x2)^2 + (y1 - y2)^2
                    if dist < min_dist then min_dist = dist end
                end
            end
        end
    end

    -- Collect all pairs of points that are at the minimum distance
    local best_points = {}
    for x1 = lRoom.x, lRoom.x + lRoom.width - 1 do
        for y1 = lRoom.y, lRoom.y + lRoom.height - 1 do
            for x2 = rRoom.x, rRoom.x + rRoom.width - 1 do
                for y2 = rRoom.y, rRoom.y + rRoom.height - 1 do
                    local dist = (x1 - x2)^2 + (y1 - y2)^2
                    if dist == min_dist then
                        table.insert(best_points, {x1 = x1, y1 = y1, x2 = x2, y2 = y2})
                    end
                end
            end
        end
    end

    -- Pick one of the best points at random
    local best = best_points[love.math.random(#best_points)]

    -- Draw a straight line corridor between the two closest points
    local x, y = best.x1, best.y1
    while x ~= best.x2 or y ~= best.y2 do
        table.insert(bspCorridors, {x=x, y=y})
        if x < best.x2 then x = x + 1 elseif x > best.x2 then x = x - 1 end
        if y < best.y2 then y = y + 1 elseif y > best.y2 then y = y - 1 end
    end
end

function generators._generateBspMap(floorIndex, mapWidth, mapHeight)
    local map = createBlankMap(mapWidth, mapHeight)
    bspRooms, bspCorridors = {}, {}

    local rootContainer = {x=1, y=1, width=mapWidth-1, height=mapHeight-1}
    bspTree = generators._bspSplit(rootContainer)

    local leaves = {}
    generators._getLeaves(bspTree, leaves)
    generators._createRoomsInLeaves(leaves)
    generators._createCorridors(bspTree)

    for _, room in ipairs(bspRooms) do
        for y = room.y, room.y + room.height - 1 do
            for x = room.x, room.x + room.width - 1 do
                if x > 0 and x < mapWidth and y > 0 and y < mapHeight then map[y][x] = 1 end
            end
        end
    end

    for _, tile in ipairs(bspCorridors) do
        if tile.x > 0 and tile.x < mapWidth and tile.y > 0 and tile.y < mapHeight then map[tile.y][tile.x] = 1 end
    end

    local leftLeaves, rightLeaves = {}, {}
    if bspTree.leftChild then generators._getLeaves(bspTree.leftChild, leftLeaves) end
    if bspTree.rightChild then generators._getLeaves(bspTree.rightChild, rightLeaves) end
    
    local leftRooms, rightRooms = {}, {}
    for _, leaf in ipairs(leftLeaves) do if leaf.room then table.insert(leftRooms, leaf.room) end end -- luacheck: ignore
    for _, leaf in ipairs(rightLeaves) do if leaf.room then table.insert(rightRooms, leaf.room) end end -- luacheck: ignore

    local transitions = config.floorData[floorIndex].transitions
    placeStairs(map, leftRooms, transitions.up, 0) -- Place Up stairs in the "left" partition
    placeStairs(map, rightRooms, 0, transitions.down) -- Place Down stairs in the "right" partition

    return map, bspRooms
end

-- Generator for the winding village streets
-- Implements a BSP algorithm to create a network of streets with varying widths.
function generators.village(floorIndex, mapWidth, mapHeight)
    local map = createBlankMap(mapWidth, mapHeight)

    -- 1. Create BSP tree for streets
    local rootContainer = {x=1, y=1, width=mapWidth-1, height=mapHeight-1}
    local streetTree = generators._bspSplit(rootContainer)
    
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

        -- Carve horizontal part
        for x = math.min(p1.x, p2.x), math.max(p1.x, p2.x) do
            for w = startOffset, endOffset do
                local y = p1.y + w
                if x > 1 and x < mapWidth and y > 1 and y < mapHeight then map[y][x] = {type = 1, variant = love.math.random(4)} end
            end
        end
        -- Carve vertical part
        for y = math.min(p1.y, p2.y), math.max(p1.y, p2.y) do
            for w = startOffset, endOffset do
                local x = p2.x + w
                if x > 1 and x < mapWidth and y > 1 and y < mapHeight then map[y][x] = {type = 1, variant = love.math.random(4)} end
            end
        end
    end
    createStreets(streetTree, 0)

    -- 2. Place Town Square
    local quadW, quadH = math.floor(mapWidth / 2), math.floor(mapHeight / 2)
    -- Make square size dynamic to prevent errors on smaller maps.
    -- It must be smaller than the quadrant it's placed in.
    local maxSquareSize = math.min(16, quadW - 4, quadH - 4)
    local squareSize = 0
    local squareX, squareY = -1, -1 -- Default to invalid coords

    if maxSquareSize > 5 then -- Only place a square if it can be reasonably large
        squareSize = love.math.random(math.floor(maxSquareSize * 0.5), maxSquareSize)
        squareX = love.math.random(2, quadW - squareSize - 1)
        squareY = love.math.random(2, quadH - squareSize - 1)
        for y = squareY, squareY + squareSize - 1 do
            for x = squareX, squareX + squareSize - 1 do
                -- Also check bounds here for safety
                if x > 1 and x < mapWidth and y > 1 and y < mapHeight then
                    map[y][x] = 4 -- Town Square tile type
                end
            end
        end
    end

    -- 3. Place Stairs in different quadrants
    local transitions = config.floorData[floorIndex].transitions or {}
    local quadrants = { {}, {}, {}, {} }
    
    local function isGoodStairLocation(x, y)
        -- The most important check: is the tile a walkable floor?
        local tile = map[y] and map[y][x]
        local tileType = type(tile) == "table" and tile.type or tile
        if tileType ~= 1 and tileType ~= 4 then return false end

        if not map[y] or (type(map[y][x]) == "number" and map[y][x] == 0) then return false end
        if squareSize > 0 and x >= squareX and x < squareX + squareSize and y >= squareY and y < squareY + squareSize then return false end
        return true
    end

    for y = 2, mapHeight - 2 do
        for x = 2, mapWidth - 2 do
            if isGoodStairLocation(x, y) then
                if x <= quadW and y <= quadH then table.insert(quadrants[1], {x=x, y=y}) -- TL
                elseif x > quadW and y <= quadH then table.insert(quadrants[2], {x=x, y=y}) -- TR
                elseif x <= quadW and y > quadH then table.insert(quadrants[3], {x=x, y=y}) -- BL
                else table.insert(quadrants[4], {x=x, y=y}) end -- BR
            end
        end
    end

    for i = #quadrants, 2, -1 do local j = love.math.random(i); quadrants[i], quadrants[j] = quadrants[j], quadrants[i] end

    -- Revert to the simpler placement logic
    for i = 1, (transitions.up or 0) do if #quadrants > 0 then local quad = table.remove(quadrants, 1); if quad and #quad > 0 then local pos = quad[love.math.random(#quad)]; map[pos.y][pos.x] = 3 end end end
    for i = 1, (transitions.down or 0) do if #quadrants > 0 then local quad = table.remove(quadrants, 1); if quad and #quad > 0 then local pos = quad[love.math.random(#quad)]; map[pos.y][pos.x] = 2 end end end

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

-- Default generator for sewers and alien lair
function generators.default(floorIndex, mapWidth, mapHeight)
    local map = createBlankMap(mapWidth, mapHeight)
    local dungeon = ROT.Map.Uniform(mapWidth, mapHeight, { timeLimit = 5000 })
    return generators._generateFromROTMap(dungeon, floorIndex, map, mapWidth, mapHeight)
end

-- Shared logic for processing a rotLove map object
function generators._generateFromROTMap(dungeon, floorIndex, map, mapWidth, mapHeight)
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
    
    -- Carve rooms
    for _, room in ipairs(dungeonRooms) do
        for y = room:getTop(), room:getBottom() do
            for x = room:getLeft(), room:getRight() do
                -- Convert from 0-indexed rotLove coords to 1-indexed map coords
                map[y + 1][x + 1] = 1
            end
        end
    end

    -- Carve corridors
    local dungeonCorridors = dungeon:getCorridors()
    for _, corridor in ipairs(dungeonCorridors) do
        corridor:create(function(x, y)
            -- The corridor callback provides 0-indexed coords
            map[y + 1][x + 1] = 1
        end)
    end

    -- 5. Fallback if generation failed
    if #rooms == 0 then
        local startX, startY = math.floor(mapWidth / 2), math.floor(mapHeight / 2)
        for y = startY - 3, startY + 3 do
            for x = startX - 3, startX + 3 do
                if x >= 1 and x <= mapWidth and y >= 1 and y <= mapHeight then
                    map[y][x] = 1
                end
            end
        end
        table.insert(rooms, {x = startX - 3, y = startY - 3, width = 7, height = 7})
    end
    
    -- Place stairs based on floor configuration
    local transitions = config.floorData[floorIndex].transitions
    placeStairs(map, rooms, transitions.up, transitions.down)

    return map, rooms
end

-- Main dispatcher function
local function generateFloor(floorIndex, mapWidth, mapHeight)
    local floorInfo = config.floorData[floorIndex]
    local generatorFunc = generators[floorInfo.generator] or generators.default
    return generatorFunc(floorIndex, mapWidth, mapHeight)
end

return generateFloor