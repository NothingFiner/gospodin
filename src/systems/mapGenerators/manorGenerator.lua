-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/manorGenerator.lua

local Utils = require('src.systems.mapGenerators.mapGeneratorUtils')
local config = require('src.config')
local Assets = require('src.assets')
local Game = require('src.Game')

local ManorGenerator = {}

-- BSP Generation Helper Functions
local bspTree
local bspRooms
local bspCorridors
-- A leaf size of 5 results in a 3x3 room (5-2=3), ensuring no wall is smaller than 3.
local MIN_LEAF_SIZE = 5 -- The smallest a partition can be before it stops splitting.
local MAX_ASPECT_RATIO = 1.25 -- How stretched a partition can be before we force a split direction.

-- Constant data for rug placement, using exact pixel dimensions from the 2x atlas.
local RUG_DATA = {
    rug_1 = {sprite = "rug_1", w = 190, h = 250},
    rug_2 = {sprite = "rug_2", w = 122, h = 190},
    rug_3 = {sprite = "rug_3", w = 132, h = 90},
    rug_7 = {sprite = "rug_7", w = 124, h = 172},
    rug_8 = {sprite = "rug_8", w = 136, h = 132}, 
    rug_10 = {sprite = "rug_10", w = 130, h = 136},
    rug_5_circ = {sprite = "rug_5_circ", w = 124, h = 58},
    rug_6_circ = {sprite = "rug_6_circ", w = 130, h = 130},
}

-- Special set of rugs for narrow rooms (short side =< 4 tiles)
local NARROW_ROOM_RUGS = {
    rug_3 = {sprite = "rug_3", w = 132, h = 90},
    rug_5_circ = {sprite = "rug_5_circ", w = 124, h = 58},
}

local RUNNERS = {
    runner_1 = {sprite = "runner_1", w = 38, h = 140}, 
    runner_2 = {sprite = "runner_2", w = 48, h = 204}, 
}

local LONG_SIDES = {
    rug_1 = "h",
    rug_2 = "h",
    rug_3 = "w",
    rug_7 = "h",
    rug_8 = "w",
    rug_10 = "w",
    rug_5_circ = "h",
    rug_6_circ = "w",
    runner_1 = "h",
    runner_2 = "h",
}

-- The smallest dimension of any rug, used for budget checking.
local SMALLEST_RUG_DIM = 58

function ManorGenerator._bspSplit(container, level)
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
        node.leftChild = ManorGenerator._bspSplit({x=node.x, y=node.y, width=node.width, height=splitY}, level + 1)
        node.rightChild = ManorGenerator._bspSplit({x=node.x, y=node.y + splitY, width=node.width, height=node.height - splitY}, level + 1)
    else
        local splitX = love.math.random(MIN_LEAF_SIZE, node.width - MIN_LEAF_SIZE)
        node.leftChild = ManorGenerator._bspSplit({x=node.x, y=node.y, width=splitX, height=node.height}, level + 1)
        node.rightChild = ManorGenerator._bspSplit({x=node.x + splitX, y=node.y, width=node.width - splitX, height=node.height}, level + 1)
    end

    return node
end

function ManorGenerator._getLeaves(node, leaves)
    if node.leftChild or node.rightChild then
        if node.leftChild then ManorGenerator._getLeaves(node.leftChild, leaves) end
        if node.rightChild then ManorGenerator._getLeaves(node.rightChild, leaves) end
    else
        table.insert(leaves, node)
    end
end

function ManorGenerator._createRoomsInLeaves(leaves)
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

function ManorGenerator._createCorridors(node, map)
    if not node.leftChild or not node.rightChild then return end

    ManorGenerator._createCorridors(node.leftChild, map)
    ManorGenerator._createCorridors(node.rightChild, map)

    -- Helper to get a representative room from a subtree
    local function getRoom(subtree)
        if subtree.room then return subtree.room end
        local leaves = {}
        ManorGenerator._getLeaves(subtree, leaves)
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
        -- Only add this tile to the corridor list if it's not already part of a room's floor.
        if not map[y] or map[y][x] ~= 1 then
            table.insert(bspCorridors, {x=x, y=y})
        end
        if x < best.x2 then x = x + 1 elseif x > best.x2 then x = x - 1 end
        if y < best.y2 then y = y + 1 elseif y > best.y2 then y = y - 1 end
    end
end

local function _placeManorStairs(map, rooms, numUp, numDown)
    if #rooms < 2 then return end -- Need at least two rooms for stairs

    local cornerRooms = {rooms[1], rooms[#rooms]} -- A simple way to get corner-ish rooms
    local upRoom = table.remove(cornerRooms, love.math.random(#cornerRooms))
    local downRoom = cornerRooms[1]

    -- Attempt to place up stairs in the first corner room
    if numUp > 0 then
        local ux, uy
        -- Try top wall first
        ux, uy = upRoom.x + math.floor(upRoom.width/2), upRoom.y - 1
        if map[uy] and map[uy][ux] == 0 then
            map[uy][ux] = {type = 3, rotation = math.rad(180)} -- Face down
        else -- Fallback to left wall
            ux, uy = upRoom.x - 1, upRoom.y + math.floor(upRoom.height/2)
            if map[uy] and map[uy][ux] == 0 then
                map[uy][ux] = {type = 3, rotation = math.rad(90)} -- Face right
            else -- Fallback to right wall
                ux, uy = upRoom.x + upRoom.width, upRoom.y + math.floor(upRoom.height/2)
                if map[uy] and map[uy][ux] == 0 then 
                    map[uy][ux] = {type = 3, rotation = math.rad(-90)} -- Face left
                end
            end
        end
    end

    -- Attempt to place down stairs in the second corner room
    if numDown > 0 then
        local dx, dy
        -- Try bottom wall first
        dx, dy = downRoom.x + math.floor(downRoom.width/2), downRoom.y + downRoom.height
        if map[dy] and map[dy][dx] == 0 then
            map[dy][dx] = {type = 2, rotation = 0} -- Face up (default)
        else -- Fallback to right wall
            dx, dy = downRoom.x + downRoom.width, downRoom.y + math.floor(downRoom.height/2)
            if map[dy] and map[dy][dx] == 0 then
                map[dy][dx] = {type = 2, rotation = math.rad(-90)} -- Right wall, faces left
            end
         end
    end
end

function ManorGenerator.generate(floorIndex, mapWidth, mapHeight)
    local map = Utils.createBlankMap(mapWidth, mapHeight)
    bspRooms, bspCorridors = {}, {}
    local largeProps = {}

    local rootContainer = {x=1, y=1, width=mapWidth-1, height=mapHeight-1}
    bspTree = ManorGenerator._bspSplit(rootContainer)

    local leaves = {}
    ManorGenerator._getLeaves(bspTree, leaves)
    -- This just defines the room data, it doesn't draw it yet.
    ManorGenerator._createRoomsInLeaves(leaves)

    -- Now, carve the rooms onto the map *before* creating corridors.
    for _, room in ipairs(bspRooms) do
        for y = room.y, room.y + room.height - 1 do
            for x = room.x, room.x + room.width - 1 do
                if x > 0 and x < mapWidth and y > 0 and y < mapHeight then
                    map[y][x] = 1 -- Mark as floor
                end
            end
        end
    end

    ManorGenerator._createCorridors(bspTree, map)

    for _, room in ipairs(bspRooms) do
        for y = room.y, room.y + room.height - 1 do
            for x = room.x, room.x + room.width - 1 do
                if x > 0 and x < mapWidth and y > 0 and y < mapHeight then
                    -- Assign a random variant, ensuring it's not the same as its neighbors
                    local neighbors = {map[y-1] and map[y-1][x], map[y+1] and map[y+1][x], map[y][x-1], map[y][x+1]}
                    local variant
                    repeat
                        variant = love.math.random(16) -- Assuming 16 tiles in the atlas (4x4 grid of 32x32 tiles in a 128x128 image)
                        local isSameAsNeighbor = false
                        for _, neighborTile in ipairs(neighbors) do
                            if type(neighborTile) == "table" and neighborTile.variant == variant then
                                isSameAsNeighbor = true
                                break
                            end
                        end
                    until not isSameAsNeighbor
                    map[y][x] = {type = 1, variant = variant}
                end
            end
        end
    end

    for _, room in ipairs(bspRooms) do
        -- 1. Determine room orientation and budget in PIXELS
        local isWider = room.width > room.height
        local longSide = isWider and room.width or room.height
        local shortSide = isWider and room.height or room.width
        local longAxisPixels = longSide * Game.tileSize
        local shortAxisPixels = shortSide * Game.tileSize
        local rugBudget = longAxisPixels - (2 * Game.tileSize) -- Leave a 1-tile (32px) border on each side

        -- 2. Find a set of rugs that fits the budget
        local rugsToPlace = {}
        local remainingBudget = rugBudget
        local availableRugs = {}
        local sourceRugData = RUG_DATA

        -- Use special rules for narrow rooms.
        if shortSide == 3 then -- Runners ONLY
            sourceRugData = RUNNERS
        elseif shortSide == 4 then -- Narrow room rugs (no runners)
            sourceRugData = NARROW_ROOM_RUGS
        end

        -- Create a shallow copy so we don't modify the original constant tables
        for _, data in pairs(sourceRugData) do table.insert(availableRugs, data) end

        while remainingBudget >= SMALLEST_RUG_DIM and #availableRugs > 0 do
            local rugIndex = love.math.random(#availableRugs)
            local rug = table.remove(availableRugs, rugIndex)
            local rugLong = math.max(rug.w, rug.h)
            local rugShort = math.min(rug.w, rug.h)
            local rugLength = 0
            local rugRotation = 0

            -- Check if the rug is too wide for the room's shorter side
            if rugShort > shortAxisPixels then goto continue end
            if shortSide > 4 then
                if isWider and rug.w < shortAxisPixels then 
                    rugLength = rug.h
                    rugRotation = math.rad(90)
                elseif not isWider and rug.h < shortAxisPixels then
                    rugLength = rug.w
                else 
                    goto continue
                end
            else
                rugLength = rugLong
                -- If the room is wide, but the rug's long side is its height, we need to rotate.
                if isWider and LONG_SIDES[rug.sprite] == "h" then
                    rugRotation = math.rad(90)
                -- If the room is tall, but the rug's long side is its width, we need to rotate.
                elseif not isWider and LONG_SIDES[rug.sprite] == "w" then
                    rugRotation = math.rad(90)
                end
            end


            if remainingBudget >= rugLength then
                local rugToPlace = deepcopy(rug)
                rugToPlace.baseRotation = rugRotation -- Store the calculated rotation
                table.insert(rugsToPlace, rugToPlace)
                remainingBudget = remainingBudget - rugLength
            end
            ::continue::
        end

        if #rugsToPlace > 0 then
            -- 3. Place the chosen rugs using PIXEL coordinates
            local totalRugLength = 0
            for _, rug in ipairs(rugsToPlace) do
                local length = (rug.baseRotation == 0) and rug.h or rug.w
                totalRugLength = totalRugLength + length
            end

            local spacing = (rugBudget%totalRugLength) / (#rugsToPlace)
            local currentPos = spacing + Game.tileSize -- Start with the first gap, plus the 1-tile border

            for _, rug in ipairs(rugsToPlace) do

                local finalRotation = rug.baseRotation + math.rad(love.math.random(-2, 2))
                
                local rugW, rugH = rug.w, rug.h
                if rug.baseRotation ~= 0 then
                    rugW, rugH = rugH, rugW
                end

                local x, y
                if isWider then
                    -- Place along horizontal center
                    local isRunner = (rug.sprite == "runner_1" or rug.sprite == "runner_2")
                    -- For a rotated runner, its effective height is its original width.
                    local effectiveRugH = (isRunner) and rug.w or rugH

                    x = (room.x * Game.tileSize) + currentPos
                    y = (room.y * Game.tileSize) + ((room.height * Game.tileSize) - effectiveRugH) / 2 + love.math.random(-4, 4)
                else
                    -- Place along vertical center
                    x = (room.x * Game.tileSize) + ((room.width * Game.tileSize) - rugW) / 2 + love.math.random(-4, 4)
                    y = (room.y * Game.tileSize) + currentPos
                end

                -- Convert final pixel coordinates back to tile coordinates for storage
                table.insert(largeProps, {x = x, y = y, sprite = rug.sprite, rotation = finalRotation, isPixelCoords = true})
                currentPos = currentPos + (isWider and rugH or rugW) + spacing
            end
        end

        -- Debug printing for the room and its rugs
        print("--- Room Processed ---")
        print(string.format("Room Dimensions: %d x %d", room.width, room.height))
        if #rugsToPlace > 0 then
            print("Rugs Placed:")
            for _, rug in ipairs(rugsToPlace) do
                local rotationDegrees = math.deg(rug.baseRotation or 0)
                print(string.format("  - %s (Rotation: %.0f degrees)", rug.sprite, rotationDegrees))
            end
        else
            print("No rugs were placed in this room.")
        end
    end

    for _, tile in ipairs(bspCorridors) do
        if tile.x > 0 and tile.x < mapWidth and tile.y > 0 and tile.y < mapHeight then
            -- Corridors can have a simpler random assignment
            local variant = love.math.random(16)
            map[tile.y][tile.x] = {type = 1, variant = variant}
        end
    end

    local leftLeaves, rightLeaves = {}, {}
    if bspTree.leftChild then ManorGenerator._getLeaves(bspTree.leftChild, leftLeaves) end
    if bspTree.rightChild then ManorGenerator._getLeaves(bspTree.rightChild, rightLeaves) end
    
    local leftRooms, rightRooms = {}, {}
    for _, leaf in ipairs(leftLeaves) do if leaf.room then table.insert(leftRooms, leaf.room) end end -- luacheck: ignore
    for _, leaf in ipairs(rightLeaves) do if leaf.room then table.insert(rightRooms, leaf.room) end end -- luacheck: ignore

    local transitions = config.floorData[floorIndex].transitions
    -- Use the new manor-specific stair placement logic, passing all rooms
    _placeManorStairs(map, bspRooms, transitions.up, transitions.down)

    return map, bspRooms, largeProps
end

return ManorGenerator