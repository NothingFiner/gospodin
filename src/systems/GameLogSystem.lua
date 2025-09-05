-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/GameLogSystem.lua

local MessageLog = require('src.ui.MessageLog')
local colors = require('src.colors')

local GameLogSystem = {}

-- Targeting and Firing Messages
function GameLogSystem.logNoAP(action)
    MessageLog.add("Not enough AP to " .. (action or "act") .. "!", "info")
end

function GameLogSystem.logNoClearShot()
    MessageLog.add("You don't have a clear shot!", "info")
end

function GameLogSystem.logOutOfRange()
    MessageLog.add("Target is out of range!", "info")
end

function GameLogSystem.logInvalidTarget()
    MessageLog.add("You can't fire there.", "info")
end

function GameLogSystem.logMultiTargetSelect(remaining)
    if remaining > 0 then
        MessageLog.add("Select the next target (" .. remaining .. " left).", "info")
    else
        MessageLog.add("All targets selected. Firing...", "info")
    end
end

function GameLogSystem.logMessage(text, colorKey)
    MessageLog.add(text, colorKey or "default")
end

function GameLogSystem.logOnCooldown(abilityName, turnsLeft)
    MessageLog.add(abilityName .. " is on cooldown (" .. turnsLeft .. " turns left).", "info")
end

-- === COMBAT MESSAGES (MERGED) ===

function GameLogSystem.logAttack(attacker, target, damage, isCrit)
    if not attacker or not target then return end

    local attackerName = attacker.isPlayer and "You" or "The " .. attacker.name
    local targetName = target.isPlayer and "you" or "the " .. target.name
    local verb
    local colorKey

    if isCrit then
        verb = attacker.isPlayer and "critically strike" or "critically strikes"
        colorKey = attacker.isPlayer and "kill" or "enemy_attack" -- Use a more impactful color for crits
    else
        verb = attacker.isPlayer and "attack" or "attacks"
        colorKey = attacker.isPlayer and "player_attack" or "enemy_attack"
    end

    MessageLog.add(string.format("%s %s %s for %d damage!", attackerName, verb, targetName, damage), colorKey)
end

function GameLogSystem.logDodge(attacker, target)
    local targetName = target.isPlayer and "You" or "The " .. target.name
    MessageLog.add(string.format("%s dodged the attack!", targetName:gsub("^%l", string.upper)), "info")
end

function GameLogSystem.logArmorSave(target, reduction)
    MessageLog.add(string.format("Your armor absorbs %d damage!", reduction), "info")
end

function GameLogSystem.logDeath(entity)
    if not entity then return end

    local entityName = entity.isPlayer and "You have" or "The " .. entity.name
    -- Capitalize the first letter of the name
    local capitalizedName = entityName:gsub("^%l", string.upper)
    
    MessageLog.add(string.format("%s died!", capitalizedName), "kill")
end

function GameLogSystem.logXPGain(amount)
    MessageLog.add("You gain " .. amount .. " experience.", "info")
end

function GameLogSystem.logLevelUp(level)
    MessageLog.add("You reached level " .. level .. "! You feel stronger.", "kill")
end

-- Item Interaction Messages
function GameLogSystem.logItemPickup(item)
    MessageLog.add("You pick up the " .. item.name .. ".", "player_attack")
end

function GameLogSystem.logNothingToPickup()
    MessageLog.add("There is nothing here to pick up.", "info")
end

function GameLogSystem.logCannotUseItem()
    MessageLog.add("You can't use that right now.", "info")
end

-- Floor Transition Messages
function GameLogSystem.logCantGoThatWay()
    MessageLog.add("You can't go that way.", "info")
end

function GameLogSystem.logNoStairsFound()
    MessageLog.add("Error: No destination stairs found! Placing you in a safe spot.", "info")
end

function GameLogSystem.logEnterFloor(floorName)
    MessageLog.add("You enter the " .. floorName .. ".", "info")
end

function GameLogSystem.logItemUsed(itemName, effectText)
    MessageLog.add("You use the " .. itemName .. ", " .. effectText, "player_attack")
end

-- === STATUS EFFECT MESSAGES (MERGED) ===

function GameLogSystem.logStatusApplied(target, effectType)
    local targetName = target.isPlayer and "You are" or "The " .. target.name .. " is"
    MessageLog.add(string.format("%s now %sed!", targetName, effectType), {1, 0.6, 0.2}) -- Orange for status
end

function GameLogSystem.logStatusDamage(target, effectType, damage)
    local targetName = target.isPlayer and "You take" or "The " .. target.name .. " takes"
    MessageLog.add(string.format("%s %d damage from %s.", targetName, damage, colors.dark_red))
end

function GameLogSystem.logStatusWearsOff(target, effectType)
    local targetName = target.isPlayer and "You are" or "The " .. target.name .. " is"
    MessageLog.add(string.format("%s no longer %sed.", targetName, effectType), "info")
end

return GameLogSystem