-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/ui/GameUI.lua

local Game = require('src.Game')
local config = require('src.config')
local MessageLog = require('src.ui.MessageLog')

local GameUI = {}
-- Make slotOrder accessible to PlayingState
local C = require('src.constants')
GameUI.slotOrder = {C.EquipmentSlot.IMPLANT, C.EquipmentSlot.HEAD, C.EquipmentSlot.CHEST, C.EquipmentSlot.HANDS, C.EquipmentSlot.LEGS, C.EquipmentSlot.FEET, C.EquipmentSlot.WEAPON1, C.EquipmentSlot.WEAPON2}


function GameUI.draw(playingState)
    -- Define layout regions
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local statsPanelW = screenW * 0.3 -- Increased width by 20% (from 0.25)
    local commandPanelH = screenH * 0.05 -- Reverted to original height
    local mapX = statsPanelW
    local mapW = screenW - statsPanelW
    local mapH = screenH - commandPanelH
    local padding = 10

    -- Draw left panel content
    if Game.player then
        local textX = padding
        local currentY = padding
        local textWidth = statsPanelW - padding * 2

        -- Draw Stats
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
        
        -- Add a visual indicator for level up
        if Game.player.xp >= Game.player.xpToNextLevel then
            -- Make the text flash by changing its alpha based on time
            local alpha = (math.sin(love.timer.getTime() * 5) + 1) / 2
            love.graphics.setColor(1, 1, 0, alpha)
            love.graphics.printf("Level Up!", textX + 70, currentY - 40, textWidth, "left")
        end

        love.graphics.printf("STR: " .. Game.player.strength, textX, currentY, textWidth, "left")
        currentY = currentY + 20
        love.graphics.printf("DEX: " .. Game.player.dexterity, textX, currentY, textWidth, "left")
        currentY = currentY + 20
        love.graphics.printf("INT: " .. Game.player.intelligence, textX, currentY, textWidth, "left")
        currentY = currentY + 40

        -- Display active weapon
        local activeWeapon = Game.player.equipment[Game.player.activeWeaponSlot]
        local weaponName = activeWeapon and activeWeapon.name or "Unarmed"
        love.graphics.printf("Weapon: " .. weaponName, textX, currentY, textWidth, "left")
        currentY = currentY + 40

        -- Draw Message Log in left panel
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("--- Log ---", textX, currentY, textWidth, "left")
        currentY = currentY + 20
        
        local font = love.graphics.getFont()
        local lineHeight = font:getHeight()
        local messages = MessageLog.getMessages()
        for i = 1, #messages do
            if currentY > screenH - commandPanelH - padding - lineHeight then break end -- Stop if we run out of space
            local msg = messages[i]
            love.graphics.setColor(msg.color)
            -- Use a wrapped text object to correctly calculate height
            local wrappedText = love.graphics.newText(font, msg.text, textWidth)
            love.graphics.draw(wrappedText, textX, currentY)
            currentY = currentY + wrappedText:getHeight() + 2 -- Move Y down by the height of the wrapped text
        end
    end

    -- Draw bottom panel content (Ability Bar)
    local abilityBarX = mapX + padding
    local abilityBarY = mapH + padding / 2
    local abilityBarW = mapW - padding * 2

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("(I)nventory | (K)eymap", abilityBarX, abilityBarY, abilityBarW, "left")

    if playingState.targetingMode then
        -- Targeting mode info
        local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
        local prompt = "Select target. (F) or (ENTER) to use, (ESC) to cancel."
        if ability and ability.targeting == "multi_enemy" then
            prompt = "Select targets. (F) or (ENTER) to confirm, (ESC) to cancel."
        end
        love.graphics.printf(prompt, abilityBarX, abilityBarY, abilityBarW, "center")
    else
        -- Default ability bar
        local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
        if ability then
            local abilityText = ability.name
            local cooldown = Game.player.abilityCooldowns[ability.key]
            if cooldown and cooldown > 0 then
                abilityText = string.format("%s [CD: %d]", ability.name, cooldown)
            end
            love.graphics.printf(abilityText, abilityBarX, abilityBarY, abilityBarW, "center")
            love.graphics.printf("(F) Use Ability | (V) Next Ability", abilityBarX, abilityBarY, abilityBarW, "right")
        else
            love.graphics.printf("No abilities available.", abilityBarX, abilityaBarY, abilityBarW, "center")
        end
    end
end

function GameUI.drawInventory(playingState)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW, panelH = screenW * 0.6, screenH * 0.7
    local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

    -- Draw main panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH)

    -- Draw tabs
    local tabW = panelW / 2
    -- Inventory Tab
    love.graphics.setColor(playingState.inventoryTab == "inventory" and {0.3, 0.3, 0.4} or {0.1, 0.1, 0.15})
    love.graphics.rectangle("fill", panelX, panelY, tabW, 40)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Inventory", panelX, panelY + 10, tabW, "center")
    -- Equipment Tab
    love.graphics.setColor(playingState.inventoryTab == "equipment" and {0.3, 0.3, 0.4} or {0.1, 0.1, 0.15})
    love.graphics.rectangle("fill", panelX + tabW, panelY, tabW, 40)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Equipment", panelX + tabW, panelY + 10, tabW, "center")

    -- Draw content
    local listX, listY = panelX + 20, panelY + 60
    local listW = panelW - 40
    local selectedItem = nil

    if playingState.inventoryTab == "inventory" then
        if #Game.player.inventory == 0 then
            love.graphics.printf("Your inventory is empty.", listX, listY, listW, "left")
        else
            for i, item in ipairs(Game.player.inventory) do
                local text = string.format("%s", item.name)
                if i == playingState.selectedItemIndex then
                    love.graphics.setColor(1, 1, 0)
                    love.graphics.printf("> " .. text, listX, listY, listW, "left")
                    selectedItem = item
                else
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    love.graphics.printf("  " .. text, listX, listY, listW, "left")
                end
                listY = listY + 20
            end
        end
    else
        -- Equipment Tab
        for i, slot in ipairs(GameUI.slotOrder) do
            local item = Game.player.equipment[slot]
            local text = string.format("%s: %s", slot, item and item.name or "empty")
            if i == playingState.selectedItemIndex then
                love.graphics.setColor(1, 1, 0)
                love.graphics.printf("> " .. text, listX, listY, listW, "left")
                selectedItem = item
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.printf("  " .. text, listX, listY, listW, "left")
            end
            listY = listY + 20
        end
    end

    -- Draw item stats/comparison panel
    local statsX, statsY = panelX + panelW * 0.5, panelY + 60
    local statsW = panelW * 0.5 - 20
    if selectedItem then
        love.graphics.setColor(1,1,1)
        love.graphics.printf("--- " .. selectedItem.name .. " ---", statsX, statsY, statsW, "left")
        statsY = statsY + 30
        for stat, value in pairs(selectedItem.modifiers) do
            local text = ""
            if type(value) == "number" then
                text = string.format("%s: %s%d", stat, value > 0 and "+" or "", value)
            elseif type(value) == "table" and value.name then -- Weapon
                text = string.format("Grants: %s", value.name)
            elseif type(value) == "table" and value.min then -- Damage
                text = string.format("Damage: +%dd%d", value.min, value.max)
            end
            love.graphics.printf(text, statsX, statsY, statsW, "left")
            statsY = statsY + 15
        end

        -- Comparison logic
        local equippedItem = Game.player.equipment[selectedItem.slot]
        if playingState.inventoryTab == "inventory" and equippedItem then
            statsY = statsY + 30
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf("--- Equipped: " .. equippedItem.name .. " ---", statsX, statsY, statsW, "left")
            statsY = statsY + 30
            for stat, value in pairs(equippedItem.modifiers) do
                -- (Simplified display for comparison)
                love.graphics.printf(string.format("%s: ...", stat), statsX, statsY, statsW, "left")
                statsY = statsY + 15
            end
        end
    end

    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("W/S: Nav, TAB: Switch, ENTER: Use/Equip/Unequip, ESC: Close", panelX, panelY + panelH + 10, panelW, "center")
end

function GameUI.drawKeymap()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW, panelH = screenW * 0.4, screenH * 0.5
    local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

    -- Draw panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH)

    -- Title and text
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Keymap", panelX, panelY + 20, panelW, "center")
    local textX = panelX + 30
    local textY = panelY + 60
    local keymapText = [[
WASD: Move / Bump Attack
I: Open Inventory
G: Get Item
F: Use Selected Ability
V: Cycle to Next Ability
Q: Switch Active Weapon
L: Look / Examine
SPACE: Wait (ends turn)
UP/DOWN: Scroll Message Log
ESC: Close Menu / Open Pause Menu
    ]]
    love.graphics.printf(keymapText, textX, textY, panelW - 60, "left")
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