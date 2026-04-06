class_name PlayerLevelConfig
extends Resource

## Tunable parameters for the player levelling system.
## Edit player_level_config.tres in the inspector to tune game feel
## without touching code.

@export_group("XP Curve")
## XP required to level up at level 1.
## Formula: xp_for_level(n) = xp_base + xp_growth * (n - 1)
@export var xp_base: int = 200
## Additional XP required per level. Higher = steeper linear growth.
@export var xp_growth: int = 50
@export var max_level: int = 100

@export_group("Base Stats (at level 1)")
@export var base_max_hp: int = 80
@export var base_max_energy: int = 100
@export var base_attack: float = 8.0
@export var base_defense: float = 4.0

@export_group("Auto Growth (added each level-up)")
@export var hp_growth: float = 5.0
@export var energy_growth: float = 2.0
@export var attack_growth: float = 0.5
@export var defense_growth: float = 0.25

