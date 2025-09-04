-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Consumable.lua

local Entity = require('src.entities.Entity')
local Item = require('src.entities.Item')
local C = require('src.constants')
local GameLogSystem = require('src.systems.GameLogSystem')

local Consumable = {}
setmetatable(Consumable, {__index = Item})
Consumable.__index = Consumable
Consumable.__type = "Consumable"

function Consumable:new(x, y, char, color, name, itemData)
    local consumable = Entity:new(x, y, char, color, name)
    consumable.itemData = itemData
    consumable.blocksMovement = false
    setmetatable(consumable, self)
    return consumable
end

function Consumable:use(user)
    if self.itemData.effect.type == C.ItemEffect.HEAL then
        user.health = math.min(user.maxHealth, user.health + self.itemData.effect.amount)
        local effectText = "recovering " .. self.itemData.effect.amount .. " health."
        GameLogSystem.logItemUsed(self.name, effectText)
        return true
    end
    return false
end

return Consumable

