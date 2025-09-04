-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Player.lua

local Actor = require('src.entities.Actor')
local config = require('src.config')
local CombatLogSystem = require('src.systems.CombatLogSystem')
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
    player.abilityCooldowns = {}
    player.selectedAbilityIndex = 1

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
    self.damage = {min = 1, max = 2} -- Base unarmed damage
    self.abilities = {} -- Reset abilities
    self.selectedAbilityIndex = 1 -- Reset selected ability

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
                    self.damage.min = self.damage.min + value.min
                    self.damage.max = self.damage.max + value.max
                end
            end

            -- Add abilities from item
            if item.itemData.abilities then
                for _, abilityKey in ipairs(item.itemData.abilities) do
                    local ability = config.abilities[abilityKey]
                    if ability then
                        -- Add the key to the ability table for reference
                        ability.key = abilityKey
                        table.insert(self.abilities, ability)
                    end
                end
            end
        end
    end

    -- Ensure health doesn't exceed new maxHealth
    self.health = math.min(self.health, self.maxHealth)
end

function Player:equip(item, slot)
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
    GameLogSystem.logMessage("You equip the " .. item.name .. ".", "info")

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
    CombatLogSystem.logXPGain(amount)

    if self.xp >= self.xpToNextLevel then self:levelUp() end
end

function Player:levelUp()
    self.level = self.level + 1
    self.xp = self.xp - self.xpToNextLevel
    self.xpToNextLevel = self.level * config.playerStats.xpPerLevel

    self.maxHealth = self.maxHealth + 10
    self.health = self.maxHealth
    self.strength = self.strength + 1
    self.dexterity = self.dexterity + 1
    self.intelligence = self.intelligence + 1

    CombatLogSystem.logLevelUp(self.level)
end

return Player