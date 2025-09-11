-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/config.lua

local config = {}
local C = require('src.constants')

-- Game states
config.GameState = {
    MENU = "menu",
    EQUIPMENT_SELECT = "equipment_select",
    PLAYING = "playing",
    VICTORY = "victory",
    GAME_OVER = "game_over",
    LEVEL_UP = "level_up"
}

-- Floor definitions
config.floorData = {
    {name = "Audience Room",                generator = "audience_chamber", width = 40, height = 20, transitions = {down = 1}, enemies = {"infected_servant"},
        colors = {
            floor = require('src.colors').manor_red,
            wall = {0.2, 0.15, 0.12}
        }
    },
    {name = "Burmestor's Manor: Apartments", generator = "manor",            width = 60, height = 25, transitions = {up = 1, down = 2}, enemies = {"guard", "infected_servant"},
        colors = {
            floor = require('src.colors').manor_red,
            wall = {0.3, 0.2, 0.15}
        }
    },
    {name = "Burmestor's Manor: Ground Floor", generator = "manor",            width = 60, height = 25, transitions = {up = 2, down = 1}, enemies = {"guard"}, uniqueSpawns = {"burmestors_daughter"},
        colors = {
            floor = require('src.colors').manor_red,
            wall = {0.4, 0.3, 0.2}
        }
    },
    {name = "Burmestor's Manor: Grounds",   generator = "grounds",          width = 30, height = 30, transitions = {up = 1, down = 1}, enemies = {"guard", "wild_canid"},
        colors = {
            floor = require('src.colors').dark_green, -- Dirt/grass path
            wall = {0.1, 0.4, 0.1} -- Hedges
        }
    },
    {name = "Village Streets",              generator = "village",          width = 100, height = 30, transitions = {up = 1, down = 1}, enemies = {"thug", "watchman"},
        colors = {
            floor = {0.5, 0.5, 0.45}, -- Cobblestone
            wall = {0.4, 0.35, 0.3}, -- Building walls
            town_square = {0.6, 0.6, 0.55}
        }
    },
    {name = "Dark Sewers",                  generator = "default",          width = 80, height = 25, transitions = {up = 1, down = 1}, enemies = {"rat", "sewer_dweller"},
        colors = {
            floor = {0.3, 0.4, 0.3}, -- Mossy floor
            wall = {0.2, 0.3, 0.2}  -- Damp wall
        }
    },
    {name = "Alien Lair",                   generator = "default",          width = 80, height = 25, transitions = {up = 1, down = 0}, enemies = {"alien_drone", "alien_praetorian"}, uniqueSpawns = {"alien_patriarch"},
        colors = {
            floor = {0.4, 0.3, 0.4}, -- Purple-ish organic floor
            wall = {0.3, 0.2, 0.3}  -- Dark fleshy wall
        }
    }
}

-- Equipment loadouts
config.equipmentLoadouts = {
    nanite_cloud_array = {
        name = "Nanite Cloud Array",
        description = "A suite of specialized neural coprocessors and nano-scale factories replace your biological spinal cord, allowing you to control a swarm of tiny machines that can be used for defense and offense.",
        implant = "nanite_cloud_array"
    },
    type_77 = {
        name = "Type 77",
        description = "Maybe your body can't handle traumatic implants, maybe you're old enough to remember the horror stories when they were first developed. Either way, the Type 77 is an old weapon for Old Souls.",
        weapon = "type_77"
    },
    war_gecko = { -- This one is already consistent
        name = "War Gecko",
        description = "An implant suite named after its most distinct constituant: the replacement of the epidermis with billions of minute suckers. In conjunction with your enhanced myofibers and composite skeleton you can hold onto any surface or rip the skin off of an unaugmented human being.",
        implant = "war_gecko"
    }
}

-- Base player stats and level-up configuration
config.playerStats = {
    baseHealth = 70,
    baseActionPoints = 3,
    baseDodge = 10,
    baseArmor = 3,
    strength = 5,
    dexterity = 5,
    intelligence = 5,
    xpPerLevel = 100 -- XP needed for the next level is level * xpPerLevel
}

-- Perk definitions
config.perks = {
    -- General Perks
    beefy = {
        name = "Beefy",
        description = "Your physical form is exceptionally robust.",
        effects = { {type = "stat", stat = "health", value = 30} }
    },
    digital_weapons = {
        name = "Digital Weapons",
        description = "Nanites sharpen your every blow.",
        effects = { {type = "stat", stat = "damage", value = {min=2, max=2}} }
    },
    way_of_the_mongoose = {
        name = "Way of the Mongoose",
        description = "Your movements are fluid and your system resilient.",
        effects = { {type = "stat", stat = "dodge", value = 5}, {type = "immunity", status = C.StatusEffect.POISON} }
    },
    sharpshooter = {
        name = "Sharpshooter",
        description = "You have a preternatural aim with ranged weapons.",
        effects = { {type = "stat", stat = "critChance", value = 10, condition="ranged"} } -- Condition needs implementation
    },
    anatomist = {
        name = "Anatomist",
        description = "You know exactly where to strike for maximum effect.",
        effects = { {type = "stat", stat = "critDamage", value = {min=2, max=4}} }
    },
    prodigy = {
        name = "Prodigy",
        description = "You are a natural at everything.",
        effects = { {type = "stat", stat = "strength", value = 1}, {type = "stat", stat = "dexterity", value = 1}, {type = "stat", stat = "intelligence", value = 1} }
    },
    first_aid = {
        name = "First Aid",
        description = "Gain an ability to perform emergency self-repair.",
        effects = { {type = "add_ability", ability = "first_aid_heal"} }
    },
    -- Upgraded Perks
    surgical_expert = {
        name = "Surgical Expert",
        description = "Your knowledge of anatomy is lethally precise.",
        prereq = "anatomist",
        effects = { {type = "stat", stat = "critDamage", value = {min=2, max=4}} }
    },
    -- Implant-specific perks
    advanced_targeting_algorithms = {
        name = "Advanced Targeting",
        description = "Your Nanite Swarm can target one additional enemy.",
        prereq_implant = "nanite_cloud_array",
        effects = { {type = "modify_ability", ability = C.Ability.SHOOT_NANITE, property = "maxTargets", value = 1} }
    },
    toxic_injectors = {
        name = "Toxic Injectors",
        description = "Your melee attacks have a chance to poison enemies.",
        prereq_implant = "war_gecko",
        effects = { {type = "add_effect", effect = "poison_on_hit", chance = 0.5, duration = 3, damage = {min=1, max=5}} }
    }
}

-- Ability definitions
config.abilities = {
    basic_attack = {
        name = "Basic Attack",
        description = "A standard melee attack.",
        apCost = 1,
        range = 1.5,
        cooldown = 0,
        targeting = "single_enemy",
        effect = "melee_attack",
        hidden = true,
        damage = {min=1, max=2} -- Basic attack needs damage
    },
    first_aid_heal = {
        name = "First Aid",
        description = "Heal for 10 health. 2 Charges, restored on level up.",
        apCost = 2,
        cooldown = 0,
        effect = "heal",
        amount = 10,
        charges = 2,
        maxCharges = 2
    },
    reload_crossbow = {
        name = "Reload Crossbow",
        description = "Reload the primitive crossbow.",
        apCost = 3,
        cooldown = 0,
        effect = "reload_ability",
        targetAbility = "shoot_crossbow"
    },
    shoot_crossbow = {
        name = "Shoot (Crossbow)",
        description = "Fire a bolt from the crossbow.",
        apCost = 1,
        range = 8,
        cooldown = 0,
        targeting = "single_enemy",
        effect = "ranged_attack",
        damage = {min = 2, max = 5},
        charges = 1,
        maxCharges = 1
    },
    sweep = {
        name = "Sweep",
        description = "Attack all adjacent enemies in a forward arc.",
        apCost = 3,
        effect = "area_attack",
        damage = {min = 3, max = 5}
    },
    toxic_strike = {
        name = "Toxic Strike",
        description = "Inject a debilitating poison on hit.",
        apCost = 0, -- This is a passive effect, not a usable ability
        cooldown = 0,
        effect = "apply_status",
        status = C.StatusEffect.POISON,
        hidden = true
    },
    [C.Ability.SHOOT_TYPE77] = {
        name = "Shoot (Type 77)",
        description = "Fire a high-energy bolt at a single target.",
        apCost = 3,
        range = 10,
        cooldown = 0,
        targeting = "single_enemy",
        effect = "ranged_attack",
        damage = {min = 6, max = 10}
    },
    [C.Ability.SHOOT_NANITE] = {
        name = "Nanite Swarm",
        description = "Launch a swarm of nanites at up to 3 targets.",
        apCost = 2,
        range = 3,
        cooldown = 0,
        targeting = "multi_enemy",
        maxTargets = 3,
        effect = "ranged_attack",
        damage = {min = 4, max = 8}
    },
    [C.Ability.GECKO_STRIKE] = {
        name = "Gecko Strike",
        description = "A powerful melee strike that bypasses some armor.",
        apCost = 2,
        cooldown = 0,
        targeting = "single_enemy", -- Melee abilities also need a target
        range = 1.5, -- A bit more than 1 to allow diagonal attacks
        effect = "melee_attack",
        damage = {min = 8, max = 12}
    },
    [C.Ability.GECKO_LEAP] = {
        name = "Gecko Leap",
        description = "Instantly leap to a nearby empty tile.",
        apCost = 1,
        range = 3,
        cooldown = 3,
        targeting = "empty_tile",
        effect = "move_to_target"
    }
}

-- Item definitions. Items are now either Consumables or Equipment.
config.items = {
    -- === CONSUMABLES ===
    health_potion = {
        type = C.ItemType.CONSUMABLE,
        name = "Health Potion",
        description = "A bubbling red liquid that restores a moderate amount of health.",
        char = "!",
        color = {1, 0.2, 0.2},
        effect = {
            type = C.ItemEffect.HEAL,
            amount = 40
        }
    },

    -- === IMPLANTS (now treated as items for creation purposes) ===
    nanite_cloud_array = {
        type = C.ItemType.EQUIPMENT,
        name = "Nanite Cloud Array",
        slot = C.EquipmentSlot.IMPLANT, -- This identifies it as an implant
        char = "*", color = {0.7, 0.7, 0.9},
        modifiers = {
            health = 10, actionPoints = 1, dodge = 5, armor = -1
        },
        abilities = {C.Ability.SHOOT_NANITE}
    },
    war_gecko = {
        type = C.ItemType.EQUIPMENT,
        name = "War Gecko",
        slot = C.EquipmentSlot.IMPLANT, -- This identifies it as an implant
        char = "*", color = {0.4, 0.8, 0.4},
        modifiers = {
            health = 30, actionPoints = 2, dodge = -5, armor = 2
        },
        abilities = {C.Ability.GECKO_STRIKE, C.Ability.GECKO_LEAP}
    },

    -- === EQUIPMENT: WEAPONS ===
    type_77 = {
        type = C.ItemType.EQUIPMENT,
        name = "Type 77",
        char = "/", color = {0.9, 0.5, 0.2},
        slot = C.EquipmentSlot.WEAPON1, -- Can go in either weapon slot
        modifiers = {
            -- This item's power comes from the ability it grants
        },
        abilities = {C.Ability.SHOOT_TYPE77}
    },
    nobles_knife = {
        type = C.ItemType.EQUIPMENT,
        name = "Noble's Knife",
        char = ")", color = {0.8, 0.8, 0.8},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = {
            damage = {min = 1, max = 2}
        }
    },
    sonic_dagger = {
        type = C.ItemType.EQUIPMENT,
        name = "Sonic Dagger",
        char = ")", color = {0.4, 0.9, 0.9},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = {
            damage = {min = 2, max = 4},
            critChance = 10, -- Additive: +10%
            critDamage = {min = 1, max = 6} -- Additive: +1d6 bonus damage
        },
        abilities = {} -- This weapon uses standard attacks, not special abilities
    },
    primitive_crossbow = {
        type = C.ItemType.EQUIPMENT,
        name = "Primitive Crossbow",
        char = "}", color = {0.5, 0.4, 0.3},
        slot = C.EquipmentSlot.WEAPON1,
        abilities = {"shoot_crossbow", "reload_crossbow"}
    },
    guards_halberd = {
        type = C.ItemType.EQUIPMENT,
        name = "Guard's Halberd",
        char = "P", color = {0.8, 0.7, 0.6},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = { damage = {min = 4, max = 8} },
        abilities = {"sweep"}
    },
    cleaver = {
        type = C.ItemType.EQUIPMENT,
        name = "Cleaver",
        char = ")", color = {0.7, 0.7, 0.7},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = { damage = {min = 2, max = 3}, critDamage = 3 }
    },
    short_sword = {
        type = C.ItemType.EQUIPMENT,
        name = "Short Sword",
        char = ")", color = {0.8, 0.8, 0.8},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = { damage = {min = 2, max = 6} }
    },
    severed_arm = {
        type = C.ItemType.EQUIPMENT,
        name = "Severed Arm",
        char = "(", color = {0.4, 0.6, 0.4},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = { damage = {min = 2, max = 4}, stun_chance = 0.1 } -- stun_chance is a new modifier
    },
    alien_claw_dagger = {
        type = C.ItemType.EQUIPMENT,
        name = "Alien Claw Dagger",
        char = "'", color = {0.6, 0.2, 0.8},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = { damage = {min = 2, max = 6}, poison_chance = 0.25 } -- poison_chance is a new modifier
    },
    relic_blade = {
        type = C.ItemType.EQUIPMENT,
        name = "Relic Blade",
        char = "|", color = {0.9, 0.9, 0.2},
        slot = C.EquipmentSlot.WEAPON1,
        modifiers = { damage = {min = 4, max = 10} }
    },


    -- === EQUIPMENT: ARMOR ===
    elegant_blouse = {
        type = C.ItemType.EQUIPMENT,
        name = "Elegant Blouse",
        char = "[", color = {0.9, 0.9, 1.0},
        slot = C.EquipmentSlot.CHEST,
        modifiers = {
            armor = 1
        }
    },
    refined_pantaloons = {
        type = C.ItemType.EQUIPMENT,
        name = "Refined Pantaloons",
        char = "[", color = {0.8, 0.8, 0.7},
        slot = C.EquipmentSlot.LEGS,
        modifiers = {
            dodge = 1
        }
    },
    sensible_boots = {
        type = C.ItemType.EQUIPMENT,
        name = "Sensible Boots",
        char = "[", color = {0.5, 0.4, 0.3},
        slot = C.EquipmentSlot.FEET,
        modifiers = {
            -- No modifiers, just flavor for now
        }
    },

    -- === EQUIPMENT: ARMOR (New) ===
    guards_helmet = {
        type = C.ItemType.EQUIPMENT, name = "Guard's Helmet", char = "^", color = {0.7, 0.7, 0.7},
        slot = C.EquipmentSlot.HEAD, modifiers = { armor = 2 }
    },
    guards_cuirass = {
        type = C.ItemType.EQUIPMENT, name = "Guard's Cuirass", char = "[", color = {0.7, 0.7, 0.7},
        slot = C.EquipmentSlot.CHEST, modifiers = { armor = 3 }
    },
    guards_braces = {
        type = C.ItemType.EQUIPMENT, name = "Guard's Braces", char = "[", color = {0.7, 0.7, 0.7},
        slot = C.EquipmentSlot.HANDS, modifiers = { armor = 2 }
    },
    guards_greaves = {
        type = C.ItemType.EQUIPMENT, name = "Guard's Greaves", char = "[", color = {0.7, 0.7, 0.7},
        slot = C.EquipmentSlot.LEGS, modifiers = { armor = 2 }
    },
    ancient_combat_exoskeleton = {
        type = C.ItemType.EQUIPMENT, name = "Ancient Combat Exoskeleton", char = "[", color = {0.4, 0.4, 0.5},
        slot = C.EquipmentSlot.CHEST, modifiers = { actionPoints = 2, damage = {min=3, max=3}, critDamage = 3 }
    },
    boots_of_the_venerated_star_people = {
        type = C.ItemType.EQUIPMENT, name = "Boots of the Venerated Star People", char = "[", color = {0.9, 0.9, 0.2},
        slot = C.EquipmentSlot.FEET, modifiers = { armor = 2, actionPoints = 1 }
    },
    improvised_chitin_breast_plate = {
        type = C.ItemType.EQUIPMENT, name = "Improvised Chitin Breast Plate", char = "[", color = {0.6, 0.2, 0.8},
        slot = C.EquipmentSlot.CHEST, modifiers = { armor = 5 }
    },
    alien_claw_gauntlet = {
        type = C.ItemType.EQUIPMENT, name = "Alien Claw Gauntlet", char = "[", color = {0.6, 0.2, 0.8},
        slot = C.EquipmentSlot.HANDS, modifiers = { armor = 2, damage = {min=1, max=1} }
    },
    helmet_of_the_venerated_star_people = {
        type = C.ItemType.EQUIPMENT, name = "Helmet of the Venerated Star People", char = "^", color = {0.9, 0.9, 0.2},
        slot = C.EquipmentSlot.HEAD, modifiers = { armor = 2, stun_immunity = true } -- stun_immunity is a new modifier
    },
    chestplate_of_the_venerated_star_people = {
        type = C.ItemType.EQUIPMENT, name = "Chestplate of the Venerated Star People", char = "[", color = {0.9, 0.9, 0.2},
        slot = C.EquipmentSlot.CHEST, modifiers = { armor = 6 }
    },
    gambeson = {
        type = C.ItemType.EQUIPMENT, name = "Gambeson", char = "[", color = {0.8, 0.7, 0.6},
        slot = C.EquipmentSlot.CHEST, modifiers = { armor = 2 }
    },
    leather_bracers = {
        type = C.ItemType.EQUIPMENT, name = "Leather Bracers", char = "[", color = {0.5, 0.4, 0.3},
        slot = C.EquipmentSlot.HANDS, modifiers = { armor = 1 }
    },
    assassins_boots = {
        type = C.ItemType.EQUIPMENT, name = "Assassin's Boots", char = "[", color = {0.2, 0.2, 0.2},
        slot = C.EquipmentSlot.FEET, modifiers = { armor = 1, critChance = 10 }
    }
}

return config