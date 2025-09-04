-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/Menu.lua

local config = require('src.config')
local Assets = require('src.assets')
-- local Game = require('src.Game') -- Not directly used, can be removed if not needed elsewhere

local MenuState = {}

function MenuState:new(changeState)
    local state = {
        selectedOption = 1,
        options = {"New Game", "Quit"},
        changeState = changeState
    }
    setmetatable(state, self)
    self.__index = self
    return state
end

function MenuState:enter()
    self.selectedOption = 1
    if Assets.music.theme then
        if not Assets.music.theme:isPlaying() then
            Assets.music.theme:setLooping(true)
            love.audio.play(Assets.music.theme)
        end
    end
end

function MenuState:update(dt)
end

function MenuState:draw()
    love.graphics.clear(0, 0, 0.1)
    love.graphics.setColor(1, 1, 1)

    local screenW = love.graphics.getWidth()

    -- Draw the game title
    love.graphics.setFont(Assets.fonts.astlochTitleFont)
    love.graphics.printf("Gospodin", 0, 150, screenW, "center")

    -- Set font for menu options
    love.graphics.setFont(Assets.fonts.astlochMenuFont)

    local menuYStart = 250

    -- Menu options
    for i, option in ipairs(self.options) do
        local color = i == self.selectedOption and {1, 1, 0} or {0.7, 0.7, 0.7}
        love.graphics.setColor(color)
        love.graphics.printf(option, 0, menuYStart + (i - 1) * 40, screenW, "center") -- Increased spacing for larger font
    end

    love.graphics.setFont(Assets.fonts.hostGroteskRegular) -- Reset to default game font
end

function MenuState:keypressed(key)
    if key == "up" then
        self.selectedOption = math.max(1, self.selectedOption - 1)
    elseif key == "down" then
        self.selectedOption = math.min(#self.options, self.selectedOption + 1)
    elseif key == "return" then
        if self.selectedOption == 1 then
            self.changeState(config.GameState.EQUIPMENT_SELECT)
        elseif self.selectedOption == 2 then
            love.event.quit()
        end
    end
end

return MenuState