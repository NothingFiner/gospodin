-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/constants.lua
-- A central place for game-wide constants, acting like enums.

local constants = {}

constants.ItemType = {
    CONSUMABLE = "consumable",
    EQUIPMENT = "equipment"
}

constants.EquipmentSlot = {
    IMPLANT = "implant", HEAD = "head", CHEST = "chest", HANDS = "hands",
    LEGS = "legs", FEET = "feet", WEAPON1 = "weapon1", WEAPON2 = "weapon2"
}

constants.WeaponType = {
    NANITE_CLOUD_ARRAY = "Nanite Cloud Array",
    TYPE_77 = "Type 77",
    GECKO_STRIKE = "Gecko Strike"
}

constants.Ability = {
    SHOOT_TYPE77 = "shoot_type77",
    SHOOT_NANITE = "shoot_nanite",
    GECKO_STRIKE = "gecko_strike",
    GECKO_LEAP = "gecko_leap"
}

constants.StatusEffect = {
    POISON = "poison",
    STUN = "stun"
}

constants.ItemEffect = {
    HEAL = "heal"
}

return constants