-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/mapGenerators/mapGeneratorUtils.lua
-- Shared utility functions for map generation.

local Utils = {}

-- Helper function to create a blank map filled with walls
function Utils.createBlankMap(mapWidth, mapHeight)
    local map = {}
    for y = 1, mapHeight do
        map[y] = {}
        for x = 1, mapWidth do
            map[y][x] = 0 -- wall
        end
    end
    return map
end

-- Helper function to place stairs in random rooms
function Utils.placeStairs(map, rooms, numUp, numDown)
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

return Utils