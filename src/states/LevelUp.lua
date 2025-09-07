-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/LevelUp.lua

local config = require('src.config')
local Game = require('src.Game')
local Assets = require('src.assets')
local C = require('src.constants')

local LevelUpState = {}

function LevelUpState:new(changeState)
    local state = {
        changeState = changeState,
        pointsToSpend = 3,
        tempStats = {},
        perkPool = {},
        statOptions = {"strength", "dexterity", "intelligence"},
        selectedStatIndex = 1,
        selectedPerkIndex = 1,
        currentScreen = "stats" -- "stats" or "perks"
    }
    setmetatable(state, self)
    self.__index = self
    return state
end

function LevelUpState:enter()
    self.pointsToSpend = 3
    self.tempStats = {
        strength = Game.player.baseStrength,
        dexterity = Game.player.baseDexterity,
        intelligence = Game.player.baseIntelligence
    }
    self.selectedStatIndex = 1
    self.currentScreen = "stats"
    self:generatePerkChoices()
end

function LevelUpState:generatePerkChoices()
    self.perkPool = {}
    local availablePerks = {}
    local playerPerks = Game.player.perks or {}

    for key, perkData in pairs(config.perks) do
        local alreadyChosen = false
        for _, p in ipairs(playerPerks) do
            if p.key == key then
                alreadyChosen = true
                break
            end
        end

        if not alreadyChosen then
            local meetsAllPrereqs = true
            if perkData.prereq then
                -- This is a simplified check. We can expand it for stat/implant prereqs.
                local hasPrereqPerk = false
                for _, p in ipairs(playerPerks) do
                    if p.key == perkData.prereq then
                        hasPrereqPerk = true
                        break
                    end
                end
                if not hasPrereqPerk then
                    meetsAllPrereqs = false
                end
            end

            if perkData.prereq_implant then
                local hasRequiredImplant = false
                for _, implant in ipairs(Game.player.implants) do
                    if implant then
                        -- The item's key is stored in its itemData.name, but we need to convert it to the snake_case key.
                        local implantKey = string.lower(implant.name:gsub(" ", "_"))
                        if implantKey == perkData.prereq_implant then
                            hasRequiredImplant = true
                            break
                        end
                    end
                end
                if not hasRequiredImplant then
                    meetsAllPrereqs = false
                end
            end

            if meetsAllPrereqs then
                perkData.key = key -- Ensure the key is part of the data
                table.insert(availablePerks, perkData)
            end
        end
    end

    -- Shuffle and pick 3
    for i = #availablePerks, 2, -1 do
        local j = love.math.random(i)
        availablePerks[i], availablePerks[j] = availablePerks[j], availablePerks[i]
    end

    for i = 1, math.min(3, #availablePerks) do
        table.insert(self.perkPool, availablePerks[i])
    end
end

function LevelUpState:applyChanges()
    -- Apply stats
    Game.player.baseStrength = self.tempStats.strength
    Game.player.baseDexterity = self.tempStats.dexterity
    Game.player.baseIntelligence = self.tempStats.intelligence

    -- Apply perk
    local chosenPerk = self.perkPool[self.selectedPerkIndex]
    if chosenPerk then
        Game.player:addPerk(chosenPerk)
    end

    -- Finalize
    require('src.systems.GameLogSystem').logLevelUp(Game.player.level)
    self.changeState(config.GameState.PLAYING)
end

function LevelUpState:update(dt)
end

function LevelUpState:draw()
    -- Draw the playing state in the background
    Game.states.playing:draw()

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    love.graphics.setFont(Assets.fonts.astlochTitleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Level Up!", 0, 100, screenW, "center")

    love.graphics.setFont(Assets.fonts.hostGroteskRegular)
    if self.currentScreen == "stats" then
        love.graphics.printf("You have " .. self.pointsToSpend .. " points to spend.", 0, 200, screenW, "center")
        
        local y = 250
        for i, statName in ipairs(self.statOptions) do
            local isSelected = (i == self.selectedStatIndex)
            if isSelected then love.graphics.setColor(1,1,0) else love.graphics.setColor(1,1,1) end
            
            local statDisplayName = statName:gsub("^%l", string.upper)
            local text = string.format("%s: %d", statDisplayName, self.tempStats[statName])
            if isSelected then text = "< " .. text .. " >" end
            
            love.graphics.printf(text, 0, y, screenW, "center")
            y = y + 40
        end
        love.graphics.printf("Use UP/DOWN to select, LEFT/RIGHT to change.\nPress ENTER when done.", 0, y + 50, screenW, "center")
    else -- Perks screen
        love.graphics.printf("Choose a Perk", 0, 200, screenW, "center")
        local y = 250
        for i, perk in ipairs(self.perkPool) do
            if i == self.selectedPerkIndex then love.graphics.setColor(1,1,0) else love.graphics.setColor(1,1,1) end
            love.graphics.printf(perk.name, 0, y, screenW, "center")
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf(perk.description, 0, y + 20, screenW, "center")
            y = y + 60
        end
        love.graphics.printf("Use UP/DOWN to select a perk.\nPress ENTER to confirm.", 0, y + 20, screenW, "center")
    end
end

function LevelUpState:keypressed(key)
    if self.currentScreen == "stats" then
        if key == "up" then
            self.selectedStatIndex = math.max(1, self.selectedStatIndex - 1)
        elseif key == "down" then
            self.selectedStatIndex = math.min(#self.statOptions, self.selectedStatIndex + 1)
        elseif key == "right" then
            if self.pointsToSpend > 0 then
                local statToChange = self.statOptions[self.selectedStatIndex]
                self.tempStats[statToChange] = self.tempStats[statToChange] + 1
                self.pointsToSpend = self.pointsToSpend - 1
            end
        elseif key == "left" then
            local statToChange = self.statOptions[self.selectedStatIndex]
            if self.tempStats[statToChange] > Game.player["base" .. statToChange:gsub("^%l", string.upper)] then
                self.tempStats[statToChange] = self.tempStats[statToChange] - 1
                self.pointsToSpend = self.pointsToSpend + 1
            end
        end
        if key == "return" and self.pointsToSpend == 0 then
            self.currentScreen = "perks"
        end
    else -- Perks screen
        if key == "up" then self.selectedPerkIndex = math.max(1, self.selectedPerkIndex - 1)
        elseif key == "down" then self.selectedPerkIndex = math.min(#self.perkPool, self.selectedPerkIndex + 1)
        elseif key == "return" then
            self:applyChanges()
        end
    end
end

return LevelUpState