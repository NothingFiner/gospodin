-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/GameOver.lua

local Game = require('src.Game')
local config = require('src.config')
local Assets = require('src.assets')

local GameOverState = {}

function GameOverState:new(changeState)
    local state = {
        changeState = changeState
    }
    setmetatable(state, self)
    self.__index = self
    return state
end

function GameOverState:enter()
    if Assets.music.theme and Assets.music.theme:isPlaying() then
        love.audio.stop(Assets.music.theme)
    end
end

function GameOverState:update(dt)
end

function GameOverState:draw()
    love.graphics.clear(0.3, 0.1, 0.1)
    love.graphics.setColor(1, 1, 1)

    love.graphics.setFont(Assets.fonts.astlochTitleFont)
    love.graphics.printf("GAME OVER", 0, 200, love.graphics.getWidth(), "center")
    love.graphics.setFont(Assets.fonts.astlochMenuFont)
    if Game.lastPlayerAttacker then
        love.graphics.printf("You were killed by a " .. Game.lastPlayerAttacker.name .. ".", 0, 250, love.graphics.getWidth(), "center")
    end
    love.graphics.printf("Press ESC to return to menu", 0, 300, love.graphics.getWidth(), "center")
    love.graphics.setFont(Assets.fonts.hostGroteskRegular) -- Reset to default game font
end

function GameOverState:keypressed(key)
    if key == "escape" then
        self.changeState(config.GameState.MENU)
    end
end

return GameOverState