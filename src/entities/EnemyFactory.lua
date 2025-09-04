-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/entities/EnemyFactory.lua

local Actor = require('src.entities.Actor')

local enemyData = {
    infected_servant = {
        name = "Infected Servant",
        char = "i", color = {0.6, 0.4, 0.2}, health = 10, ap = 2,
        damage = {min = 1, max = 2}, xpValue = 5,
        description = "The signs of infection in this servant are subtle, but clear. It's a shame you didn't notice earlier.",
        dropTable = {}
    },
    guard = {
        name = "Guard",
        char = "G", color = {0.8, 0.2, 0.2}, health = 25, ap = 3,
        damage = {min = 3, max = 5}, xpValue = 25,
        description = "A stern guard, sworn to protect the Burmestor.",
        dropTable = { {name = "health_potion", chance = 0.25} }
    },
    burmestors_daughter = {
        name = "Burmestor's Daughter",
        char = "B", color = {0.9, 0.1, 0.1}, health = 50, ap = 4,
        unique = true,
        damage = {min = 5, max = 8}, xpValue = 100,
        description = "The Burmestor's twisted daugther, the product of his unholy union with a tainted lineage",
        dropTable = {}
    },
    crazed_villager = {
        name = "Crazed Villager",
        char = "v", color = {0.7, 0.3, 0.3}, health = 20, ap = 3,
        damage = {min = 2, max = 4}, xpValue = 15,
        description = "A villager driven mad by recent events, lashing out wildly.",
        dropTable = { {name = "health_potion", chance = 0.05} }
    },
    thug = {
        name = "Thug",
        char = "t", color = {0.7, 0.3, 0.3}, health = 30, ap = 3,
        damage = {min = 2, max = 6}, xpValue = 20,
        description = "A street tough looking for trouble.",
        dropTable = { {name = "health_potion", chance = 0.15} }
    },
    wild_canid = {
        name = "Wild Canid",
        char = "c", color = {0.7, 0.5, 0.3}, health = 15, ap = 4,
        damage = {min = 2, max = 4}, xpValue = 15,
        description = "A feral dog, hungry and aggressive.",
        dropTable = {}
    },
    watchman = {
        name = "Watchman",
        char = "W", color = {0.5, 0.5, 0.8}, health = 35, ap = 3,
        damage = {min = 4, max = 7}, xpValue = 30,
        description = "A vigilant member of the town watch.",
        dropTable = { {name = "health_potion", chance = 0.2} }
    },
    rat = {
        name = "Rat",
        char = "r", color = {0.4, 0.2, 0.1}, health = 10, ap = 2,
        damage = {min = 1, max = 2}, xpValue = 5,
        description = "A large, aggressive sewer rat.",
        dropTable = {}
    },
    synapse_rat = {
        name = "Synapse Rat",
        char = "R", color = {0.6, 0.2, 0.1}, health = 20, ap = 3,
        damage = {min = 2, max = 4}, xpValue = 15,
        description = "A rat acting as a psychic node for the hive mind.",
        dropTable = {}
    },
    sewer_dweller = {
        name = "Sewer Dweller",
        char = "D", color = {0.3, 0.6, 0.3}, health = 40, ap = 3,
        damage = {min = 5, max = 9}, xpValue = 50,
        description = "A wretched soul who calls the sewers home.",
        dropTable = { {name = "health_potion", chance = 0.5} }
    },
    alien_drone = {
        name = "Alien Drone",
        char = "d", color = {0.8, 0.8, 0.2}, health = 45, ap = 4,
        damage = {min = 6, max = 10}, xpValue = 75,
        description = "A skittering alien drone, moving with unnerving purpose.",
        dropTable = {}
    },
    alien_praetorian = {
        name = "Alien Praetorian",
        char = "p", color = {1, 0.6, 0}, health = 65, ap = 4,
        damage = {min = 8, max = 12}, xpValue = 150,
        description = "An elite alien warrior, its carapace hardened by countless battles.",
        dropTable = {}
    },
    alien_patriarch = {
        name = "Alien Patriarch",
        char = "P", color = {1, 0.8, 0}, health = 100, ap = 5,
        unique = true,
        damage = {min = 10, max = 15}, xpValue = 500,
        description = "The psychic patriarch of the alien hive.",
        dropTable = {}
    }
}

local function createEnemy(type, x, y)
    local data = enemyData[type]
    if not data then return nil end
    
    local enemy = Actor:new(x, y, data.char, data.color, data.name, data.health, data.ap)
    enemy.type = type
    enemy.damage = data.damage
    enemy.xpValue = data.xpValue
    enemy.description = data.description
    enemy.dropTable = data.dropTable
    return enemy
end

return createEnemy