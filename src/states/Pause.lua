-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/Pause.lua

local config = require('src.config')
local Game = require('src.Game')
local Assets = require('src.assets')
local GameUI = require('src.ui.GameUI')

local Pause = {}

function Pause:new()
    local pause = {
        selectedOption = 1,
        options = {"Resume", "Options", "Fast Restart", "Main Menu", "Quit"}
    }
    setmetatable(pause, self)
    self.__index = self
    return pause
end

function Pause:draw()
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
    for i, option in ipairs(self.options) do
        local color = (i == self.selectedOption) and {1, 1, 0} or {0.7, 0.7, 0.7}
        love.graphics.setColor(color)
        love.graphics.printf(option, 0, menuYStart + (i - 1) * 50, screenW, "center")
    end

    -- Reset font
    love.graphics.setFont(require('src.assets').fonts.hostGroteskRegular)
end

function Pause:keypressed(playingState, key)
    if key == 'w' or key == 'up' then
        self.selectedOption = math.max(1, self.selectedOption - 1)
    elseif key == 's' or key == 'down' then
        self.selectedOption = math.min(#self.options, self.selectedOption + 1)
    elseif key == 'return' then
        local option = self.options[self.selectedOption]
        if option == "Options" then
            playingState.activeSubState = "options"
        elseif option == "Resume" then
            playingState.activeSubState = "gameplay"
        elseif option == "Fast Restart" then
            Game.initialize(Game.lastLoadout)
            playingState.activeSubState = "gameplay"
        elseif option == "Main Menu" then
            playingState:changeState(config.GameState.MENU)
        elseif option == "Quit" then
            love.event.quit()
        end
    end
end

return Pause