-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Actor.lua

local Entity = require('src.entities.Entity')
local GameLogSystem = require('src.systems.GameLogSystem')
local C = require('src.constants')

local Actor = {}
setmetatable(Actor, {__index = Entity}) -- Inheritance
Actor.__index = Actor
Actor.__type = "Actor"

-- This needs to be declared after the class table to avoid circular dependency issues with other files that might require Actor.
local config = require('src.config')

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
        local destTileType = type(destTile) == "table" and destTile.type or destTile
        if destTileType == 2 then return Game.changeFloor(1)
        elseif destTileType == 3 then return Game.changeFloor(-1) end
    end

    -- A tile is walkable if it's not a wall (0). This allows movement on floors, stairs, etc.
    local destTileType = type(destTile) == "table" and destTile.type or destTile
    if destTileType == 0 then return failMove() end
    
    local targetEntity = Game.getEntityAt(newX, newY)

    if targetEntity and targetEntity ~= self and targetEntity.blocksMovement then
        if self.isPlayer ~= targetEntity.isPlayer then
            local success
            if self.isPlayer then
                -- Player bump attacks use the basic attack ability
                local basicAttack = require('src.config').abilities.basic_attack
                -- The key needs to be set manually here since we're not pulling from the player's list
                basicAttack.key = "basic_attack" 
                success = self:useAbility(basicAttack, targetEntity) 
            else
                -- Enemies use their standard attack
                success = self:attack(targetEntity)
            end
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

function Actor:_resolveAttack(target, ability)
    if not target.dodge then return true end -- Can't attack non-actors

    if love.math.random(100) <= target.dodge then
        GameLogSystem.logDodge(self, target)
        return true
    end
    
    local baseDamage, isCrit = 0, false

    -- Critical Hit Check
    local critChance = self.critChance or 5 -- Start with base crit chance
    if self.isPlayer and self.conditionalBonuses and self.conditionalBonuses.critChance then
        for _, bonus in ipairs(self.conditionalBonuses.critChance) do
            -- Check for Sharpshooter's "ranged" condition
            if bonus.condition == "ranged" and ability and ability.effect == "ranged_attack" then
                critChance = critChance + bonus.value
            end
            -- Other conditions could be added here with 'elseif'
        end
    end

    if love.math.random(100) <= critChance then
        isCrit = true
    end

    if self.isPlayer and ability then
        -- Player damage is based on the ability used
        local abilityDamage = config.abilities[ability.key].damage or {min=1, max=4}
        baseDamage = love.math.random(abilityDamage.min, abilityDamage.max)
        baseDamage = baseDamage + math.floor(self.strength / 2)
    else
        -- Standard attack damage (for enemies or player basic attacks)
        baseDamage = love.math.random(self.damage.min, self.damage.max)
    end

    if isCrit then
        local critMultiplier = (self.critDamageBonus or 100) / 100
        local bonusCritDamage = 0
        if type(self.critDamageBonus) == "table" then
             -- This handles additive dice rolls like from the Sonic Dagger
             bonusCritDamage = love.math.random(self.critDamageBonus.min, self.critDamageBonus.max)
        end
        baseDamage = math.floor(baseDamage * (1 + critMultiplier)) + bonusCritDamage
    end

    local damageReduction = math.min(baseDamage, target.armor)
    local finalDamage = baseDamage - damageReduction

    if finalDamage > 0 then
        target.health = target.health - finalDamage
        if target.isPlayer then require('src.Game').lastPlayerAttacker = self end
        GameLogSystem.logAttack(self, target, finalDamage, isCrit)
        if target.health <= 0 then self:onKill(target) end
    end

    -- Apply on-hit effects from perks
    if self.isPlayer then
        for _, perk in ipairs(self.perks) do
            for _, effect in ipairs(perk.effects) do
                if effect.type == "add_effect" and effect.effect == "poison_on_hit" then
                    if love.math.random() <= effect.chance then
                        require('src.systems.StatusEffectSystem').apply(target, {
                            type = C.StatusEffect.POISON,
                            duration = effect.duration,
                            damage = love.math.random(effect.damage.min, effect.damage.max)
                        })
                    end
                end
            end
        end
    end
    return true
end

function Actor:onKill(target)
    local Game = require('src.Game')
    local Corpse = require('src.entities.Corpse')

    if self == Game.player and Game.player:giveXP(target.xpValue) then
        -- If giveXP returns true, a level up occurred. Change the state.
        changeState(config.GameState.LEVEL_UP)
    end

    if target == Game.player then
        GameLogSystem.logDeath(target)
        return
    end

    -- Find the dead entity in the main list and replace it with a corpse
    for i, entity in ipairs(Game.entities) do
        if entity == target then
            GameLogSystem.logDeath(target)
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