class_name PlayerLevelConfig
extends Resource

## Tunable parameters for the player levelling system.
## Edit player_level_config.tres in the inspector to tune game feel
## without touching code.

@export_group("XP Curve")
## XP required to level up from level 1 (the hardest level).
## Formula: xp_for_level(n) = int(xp_base * xp_decay^(n-1))
@export var xp_base: int = 1000
## Decay factor per level. Must be strictly between 0 and 1.
@export_range(0.01, 0.99, 0.001) var xp_decay: float = 0.97
@export var max_level: int = 100

@export_group("Base Stats (at level 1)")
@export var base_max_hp: int = 80
@export var base_max_energy: int = 100
@export var base_attack: float = 8.0
@export var base_defense: float = 4.0

@export_group("Auto Growth (added each level-up)")
@export var hp_growth: float = 12.0
@export var energy_growth: float = 3.0
@export var attack_growth: float = 1.5
@export var defense_growth: float = 0.8

@export_group("Bonus Points")
## Bonus stat points awarded to the player each level-up for manual allocation.
@export var bonus_points_per_level: int = 2
