-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/SoundSystem.lua
-- Manages playing sound effects in response to game events.

local EventSystem = require('src.systems.EventSystem')
local Assets = require('src.assets')

local SoundSystem = {}

-- A data-driven map to associate enemy types and events with sounds.
-- This avoids large if/else blocks and is easily extensible.
local soundMap = {
    onAttack = {
        wild_canid = "bark",
        burmestors_daughter = "daughter_attack",
        sewer_dweller = "dweller_attack",
        alien_patriarch = "patriarch_roar",
        alien_drone = "chitter",
        alien_praetorian = "chitter",
        player_attack = "sword_swing",
        guard = "masc_attack",
        watchman = "masc_attack",
        thug = "masc_attack",
    },
    onDeath = {
        -- For random sounds, we provide a table of sound keys.
        guard = {"masc_death", "long_death"},
        watchman = {"masc_death", "long_death"},
        thug = {"masc_death", "long_death"},
        sewer_dweller = "creature_death",
        alien_drone = "creature_death",
        alien_praetorian = "creature_death",
        alien_patriarch = "creature_death",
    }
}

local function playSoundForEvent(eventName, entity)
    if not entity or not entity.type then return end

    local soundKeyOrTable = soundMap[eventName] and soundMap[eventName][entity.type]
    if not soundKeyOrTable then return end

    local soundKey
    if type(soundKeyOrTable) == "table" then
        -- It's a list of sounds, pick one randomly
        soundKey = soundKeyOrTable[love.math.random(#soundKeyOrTable)]
    else
        -- It's a single sound key
        soundKey = soundKeyOrTable
    end

    if Assets.sounds[soundKey] then
        Assets.sounds[soundKey]:play()
    end
end

function SoundSystem.initialize()
    -- Subscribe to game events to play sounds.
    EventSystem.on("onAttack", function(attacker, target)
        playSoundForEvent("onAttack", attacker)
    end)

    EventSystem.on("onDeath", function(deadEntity)
        playSoundForEvent("onDeath", deadEntity)
    end)
end

return SoundSystem