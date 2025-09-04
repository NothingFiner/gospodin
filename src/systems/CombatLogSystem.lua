-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/CombatLogSystem.lua

local MessageLog = require('src.ui.MessageLog')
local colors = require('src.colors')

local CombatLogSystem = {}

function CombatLogSystem.logAttack(attacker, target, damage)
    if not attacker or not target then return end

    local attackerName = attacker.isPlayer and "You" or "The " .. attacker.name
    local targetName = target.isPlayer and "you" or "the " .. target.name
    local verb = attacker.isPlayer and "attack" or "attacks"
    local colorKey = attacker.isPlayer and "player_attack" or "enemy_attack"

    MessageLog.add(string.format("%s %s %s for %d damage.", attackerName, verb, targetName, damage), colorKey)
end

function CombatLogSystem.logDodge(attacker, target)
    local targetName = target.isPlayer and "You" or "The " .. target.name
    MessageLog.add(string.format("%s dodged the attack!", targetName:gsub("^%l", string.upper)), "info")
end

function CombatLogSystem.logArmorSave(target, reduction)
    MessageLog.add(string.format("Your armor absorbs %d damage!", reduction), "info")
end

function CombatLogSystem.logDeath(entity)
    if not entity then return end

    local entityName = entity.isPlayer and "You have" or "The " .. entity.name
    -- Capitalize the first letter of the name
    local capitalizedName = entityName:gsub("^%l", string.upper)
    
    MessageLog.add(string.format("%s died!", capitalizedName), "kill")
end

function CombatLogSystem.logXPGain(amount)
    MessageLog.add("You gain " .. amount .. " experience.", "info")
end

function CombatLogSystem.logLevelUp(level)
    MessageLog.add("You reached level " .. level .. "! You feel stronger.", "kill")
end

function CombatLogSystem.logStatusApplied(target, effectType)
    local targetName = target.isPlayer and "You are" or "The " .. target.name .. " is"
    MessageLog.add(string.format("%s now %sed!", targetName, effectType), {1, 0.6, 0.2}) -- Orange for status
end

function CombatLogSystem.logStatusDamage(target, effectType, damage)
    local targetName = target.isPlayer and "You take" or "The " .. target.name .. " takes"
    MessageLog.add(string.format("%s %d damage from %s.", targetName, damage, effectType), colors.dark_red)
end

function CombatLogSystem.logStatusWearsOff(target, effectType)
    local targetName = target.isPlayer and "You are" or "The " .. target.name .. " is"
    MessageLog.add(string.format("%s no longer %sed.", targetName, effectType), "info")
end


return CombatLogSystem