extends Node

## Owns all XP/level progression logic.
## Reads and writes raw data through PlayerProfileService (the autoload).
## _profile_service is a settable var so tests can inject a local instance.

signal xp_gained(amount: int, new_xp: int, xp_needed: int)
signal level_up(new_level: int, new_stats: CombatStats, bonus_points_gained: int)

const DEFAULT_CONFIG_PATH := \
	"res://src/entities/player/resources/player_level_config.tres"

## Bonus stat gained per allocated point — adjust here to tune build variety.
const BONUS_HP_PER_POINT: int = 10
const BONUS_ENERGY_PER_POINT: int = 5
const BONUS_ATTACK_PER_POINT: float = 2.0
const BONUS_DEFENSE_PER_POINT: float = 1.0

var _config: PlayerLevelConfig = null
## Default: the PlayerProfileService autoload. Tests override this before use.
var _profile_service: Node = null


func _ready() -> void:
	if _config == null:
		_config = load(DEFAULT_CONFIG_PATH) as PlayerLevelConfig
	if _profile_service == null:
		_profile_service = PlayerProfileService


## XP required to advance from level n to level n+1.
## Formula: int(xp_base * xp_decay^(n-1)), minimum 1.
func xp_needed_for_level(level: int) -> int:
	var raw: float = float(_config.xp_base) * pow(_config.xp_decay, float(level - 1))
	return maxi(1, int(raw))


## Progress through the current level as a value in [0.0, 1.0].
## Useful for XP progress bars.
func xp_progress() -> float:
	var current_xp: int = int(_profile_service.call("get_player_xp"))
	var level: int = int(_profile_service.call("get_player_level"))
	var needed: int = xp_needed_for_level(level)
	if needed <= 0:
		return 1.0
	return clampf(float(current_xp) / float(needed), 0.0, 1.0)


## Awards XP for a victory. Handles multi-level-up in a single call.
## Emits xp_gained once and level_up for each level crossed.
func award_xp(amount: int) -> void:
	if amount <= 0:
		return
	var current_xp: int = int(_profile_service.call("get_player_xp"))
	var current_level: int = int(_profile_service.call("get_player_level"))
	var allocations: Dictionary = _profile_service.call("get_bonus_allocations")
	var bonus_available: int = int(_profile_service.call("get_bonus_points_available"))

	current_xp += amount

	while current_level < _config.max_level:
		var needed: int = xp_needed_for_level(current_level)
		if current_xp < needed:
			break
		current_xp -= needed
		current_level += 1
		bonus_available += _config.bonus_points_per_level
		level_up.emit(current_level, calculate_stats(current_level, allocations),
			_config.bonus_points_per_level)

	_profile_service.call("set_xp_and_level", current_xp, current_level)
	_profile_service.call("set_bonus_state", bonus_available, allocations)
	xp_gained.emit(amount, current_xp, xp_needed_for_level(current_level))


## Pure stat calculation: base + (level-1)*growth + bonus allocations.
## Safe to call without any profile state.
func calculate_stats(level: int, allocations: Dictionary) -> CombatStats:
	var stats := CombatStats.new()
	var levels_gained: int = level - 1

	stats.max_hp = _config.base_max_hp + int(levels_gained * _config.hp_growth)
	stats.max_hp += int(allocations.get(&"max_hp", 0)) * BONUS_HP_PER_POINT

	stats.max_energy = _config.base_max_energy + int(levels_gained * _config.energy_growth)
	stats.max_energy += int(allocations.get(&"max_energy", 0)) * BONUS_ENERGY_PER_POINT

	stats.attack = _config.base_attack + levels_gained * _config.attack_growth
	stats.attack += float(int(allocations.get(&"attack", 0))) * BONUS_ATTACK_PER_POINT

	stats.defense = _config.base_defense + levels_gained * _config.defense_growth
	stats.defense += float(int(allocations.get(&"defense", 0))) * BONUS_DEFENSE_PER_POINT

	return stats


func get_bonus_points_available() -> int:
	return int(_profile_service.call("get_bonus_points_available"))


## Spends 1 bonus point on stat_key. Returns false if no points available.
## Valid stat_key values: &"max_hp", &"max_energy", &"attack", &"defense"
func allocate_bonus_point(stat_key: StringName) -> bool:
	var available: int = get_bonus_points_available()
	if available <= 0:
		return false
	var allocations: Dictionary = _profile_service.call("get_bonus_allocations")
	allocations[stat_key] = int(allocations.get(stat_key, 0)) + 1
	_profile_service.call("set_bonus_state", available - 1, allocations)
	return true


## Builds a CombatantSnapshot for the player using current level and stats.
## Sprite and VFX data are NOT included — callers augment the snapshot.
func build_player_snapshot() -> CombatantSnapshot:
	var level: int = int(_profile_service.call("get_player_level"))
	var allocations: Dictionary = _profile_service.call("get_bonus_allocations")
	var snap := CombatantSnapshot.new()
	snap.combatant_id = &"player"
	snap.display_name = "Player"
	snap.level = level
	snap.base_stats = calculate_stats(level, allocations)
	snap.skill_loadout = []
	return snap
