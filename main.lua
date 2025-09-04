-- main.lua
-- Gospodin - A Love2D Roguelike using rotLove

local config = require('src.config')

-- State definitions
local states = {
    menu = require('src.states.Menu'),
    equipment_select = require('src.states.EquipmentSelect'),
    playing = require('src.states.Playing'),
    victory = require('src.states.Victory'),
    game_over = require('src.states.GameOver')
}

local currentState
local stateInstances = {}

-- Global type-checking function, the Lua equivalent of 'instanceof'
function is_a(object, class)
    if type(object) ~= "table" or type(class) ~= "table" then return false end
    local metatable = getmetatable(object)
    while metatable do
        if metatable == class then return true end
        metatable = getmetatable(metatable)
    end
    return false
end

-- This global function will be passed to states so they can change the game state.
function changeState(stateName)
    assert(states[stateName], "Attempted to switch to an unknown state: " .. tostring(stateName))
    if currentState and currentState.exit then
        currentState:exit()
    end
    currentState = stateInstances[stateName]
    if currentState.enter then
        currentState:enter()
    end
end

function love.load()
    love.window.setTitle("Gospodin")
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load game assets
    require('src.assets').load()

    -- Instantiate all states, passing the changeState function
    for name, stateClass in pairs(states) do
        stateInstances[name] = stateClass:new(changeState)
    end
    
    -- Set up default font for the game
    love.graphics.setFont(require('src.assets').fonts.hostGroteskRegular)

    -- Start with menu state
    changeState(config.GameState.MENU)
end

function love.update(dt)
    if currentState and currentState.update then
        currentState:update(dt)
    end
end

function love.draw()
    if currentState and currentState.draw then
        currentState:draw()
    end
end

function love.keypressed(key, scancode)
    if currentState and currentState.keypressed then
        currentState:keypressed(key, scancode)
    end
end