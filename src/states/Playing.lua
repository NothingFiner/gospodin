-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/Playing.lua

local config = require('src.config')
local Game = require('src.Game')
local MapRenderer = require('src.systems.MapRenderer')
local GameUI = require('src.ui.GameUI')
local Assets = require('src.assets')
local Gameplay = require('src.states.Gameplay')
local Pause = require('src.states.Pause')
local Options = require('src/states/Options')

local PlayingState = {}

function PlayingState:new(changeState)
    local state = {
        changeState = changeState,
        activeSubState = "gameplay", -- "gameplay", "pause", "options"
    }
    -- Initialize sub-state objects
    state.gameplay = Gameplay:new()
    state.pause = Pause:new()
    state.options = Options:new()

    state.visibilityCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    setmetatable(state, self)
    -- Music crossfading properties
    state.currentMusic = nil
    state.nextMusic = nil
    self.__index = self
    return state
end

function PlayingState:startMusicCrossfade(newMusicKey)
    local newMusic = newMusicKey and Assets.music[newMusicKey]

    if self.currentMusic == newMusic then return end -- No change needed

    self.nextMusic = newMusic
    if self.nextMusic and not self.nextMusic:isPlaying() then self.nextMusic:play() end
    -- The update loop will handle fading out self.currentMusic and fading in self.nextMusic
end

function PlayingState:draw()
     -- Define layout regions
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local statsPanelW = screenW * 0.3
    local commandPanelH = screenH * 0.05 -- This is used in GameUI.draw, so keep it consistent
    Game.mapX, Game.mapY, Game.mapW, Game.mapH = statsPanelW, 0, screenW - statsPanelW, screenH - commandPanelH

    -- Draw the main gameplay screen first, always
    self.gameplay:draw(self) -- Pass playingState to gameplay draw

    -- Then, draw any overlay states on top
    if self.activeSubState == "pause" then
        self.pause:draw()
    elseif self.activeSubState == "options" then
        self.options:draw(self) -- Pass playingState for context (e.g., activeSubState change)
    end

    -- Draw the main UI over everything
    GameUI.draw(self)
end

function PlayingState:update(dt)
    -- Only update gameplay logic if not paused or in options
    if self.activeSubState == "gameplay" then
        self.gameplay:update(self, dt) -- Pass playingState to gameplay update
    end

    -- Handle music crossfading
    local crossfadeSpeed = 0.25 * dt
    local targetVolume = Assets.musicVolume

    if self.nextMusic then
        if self.currentMusic then
            local currentVolume = self.currentMusic:getVolume()
            local newVolume = math.max(0, currentVolume - crossfadeSpeed)
            self.currentMusic:setVolume(newVolume)
            if newVolume == 0 then self.currentMusic:stop(); self.currentMusic = nil end
        end

        local currentVolume = self.nextMusic:getVolume()
        local newVolume = math.min(targetVolume, currentVolume + crossfadeSpeed)
        self.nextMusic:setVolume(newVolume)
        if newVolume >= targetVolume then
            self.currentMusic = self.nextMusic
            self.nextMusic = nil
        end
    elseif self.currentMusic and self.currentMusic:getVolume() < targetVolume then
        local currentVolume = self.currentMusic:getVolume()
        local newVolume = math.min(targetVolume, currentVolume + crossfadeSpeed)
        self.currentMusic:setVolume(newVolume)
    end
end

function PlayingState:keypressed(key)
    if key == "escape" then
        if self.activeSubState == "options" then
            self.activeSubState = "pause"
        elseif self.activeSubState == "pause" then
            self.activeSubState = "gameplay"
        elseif self.gameplay.inventoryMode then
            self.gameplay.inventoryMode = false
        elseif self.gameplay.targetingMode then
            self.gameplay.targetingMode = false
        else
            self.pause.selectedOption = 1 -- Reset selected option when opening pause menu
            self.activeSubState = "pause" -- Open pause menu
        end
        return
    end

    if self.activeSubState == "gameplay" then
        self.gameplay:keypressed(self, key)
    elseif self.activeSubState == "pause" then
        self.pause:keypressed(self, key)
    elseif self.activeSubState == "options" then
        self.options:keypressed(self, key)
    end
end

return PlayingState