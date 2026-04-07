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
## Injected by main.gd after Player scene is ready. Null = no equipment wired (fallback OK).
var _equipment_component: PlayerEquipmentComponent = null
## Injected reference to MasteryService autoload. Settable for tests.
var _mastery_service: Node = null


func _ready() -> void:
	if _config == null:
		_config = load(DEFAULT_CONFIG_PATH) as PlayerLevelConfig
	if _profile_service == null:
		_profile_service = Engine.get_singleton(&"PlayerProfileService")


## Called by main.gd after the Player scene is added to the scene tree.
func set_equipment_component(comp: PlayerEquipmentComponent) -> void:
	_equipment_component = comp


func _get_mastery_service() -> Node:
	if _mastery_service != null:
		return _mastery_service
	return Engine.get_singleton(&"MasteryService")


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


## Builds a CombatantSnapshot for the player using current level, base stats, and equipment.
## Sprite and VFX data are NOT included — callers augment the snapshot.
func build_player_snapshot() -> CombatantSnapshot:
	var level: int = int(_profile_service.call("get_player_level"))
	var snap := CombatantSnapshot.new()
	snap.combatant_id = &"player"
	snap.display_name = "Player"
	snap.level = level

	# 1. Base stats from level
	var base: CombatStats = calculate_stats(level)

	# 2. Equipment stat bonuses
	if _equipment_component != null:
		var bonus: CombatStats = _equipment_component.get_total_stat_bonuses()
		base.max_hp     += bonus.max_hp
		base.max_energy += bonus.max_energy
		base.attack     += bonus.attack
		base.defense    += bonus.defense

	snap.base_stats = base

	# 3. Skill grants resolved through mastery
	if _equipment_component != null:
		var mastery: Node = _get_mastery_service()
		var family_id: StringName = _equipment_component.get_weapon_family_id()
		for skill: SkillData in _equipment_component.get_all_skill_grants():
			var active: SkillData = mastery.call(
				"get_active_skill_variant", skill, family_id, level
			)
			snap.skill_loadout.append(active)
		# 4. Passive effect from accessory
		snap.passive_effect = _equipment_component.get_passive_effect()
		# 5. Weapon family for post-combat mastery awarding
		snap.weapon_family_id = family_id

	return snap
