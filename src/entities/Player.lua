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

    -- Implant slots are separate and permanent
    player.implants = {nil, nil}

    -- Equipment slots
    player.equipment = {
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
    player.abilityCharges = {}
    player.selectedAbilityIndex = 1
    player.perks = {}

    player.sprite = require('src.assets').sprites.player

    setmetatable(player, self)
    player:initializeStats() -- New initial stat setup
    return player
end

function Player:initializeStats()
    -- This function sets the derived stats equal to the base stats at creation.
    self.maxHealth = config.playerStats.baseHealth
    self.maxActionPoints = config.playerStats.baseActionPoints
    self.strength = self.baseStrength
    self.dexterity = self.baseDexterity
    self.intelligence = self.baseIntelligence
    self.dodge = self.baseDodge
    self.armor = self.baseArmor
    self.critChance = self.baseCritChance
    self.critDamageBonus = self.baseCritDamageBonus
    self.damage = {min = 1, max = 2}
    self.conditionalBonuses = {}
    self.immunities = {}

    -- Add the permanent basic attack ability
    local basicAttack = deepcopy(config.abilities.basic_attack)
    self.allAbilities["basic_attack"] = basicAttack
end

function Player:applyLoadout(loadout)
    -- This is called once at the start of the game.
    local ItemFactory = require('src.entities.Item')

    -- 1. Apply implant (permanent)
    if loadout.implant then
        local implant = ItemFactory.create(0, 0, loadout.implant)
        self.implants[1] = implant
        self:_applyItemModifiers(implant)
    end

    -- 2. Apply starting weapon (temporary, but part of initial loadout)
    if loadout.weapon then
        local weapon = ItemFactory.create(0, 0, loadout.weapon)
        self:equip(weapon, C.EquipmentSlot.WEAPON1, true)
    end

    -- 3. Apply other starting gear
    self:equip(ItemFactory.create(0, 0, "elegant_blouse"), nil, true)
    self:equip(ItemFactory.create(0, 0, "refined_pantaloons"), nil, true)
    self:equip(ItemFactory.create(0, 0, "sensible_boots"), nil, true)
    self:equip(ItemFactory.create(0, 0, "nobles_knife"), nil, true)

    -- 4. Finalize stats
    self.health = self.maxHealth
    self.actionPoints = self.maxActionPoints
end

function Player:equip(item, slot, silent)
    local targetSlot = slot or item.slot

    -- Special handling for weapons: if weapon1 is taken, try weapon2
    if targetSlot == C.EquipmentSlot.WEAPON1 and self.equipment[C.EquipmentSlot.WEAPON1] then
        targetSlot = C.EquipmentSlot.WEAPON2
    end

    -- Unequip any item currently in the target slot
    if self.equipment[targetSlot] then
        self:unequip(targetSlot)
    end

    -- Place the new item in the slot and apply its modifiers
    self.equipment[targetSlot] = item
    self:_applyItemModifiers(item)

    if not silent then
        GameLogSystem.logMessage("You equip the " .. item.name .. ".", "info")
    end
end

function Player:unequip(slot)
    local item = self.equipment[slot]
    if item then
        self.equipment[slot] = nil
        table.insert(self.inventory, item) -- Return item to inventory
        self:_removeItemModifiers(item)
        GameLogSystem.logMessage("You unequip the " .. item.name .. ".", "info")
    end
end

-- Dispatch table for applying/removing stat modifiers from items
local statModifiers = {
    health = function(player, value)
        player.maxHealth = player.maxHealth + value
        if value > 0 then player.health = player.health + value end 
        if player.health > player.maxHealth then player.health = player.maxHealth end 

    end,
    actionPoints = function(player, value) player.maxActionPoints = player.maxActionPoints + value end,
    strength = function(player, value) player.strength = player.strength + value end,
    dexterity = function(player, value) player.dexterity = player.dexterity + value end,
    intelligence = function(player, value) player.intelligence = player.intelligence + value end,
    dodge = function(player, value) player.dodge = player.dodge + value end,
    armor = function(player, value) player.armor = player.armor + value end,
    damage = function(player, value)
        player.damage.min = (player.damage.min or 0) + (value.min or 0)
        player.damage.max = (player.damage.max or 0) + (value.max or 0)
    end,
    critChance = function(player, value) player.critChance = player.critChance + value end,
    critDamage = function(player, value) player.critDamageBonus = player.critDamageBonus + value end
}

function Player:_applyItemModifiers(item)
    -- Add stat modifiers
    for stat, value in pairs(item.modifiers or {}) do
        local modifierFunc = statModifiers[stat]
        if modifierFunc then modifierFunc(self, value) end
    end
    -- Add abilities
    if item.itemData.abilities then
        for _, key in ipairs(item.itemData.abilities) do
            local ability = deepcopy(config.abilities[key])
            ability.key = key
            self.allAbilities[key] = ability
            if not ability.hidden then table.insert(self.abilities, self.allAbilities[key]) end
        end
    end
end

function Player:_removeItemModifiers(item)
    -- Remove stat modifiers
    for stat, value in pairs(item.modifiers or {}) do
        local modifier = statModifiers[stat]
        if type(modifier) == "table" and modifier.remove then
            modifier.remove(self, value)
        elseif type(modifier) == "function" then
            modifier(self, -value)
        end
    end
    -- Remove abilities
    if item.itemData.abilities then
        for _, keyToRemove in ipairs(item.itemData.abilities) do
            self.allAbilities[keyToRemove] = nil
            for i = #self.abilities, 1, -1 do if self.abilities[i].key == keyToRemove then table.remove(self.abilities, i) end end
        end
    end
end

-- Dispatch table for applying perk effects
local perkEffects = {
    stat = function(player, effect)
        if effect.stat == "health" then player.maxHealth = player.maxHealth + effect.value; player.health = player.health + effect.value
        elseif effect.stat == "strength" then player.baseStrength = player.baseStrength + effect.value; player.strength = player.strength + effect.value
        elseif effect.stat == "dexterity" then player.baseDexterity = player.baseDexterity + effect.value; player.dexterity = player.dexterity + effect.value
        elseif effect.stat == "intelligence" then player.baseIntelligence = player.baseIntelligence + effect.value; player.intelligence = player.intelligence + effect.value
        elseif effect.stat == "dodge" then player.baseDodge = player.baseDodge + effect.value; player.dodge = player.dodge + effect.value
        end
    end,
    modify_ability = function(player, effect)
        local abilityToModify = player.allAbilities[effect.ability]
        if abilityToModify then
            abilityToModify[effect.property] = (abilityToModify[effect.property] or 0) + effect.value
        end
    end,
    add_ability = function(player, effect)
        local ability = deepcopy(config.abilities[effect.ability])
        ability.key = effect.ability
        player.allAbilities[effect.ability] = ability
        if not ability.hidden then table.insert(player.abilities, ability) end
    end
}

function Player:addPerk(perk)
    table.insert(self.perks, perk)
    for _, effect in ipairs(perk.effects) do
        local effectFunc = perkEffects[effect.type]
        if effectFunc then effectFunc(self, effect) end
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

    -- Check for charges if the ability uses them
    if ability.charges then
        if not self.abilityCharges[ability.key] or self.abilityCharges[ability.key] <= 0 then
            GameLogSystem.logMessage(ability.name .. " has no charges left.", "info")
            return false
        end
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
    elseif ability.effect == "heal" then
        self.health = math.min(self.maxHealth, self.health + ability.amount)
        GameLogSystem.logMessage("You heal for " .. ability.amount .. " health.", "player_attack")
        success = true
    end

    -- 4. Finalize if successful
    if success then
        self.actionPoints = self.actionPoints - ability.apCost
        if ability.cooldown > 0 then
            self:setCooldown(ability.key, ability.cooldown)
        end
        if ability.charges then
            self.abilityCharges[ability.key] = self.abilityCharges[ability.key] - 1
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

    if is_a(item, Consumable) then return item:use(self)
    elseif is_a(item, Equipment) then self:equip(item); return true end

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

    -- Restore charges on abilities that have them
    for key, ability in pairs(self.allAbilities) do
        if ability.maxCharges then
            self.abilityCharges[ability.key] = ability.maxCharges
        end
    end
end

return Player