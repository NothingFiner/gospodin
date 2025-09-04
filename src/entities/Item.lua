-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Item.lua

local Entity = require('src.entities.Entity')

local Item = {}
setmetatable(Item, {__index = Entity})
Item.__index = Item
Item.__type = "Item"

function Item:new(x, y, char, color, name, itemData)
    local item = Entity:new(x, y, char, color, name)
    item.itemData = itemData
    item.blocksMovement = false
    setmetatable(item, self)
    return item
end

return Item