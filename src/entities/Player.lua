-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/Player.lua

local Actor = require('src.entities.Actor')
local config = require('src.config')
local CombatLogSystem = require('src.systems.CombatLogSystem')
local GameLogSystem = require('src.systems.GameLogSystem')
local C = require('src.constants')

local Player = {}
setmetatable(Player, {__index = Actor}) -- Inheritance from Actor
Player.__index = Player
Player.__type = "Player"

function Player:new(x, y, char, color, name, health, actionPoints, loadout)
    local player = Actor:new(x, y, char, color, name, health, actionPoints)
    
    -- Add player-specific properties
    player.isPlayer = true -- Override the default Actor value
    player.level = 1
    player.xp = 0
    player.xpToNextLevel = config.playerStats.xpPerLevel
    player.strength = config.playerStats.strength
    player.dexterity = config.playerStats.dexterity
    player.intelligence = config.playerStats.intelligence
    player.weapon = loadout.weapon
    player.dodge = loadout.dodge
    player.armor = loadout.armor
    player.sprite = require('src.assets').sprites.player

    setmetatable(player, self)
    return player
end

function Player:giveXP(amount)
    self.xp = self.xp + amount
    CombatLogSystem.logXPGain(amount)

    if self.xp >= self.xpToNextLevel then self:levelUp() end
end

function Player:levelUp()
    self.level = self.level + 1
    self.xp = self.xp - self.xpToNextLevel
    self.xpToNextLevel = self.level * config.playerStats.xpPerLevel

    self.maxHealth = self.maxHealth + 10
    self.health = self.maxHealth
    self.strength = self.strength + 1
    self.dexterity = self.dexterity + 1
    self.intelligence = self.intelligence + 1

    CombatLogSystem.logLevelUp(self.level)
end

return Player