-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/AISystem.lua

local ROT = require('libs.rotLove.rot')
local Game = require('src.Game')

local AISystem = {}

function AISystem.performTurn(entity)
    -- Advanced AI using rotLove pathfinding
    if not Game.player or Game.player.health <= 0 then return end
    
    local dx = Game.player.x - entity.x
    local dy = Game.player.y - entity.y
    
    -- If adjacent, attack
    if math.abs(dx) <= 1 and math.abs(dy) <= 1 and (dx ~= 0 or dy ~= 0) then
        local success = entity:attack(Game.player)
        if not success then
            -- If the attack failed (e.g., not enough AP), the AI's turn must still
            -- end to prevent an infinite loop. We'll burn its remaining AP.
            entity.actionPoints = 0
        end
        return
    end
    
    -- rotLove's pathfinding is 0-indexed. We must convert our 1-indexed game
    -- coordinates before passing them to the library.
    local playerX_0, playerY_0 = Game.player.x - 1, Game.player.y - 1
    local entityX_0, entityY_0 = entity.x - 1, entity.y - 1

    -- Use rotLove pathfinding for smarter movement
    local passableCallback = function(x_0, y_0)
        -- The callback receives 0-indexed coords from rotLove. Convert them
        -- to 1-indexed to check against our game map.
        local x, y = x_0 + 1, y_0 + 1

        if x < 1 or x > Game.mapWidth or y < 1 or y > Game.mapHeight then
            return false
        end
        
        local map = Game.floors[Game.currentFloor]
        -- Ensure the row exists before trying to index it
        if not map[y] or not map[y][x] or map[y][x] == 0 then
            return false
        end
        
        -- Check for other entities (except player)
        for _, otherEntity in ipairs(Game.entities) do
            if otherEntity ~= entity and otherEntity ~= Game.player and 
               otherEntity.x == x and otherEntity.y == y then
                return false
            end
        end
        
        return true
    end
    
    local astar = ROT.Path.AStar(playerX_0, playerY_0, passableCallback, {topology = 8})
    local path = {}
    
    local pathCallback = function(x_0, y_0)
        -- The path is returned in 0-indexed coords. Convert to 1-indexed for game use.
        table.insert(path, {x = x_0 + 1, y = y_0 + 1})
    end
    
    astar:compute(entityX_0, entityY_0, pathCallback)
    
    -- Move along the path (skip first position which is current position)
    if #path > 1 then
        local nextPos = path[2]
        local moveX = nextPos.x - entity.x
        local moveY = nextPos.y - entity.y
        entity:move(moveX, moveY) -- move() expects a delta
    else
        -- Fallback to simple movement if no path found
        local moveX = 0
        local moveY = 0
        
        if dx > 0 then moveX = 1 elseif dx < 0 then moveX = -1 end
        if dy > 0 then moveY = 1 elseif dy < 0 then moveY = -1 end
        
        entity:move(moveX, moveY)
    end
end

return AISystem