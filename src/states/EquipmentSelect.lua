-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/EquipmentSelect.lua

local config = require('src.config')
local colors = require('src.colors')
local Game = require('src.Game')
local Assets = require('src.assets')
local EquipmentSelectState = {}

function EquipmentSelectState:new(changeState)
    local state = {
        selectedOption = 1,
        options = {"orbs", "laser", "war_gecko"},
        changeState = changeState
    }
    setmetatable(state, self)
    self.__index = self
    return state
end

function EquipmentSelectState:enter()
    self.selectedOption = 1
end

function EquipmentSelectState:update(dt)
end

function EquipmentSelectState:draw()
    love.graphics.clear(0, 0, 0.1)
    love.graphics.clear(colors.dark_mauve)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Draw main title
    love.graphics.setFont(Assets.fonts.astlochMenuFont)
    love.graphics.printf("Choose Your Equipment", 0, 50, screenW, "center")
    
    -- --- Tab Drawing Logic ---
    local tabWidth = 200
    local tabHeight = 40
    local totalTabsWidth = #self.options * tabWidth
    local tabsStartX = (screenW - totalTabsWidth) / 2
    local tabsY = 120

    for i, key in ipairs(self.options) do
        local loadout = config.equipmentLoadouts[key]
        local isSelected = i == self.selectedOption
        local tabX = tabsStartX + (i - 1) * tabWidth

        -- Draw tab background/outline
        if isSelected then
            love.graphics.setColor(colors.dark_khaki)
            love.graphics.rectangle("fill", tabX, tabsY, tabWidth, tabHeight)
            love.graphics.setColor(colors.gold)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", tabX, tabsY, tabWidth, tabHeight)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", tabX, tabsY, tabWidth, tabHeight)
        end

        -- Draw tab text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(loadout.name, tabX, tabsY + 10, tabWidth, "center")
    end

    -- --- Content Panel Drawing Logic ---
    local panelX = screenW * 0.15
    local panelY = tabsY + tabHeight
    local panelWidth = screenW * 0.7
    local panelHeight = screenH * 0.6

    love.graphics.setColor(colors.dark_khaki)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    love.graphics.setColor(colors.gold)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)

    -- Draw content for the selected loadout
    local selectedLoadout = config.equipmentLoadouts[self.options[self.selectedOption]]
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Assets.fonts.hostGroteskRegular)
    local textY = panelY + 40
    love.graphics.printf(selectedLoadout.description, panelX + 20, textY, panelWidth - 40, "center")
    textY = textY + 100

    -- Get the actual item data from the loadout key
    local itemKey = selectedLoadout.implant or selectedLoadout.weapon
    local itemData = config.items[itemKey]

    if itemData and itemData.modifiers then
        local modifiers = itemData.modifiers
        love.graphics.printf("--- Item Modifiers ---", panelX, textY, panelWidth, "center")
        textY = textY + 30

        if modifiers.weapon then
            local weapon = modifiers.weapon
            local weaponText = string.format("Grants Weapon: %s (Damage: %d, Range: %d, AP: %d)", weapon.name, weapon.damage, weapon.range, weapon.apCost)
            love.graphics.printf(weaponText, panelX, textY, panelWidth, "center")
            textY = textY + 20
        end

        local statsText = ""
        if modifiers.health then statsText = statsText .. "Health: +" .. modifiers.health .. "  " end
        if modifiers.actionPoints then statsText = statsText .. "AP: +" .. modifiers.actionPoints .. "  " end
        if modifiers.dodge then statsText = statsText .. "Dodge: " .. (modifiers.dodge > 0 and "+" or "") .. modifiers.dodge .. "  " end
        if modifiers.armor then statsText = statsText .. "Armor: " .. (modifiers.armor > 0 and "+" or "") .. modifiers.armor .. "  " end
        love.graphics.printf(statsText, panelX, textY, panelWidth, "center")
    end

    -- --- Instructions ---
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press ENTER to select, LEFT/RIGHT to navigate, ESC to go back", 0, screenH - 60, screenW, "center")
    love.graphics.setFont(Assets.fonts.hostGroteskRegular) -- Reset to default game font
end

function EquipmentSelectState:keypressed(key)
    if key == "left" or key == "a" then
        self.selectedOption = math.max(1, self.selectedOption - 1)
    elseif key == "right" or key == "d" then
        self.selectedOption = math.min(#self.options, self.selectedOption + 1)
    elseif key == "return" then
        local selectedLoadout = config.equipmentLoadouts[self.options[self.selectedOption]]
        Game.initialize(selectedLoadout)
        self.changeState(config.GameState.PLAYING)
    elseif key == "escape" then
        self.changeState(config.GameState.MENU)
    end
end

return EquipmentSelectState