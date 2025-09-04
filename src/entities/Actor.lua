-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Actor.lua

local Entity = require('src.entities.Entity')
local CombatLogSystem = require('src.systems.CombatLogSystem')
local GameLogSystem = require('src.systems.GameLogSystem')
local C = require('src.constants')

local Actor = {}
setmetatable(Actor, {__index = Entity}) -- Inheritance
Actor.__index = Actor
Actor.__type = "Actor"

function Actor:new(x, y, char, color, name, health, actionPoints)
    local actor = Entity:new(x, y, char, color, name)
    
    -- Add actor-specific properties
    actor.maxHealth = health or 10
    actor.health = health or 10
    actor.maxActionPoints = actionPoints or 3
    actor.actionPoints = actionPoints or 3
    actor.isPlayer = false
    actor.sprite = nil
    actor.damage = {min = 1, max = 3}
    actor.xpValue = 0
    actor.dodge = 5
    actor.armor = 0
    actor.statusEffects = {}
    actor.inventory = {}

    setmetatable(actor, self)
    return actor
end

function Actor:move(dx, dy)
    local Game = require('src.Game')
    if self.actionPoints <= 0 then return false end
    
    local function failMove()
        if not self.isPlayer then self.actionPoints = self.actionPoints - 1 end
        return false
    end

    local newX, newY = self.x + dx, self.y + dy
    
    if newX < 1 or newX > Game.mapWidth or newY < 1 or newY > Game.mapHeight then return failMove() end
    
    local map = Game.floors[Game.currentFloor].map
    local destTile = map and map[newY] and map[newY][newX]

    if self.isPlayer then -- Check for player identity
        if destTile == 2 then return Game.changeFloor(1)
        elseif destTile == 3 then return Game.changeFloor(-1) end
    end

    if destTile ~= 1 and destTile ~= 4 then return failMove() end
    
    local targetEntity = Game.getEntityAt(newX, newY)

    if targetEntity and targetEntity ~= self and targetEntity.blocksMovement then
        if self.isPlayer ~= targetEntity.isPlayer then
            local success = self:attack(targetEntity)
            if not success and self.isPlayer then GameLogSystem.logNoAP("attack") end
            return true
        else
            return failMove()
        end
    end
    
    self.x = newX
    self.y = newY
    self.actionPoints = self.actionPoints - 1
    return true
end

function Actor:attack(target)
    if self.actionPoints < (self.weapon and self.weapon.apCost or 2) then return false end
    
    local apCost = self.weapon and self.weapon.apCost or 2
    self.actionPoints = self.actionPoints - apCost

    return self:_resolveAttack(target)
end

function Actor:_resolveAttack(target)
    if not target.dodge then return true end -- Can't attack non-actors

    if love.math.random(100) <= target.dodge then
        CombatLogSystem.logDodge(self, target)
        return true
    end

    local baseDamage
    if self.isPlayer and self.weapon then
        baseDamage = self.weapon.damage + math.floor(self.strength / 2)
    else
        baseDamage = love.math.random(self.damage.min, self.damage.max)
    end

    local damageReduction = math.min(baseDamage, target.armor)
    local finalDamage = baseDamage - damageReduction

    if finalDamage > 0 then
        target.health = target.health - finalDamage
        if target.isPlayer then require('src.Game').lastPlayerAttacker = self end
        CombatLogSystem.logAttack(self, target, finalDamage)
        if target.health <= 0 then self:onKill(target) end
    end
    return true
end

function Actor:onKill(target)
    local Game = require('src.Game')
    local Corpse = require('src.entities.Corpse')

    if self == Game.player then Game.player:giveXP(target.xpValue) end

    if target == Game.player then
        CombatLogSystem.logDeath(target)
        return
    end

    -- Find the dead entity in the main list and replace it with a corpse
    for i, entity in ipairs(Game.entities) do
        if entity == target then
            CombatLogSystem.logDeath(target)
            local corpse = Corpse:new(target.x, target.y, target.name, Game.getDrops(target.dropTable))
            Game.entities[i] = corpse -- Replace with corpse
            break
        end
    end
end

function Actor:resetActionPoints()
    self.actionPoints = self.maxActionPoints
end

function Actor:useItem(item)
    local Consumable = require('src.entities.Consumable')

    -- Generic actors (like enemies) can only use consumables.
    -- Player-specific actions like equipping are handled in the Player class.
    if is_a(item, Consumable) then
        -- The item's use() method returns true on success
        return item:use(self)
    end
    return false
end

return Actor