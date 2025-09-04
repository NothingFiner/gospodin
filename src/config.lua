-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/config.lua

local config = {}
local C = require('src.constants')

-- Game states
config.GameState = {
    MENU = "menu",
    EQUIPMENT_SELECT = "equipment_select",
    PLAYING = "playing",
    VICTORY = "victory",
    GAME_OVER = "game_over"
}

-- Floor definitions
config.floorData = {
    {name = "Audience Room",                generator = "audience_chamber", transitions = {down = 1}, enemies = {"infected_servant"},
        colors = {
            floor = {0.4, 0.3, 0.25},
            wall = {0.2, 0.15, 0.12}
        }
    },
    {name = "Burmestor's Manor: Apartments", generator = "manor",            transitions = {up = 1, down = 2}, enemies = {"guard", "infected_servant"},
        colors = {
            floor = {0.5, 0.4, 0.3},
            wall = {0.3, 0.2, 0.15}
        }
    },
    {name = "Burmestor's Manor: Ground Floor", generator = "manor",            transitions = {up = 2, down = 1}, enemies = {"guard"}, uniqueSpawns = {"burmestors_daughter"},
        colors = {
            floor = {0.6, 0.5, 0.4},
            wall = {0.4, 0.3, 0.2}
        }
    },
    {name = "Village Streets",              generator = "village",          transitions = {up = 1, down = 2}, enemies = {"thug", "watchman"},
        colors = {
            floor = {0.5, 0.5, 0.45}, -- Cobblestone
            wall = {0.4, 0.35, 0.3}, -- Building walls
            town_square = {0.6, 0.6, 0.55}
        }
    },
    {name = "Dark Sewers",                  generator = "default",          transitions = {up = 2, down = 1}, enemies = {"rat", "sewer_dweller"},
        colors = {
            floor = {0.3, 0.4, 0.3}, -- Mossy floor
            wall = {0.2, 0.3, 0.2}  -- Damp wall
        }
    },
    {name = "Alien Lair",                   generator = "default",          transitions = {up = 1, down = 0}, enemies = {"alien_drone"}, uniqueSpawns = {"alien_patriarch"},
        colors = {
            floor = {0.4, 0.3, 0.4}, -- Purple-ish organic floor
            wall = {0.3, 0.2, 0.3}  -- Dark fleshy wall
        }
    }
}

-- Equipment loadouts
config.equipmentLoadouts = {
    orbs = {
        name = "Nanite Cloud Array",
        description = "A suite of specialized neural coprocessors and nano-scale factories replace your biological spinal cord, allowing you to control a swarm of tiny machines that can be used for defense and offense; Forming into fist-sized projecticles covered in molecule thin-spines, claw-like blades, or reactive armor.",
        weapon = {name = C.WeaponType.NANITE_CLOUD_ARRAY, damage = 6, range = 3, apCost = 2},
        health = 80,
        actionPoints = 4,
        dodge = 15, -- moderate dodge
        armor = 2    -- low armor
    },
    laser = {
        name = "Type 77 ",
        description = "Maybe your body can't handle traumatic implants, maybe you're old enough to remember the horror stories when they were first developed. Either way, the Type 77 is an old weapon for Old Souls. With its onboard fusion cell and factories it makes it's own ammunition from almost any material, even your own flesh.",
        weapon = {name = C.WeaponType.TYPE_77, damage = 8, range = 5, apCost = 3},
        health = 70,
        actionPoints = 3,
        dodge = 10, -- low dodge
        armor = 3    -- moderate armor
    },
    war_gecko = {
        name = "War Gecko",
        description = "An implant suite named after its most distinct constituant: the replacement of the epidermis with billions of minute suckers. In conjunction your enhanced myofibers and composite skeleton you can hold onto any surface or rip the skin off of an unaugmented human being.",
        weapon = {name = C.WeaponType.GECKO_STRIKE, damage = 10, range = 1, apCost = 2},
        health = 100,
        actionPoints = 5,
        dodge = 5,  -- very low dodge
        armor = 5    -- high armor
    }
}

-- Base player stats and level-up configuration
config.playerStats = {
    strength = 5,
    dexterity = 5,
    intelligence = 5,
    xpPerLevel = 100 -- XP needed for the next level is level * xpPerLevel
}

-- Item definitions
config.items = {
    health_potion = {
        name = "Health Potion",
        description = "A bubbling red liquid that restores a moderate amount of health.",
        char = "!",
        color = {1, 0.2, 0.2},
        effect = {
            type = C.ItemEffect.HEAL,
            amount = 40
        }
    }
}

return config