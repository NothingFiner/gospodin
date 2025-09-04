end

function PlayingState:keypressed(key)
    -- Ignore keys that aren't for gameplay control to reduce console noise
    if key ~= "w" and key ~= "a" and key ~= "s" and key ~= "d" and key ~= "space" and key ~= "escape" then
        return
    end

    print("--- PlayingState:keypressed ---")
    print("Key pressed: " .. key)

    local currentEntity = Game.getCurrentEntity()
    if not currentEntity then
        print("DEBUG: No entity found for the current turn. Turn queue might be empty.")
        return
    end

    print("DEBUG: Current turn belongs to '" .. currentEntity.name .. "'. Is player? " .. tostring(currentEntity.isPlayer))
    print("DEBUG: Player AP: " .. Game.player.actionPoints .. "/" .. Game.player.maxActionPoints)

    -- Only process input if it's the player's turn.
    if not (currentEntity and currentEntity.isPlayer) then
        if key ~= "escape" then
            print("DEBUG: Input ignored, it is not the player's turn.")
            return
        end
    end


    local tookAction = false
    
    if currentEntity.actionPoints > 0 then
        if key == "w" then
            tookAction = Game.player:move(0, -1)
            Game.player.actionPoints = 0
            tookAction = true
        end
    elseif key ~= "escape" then
        print("DEBUG: Player has no AP, cannot take action.")
    end
    
    print("DEBUG: Action resulted in 'tookAction' = " .. tostring(tookAction))
    if tookAction then
        Game.updateCamera()
        -- If the player is out of AP, their turn ends. Process all AI turns.

