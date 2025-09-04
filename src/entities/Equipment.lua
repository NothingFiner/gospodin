-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Equipment.lua

local Entity = require('src.entities.Entity')
local Item = require('src.entities.Item')

local Equipment = {}
setmetatable(Equipment, {__index = Item})
Equipment.__index = Equipment
Equipment.__type = "Equipment"

function Equipment:new(x, y, char, color, name, itemData)
    local equip = Entity:new(x, y, char, color, name)
    equip.itemData = itemData
    equip.slot = itemData.slot
    equip.modifiers = itemData.modifiers or {}
    setmetatable(equip, self)
    return equip
end

return Equipment

