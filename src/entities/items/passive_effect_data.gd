class_name PassiveEffectData
extends Resource

## Passive proc effect granted by an Accessory.
## Evaluated by CombatRoundResolver after each phase.

enum PassiveEffectType {
	POISON_ON_HIT,   ## Deal value damage to defender each round after hit
	REGEN_ENERGY,    ## Restore value energy at start of player turn (always triggers)
	REFLECT_DAMAGE,  ## Reflect value% of incoming damage back to attacker
	THORNS,          ## Deal value flat damage when taking a hit
	LIFESTEAL        ## Heal value% of damage dealt
}

@export var effect_type: PassiveEffectType = PassiveEffectType.POISON_ON_HIT
@export_range(0.0, 1.0) var trigger_chance: float = 0.1
@export var value: float = 5.0
