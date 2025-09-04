-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Corpse.lua

local Entity = require('src.entities.Entity')

local Corpse = {}
setmetatable(Corpse, {__index = Entity})
Corpse.__index = Corpse
Corpse.__type = "Corpse"

function Corpse:new(x, y, originalName, inventory)
    local corpse = Entity:new(x, y, "%", {0.8, 0.2, 0.2}, "Corpse of " .. originalName)
    corpse.inventory = inventory or {}
    corpse.blocksMovement = false
    setmetatable(corpse, self)
    return corpse
end

return Corpse