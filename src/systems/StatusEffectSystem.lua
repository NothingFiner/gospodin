-- /Users/eliotasenothgaspar-finer/Projects/Gospodin/src/systems/StatusEffectSystem.lua

local GameLogSystem = require('src.systems.GameLogSystem')
local C = require('src.constants')

local StatusEffectSystem = {}

function StatusEffectSystem.apply(target, effect)
    if not target or not target.statusEffects then return end

    -- For stackable effects like poison, add to existing duration.
    if target.statusEffects[effect.type] and effect.stackable then
        target.statusEffects[effect.type].duration = target.statusEffects[effect.type].duration + effect.duration
    else
        -- For non-stackable or new effects, just apply it.
        target.statusEffects[effect.type] = {
            duration = effect.duration,
            damage = effect.damage,
            potency = effect.potency
        }
    end
    GameLogSystem.logStatusApplied(target, effect.type)
end

function StatusEffectSystem.processTurn(entity)
    if not entity or not entity.statusEffects then return end

    -- Process Damage Over Time (DOT)
    if entity.statusEffects[C.StatusEffect.POISON] then
        local effect = entity.statusEffects[C.StatusEffect.POISON]
        local damage = effect.damage or 1
        entity.health = entity.health - damage
        GameLogSystem.logStatusDamage(entity, C.StatusEffect.POISON, damage)
        effect.duration = effect.duration - 1
        if effect.duration <= 0 then
            entity.statusEffects[C.StatusEffect.POISON] = nil
            GameLogSystem.logStatusWearsOff(entity, C.StatusEffect.POISON)
        end
    end

    -- Process Stun (wears off at the start of the entity's turn)
    if entity.statusEffects[C.StatusEffect.STUN] then
        local effect = entity.statusEffects[C.StatusEffect.STUN]
        effect.duration = effect.duration - 1
        if effect.duration <= 0 then
            entity.statusEffects[C.StatusEffect.STUN] = nil
            GameLogSystem.logStatusWearsOff(entity, C.StatusEffect.STUN)
        end
    end
end

return StatusEffectSystem