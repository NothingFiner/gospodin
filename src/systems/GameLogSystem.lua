-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/GameLogSystem.lua

local MessageLog = require('src.ui.MessageLog')

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

return GameLogSystem