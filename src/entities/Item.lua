-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Item.lua

local Entity = require('src.entities.Entity')
local C = require('src.constants')

local Item = {}
setmetatable(Item, {__index = Entity})
Item.__index = Item
Item.__type = "Item"

-- This is now a factory function that returns the correct item subtype.
function Item.create(x, y, itemName)
    local itemData = require('src.config').items[itemName]
    if not itemData then return nil end

    if itemData.type == C.ItemType.EQUIPMENT then
        local Equipment = require('src.entities.Equipment')
        return Equipment:new(x, y, itemData.char, itemData.color, itemData.name, itemData) -- This now works correctly
    elseif itemData.type == C.ItemType.CONSUMABLE then
        local Consumable = require('src.entities.Consumable')
        return Consumable:new(x, y, itemData.char, itemData.color, itemData.name, itemData) -- This now works correctly
    end
    return nil
end

return Item