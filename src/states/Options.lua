-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/Options.lua

local Assets = require('src.assets')

local Options = {}

function Options:new()
    local options = {
        selectedOption = 1,
        options = {
            {name = "Master Volume", type = "slider", min = 0, max = 1, getValue = function() return Assets.masterVolume end, setValue = Assets.setMasterVolume},
            {name = "Music Volume", type = "slider", min = 0, max = 1, getValue = function() return Assets.musicVolume end, setValue = Assets.setMusicVolume},
            {name = "Back"}
        }
    }
    setmetatable(options, self)
    self.__index = self
    return options
end

function Options:keypressed(playingState, key)
    local optionsMenu = self -- This is the Options instance
    if key == 'w' or key == 'up' then
        optionsMenu.selectedOption = math.max(1, optionsMenu.selectedOption - 1)
    elseif key == 's' or key == 'down' then
        optionsMenu.selectedOption = math.min(#optionsMenu.options, optionsMenu.selectedOption + 1)
    elseif key == 'a' or key == 'left' then
        local option = optionsMenu.options[optionsMenu.selectedOption]
        if option.type == "slider" then
            local currentValue = option.getValue()
            option.setValue(math.max(option.min, currentValue - 0.05))
        end
    elseif key == 'd' or key == 'right' then
        local option = optionsMenu.options[optionsMenu.selectedOption]
        if option.type == "slider" then
            local currentValue = option.getValue()
            option.setValue(math.min(option.max, currentValue + 0.05))
        end
    elseif key == 'return' then
        local option = optionsMenu.options[optionsMenu.selectedOption]
        if option.name == "Back" then
            playingState.activeSubState = "gameplay"
        end
    end
end

function Options:draw(playingState) -- playingState is needed for context, but self is the options object itself
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW, panelH = screenW * 0.5, screenH * 0.7
    local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

    -- Draw panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH)

    love.graphics.setFont(Assets.fonts.astlochMenuFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("---Options---", panelX, panelY + 20, panelW, "center")

    love.graphics.setFont(Assets.fonts.hostGroteskRegular) -- Use self for options data
    local optionsMenu = self -- This is the Options instance
    local sliderLength = panelW * 0.5
    local sliderStartX = panelX + panelW * 0.4

    for i, option in ipairs(optionsMenu.options) do
        local color = (i == optionsMenu.selectedOption) and {1, 1, 0} or {0.7, 0.7, 0.7}
        love.graphics.setColor(color)
        local itemY = panelY + 80 + (i - 1) * 50
        love.graphics.printf(option.name, panelX + 20, itemY, panelW * 0.4 - 20, "left") -- Adjust width for slider text

        if option.type == "slider" then
            local value = option.getValue()
            love.graphics.setColor(0.3, 0.3, 0.3); love.graphics.setLineWidth(5)
            love.graphics.line(sliderStartX, itemY + 10, sliderStartX + sliderLength, itemY + 10)
            love.graphics.setColor(color); love.graphics.setLineWidth(1)
            love.graphics.circle("fill", sliderStartX + (value * sliderLength), itemY + 10, 8)
        end
    end
end

return Options