-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/Playing.lua

local config = require('src.config')
local Game = require('src.Game')
local AISystem = require('src.systems.AISystem')
local GameUI = require('src.ui.GameUI')
local Assets = require('src.assets')
local StatusEffectSystem = require('src.systems.StatusEffectSystem')
local MessageLog = require('src.ui.MessageLog')
local GameLogSystem = require('src.systems.GameLogSystem')
local C = require('src.constants')

local PlayingState = {}

function PlayingState:new(changeState)
    local state = {
        changeState = changeState,
        targetingMode = false,
        isFiring = false,
        inventoryMode = false,
        selectedItemIndex = 1,
        cursor = {x = 0, y = 0},
        fadingMusic = false,
        musicFadeDuration = 1.5, -- seconds
        multiTargetData = nil, -- Will hold data for multi-targeting
        isPaused = false,
        selectedPauseOption = 1,
        aiTurnDelay = 0.2, -- Delay in seconds before an AI acts
        aiTurnTimer = 0
    }
    setmetatable(state, self)
    self.__index = self
    -- These need to be on the object itself, not the temporary 'state' table
    self.pauseMenuOptions = {"Resume", "Fast Restart", "Main Menu", "Quit"}
    return state
end

function PlayingState:startTargeting(isFiring)
    self.targetingMode = true
    self.isFiring = isFiring or false
    self.cursor.x = Game.player.x
    self.cursor.y = Game.player.y
end

function PlayingState:startInventory()
    self.inventoryMode = true
    self.selectedItemIndex = 1
end

function PlayingState:enter()
    -- Game is initialized before entering this state
    -- Start fading out the menu music instead of stopping it abruptly
    if Assets.music.theme and Assets.music.theme:isPlaying() then
        self.fadingMusic = true
    end
end

function PlayingState:update(dt)
    -- Handle music fade-out
    if self.fadingMusic then
        local currentVolume = Assets.music.theme:getVolume()
        local fadeSpeed = (0.5 / self.musicFadeDuration) * dt -- Start volume is 0.5
        local newVolume = math.max(0, currentVolume - fadeSpeed)
        Assets.music.theme:setVolume(newVolume)

        if newVolume == 0 then
            love.audio.stop(Assets.music.theme)
            self.fadingMusic = false
        end
    end

    local victory = false
    for i = #Game.turnQueue, 1, -1 do
        local entity = Game.turnQueue[i]
        if entity.health <= 0 then
            if entity.type == "alien_patriarch" then
                victory = true
            end
            table.remove(Game.turnQueue, i)
            if Game.currentTurnIndex > i then
                Game.currentTurnIndex = Game.currentTurnIndex - 1
            elseif Game.currentTurnIndex > #Game.turnQueue then
                Game.currentTurnIndex = 1
            end
        end
    end

    if victory then
        self.changeState(config.GameState.VICTORY)
        return
    end
    
    -- Make sure we have a valid current turn index
    if #Game.turnQueue > 0 and Game.currentTurnIndex > #Game.turnQueue then
        Game.currentTurnIndex = 1
    end
end

function PlayingState:processAITurns()
    local currentEntity = Game.getCurrentEntity()
    while currentEntity and not currentEntity.isPlayer do
        self:processSingleAITurn()
        currentEntity = Game.getCurrentEntity()
    end

    -- After all AI turns are done, it's the player's turn again.
    local player = Game.getCurrentEntity()
    if player and player.isPlayer then
        player:resetActionPoints()
    end
end

function PlayingState:draw()
    love.graphics.clear(0.05, 0.05, 0.05)

    -- Define layout regions
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local statsPanelW = screenW * 0.2
    local commandPanelH = screenH * 0.15 -- Increased by 50% from 0.1
    local mapX, mapY = statsPanelW, 0
    local mapW, mapH = screenW - statsPanelW, screenH - commandPanelH
    -- Store these on Game for the lighting system to access
    Game.mapX = mapX
    Game.mapY = mapY

    -- Draw the map view inside a clipped region
    local font = love.graphics.getFont()
    local function getCenteredOffsets(char)
        local charWidth = font:getWidth(char)
        local charHeight = font:getHeight()
        local offsetX = (Game.tileSize - charWidth) / 2
        local offsetY = (Game.tileSize - charHeight) / 2
        return offsetX, offsetY
    end

	love.graphics.push()
	love.graphics.setScissor(mapX, mapY, mapW, mapH)

	-- 1. Draw the world (map and entities)
	if Game.floors[Game.currentFloor] then
		local map = Game.floors[Game.currentFloor].map
		-- Draw map tiles
		for y = 1, Game.mapHeight do
			for x = 1, Game.mapWidth do
				local screenX = mapX + (x - Game.camera.x) * Game.tileSize
				local screenY = mapY + (y - Game.camera.y) * Game.tileSize
				local visibility = Game.fovMap[y] and Game.fovMap[y][x] or 0
				local isVisible = visibility > 0
				local isExplored = Game.floors[Game.currentFloor].exploredMap[y] and Game.floors[Game.currentFloor].exploredMap[y][x]

				-- Safely get floor colors, providing a default if the floor index is invalid.
				local floorColors = (config.floorData[Game.currentFloor] and config.floorData[Game.currentFloor].colors) or {
					floor = {0.5, 0.5, 0.5}, -- Default gray floor
					wall = {0.3, 0.3, 0.3}   -- Default gray wall
				}

				if isVisible then
					-- Draw visible tiles with full brightness
					local r, g, b = 0, 0, 0
					if map[y][x] == 4 then r, g, b = unpack(floorColors.town_square or floorColors.floor) -- Use town_square color if available, otherwise fallback to floor
					elseif map[y][x] == 0 then r, g, b = unpack(floorColors.wall) -- Wall color
					else r, g, b = unpack(floorColors.floor) end -- Default floor color
					love.graphics.setColor(r * visibility, g * visibility, b * visibility)
					love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
				elseif isExplored then
					-- Draw explored but not visible tiles dimly
					local r, g, b = 0, 0, 0
					if map[y][x] == 4 then r, g, b = unpack(floorColors.town_square or floorColors.floor) -- Use town_square color if available, otherwise fallback to floor
					elseif map[y][x] == 0 then r, g, b = unpack(floorColors.wall) -- Wall color
					else r, g, b = unpack(floorColors.floor) end -- Default floor color
					love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3) -- Dimmed version of the floor's specific color
					love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
				else
					-- If not explored, it's just black
					love.graphics.setColor(0,0,0) -- Undiscovered
					love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
				end

				-- Draw stairs
				if (isVisible or isExplored) and (map[y][x] == 2 or map[y][x] == 3) then
					local char = (map[y][x] == 2) and ">" or "<"
					local ox, oy = getCenteredOffsets(char)
					love.graphics.setColor(visibility, visibility, visibility)
					love.graphics.print(char, screenX + ox, screenY + oy)
				end
			end
		end

		-- Draw entities
		for _, entity in ipairs(Game.entities) do
			local visibility = Game.fovMap[entity.y] and Game.fovMap[entity.y][entity.x] or 0
			if visibility > 0 then
				local screenX = mapX + (entity.x - Game.camera.x) * Game.tileSize
				local screenY = mapY + (entity.y - Game.camera.y) * Game.tileSize
				if entity.sprite then
					love.graphics.setColor(visibility, visibility, visibility)
					love.graphics.draw(entity.sprite, screenX, screenY)
				else
					local ox, oy = getCenteredOffsets(entity.char or ' ')
					love.graphics.setColor(entity.color[1] * visibility, entity.color[2] * visibility, entity.color[3] * visibility)
					love.graphics.print(entity.char, screenX + ox, screenY + oy)
				end
			end
		end
	end

	-- Draw targeting cursor and line
    if self.targetingMode then
        local cursorColor = {1, 1, 0} -- Default yellow for 'look' mode
        if self.isFiring then
            local dist = math.sqrt((self.cursor.x - Game.player.x)^2 + (self.cursor.y - Game.player.y)^2)
            local targetEntity = Game.getEntityAt(self.cursor.x, self.cursor.y)
            local hasLOS = Game.fovMap[self.cursor.y] and Game.fovMap[self.cursor.y][self.cursor.x]

            if dist > Game.player.weapon.range or not targetEntity or targetEntity.isPlayer or not hasLOS then
                cursorColor = {1, 0.2, 0.2} -- Red for invalid target (out of range, no target, no LoS)
            else
                cursorColor = {0.2, 1, 0.2} -- Green for valid target
            end
        end

        -- Draw line from player to cursor
        love.graphics.setColor(cursorColor[1], cursorColor[2], cursorColor[3], 0.5)
        love.graphics.setLineWidth(1)
        local playerScreenX = mapX + (Game.player.x - Game.camera.x) * Game.tileSize + Game.tileSize / 2
        local playerScreenY = mapY + (Game.player.y - Game.camera.y) * Game.tileSize + Game.tileSize / 2
        local cursorScreenX = mapX + (self.cursor.x - Game.camera.x) * Game.tileSize + Game.tileSize / 2
        local cursorScreenY = mapY + (self.cursor.y - Game.camera.y) * Game.tileSize + Game.tileSize / 2
        love.graphics.line(playerScreenX, playerScreenY, cursorScreenX, cursorScreenY)
        -- Draw cursor box
        local screenX = mapX + (self.cursor.x - Game.camera.x) * Game.tileSize
        local screenY = mapY + (self.cursor.y - Game.camera.y) * Game.tileSize
        love.graphics.setColor(cursorColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", screenX, screenY, Game.tileSize, Game.tileSize)
    end

    -- Draw multi-target numbers if active
    if self.multiTargetData and #self.multiTargetData.targets > 0 then
        for i, entity in ipairs(self.multiTargetData.targets) do
            local screenX = mapX + (entity.x - Game.camera.x) * Game.tileSize
            local screenY = mapY + (entity.y - Game.camera.y) * Game.tileSize
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", screenX + Game.tileSize - 8, screenY + 8, 8)
            love.graphics.setColor(0,0,0)
            love.graphics.printf(tostring(i), screenX + Game.tileSize - 11, screenY + 2, 10, "center")
        end
    end

    -- Draw inventory screen if active
    if self.inventoryMode then
        love.graphics.setColor(0,0,0,0.8)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("INVENTORY", 0, 50, screenW, "center")
        GameUI.drawInventory(self)
    end

    love.graphics.setScissor()
    love.graphics.pop()

    -- Draw panel borders
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", mapX, mapY, mapW, mapH)

    -- Draw UI text content
    GameUI.draw(self)

    -- Draw pause menu overlay if the game is paused
    if self.isPaused then
        GameUI.drawPauseMenu(self)
    end
end

function PlayingState:update(dt)
    -- Handle music fade-out
    if self.fadingMusic then
        local currentVolume = Assets.music.theme:getVolume()
        local fadeSpeed = (0.5 / self.musicFadeDuration) * dt -- Start volume is 0.5
        local newVolume = math.max(0, currentVolume - fadeSpeed)
        Assets.music.theme:setVolume(newVolume)

        if newVolume == 0 then
            love.audio.stop(Assets.music.theme)
            self.fadingMusic = false
        end
    end

    -- Process AI turns if it's not the player's turn
    local currentEntity = Game.getCurrentEntity()
    if currentEntity and not currentEntity.isPlayer and not self.isPaused then
        self.aiTurnTimer = self.aiTurnTimer - dt
        if self.aiTurnTimer <= 0 then
            self:processSingleAITurn()
            self.aiTurnTimer = self.aiTurnDelay -- Reset timer for the next AI
        end
    end
end

function PlayingState:processSingleAITurn()
    local currentEntity = Game.getCurrentEntity()
    if not currentEntity or currentEntity.isPlayer then return end

    -- Process status effects at the start of the entity's turn
    StatusEffectSystem.processTurn(currentEntity)
    if currentEntity.statusEffects.stun then
        currentEntity.actionPoints = 0 -- Stunned entities lose their turn
    end

    -- Process this entity's entire turn (all its AP)
    while currentEntity.actionPoints > 0 do
        if currentEntity.health <= 0 then break end -- Stop if entity died mid-turn
        AISystem.performTurn(currentEntity)
        -- Check for game over after every single AI action
        if Game.player.health <= 0 then
            self.changeState(config.GameState.GAME_OVER)
            return -- Exit immediately
        end
    end

    -- This AI's turn is over, move to the next in the queue
    Game.nextTurn()
end

function PlayingState:keypressed(key)
    if key == "escape" then
        if self.inventoryMode then
            self.inventoryMode = false
        elseif self.targetingMode then
            self.targetingMode = false
            self.isFiring = false
            self.multiTargetData = nil -- Cancel multi-targeting
        elseif self.isPaused then
            self.isPaused = false
        else
            -- If no other menu is open, open the pause menu
            self.isPaused = true
            self.selectedPauseOption = 1
        end
        return
    end

    -- If the game is paused, ignore all other input
    if self.isPaused then
        if key == 'w' or key == 'up' then self.selectedPauseOption = math.max(1, self.selectedPauseOption - 1)
        elseif key == 's' or key == 'down' then self.selectedPauseOption = math.min(#self.pauseMenuOptions, self.selectedPauseOption + 1)
        elseif key == 'return' then
            local option = self.pauseMenuOptions[self.selectedPauseOption]
            if option == "Resume" then self.isPaused = false
            elseif option == "Fast Restart" then Game.initialize(Game.lastLoadout); self.isPaused = false; self:enter()
            elseif option == "Main Menu" then self.changeState(config.GameState.MENU)
            elseif option == "Quit" then love.event.quit() end
        end
        return
    end

    if self.targetingMode then
        -- Targeting mode input
        local newCursorX, newCursorY = self.cursor.x, self.cursor.y
        if key == 'w' then newCursorY = newCursorY - 1
        elseif key == 's' then newCursorY = newCursorY + 1
        elseif key == 'a' then newCursorX = newCursorX - 1
        elseif key == 'd' then newCursorX = newCursorX + 1
        end

        if newCursorX ~= self.cursor.x or newCursorY ~= self.cursor.y then
            if self.isFiring then
                -- Constrain cursor to weapon range when firing
                local dist = math.sqrt((newCursorX - Game.player.x)^2 + (newCursorY - Game.player.y)^2)
                if dist <= Game.player.weapon.range then
                    self.cursor.x = newCursorX
                    self.cursor.y = newCursorY
                end
            else
                -- Allow free movement when just looking
                self.cursor.x = newCursorX
                self.cursor.y = newCursorY
            end
        elseif key == 'return' or (self.isFiring and key == 'f') then
            local tookAction = false
            if self.isFiring then
                if self.multiTargetData then
                    -- This is the 2nd, 3rd, etc. target selection
                    self:selectMultiTarget()
                    return -- Don't end turn yet
                end

                local targetX, targetY = self.cursor.x, self.cursor.y
                local targetEntity = Game.getEntityAt(targetX, targetY)
                
                -- Check for a valid target
                if targetEntity and not targetEntity.isPlayer then
                    local dist = math.sqrt((targetX - Game.player.x)^2 + (targetY - Game.player.y)^2)
                    -- Check range and line of sight (using FOV map)
                    if dist <= Game.player.weapon.range then
                        if Game.fovMap[targetY] and Game.fovMap[targetY][targetX] then
                            -- Check for sufficient AP before initiating any attack
                            if Game.player.actionPoints >= Game.player.weapon.apCost then
                                if Game.player.weapon.name == C.WeaponType.NANITE_CLOUD_ARRAY then
                                    -- Start multi-targeting for the orb attack
                                    self.multiTargetData = {
                                        targets = {}, -- Start with an empty list
                                        maxTargets = 3,
                                    }
                                    -- The first target selection happens here
                                    self:selectMultiTarget() 
                                    return -- Don't end turn yet, more targets to select
                                end
                                tookAction = Game.player:attack(targetEntity)
                            else
                                GameLogSystem.logNoAP("fire")
                            end
                        else
                            MessageLog.add("You don't have a clear shot!", "info")
                        end
                    else
                        GameLogSystem.logOutOfRange()
                    end
                else
                    GameLogSystem.logInvalidTarget()
                end
            end

            if tookAction then
                self.targetingMode = false
                self.isFiring = false
                self:checkEndOfPlayerTurn()
            end
        end
    elseif self.inventoryMode then
        if key == 'w' then self.selectedItemIndex = math.max(1, self.selectedItemIndex - 1)
        elseif key == 's' then self.selectedItemIndex = math.min(#Game.player.inventory, self.selectedItemIndex + 1)
        elseif key == 'return' then
            local item = Game.player.inventory[self.selectedItemIndex]
            if item and Game.player:useItem(item) then
                table.remove(Game.player.inventory, self.selectedItemIndex)
                self.inventoryMode = false
                -- Using an item costs a turn
                self:checkEndOfPlayerTurn()
            else
                GameLogSystem.logCannotUseItem()
            end
        end
    else
        -- Normal gameplay input
        local currentEntity = Game.getCurrentEntity()
        if not (currentEntity and currentEntity.isPlayer) then return end

        local tookAction = false

        if key == 'l' then
            self:startTargeting(false)
        elseif key == 'f' and Game.player.weapon and Game.player.weapon.range > 1 then
            self:startTargeting(true)
        elseif key == 'g' then
            local corpseToLoot = nil
            -- Prioritize looting corpses
            for _, entity in ipairs(Game.getEntitiesAt(Game.player.x, Game.player.y)) do
                if entity.inventory then -- A simple check for corpse-like entities
                    corpseToLoot = entity
                    break
                end
            end

            if corpseToLoot then
                if #corpseToLoot.inventory > 0 then
                    for _, item in ipairs(corpseToLoot.inventory) do
                        table.insert(Game.player.inventory, item)
                        GameLogSystem.logItemPickup(item)
                    end
                    corpseToLoot.inventory = {} -- Empty the corpse's inventory
                else
                    GameLogSystem.logNothingToPickup()
                end
                tookAction = true
                return -- End the keypress handling here
            end

            -- If no corpse, look for items on the ground
            for i = #Game.entities, 1, -1 do
                local entity = Game.entities[i]
                -- Use itemData to identify items, not a boolean flag
                if entity.itemData and entity.x == Game.player.x and entity.y == Game.player.y then
                    table.insert(Game.player.inventory, entity)
                    GameLogSystem.logItemPickup(entity)
                    table.remove(Game.entities, i)
                    tookAction = true
                    break -- Only pick up one item at a time
                end
            end
            if not tookAction then GameLogSystem.logNothingToPickup() end
        elseif key == 'u' then
            self:startInventory()
        else
            -- Movement and Wait actions
            if currentEntity.actionPoints > 0 then
                -- Scroll log with pageup/pagedown
                if key == "up" then MessageLog.scroll(-1); return end -- Scrolling does not take a turn
                if key == "down" then MessageLog.scroll(1); return end -- Scrolling does not take a turn

                if key == "w" then tookAction = Game.player:move(0, -1)
                elseif key == "s" then tookAction = Game.player:move(0, 1)
                elseif key == "a" then tookAction = Game.player:move(-1, 0)
                elseif key == "d" then tookAction = Game.player:move(1, 0)
                elseif key == "space" then
                    -- Waiting consumes all remaining AP and ends the turn.
                    GameLogSystem.logMessage("You wait.", "info")
                    Game.player.actionPoints = 0
                    tookAction = true
                end
            end
        end

        if tookAction then
            self:checkEndOfPlayerTurn()
        end
    end
end

function PlayingState:checkEndOfPlayerTurn()
    -- An action was taken, so the player's turn is over.
    Game.updateCamera()

    -- Process status effects for the player at the end of their action
    StatusEffectSystem.processTurn(Game.player)
    if Game.player.health <= 0 then self.changeState(config.GameState.GAME_OVER); return end

    Game.computeFov()

    if Game.player.actionPoints <= 0 then
        -- Check if any enemies are left to take a turn.
        local hasEnemies = #Game.turnQueue > 1
        if hasEnemies then
            Game.nextTurn()
        else
            -- No enemies, so immediately reset the player's AP for their next turn.
            Game.player:resetActionPoints()
        end
    end
end

function PlayingState:selectMultiTarget()
    local targetX, targetY = self.cursor.x, self.cursor.y
    local targetEntity = Game.getEntityAt(targetX, targetY)

    if targetEntity and not targetEntity.isPlayer then
        -- A target was selected, add it to the list.
        table.insert(self.multiTargetData.targets, targetEntity)
        GameLogSystem.logMultiTargetSelect(self.multiTargetData.maxTargets - #self.multiTargetData.targets)
    else
        GameLogSystem.logInvalidTarget()
        return -- Don't proceed if the target is invalid
    end

    if #self.multiTargetData.targets >= self.multiTargetData.maxTargets then
        -- All targets selected, perform the attacks and consume AP
        Game.player.actionPoints = Game.player.actionPoints - Game.player.weapon.apCost
        for _, target in ipairs(self.multiTargetData.targets) do
            -- We call the internal resolve function that doesn't consume more AP
            Game.player:_resolveAttack(target) 
        end
        self.targetingMode = false
        self.isFiring = false
        self.multiTargetData = nil
        self:checkEndOfPlayerTurn()
    end
end

return PlayingState