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

function Gameplay:startTargeting(playingState, isForAbility)
    playingState.targetingMode = true
    playingState.isUsingAbility = isForAbility or false
    playingState.cursor.x = Game.player.x
    playingState.cursor.y = Game.player.y
end

function Gameplay:startInventory(playingState)
    playingState.inventoryMode = true
    playingState.selectedItemIndex = 1
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
    if playingState.targetingMode then
        GameUI.drawTargeting(playingState, mapX, mapY)
    end

    -- Draw multi-target numbers if active
    if playingState.multiTargetData and #playingState.multiTargetData.targets > 0 then
        GameUI.drawMultiTarget(playingState, mapX, mapY)
    end

    -- Draw inventory screen if active
    if playingState.inventoryMode then
        GameUI.drawInventory(playingState)
    end

    love.graphics.setScissor()
    love.graphics.pop()
end

function Gameplay:keypressed(playingState, key)
    local tookAction = false
    local gameplay = playingState.gameplay

    if gameplay.targetingMode then
        -- Targeting mode input
        local newCursorX, newCursorY = gameplay.cursor.x, gameplay.cursor.y
        if key == 'w' then newCursorY = newCursorY - 1
        elseif key == 's' then newCursorY = newCursorY + 1
        elseif key == 'a' then newCursorX = newCursorX - 1
        elseif key == 'd' then newCursorX = newCursorX + 1
        end

        if newCursorX ~= gameplay.cursor.x or newCursorY ~= gameplay.cursor.y then
            if gameplay.isUsingAbility then
                local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
                local dist = math.sqrt((newCursorX - Game.player.x)^2 + (newCursorY - Game.player.y)^2)
                if dist <= ability.range then
                    gameplay.cursor.x = newCursorX
                    gameplay.cursor.y = newCursorY
                end
            else
                gameplay.cursor.x = newCursorX
                gameplay.cursor.y = newCursorY
            end
        elseif key == 'return' or (gameplay.isUsingAbility and key == 'f') then
            if gameplay.isUsingAbility then
                local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
                if gameplay.multiTargetData then
                    self:selectMultiTarget(playingState)
                    return -- Don't end turn yet
                end

                if ability.targeting == "single_enemy" or ability.targeting == "multi_enemy" then
                    local targetEntity = Game.getEntityAt(gameplay.cursor.x, gameplay.cursor.y)
                    if targetEntity and not targetEntity.isPlayer then
                        if ability.targeting == "multi_enemy" then
                            gameplay.multiTargetData = { targets = {}, maxTargets = ability.maxTargets }
                            self:selectMultiTarget(playingState)
                            return -- Don't end turn yet, still selecting targets
                        end
                        tookAction = Game.player:useAbility(ability, targetEntity)
                    else
                        GameLogSystem.logInvalidTarget()
                    end
                elseif ability.targeting == "empty_tile" then
                    tookAction = Game.player:useAbility(ability, {x = gameplay.cursor.x, y = gameplay.cursor.y})
                else
                    GameLogSystem.logInvalidTarget()
                end
            end

            if tookAction then
                gameplay.targetingMode = false
                gameplay.isUsingAbility = false
            end
        end
    elseif gameplay.inventoryMode then
        if key == 'tab' then
            gameplay.inventoryTab = (gameplay.inventoryTab == "inventory") and "equipment" or "inventory"
            gameplay.selectedItemIndex = 1 -- Reset selection when tabbing
        elseif key == 'w' then
            gameplay.selectedItemIndex = math.max(1, gameplay.selectedItemIndex - 1)
        elseif key == 's' then
            local maxItems = (gameplay.inventoryTab == "inventory") and #Game.player.inventory or #GameUI.slotOrder
            gameplay.selectedItemIndex = math.min(maxItems, gameplay.selectedItemIndex + 1)
        elseif key == 'return' then -- Use/Equip/Unequip
            if gameplay.inventoryTab == "inventory" then
                local item = Game.player.inventory[gameplay.selectedItemIndex]
                if item and Game.player:useItem(item) then
                    table.remove(Game.player.inventory, gameplay.selectedItemIndex)
                    tookAction = true
                else
                    GameLogSystem.logCannotUseItem()
                end
            elseif gameplay.inventoryTab == "equipment" then
                local slot = GameUI.slotOrder[gameplay.selectedItemIndex]
                if Game.player.equipment[slot] then
                    Game.player:unequip(slot)
                    tookAction = true
                end
            end

            if tookAction then
                gameplay.inventoryMode = false -- Close inventory on action
            end
        end
    elseif gameplay.debugConsoleMode then
        -- Debug console logic remains here
    else
        -- Normal gameplay input
        local currentEntity = Game.getCurrentEntity()
        if not (currentEntity and currentEntity.isPlayer) then return end

        if key == 'l' then
            self:startTargeting(gameplay, false)
        elseif key == 'g' then
            -- Item pickup logic
        elseif key == 'i' then
            self:startInventory(gameplay)
        elseif key == 'q' then
            Game.player:switchActiveWeapon()
        elseif key == '`' then
            gameplay.debugConsoleMode = not gameplay.debugConsoleMode
        elseif key == 'k' then
            gameplay.showKeymap = true
        elseif key == 'f' then -- Use selected ability
            local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
            if ability and ability.targeting then
                self:startTargeting(gameplay, true) -- Start targeting for an ability
            end
        elseif key == 'v' then -- Cycle abilities
            Game.player:cycleAbility()
        else
            -- Movement and Wait actions
            if currentEntity.actionPoints > 0 then
                if key == "up" then MessageLog.scroll(-1); return end
                if key == "down" then MessageLog.scroll(1); return end

                if key == "w" then tookAction = Game.player:move(0, -1)
                elseif key == "s" then tookAction = Game.player:move(0, 1)
                elseif key == "a" then tookAction = Game.player:move(-1, 0)
                elseif key == "d" then tookAction = Game.player:move(1, 0)
                elseif key == "space" then
                    GameLogSystem.logMessage("You wait.", "info")
                    Game.player.actionPoints = 0
                    tookAction = true
                end
            end
        end
    end

    if tookAction then
        self:checkEndOfPlayerTurn(playingState)
    end
end

function Gameplay:checkEndOfPlayerTurn(playingState)
    Game.updateCamera()
    StatusEffectSystem.processTurn(Game.player)
    if Game.player.health <= 0 then playingState.changeState(config.GameState.GAME_OVER); return end

    Game.computeFov()

    if Game.player.actionPoints <= 0 then
        Game.nextTurn()
        self:processAITurns(playingState)
    end
end

function Gameplay:selectMultiTarget(playingState)
    local gameplay = playingState.gameplay
    local targetEntity = Game.getEntityAt(gameplay.cursor.x, gameplay.cursor.y)

    if targetEntity and not targetEntity.isPlayer then
        table.insert(gameplay.multiTargetData.targets, targetEntity)
        GameLogSystem.logMultiTargetSelect(gameplay.multiTargetData.maxTargets - #gameplay.multiTargetData.targets)
    else
        GameLogSystem.logInvalidTarget()
        return
    end

    if #gameplay.multiTargetData.targets >= gameplay.multiTargetData.maxTargets then
        local ability = Game.player.abilities[Game.player.selectedAbilityIndex]
        Game.player:useAbility(ability, gameplay.multiTargetData.targets)
        gameplay.targetingMode = false
        gameplay.isUsingAbility = false
        gameplay.multiTargetData = nil
        self:checkEndOfPlayerTurn(playingState)
    end
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
        local cursorScreenX = mapX + (playingState.cursor.x - Game.camera.x) * Game.tileSize + Game.tileSize / 2
        local cursorScreenY = mapY + (playingState.cursor.y - Game.camera.y) * Game.tileSize + Game.tileSize / 2
        love.graphics.line(playerScreenX, playerScreenY, cursorScreenX, cursorScreenY)
        -- Draw cursor box
        local screenX = mapX + (playingState.cursor.x - Game.camera.x) * Game.tileSize
        local screenY = mapY + (playingState.cursor.y - Game.camera.y) * Game.tileSize
        love.graphics.setColor(cursorColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", screenX, screenY, Game.tileSize, Game.tileSize)
end

function GameUI.drawMultiTarget(playingState, mapX, mapY)
    for i, entity in ipairs(playingState.multiTargetData.targets) do
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
    if currentEntity and not currentEntity.isPlayer and playingState.activeSubState == "gameplay" then
        playingState.aiTurnTimer = playingState.aiTurnTimer - dt
        if playingState.aiTurnTimer <= 0 then
            self:processSingleAITurn(playingState)
            playingState.aiTurnTimer = playingState.aiTurnDelay -- Reset timer for the next AI
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