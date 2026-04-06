extends Node

## Owns all XP/level progression logic.
## Reads and writes raw data through PlayerProfileService (the autoload).
## _profile_service is a settable var so tests can inject a local instance.

signal xp_gained(amount: int, new_xp: int, xp_needed: int)
signal level_up(new_level: int, new_stats: CombatStats)

const DEFAULT_CONFIG_PATH := \
	"res://src/entities/player/resources/player_level_config.tres"

var _config: PlayerLevelConfig = null
## Default: the PlayerProfileService autoload. Tests override this before use.
var _profile_service: Node = null


func _ready() -> void:
	if _config == null:
		_config = load(DEFAULT_CONFIG_PATH) as PlayerLevelConfig
	if _profile_service == null:
		_profile_service = PlayerProfileService


## XP required to advance from level n to level n+1.
## Formula: xp_base + xp_growth * (n - 1), minimum 1.
func xp_needed_for_level(level: int) -> int:
	return maxi(1, _config.xp_base + _config.xp_growth * (level - 1))


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

	current_xp += amount

	while current_level < _config.max_level:
		var needed: int = xp_needed_for_level(current_level)
		if current_xp < needed:
			break
		current_xp -= needed
		current_level += 1
		level_up.emit(current_level, calculate_stats(current_level))

	_profile_service.call("set_xp_and_level", current_xp, current_level)
	xp_gained.emit(amount, current_xp, xp_needed_for_level(current_level))


## Pure stat calculation: base + (level-1)*growth.
## Safe to call without any profile state.
func calculate_stats(level: int) -> CombatStats:
	var stats := CombatStats.new()
	var levels_gained: int = level - 1

	stats.max_hp = _config.base_max_hp + int(levels_gained * _config.hp_growth)
	stats.max_energy = _config.base_max_energy + int(levels_gained * _config.energy_growth)
	stats.attack = _config.base_attack + levels_gained * _config.attack_growth
	stats.defense = _config.base_defense + levels_gained * _config.defense_growth

	return stats


## Builds a CombatantSnapshot for the player using current level and stats.
## Sprite and VFX data are NOT included — callers augment the snapshot.
func build_player_snapshot() -> CombatantSnapshot:
	var level: int = int(_profile_service.call("get_player_level"))
	var snap := CombatantSnapshot.new()
	snap.combatant_id = &"player"
	snap.display_name = "Player"
	snap.level = level
	snap.base_stats = calculate_stats(level)
	snap.skill_loadout = []
	return snap
