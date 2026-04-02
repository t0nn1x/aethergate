class_name CombatStats
extends Resource

## Stat block for a combatant in turn-based combat.
## Shared by both player snapshots and creature snapshots.

@export_group("Vitals")
@export var max_hp: int = 100
@export var max_energy: int = 100

@export_group("Offense / Defense")
@export var attack: float = 10.0
@export var defense: float = 5.0


func duplicate_stats() -> CombatStats:
	var copy := CombatStats.new()
	copy.max_hp = max_hp
	copy.max_energy = max_energy
	copy.attack = attack
	copy.defense = defense
	return copy
