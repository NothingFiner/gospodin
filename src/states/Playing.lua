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
        targetingMode = false, -- Generic targeting mode
        isUsingAbility = false, -- Specific flag for when targeting is for an ability
        inventoryMode = false,
        selectedItemIndex = 1,
        debugConsoleMode = false,
        selectedDebugOption = 1,
        debugSubMenu = nil, -- For sub-menus like floor selection
        cursor = {x = 0, y = 0},
        showKeymap = false,
        fadingMusic = false,
        musicFadeDuration = 1.5, -- seconds
        multiTargetData = nil, -- Will hold data for multi-targeting
        inventoryTab = "inventory", -- "inventory" or "equipment"
        isPaused = false,
        selectedPauseOption = 1,
        aiTurnDelay = 0.2, -- Delay in seconds before an AI acts
        aiTurnTimer = 0
    }
    state.visibilityCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    setmetatable(state, self)
    self.__index = self
    -- These need to be on the object itself, not the temporary 'state' table
    self.pauseMenuOptions = {"Resume", "Fast Restart", "Main Menu", "Quit"}
    return state
end

function PlayingState:startTargeting(isForAbility)
    self.targetingMode = true
    self.isUsingAbility = isForAbility or false
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
    local statsPanelW = screenW * 0.3 -- Match the new width from GameUI
    local commandPanelH = screenH * 0.0125 -- 25% of the previous 0.05 height
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

	-- 0. Prepare the visibility canvas for the shader
	love.graphics.setCanvas(self.visibilityCanvas)
	love.graphics.clear(0,0,0,1) -- Start with black (not visible)
	if Game.floors[Game.currentFloor] then
		for y = 1, Game.mapHeight do
			for x = 1, Game.mapWidth do
				local visibility = (Game.fovEnabled and Game.fovMap[y] and Game.fovMap[y][x]) or 1
				local isExplored = Game.floors[Game.currentFloor].exploredMap[y] and Game.floors[Game.currentFloor].exploredMap[y][x]
				local finalVisibility = 0
				if visibility > 0 then finalVisibility = visibility -- Use full visibility if in FOV
				elseif isExplored then finalVisibility = 0.3 end -- Use dim visibility if explored
				
				love.graphics.setColor(finalVisibility, finalVisibility, finalVisibility)
				love.graphics.rectangle("fill", mapX + (x - Game.camera.x) * Game.tileSize, mapY + (y - Game.camera.y) * Game.tileSize, Game.tileSize, Game.tileSize)
			end
		end
	end
	love.graphics.setCanvas() -- Return to drawing on the main screen

	-- 1. Draw the world (map and entities)
	if Game.floors[Game.currentFloor] then
		-- Existing Tile-Based Rendering Path
		local map = Game.floors[Game.currentFloor].map
			local floorInfo = config.floorData[Game.currentFloor]
			-- Draw map tiles
			for y = 1, Game.mapHeight do
				for x = 1, Game.mapWidth do
					local screenX = mapX + (x - Game.camera.x) * Game.tileSize
					local screenY = mapY + (y - Game.camera.y) * Game.tileSize
					local visibility = (Game.fovEnabled and Game.fovMap[y] and Game.fovMap[y][x]) or 1
					local isVisible = visibility > 0
					local isExplored = Game.floors[Game.currentFloor].exploredMap[y] and Game.floors[Game.currentFloor].exploredMap[y][x]
					
					-- Safely get floor colors, providing a default if the floor index is invalid.
					local floorColors = (config.floorData[Game.currentFloor] and config.floorData[Game.currentFloor].colors) or {
						floor = {0.5, 0.5, 0.5}, -- Default gray floor
						wall = {0.3, 0.3, 0.3}   -- Default gray wall
					}

					local tileSprite = nil
					local tileType = type(map[y][x]) == "table" and map[y][x].type or map[y][x]

					if floorInfo.name == "Village Streets" and tileType == 1 then
						if type(map[y][x]) == "table" then
							local variant = map[y][x].variant
							if variant == 1 then tileSprite = Assets.sprites.village_floor
							elseif variant == 2 then tileSprite = Assets.sprites.village_floor_1
							elseif variant == 3 then tileSprite = Assets.sprites.village_floor_2
							elseif variant == 4 then tileSprite = Assets.sprites.village_floor_3
							end
						end
				elseif floorInfo.name:find("Manor") and tileType == 1 then
					if type(map[y][x]) == "table" then
						local variant = map[y][x].variant
						if variant and Assets.sprites.manor_hardwood_tiles[variant] then
							tileSprite = Assets.sprites.manor_hardwood_tiles[variant]
						end
						end
					end

					if isVisible then
						-- Draw visible tiles with full brightness
						local r, g, b = 0, 0, 0
						if tileType == 4 then r, g, b = unpack(floorColors.town_square or floorColors.floor)
						elseif tileType == 0 then r, g, b = unpack(floorColors.wall)
						else r, g, b = unpack(floorColors.floor) end

						if tileSprite and floorInfo.name:find("Manor") then
							love.graphics.setColor(visibility, visibility, visibility)
							-- For manor floors, we need to draw the atlas with the correct quad
							love.graphics.draw(Assets.sprites.manor_hardwood_atlas, tileSprite, screenX, screenY)
						elseif tileSprite then
							love.graphics.setColor(visibility, visibility, visibility)
							-- For village floors
							love.graphics.draw(tileSprite, screenX, screenY)
						else
							love.graphics.setColor(r * visibility, g * visibility, b * visibility)
							love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
						end

					elseif isExplored then
						local dimColor = 0.3
						if tileSprite and floorInfo.name:find("Manor") then
							love.graphics.setColor(dimColor, dimColor, dimColor)
							-- For manor floors, we need to draw the atlas with the correct quad
							love.graphics.draw(hedgeSprite, screenX, screenY)
						else
							local r, g, b = 0, 0, 0
							if tileType == 4 then r, g, b = unpack(floorColors.town_square or floorColors.floor)
							elseif tileType == 0 then r, g, b = unpack(floorColors.wall)
							else r, g, b = unpack(floorColors.floor) end
							love.graphics.setColor(r * dimColor, g * dimColor, b * dimColor)
							if tileSprite then love.graphics.draw(tileSprite, screenX, screenY)
							else love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize) end
						end
					else
						-- If not explored, it's just black
						love.graphics.setColor(0,0,0) -- Undiscovered
						love.graphics.rectangle("fill", screenX, screenY, Game.tileSize, Game.tileSize)
					end

					-- Draw stairs with sprites
					if (isVisible or isExplored) then
						local stairSprite = nil
						if tileType == 2 then -- Down stairs
							if floorInfo.name:find("Manor") then stairSprite = Assets.sprites.manor_stairs_down
							elseif floorInfo.name == "Village Streets" then stairSprite = Assets.sprites.village_to_sewers end
						elseif tileType == 3 then -- Up stairs
							if floorInfo.name:find("Manor") then stairSprite = Assets.sprites.manor_stairs_up end
						end

						if stairSprite then
							local rotation = (type(map[y][x]) == "table" and map[y][x].rotation) or 0
							love.graphics.setColor(visibility, visibility, visibility)
							love.graphics.draw(stairSprite, screenX + 16, screenY + 16, rotation, 1, 1, 16, 16)
						elseif tileType == 2 or tileType == 3 then -- Fallback for other stairs
							local char = (tileType == 2) and ">" or "<"
							local ox, oy = getCenteredOffsets(char)
							love.graphics.setColor(visibility, visibility, visibility)
							love.graphics.print(char, screenX + ox, screenY + oy)
						end
					end
				end
			end

		-- Draw large props (doodads)
		local largeProps = Game.floors[Game.currentFloor].largeProps or {}
		for _, prop in ipairs(largeProps) do
			-- Check if it's a rug/runner
			local isRug = prop.sprite:find("rug") or prop.sprite:find("runner")
			local propQuad = isRug and Assets.sprites.rugs[prop.sprite]
			local propAtlas = isRug and Assets.sprites.rug_atlas

			if propQuad and propAtlas then
				local screenX, screenY
				if prop.isPixelCoords then
					screenX = mapX + (prop.x - Game.camera.x * Game.tileSize)
					screenY = mapY + (prop.y - Game.camera.y * Game.tileSize)
				else -- Fallback for any old props that might use tile coords
					screenX = mapX + (prop.x - Game.camera.x) * Game.tileSize
					screenY = mapY + (prop.y - Game.camera.y) * Game.tileSize
				end
				local rotation = prop.rotation or 0
				-- To rotate around the center, we need to calculate the origin offset
				local ox, oy = 0, 0
				if rotation ~= 0 then
                        local _, _, quadWidth, quadHeight = propQuad:getViewport()
						ox, oy = quadWidth / 2, quadHeight / 2
				end

				-- Use the fog shader to draw the rug
				love.graphics.setShader(Assets.shaders.fog)
				Assets.shaders.fog:send("visibilityMap", self.visibilityCanvas)
				love.graphics.setColor(1, 1, 1) -- Shader handles the tinting
					love.graphics.draw(propAtlas, propQuad, screenX + ox, screenY + oy, rotation, 1, 1, ox, oy)
				love.graphics.setShader() -- Reset to default shader
			end
		end

		-- Draw entities
		for _, entity in ipairs(Game.entities) do
			local visibility = (Game.fovEnabled and Game.fovMap[entity.y] and Game.fovMap[entity.y][entity.x]) or 1
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
        local cursorColor = {1, 1, 0} -- Default yellow for 'look'
        if self.isUsingAbility then
            local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
            local dist = math.sqrt((self.cursor.x - Game.player.x)^2 + (self.cursor.y - Game.player.y)^2)
            local targetEntity = Game.getEntityAt(self.cursor.x, self.cursor.y)
            local hasLOS = Game.fovMap[self.cursor.y] and Game.fovMap[self.cursor.y][self.cursor.x]
            local map = Game.floors[Game.currentFloor].map
            local tile = map[self.cursor.y] and map[self.cursor.y][self.cursor.x]
            local tileType = type(tile) == "table" and tile.type or tile
            local isWall = tileType == 0

            if not ability or dist > ability.range or not hasLOS or isWall then
                cursorColor = {1, 0.2, 0.2} -- Red for invalid target (out of range, no LoS, or wall)
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
    -- Vertical line
    love.graphics.line(mapX, mapY, mapX, screenH - commandPanelH)
    -- Horizontal line
    love.graphics.line(0, mapH, screenW, mapH)

    -- Draw UI text content
    GameUI.draw(self)

    -- Draw pause menu overlay if the game is paused
    if self.isPaused then
        GameUI.drawPauseMenu(self)
    end

    -- Draw keymap overlay
    if self.showKeymap then
        GameUI.drawKeymap()
    end

    -- Draw debug console overlay
    if self.debugConsoleMode then
        GameUI.drawDebugConsole(self)
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
        elseif self.showKeymap then
            self.showKeymap = false
        elseif self.targetingMode then
            self.targetingMode = false
            self.isUsingAbility = false
            self.multiTargetData = nil -- Cancel multi-targeting
        elseif self.isPaused then
            self.isPaused = false
        elseif self.debugConsoleMode then
            self.debugConsoleMode = false
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
        elseif key == 's' then newCursorY = newCursorY + 1
        elseif key == 'a' then newCursorX = newCursorX - 1
        elseif key == 'd' then newCursorX = newCursorX + 1
        end

        if newCursorX ~= self.cursor.x or newCursorY ~= self.cursor.y then
            if self.isUsingAbility then
                -- Constrain cursor to weapon range when firing
                local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
                local dist = math.sqrt((newCursorX - Game.player.x)^2 + (newCursorY - Game.player.y)^2)
                if dist <= ability.range then
                    self.cursor.x = newCursorX
                    self.cursor.y = newCursorY
                end
            else
                -- Allow free movement when just looking
                self.cursor.x = newCursorX
                self.cursor.y = newCursorY
            end
        elseif key == 'return' or (self.isUsingAbility and key == 'f') then
            local tookAction = false
            if self.isUsingAbility then
                local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
                if self.multiTargetData then
                    -- This is the 2nd, 3rd, etc. target selection
                    self:selectMultiTarget()
                    return -- Don't end turn yet
                end

                if ability.targeting == "single_enemy" or ability.targeting == "multi_enemy" then
                    local targetEntity = Game.getEntityAt(self.cursor.x, self.cursor.y)
                    if targetEntity and not targetEntity.isPlayer then
                        if ability.targeting == "multi_enemy" then
                            self.multiTargetData = { targets = {}, maxTargets = ability.maxTargets }
                            self:selectMultiTarget()
                            return -- Don't end turn yet, still selecting targets
                        end
                        -- A single-target attack ability
                        tookAction = Game.player:useAbility(ability, targetEntity)
                    else
                        GameLogSystem.logInvalidTarget()
                    end
                elseif ability.targeting == "empty_tile" then
                    -- The target for a movement ability is the coordinate, not an entity
                    tookAction = Game.player:useAbility(ability, {x = self.cursor.x, y = self.cursor.y})
                else
                    GameLogSystem.logInvalidTarget()
                end
            end

            if tookAction then
                self.targetingMode = false
                self.isUsingAbility = false
                self:checkEndOfPlayerTurn()
            end
        end
    elseif self.inventoryMode then
        if key == 'tab' then
            self.inventoryTab = (self.inventoryTab == "inventory") and "equipment" or "inventory"
            self.selectedItemIndex = 1 -- Reset selection when tabbing
        elseif key == 'w' then
            self.selectedItemIndex = math.max(1, self.selectedItemIndex - 1)
        elseif key == 's' then
            local maxItems = (self.inventoryTab == "inventory") and #Game.player.inventory or #GameUI.slotOrder
            self.selectedItemIndex = math.min(maxItems, self.selectedItemIndex + 1)
        elseif key == 'return' then -- Use/Equip/Unequip
            local tookAction = false
            if self.inventoryTab == "inventory" then
                local item = Game.player.inventory[self.selectedItemIndex]
                if item and Game.player:useItem(item) then
                    -- useItem handles both consuming and equipping
                    if is_a(item, require('src.entities.Equipment')) then
                        -- If it was equipment, it's now in a slot, so just remove from inventory
                        table.remove(Game.player.inventory, self.selectedItemIndex)
                    else
                        -- If it was a consumable, it's used up
                        table.remove(Game.player.inventory, self.selectedItemIndex)
                    end
                    tookAction = true
                else
                    GameLogSystem.logCannotUseItem()
                end
            elseif self.inventoryTab == "equipment" then
                local slot = GameUI.slotOrder[self.selectedItemIndex]
                if Game.player.equipment[slot] then
                    Game.player:unequip(slot)
                    tookAction = true
                end
            end

            if tookAction then
                self.inventoryMode = false -- Close inventory on action
                self:checkEndOfPlayerTurn() -- Using/equipping/unequipping costs a turn
            else
                GameLogSystem.logCannotUseItem()
            end
        end
    elseif self.debugConsoleMode then
        local options = self.debugSubMenu and self.debugSubMenu.options or {"Add 100 XP", "Warp to Floor", "Toggle FOV"}
        if key == 'w' or key == 'up' then self.selectedDebugOption = math.max(1, self.selectedDebugOption - 1)
        elseif key == 's' or key == 'down' then self.selectedDebugOption = math.min(#options, self.selectedDebugOption + 1)
        elseif key == 'return' then
            if self.debugSubMenu then
                -- Handle sub-menu action (warping)
                local floorIndex = self.debugSubMenu.options[self.selectedDebugOption].index
                Game.goToFloor(floorIndex)
                self.debugConsoleMode = false
                self.debugSubMenu = nil
            else
                -- Handle main menu action
                local command = options[self.selectedDebugOption]
                if command == "Add 100 XP" then
                    if Game.player:giveXP(100) then
                        self.changeState(config.GameState.LEVEL_UP)
                    end
                    self.debugConsoleMode = false
                elseif command == "Warp to Floor" then
                    -- Open the floor selection sub-menu
                    self.debugSubMenu = { options = {} }
                    for i, floorData in ipairs(config.floorData) do
                        table.insert(self.debugSubMenu.options, {name = floorData.name, index = i})
                    end
                    self.selectedDebugOption = 1
                elseif command == "Toggle FOV" then
                    Game.fovEnabled = not Game.fovEnabled
                    Game.computeFov() -- Recompute to update explored areas if needed
                end
            end
        end
    else
        -- Normal gameplay input
        local currentEntity = Game.getCurrentEntity()
        if not (currentEntity and currentEntity.isPlayer) then return end

        local tookAction = false

        if key == 'l' then
            self:startTargeting(false)
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
        elseif key == 'i' then
            self:startInventory()
        elseif key == 'q' then
            Game.player:switchActiveWeapon()
        elseif key == '`' then
            self.debugConsoleMode = not self.debugConsoleMode
        elseif key == 'k' then
            self.showKeymap = true
        elseif key == 'f' then -- Use selected ability
            local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
            if ability then
                if Game.player.abilityCooldowns[ability.key] and Game.player.abilityCooldowns[ability.key] > 0 then
                    GameLogSystem.logOnCooldown(ability.name, Game.player.abilityCooldowns[ability.key])
                elseif ability.targeting then
                    self:startTargeting(true) -- Start targeting for an ability
                end
            end
        elseif key == 'v' then -- Cycle abilities
            Game.player:cycleAbility()
            -- Cycling abilities does not cost a turn
        else
            -- Movement and Wait actions
            if currentEntity.actionPoints > 0 then
                -- Scroll log with pageup/pagedown
                if key == "up" then MessageLog.scroll(-1); return end -- Scrolling does not take a turn
                if key == "down" then MessageLog.scroll(1); return end -- Scrolling does not take a turn

                if key == "w" then tookAction = Game.player:move(0, -1) -- Move Up
                elseif key == "s" then tookAction = Game.player:move(0, 1) -- Move Down
                elseif key == "a" then tookAction = Game.player:move(-1, 0) -- Move Left
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
        Game.nextTurn()

        -- After the player's turn is over and we've advanced the turn,
        -- process all subsequent AI turns until it's the player's turn again.
        self:processAITurns()
    else
        -- If player still has AP, it's still their turn.
        -- No need to do anything here, just wait for the next input.
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
        local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
        -- All targets selected, perform the attacks
        for _, target in ipairs(self.multiTargetData.targets) do
            Game.player:_resolveAttack(target, ability)
        end
        Game.player.actionPoints = Game.player.actionPoints - ability.apCost
        Game.player:setCooldown(ability.key, ability.cooldown)
        self.targetingMode = false
        self.isUsingAbility = false
        self.multiTargetData = nil
        self:checkEndOfPlayerTurn()
    end
end

return PlayingState