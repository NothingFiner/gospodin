-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Player.lua

local Actor = require('src.entities.Actor')
local config = require('src.config')
local GameLogSystem = require('src.systems.GameLogSystem')
local C = require('src.constants')

local Player = {}
setmetatable(Player, {__index = Actor}) -- Inheritance from Actor
Player.__index = Player
Player.__type = "Player"

function Player:new(x, y, char, color, name)
    local player = Actor:new(x, y, char, color, name, config.playerStats.baseHealth, config.playerStats.baseActionPoints)
    
    -- Add player-specific properties
    player.isPlayer = true -- Override the default Actor value
    player.level = 1
    player.xp = 0
    player.xpToNextLevel = config.playerStats.xpPerLevel
    
    -- Base stats that don't get modified by equipment
    player.baseStrength = config.playerStats.strength
    player.baseDexterity = config.playerStats.dexterity
    player.baseIntelligence = config.playerStats.intelligence
    player.baseDodge = config.playerStats.baseDodge
    player.baseArmor = config.playerStats.baseArmor
    player.baseCritChance = 5 -- Base 5% crit chance
    player.baseCritDamageBonus = 100 -- Base 100% bonus damage (double)

    -- Equipment slots
    player.equipment = {
        [C.EquipmentSlot.IMPLANT] = nil,
        [C.EquipmentSlot.HEAD] = nil,
        [C.EquipmentSlot.CHEST] = nil,
        [C.EquipmentSlot.HANDS] = nil,
        [C.EquipmentSlot.LEGS] = nil,
        [C.EquipmentSlot.FEET] = nil,
        [C.EquipmentSlot.WEAPON1] = nil,
        [C.EquipmentSlot.WEAPON2] = nil,
    }
    player.activeWeaponSlot = C.EquipmentSlot.WEAPON1
    player.abilities = {}
    player.allAbilities = {} -- New table to hold all abilities, including hidden ones
    player.abilityCooldowns = {}
    player.selectedAbilityIndex = 1
    player.perks = {}

    player.sprite = require('src.assets').sprites.player

    setmetatable(player, self)
    player:recalculateStats() -- Initial stat calculation
    return player
end

function Player:recalculateStats()
    -- Start with base stats
    self.maxHealth = config.playerStats.baseHealth
    self.maxActionPoints = config.playerStats.baseActionPoints
    self.strength = self.baseStrength
    self.dexterity = self.baseDexterity
    self.intelligence = self.baseIntelligence
    self.dodge = self.baseDodge
    self.armor = self.baseArmor
    self.weapon = nil -- Reset weapon, abilities will handle attacks
    self.critChance = self.baseCritChance
    self.critDamageBonus = self.baseCritDamageBonus
    self.damage = {min = 1, max = 2} -- Base unarmed damage
    self.abilities = {} -- Reset abilities
    self.allAbilities = {} -- Reset all abilities
    self.selectedAbilityIndex = 1 -- Reset selected ability

    -- Apply perk effects before equipment
    for _, perk in ipairs(self.perks) do
        for _, effect in ipairs(perk.effects) do
            if effect.type == "stat" then
                if effect.stat == "health" then self.maxHealth = self.maxHealth + effect.value
                elseif effect.stat == "strength" then self.strength = self.strength + effect.value
                elseif effect.stat == "dexterity" then self.dexterity = self.dexterity + effect.value
                elseif effect.stat == "intelligence" then self.intelligence = self.intelligence + effect.value
                elseif effect.stat == "dodge" then self.dodge = self.dodge + effect.value
                elseif effect.stat == "critChance" then self.critChance = self.critChance + effect.value
                elseif effect.stat == "damage" then
                    self.damage.min = self.damage.min + effect.value.min
                    self.damage.max = self.damage.max + effect.value.max
                end
            elseif effect.type == "modify_ability" then
                -- Find the ability in the config and modify it before it gets added to the player
                local abilityToModify = config.abilities[effect.ability]
                if abilityToModify then
                    abilityToModify[effect.property] = (abilityToModify[effect.property] or 0) + effect.value
                end
            end
        end
    end

    -- Apply modifiers from all equipped items
    for slot, item in pairs(self.equipment) do
        if item then
            for stat, value in pairs(item.modifiers) do
                if stat == "health" then self.maxHealth = self.maxHealth + value
                elseif stat == "actionPoints" then self.maxActionPoints = self.maxActionPoints + value
                elseif stat == "strength" then self.strength = self.strength + value
                elseif stat == "dexterity" then self.dexterity = self.dexterity + value
                elseif stat == "intelligence" then self.intelligence = self.intelligence + value
                elseif stat == "dodge" then self.dodge = self.dodge + value
                elseif stat == "armor" then self.armor = self.armor + value
                elseif stat == "damage" then
                    self.damage.min = (self.damage.min or 0) + (value.min or 0)
                    self.damage.max = (self.damage.max or 0) + (value.max or 0)
                elseif stat == "critChance" then self.critChance = self.critChance + value
                elseif stat == "critDamage" then self.critDamageBonus = self.critDamageBonus + value -- For now, we assume the bonus is a table {min, max}
                end
            end

            -- Add abilities from item
            if item.itemData.abilities then
                for _, abilityKey in ipairs(item.itemData.abilities) do
                    local ability = deepcopy(config.abilities[abilityKey])
                    if ability then
                        -- Add the key to the ability table for reference
                        ability.key = abilityKey
                        table.insert(self.allAbilities, ability) -- Add to the master list
                        if not ability.hidden then
                            table.insert(self.abilities, ability) -- Add to the selectable list
                        end
                    end
                end
            end
        end
    end

    -- Add abilities from perks
    for _, perk in ipairs(self.perks) do
        for _, effect in ipairs(perk.effects) do
            if effect.type == "add_ability" then
                local ability = deepcopy(config.abilities[effect.ability])
                if ability then
                    ability.key = effect.ability
                    table.insert(self.allAbilities, ability)
                    if not ability.hidden then table.insert(self.abilities, ability) end
                end
            end
        end
    end

    -- Add the default basic attack ability
    local basicAttack = config.abilities.basic_attack
    basicAttack.key = "basic_attack"
    table.insert(self.allAbilities, 1, basicAttack) -- Add to master list, but not selectable list

    -- Ensure health doesn't exceed new maxHealth
    self.health = math.min(self.health, self.maxHealth)

    -- Top off health and AP after calculation
    self.health = self.maxHealth
    self.actionPoints = self.maxActionPoints
end

function Player:equip(item, slot, silent)
    -- If a slot is provided, use it. Otherwise, use the item's default slot.
    local targetSlot = slot or item.slot

    -- Special handling for weapons: if weapon1 is taken, try weapon2
    if targetSlot == C.EquipmentSlot.WEAPON1 and self.equipment[C.EquipmentSlot.WEAPON1] then
        targetSlot = C.EquipmentSlot.WEAPON2
    end

    -- Unequip any item currently in the target slot
    if self.equipment[targetSlot] then
        self:unequip(targetSlot)
    end

    -- Place the new item in the slot
    self.equipment[targetSlot] = item
    if not silent then
        GameLogSystem.logMessage("You equip the " .. item.name .. ".", "info")
    end

    self:recalculateStats()
end

function Player:unequip(slot)
    local item = self.equipment[slot]
    if item then
        self.equipment[slot] = nil
        table.insert(self.inventory, item) -- Return item to inventory
        GameLogSystem.logMessage("You unequip the " .. item.name .. ".", "info")
        self:recalculateStats()
    end
end

function Player:switchActiveWeapon()
    if self.activeWeaponSlot == C.EquipmentSlot.WEAPON1 then
        self.activeWeaponSlot = C.EquipmentSlot.WEAPON2
    else
        self.activeWeaponSlot = C.EquipmentSlot.WEAPON1
    end
    GameLogSystem.logMessage("Switched to weapon slot: " .. self.activeWeaponSlot, "info")
end

function Player:cycleAbility()
    if #self.abilities == 0 then return end
    self.selectedAbilityIndex = self.selectedAbilityIndex + 1
    if self.selectedAbilityIndex > #self.abilities then
        self.selectedAbilityIndex = 1
    end
    local ability = self.abilities[self.selectedAbilityIndex]
    GameLogSystem.logMessage("Selected ability: " .. ability.name, "info")
end

function Player:tickCooldowns()
    for key, turnsLeft in pairs(self.abilityCooldowns) do
        if turnsLeft > 0 then
            self.abilityCooldowns[key] = turnsLeft - 1
        end
    end
end

function Player:setCooldown(abilityKey, turns)
    self.abilityCooldowns[abilityKey] = turns
end

function Player:useAbility(ability, target)
    if not ability then return false end

    -- 1. Check AP Cost
    if self.actionPoints < ability.apCost then
        GameLogSystem.logNoAP(ability.name)
        return false
    end

    -- 2. Check Cooldown
    if self.abilityCooldowns[ability.key] and self.abilityCooldowns[ability.key] > 0 then
        GameLogSystem.logOnCooldown(ability.name, self.abilityCooldowns[ability.key])
        return false
    end

    -- 3. Execute Effect
    local success = false
    if ability.effect == "ranged_attack" or ability.effect == "melee_attack" then
        success = self:attack(target, ability)
    elseif ability.effect == "move_to_target" then
        self.x = target.x
        self.y = target.y
        GameLogSystem.logMessage("You leap through space.", "info")
        success = true
    end

    -- 4. Finalize if successful
    if success then
        self.actionPoints = self.actionPoints - ability.apCost
        if ability.cooldown > 0 then
            self:setCooldown(ability.key, ability.cooldown)
        end
    end

    return success
end

-- Override Actor's attack method to be ability-driven
function Player:attack(target, ability)
    -- The player's attack is now just a wrapper around _resolveAttack
    -- AP costs and cooldowns are handled by useAbility
    return self:_resolveAttack(target, ability)
end

function Player:useItem(item)
    local Consumable = require('src.entities.Consumable')
    local Equipment = require('src.entities.Equipment')

    if is_a(item, Consumable) then
        -- The item's use() method returns true on success, and we consume the item.
        return item:use(self)
    elseif is_a(item, Equipment) then
        -- Equipping the item. This action is successful, and the item will be "consumed" from the inventory.
        self:equip(item)
        return true
    end

    return false -- Item is neither consumable nor equippable
end

function Player:giveXP(amount)
    self.xp = self.xp + amount
    GameLogSystem.logXPGain(amount)

    if self.xp >= self.xpToNextLevel then
        self:levelUp()
        return true
    end
    return false
end

function Player:levelUp()
    self.level = self.level + 1
    self.xp = self.xp - self.xpToNextLevel
    self.xpToNextLevel = self.level * config.playerStats.xpPerLevel
end

return Player