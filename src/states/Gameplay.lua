-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/states/Gameplay.lua

local config = require('src.config')
local Game = require('src.Game')
local AISystem = require('src.systems.AISystem')
local MapRenderer = require('src.systems.MapRenderer')
local GameUI = require('src.ui.GameUI')
local StatusEffectSystem = require('src.systems.StatusEffectSystem')
local MessageLog = require('src.ui.MessageLog')
local GameLogSystem = require('src.systems.GameLogSystem')
local Assets = require('src.assets')
local C = require('src.constants')

local Gameplay = {}

function Gameplay:new()
    local gameplay = {
        targetingMode = false, -- Generic targeting mode
        isUsingAbility = false, -- Specific flag for when targeting is for an ability
        inventoryMode = false,
        selectedItemIndex = 1,
        debugConsoleMode = false,
        selectedDebugOption = 1,
        debugSubMenu = nil, -- For sub-menus like floor selection
        cursor = {x = 0, y = 0},
        showKeymap = false,
        multiTargetData = nil, -- Will hold data for multi-targeting
        inventoryTab = "inventory", -- "inventory" or "equipment"
        aiTurnDelay = 0.2, -- Delay in seconds before an AI acts,
        aiTurnTimer = 0
    }

    return gameplay
end

function Gameplay:startTargeting(gameplayState, isForAbility)
    gameplayState.targetingMode = true
    gameplayState.isUsingAbility = isForAbility or false
    gameplayState.cursor.x = Game.player.x
    gameplayState.cursor.y = Game.player.y
end

function Gameplay:startInventory(gameplayState)
    gameplayState.inventoryMode = true
    gameplayState.selectedItemIndex = 1
end

function Gameplay:processAITurns(playingState)
    local currentEntity = Game.getCurrentEntity()
    while currentEntity and not currentEntity.isPlayer do
        self:processSingleAITurn(playingState)
        currentEntity = Game.getCurrentEntity()
    end

    -- After all AI turns are done, it's the player's turn again.
    local player = Game.getCurrentEntity()
    if player and player.isPlayer then
        player:resetActionPoints()
    end
end

function Gameplay:draw(playingState, mapX, mapY, mapW, mapH)
    love.graphics.push()
    love.graphics.setScissor(mapX, mapY, mapW, mapH)

    -- Call the new MapRenderer to draw the world
    MapRenderer.draw(playingState, mapX, mapY)

    -- Draw targeting cursor and line
    if playingState.gameplay.targetingMode then
        GameUI.drawTargeting(playingState.gameplay, mapX, mapY)
    end

    -- Draw multi-target numbers if active
    if playingState.gameplay.multiTargetData and #playingState.gameplay.multiTargetData.targets > 0 then
        GameUI.drawMultiTarget(playingState.gameplay, mapX, mapY)
    end

    -- Draw inventory screen if active
    if playingState.gameplay.inventoryMode then
        GameUI.drawInventory(playingState)
    end

    love.graphics.setScissor()
    love.graphics.pop()
end

function GameUI.drawTargeting(playingState, mapX, mapY)
    local cursorColor = {1, 1, 0} -- Default yellow for 'look'
        if playingState.isUsingAbility then
            local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
            local dist = math.sqrt((playingState.cursor.x - Game.player.x)^2 + (playingState.cursor.y - Game.player.y)^2)
            local targetEntity = Game.getEntityAt(playingState.cursor.x, playingState.cursor.y)
            local hasLOS = Game.fovMap[playingState.cursor.y] and Game.fovMap[playingState.cursor.y][playingState.cursor.x]
            local map = Game.floors[Game.currentFloor].map
            local tile = map[playingState.cursor.y] and map[playingState.cursor.y][playingState.cursor.x]
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
        local cursorScreenX = mapX + (gameplayState.cursor.x - Game.camera.x) * Game.tileSize + Game.tileSize / 2
        local cursorScreenY = mapY + (gameplayState.cursor.y - Game.camera.y) * Game.tileSize + Game.tileSize / 2
        love.graphics.line(playerScreenX, playerScreenY, cursorScreenX, cursorScreenY)
        -- Draw cursor box
        local screenX = mapX + (gameplayState.cursor.x - Game.camera.x) * Game.tileSize
        local screenY = mapY + (gameplayState.cursor.y - Game.camera.y) * Game.tileSize
        love.graphics.setColor(cursorColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", screenX, screenY, Game.tileSize, Game.tileSize)
end

function GameUI.drawMultiTarget(gameplayState, mapX, mapY)
    for i, entity in ipairs(gameplayState.multiTargetData.targets) do
        local screenX = mapX + (entity.x - Game.camera.x) * Game.tileSize
        local screenY = mapY + (entity.y - Game.camera.y) * Game.tileSize
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", screenX + Game.tileSize - 8, screenY + 8, 8)
        love.graphics.setColor(0,0,0)
        love.graphics.printf(tostring(i), screenX + Game.tileSize - 11, screenY + 2, 10, "center")
    end
end

function Gameplay:update(playingState, dt)
    -- Process AI turns if it's not the player's turn
    local currentEntity = Game.getCurrentEntity()
    if currentEntity and not currentEntity.isPlayer and not playingState.isPaused then
        self.aiTurnTimer = self.aiTurnTimer - dt
        if self.aiTurnTimer <= 0 then
            self:processSingleAITurn(playingState) -- Pass playingState for changeState
            self.aiTurnTimer = self.aiTurnDelay -- Reset timer for the next AI
        end
    end


end

function Gameplay:processSingleAITurn(playingState)
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
            playingState.changeState(config.GameState.GAME_OVER)
            return -- Exit immediately
        end
    end

    -- This AI's turn is over, move to the next in the queue
    Game.nextTurn()
end

return Gameplay