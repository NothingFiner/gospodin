-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/ui/GameUI.lua

local Game = require('src.Game')
local config = require('src.config')
local MessageLog = require('src.ui.MessageLog')

local GameUI = {}

function GameUI.draw(playingState)
    -- Define layout regions
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local statsPanelW = screenW * 0.2
    local commandPanelH = screenH * 0.1
    local mapX = statsPanelW
    local mapW = screenW - statsPanelW
    local mapH = screenH - commandPanelH
    local padding = 10

    -- Draw stats text in the left panel
    if Game.player then
        local textX = padding
        local currentY = padding
        local textWidth = statsPanelW - padding * 2

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Health: " .. Game.player.health .. "/" .. Game.player.maxHealth, textX, currentY, textWidth, "left")
        currentY = currentY + 20
        love.graphics.printf("AP: " .. Game.player.actionPoints .. "/" .. Game.player.maxActionPoints, textX, currentY, textWidth, "left")
        currentY = currentY + 20
        love.graphics.printf("Floor: " .. config.floorData[Game.currentFloor].name, textX, currentY, textWidth, "left")
        currentY = currentY + 40

        love.graphics.printf("Level: " .. Game.player.level, textX, currentY, textWidth, "left")
        currentY = currentY + 20
        love.graphics.printf(string.format("XP: %d/%d", Game.player.xp, Game.player.xpToNextLevel), textX, currentY, textWidth, "left")
        currentY = currentY + 40

        love.graphics.printf("STR: " .. Game.player.strength, textX, currentY, textWidth, "left")
        currentY = currentY + 20
        love.graphics.printf("DEX: " .. Game.player.dexterity, textX, currentY, textWidth, "left")
        currentY = currentY + 20
        love.graphics.printf("INT: " .. Game.player.intelligence, textX, currentY, textWidth, "left")
        currentY = currentY + 40
        
        local currentEntity = Game.getCurrentEntity()
        if currentEntity then
            local turnText = currentEntity.isPlayer and "Your Turn" or (currentEntity.name .. "'s Turn")
            love.graphics.printf("Turn: " .. turnText, textX, currentY, textWidth, "left")
            currentY = currentY + 20
        end
        
        if Game.player.weapon then
            love.graphics.printf("Weapon: " .. Game.player.weapon.name, textX, currentY, textWidth, "left")
        end
    end
    
    -- Draw bottom panel content
    local logWidth = mapW * 0.6 -- 60% of the bottom panel for the log
    
    -- Draw Message Log
    love.graphics.setColor(1, 1, 1)
    local maxLogLines = math.floor((commandPanelH - padding * 2) / 15)
    local messages = MessageLog.getMessages()
    local logY = mapH + padding
    for i = 1, math.min(maxLogLines, #messages) do
        local msg = messages[i]
        love.graphics.setColor(msg.color)
        love.graphics.printf(msg.text, mapX + padding, logY, logWidth - padding * 2)
        logY = logY + 15 -- Move down for the next message
    end
    -- Draw scroll indicator if needed
    if #MessageLog.messages > maxLogLines then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("[Up/Down to scroll]", mapX + logWidth - 200, screenH - 20, 200, "left")
    end

    -- Draw context-sensitive info on the right side of the bottom panel
    local infoX = mapX + logWidth
    local infoWidth = mapW - logWidth - padding

    if playingState and playingState.targetingMode then
        -- Targeting mode info
        local cursor = playingState.cursor
        local infoText = "Examining (" .. cursor.x .. ", " .. cursor.y .. ")"
        if Game.fovMap[cursor.y] and Game.fovMap[cursor.y][cursor.x] then
            local targetEntity = Game.getEntityAt(cursor.x, cursor.y)
            if targetEntity then
                infoText = infoText .. "\nYou see a " .. targetEntity.name .. "."
                infoText = infoText .. string.format("\nHealth: %d/%d", targetEntity.health, targetEntity.maxHealth)
            else
                infoText = infoText .. "\nYou see an empty space."
            end
        else
            infoText = infoText .. "\nYou can't see that tile."
        end
        love.graphics.setColor(1, 1, 0.8)
        love.graphics.printf(infoText, infoX, mapH + padding, infoWidth, "left")
    else
        -- Normal mode controls
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("WASD: Move/Attack\n(G)et, (U)se Item\n(L)ook, (F)ire\nSPACE: Wait\nUp/Down: Scroll Log", infoX, mapH + padding, infoWidth, "center")
    end
end

function GameUI.drawInventory(playingState)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local currentY = 100

    if #Game.player.inventory == 0 then
        love.graphics.printf("Your inventory is empty.", 0, currentY, screenW, "center")
    else
        for i, item in ipairs(Game.player.inventory) do
            local text = string.format("%d. %s", i, item.name)
            if i == playingState.selectedItemIndex then
                love.graphics.setColor(1, 1, 0)
                love.graphics.printf("> " .. text, 0, currentY, screenW, "center")
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.printf(text, 0, currentY, screenW, "center")
            end
            currentY = currentY + 20
        end
    end

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("W/S to navigate, ENTER to use, ESC to close.", 0, screenH - 100, screenW, "center")
end

function GameUI.drawPauseMenu(playingState)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Draw a semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Draw menu title
    love.graphics.setFont(require('src.assets').fonts.astlochTitleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 200, screenW, "center")

    -- Draw menu options
    love.graphics.setFont(require('src.assets').fonts.astlochMenuFont)
    local menuYStart = 300
    for i, option in ipairs(playingState.pauseMenuOptions) do
        local color = (i == playingState.selectedPauseOption) and {1, 1, 0} or {0.7, 0.7, 0.7}
        love.graphics.setColor(color)
        love.graphics.printf(option, 0, menuYStart + (i - 1) * 50, screenW, "center")
    end

    -- Reset font
    love.graphics.setFont(require('src.assets').fonts.hostGroteskRegular)
end

return GameUI