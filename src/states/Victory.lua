-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/Victory.lua

local config = require('src.config')
local Assets = require('src.assets')

local VictoryState = {}

function VictoryState:new(changeState)
    local state = {
        changeState = changeState
    }
    setmetatable(state, self)
    self.__index = self
    return state
end

function VictoryState:enter()
    if Assets.music.theme and Assets.music.theme:isPlaying() then
        love.audio.stop(Assets.music.theme)
    end
end

function VictoryState:update(dt)
end

function VictoryState:draw()
    love.graphics.clear(0.1, 0.3, 0.1)
    love.graphics.setColor(1, 1, 1)

    love.graphics.setFont(Assets.fonts.astlochTitleFont)
    love.graphics.printf("VICTORY!", 0, 200, love.graphics.getWidth(), "center")
    love.graphics.setFont(Assets.fonts.astlochMenuFont)
    love.graphics.printf("You have defeated the Alien Patriarch!", 0, 230, love.graphics.getWidth(), "center")
    love.graphics.printf("Press ESC to return to menu", 0, 280, love.graphics.getWidth(), "center")
    love.graphics.setFont(Assets.fonts.hostGroteskRegular) -- Reset to default game font
end

function VictoryState:keypressed(key)
    if key == "escape" then
        self.changeState(config.GameState.MENU)
    end
end

return VictoryState