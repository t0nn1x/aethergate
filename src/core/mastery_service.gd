extends Node

## Tracks mastery XP per item family and resolves active skill variants.
## Saved to player_profile.cfg [mastery] section.
## Registered as autoload "MasteryService" in project.godot.

const MASTERY_SECTION: String = "mastery"
const PROFILE_SAVE_PATH: String = "user://player_profile.cfg"

## In-memory mastery XP: item_family_id → xp total (int)
var _mastery_xp: Dictionary = {}


func _ready() -> void:
	_load_mastery_data()


## Award mastery XP for using a weapon family. Caps per-fight gain at 100.
## Emits PlayerEvents.mastery_xp_gained so the CombatResultPanel can show progress.
func award_mastery_xp(item_family_id: StringName, amount: int) -> void:
	var capped: int = mini(amount, 100)
	var current: int = _mastery_xp.get(item_family_id, 0)
	_mastery_xp[item_family_id] = current + capped
	_save_mastery_data()
	if Engine.has_singleton("PlayerEvents"):
		Engine.get_singleton("PlayerEvents").mastery_xp_gained.emit(item_family_id, capped)


## Returns 0, 1, or 2 based on XP thresholds scaled by player level.
## tier_1_threshold = 100 + player_level * 5
## tier_2_threshold = 400 + player_level * 15
func get_mastery_level(item_family_id: StringName, player_level: int) -> int:
	var xp: int = _mastery_xp.get(item_family_id, 0)
	var tier2: int = 400 + player_level * 15
	var tier1: int = 100 + player_level * 5
	if xp >= tier2:
		return 2
	if xp >= tier1:
		return 1
	return 0


## Returns the appropriate SkillData variant based on mastery level.
## mastery 0 → base skill, mastery 1 → mastery_variants[0], mastery 2 → mastery_variants[1].
func get_active_skill_variant(
	skill: SkillData,
	item_family_id: StringName,
	player_level: int
) -> SkillData:
	var level: int = get_mastery_level(item_family_id, player_level)
	if level == 0 or skill.mastery_variants.is_empty():
		return skill
	if level == 1:
		return skill.mastery_variants[0] as SkillData
	# level == 2
	if skill.mastery_variants.size() >= 2:
		return skill.mastery_variants[1] as SkillData
	return skill.mastery_variants[0] as SkillData


# --- Persistence ---

func _load_mastery_data() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PROFILE_SAVE_PATH) != OK:
		return
	if not cfg.has_section(MASTERY_SECTION):
		return
	for key: String in cfg.get_section_keys(MASTERY_SECTION):
		_mastery_xp[StringName(key)] = int(cfg.get_value(MASTERY_SECTION, key, 0))


func _save_mastery_data() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROFILE_SAVE_PATH)
	for family_id: StringName in _mastery_xp:
		cfg.set_value(MASTERY_SECTION, String(family_id), _mastery_xp[family_id])
	var err: Error = cfg.save(PROFILE_SAVE_PATH)
	if err != OK and OS.is_debug_build():
		push_warning("MasteryService: failed to save mastery data (%d)" % int(err))


# --- Test helpers (not called in production) ---

func _set_mastery_xp_for_test(item_family_id: StringName, xp: int) -> void:
	_mastery_xp[item_family_id] = xp


func _get_mastery_xp_for_test(item_family_id: StringName) -> int:
	return _mastery_xp.get(item_family_id, 0)
