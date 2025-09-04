-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Entity.lua

local Entity = {}
Entity.__index = Entity

function Entity:new(x, y, char, color, name, health, actionPoints)
    local entity = {
        x = x,
        y = y,
        char = char,
        color = color or {1, 1, 1},
        name = name,
        blocksMovement = true -- Most entities block movement
    }
    setmetatable(entity, self)
    return entity
end

return Entity