class_name PlayerProgressionServiceTest
extends RefCounted

## Tests for PlayerProgressionService: XP curve, stat calculation, award_xp.

const PROFILE_SAVE_PATH := "user://player_profile.cfg"
const PROGRESSION_SCRIPT: Script = preload("res://src/core/player_progression_service.gd")
const PROFILE_SCRIPT: Script = preload("res://src/core/player_profile_service.gd")
const CONFIG_SCRIPT: Script = preload(
	"res://src/entities/player/resources/player_level_config.gd"
)

var _failures: Array[String] = []
var _had_profile_backup: bool = false
var _profile_backup: PackedByteArray = PackedByteArray()


func run() -> bool:
	_failures.clear()
	_backup_profile_file()
	_clear_profile_file()

	_test_xp_needed_for_level()
	_test_calculate_stats_base()
	_test_calculate_stats_with_growth()
	_test_award_xp_no_level_up()
	_test_award_xp_single_level_up()
	_test_award_xp_multi_level_up()
	_test_xp_progress()

	_restore_profile_file()
	_print_summary()
	return _failures.is_empty()


# ---- XP curve ----

func _test_xp_needed_for_level() -> void:
	var svc: Node = _make_progression_service()

	var level_1_xp: int = svc.call("xp_needed_for_level", 1)
	var level_50_xp: int = svc.call("xp_needed_for_level", 50)
	var level_99_xp: int = svc.call("xp_needed_for_level", 99)

	# Linear formula: xp_base + xp_growth * (n-1). Test config: base=100, growth=25.
	if level_1_xp != 100:
		_add_failure("xp_needed_for_level(1) expected 100, got %d" % level_1_xp)
	# level 50: 100 + 49*25 = 1325
	if level_50_xp != 1325:
		_add_failure("xp_needed_for_level(50) expected 1325, got %d." % level_50_xp)
	if level_50_xp <= level_1_xp:
		_add_failure(
			"xp_needed_for_level(50) should be greater than level 1 XP (got %d vs %d)."
			% [level_50_xp, level_1_xp]
		)
	if level_99_xp <= level_50_xp:
		_add_failure(
			"xp_needed_for_level(99) should be greater than level 50 XP (got %d vs %d)."
			% [level_99_xp, level_50_xp]
		)
	if level_99_xp <= 0:
		_add_failure("xp_needed_for_level(99) must be at least 1, got %d." % level_99_xp)


# ---- Stat calculation ----

func _test_calculate_stats_base() -> void:
	var svc: Node = _make_progression_service()
	var stats: CombatStats = svc.call("calculate_stats", 1) as CombatStats
	if stats == null:
		_add_failure("calculate_stats(1, {}) returned null.")
		return
	if stats.max_hp != 80:
		_add_failure("Level 1 max_hp expected 80, got %d." % stats.max_hp)
	if stats.max_energy != 100:
		_add_failure("Level 1 max_energy expected 100, got %d." % stats.max_energy)
	if not is_equal_approx(stats.attack, 8.0):
		_add_failure("Level 1 attack expected 8.0, got %f." % stats.attack)
	if not is_equal_approx(stats.defense, 4.0):
		_add_failure("Level 1 defense expected 4.0, got %f." % stats.defense)


func _test_calculate_stats_with_growth() -> void:
	var svc: Node = _make_progression_service()
	# Level 2: base + 1 growth cycle
	var stats: CombatStats = svc.call("calculate_stats", 2) as CombatStats
	if stats == null:
		_add_failure("calculate_stats(2, {}) returned null.")
		return
	if stats.max_hp != 92:  # 80 + 12
		_add_failure("Level 2 max_hp expected 92, got %d." % stats.max_hp)
	if not is_equal_approx(stats.attack, 9.5):  # 8.0 + 1.5
		_add_failure("Level 2 attack expected 9.5, got %f." % stats.attack)


# ---- XP award ----

func _test_award_xp_no_level_up() -> void:
	var svc: Node = _make_progression_service_with_profile()
	# Level 1 needs 100 XP (test config: base=100, growth=25); award 50 — no level-up
	svc.call("award_xp", 50)
	var profile: Node = svc.get("_profile_service") as Node
	if profile == null:
		_add_failure("award_xp test: _profile_service is null.")
		return
	var stored_xp: int = int(profile.call("get_player_xp"))
	var stored_level: int = int(profile.call("get_player_level"))
	if stored_xp != 50:
		_add_failure("After award_xp(50) xp expected 50, got %d." % stored_xp)
	if stored_level != 1:
		_add_failure("Level should remain 1 after small XP award, got %d." % stored_level)


func _test_award_xp_single_level_up() -> void:
	var svc: Node = _make_progression_service_with_profile()
	var level_up_emitted: bool = false
	svc.connect("level_up", func(_lvl: int, _stats: CombatStats) -> void:
		level_up_emitted = true
	)
	# Level 1 needs 100 XP (test config: base=100, growth=25); award 101 to cross it
	svc.call("award_xp", 101)
	if not level_up_emitted:
		_add_failure("level_up signal not emitted after crossing level 1 threshold.")
	var profile: Node = svc.get("_profile_service") as Node
	if int(profile.call("get_player_level")) != 2:
		_add_failure(
			"Expected level 2 after 1001 XP, got %d." % int(profile.call("get_player_level"))
		)


func _test_award_xp_multi_level_up() -> void:
	var svc: Node = _make_progression_service_with_profile()
	var level_ups: int = 0
	svc.connect("level_up", func(_lvl: int, _stats: CombatStats) -> void:
		level_ups += 1
	)
	# Level 1: 100 XP, level 2: 125, level 3: 150 — 400 XP crosses at least 2 levels
	svc.call("award_xp", 400)
	if level_ups < 2:
		_add_failure("Expected ≥2 level_up signals for 3000 XP, got %d." % level_ups)


func _test_xp_progress() -> void:
	var svc: Node = _make_progression_service_with_profile()
	svc.call("award_xp", 50)
	var progress: float = float(svc.call("xp_progress"))
	if progress < 0.0 or progress > 1.0:
		_add_failure("xp_progress() must be in [0.0, 1.0], got %f." % progress)
	# 50 XP toward 100 should be ~0.5; allow ±0.1
	if progress < 0.4 or progress > 0.6:
		_add_failure("50/100 XP should give ~0.5 progress, got %f." % progress)


# ---- Helpers ----

func _make_test_config() -> PlayerLevelConfig:
	var cfg: PlayerLevelConfig = CONFIG_SCRIPT.new()
	cfg.xp_base = 100
	cfg.xp_growth = 25
	cfg.max_level = 100
	cfg.base_max_hp = 80
	cfg.base_max_energy = 100
	cfg.base_attack = 8.0
	cfg.base_defense = 4.0
	cfg.hp_growth = 12.0
	cfg.energy_growth = 3.0
	cfg.attack_growth = 1.5
	cfg.defense_growth = 0.8
	return cfg


func _make_progression_service() -> Node:
	var svc: Node = PROGRESSION_SCRIPT.new()
	svc.set("_config", _make_test_config())
	return svc


func _make_progression_service_with_profile() -> Node:
	var profile: Node = PROFILE_SCRIPT.new()
	profile.call("_ready")
	var svc: Node = PROGRESSION_SCRIPT.new()
	svc.set("_config", _make_test_config())
	svc.set("_profile_service", profile)
	return svc


func _backup_profile_file() -> void:
	_had_profile_backup = FileAccess.file_exists(PROFILE_SAVE_PATH)
	if not _had_profile_backup:
		return
	var file: FileAccess = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	_profile_backup = file.get_buffer(file.get_length())


func _clear_profile_file() -> void:
	if FileAccess.file_exists(PROFILE_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_SAVE_PATH))


func _restore_profile_file() -> void:
	var abs_path: String = ProjectSettings.globalize_path(PROFILE_SAVE_PATH)
	if _had_profile_backup:
		var file: FileAccess = FileAccess.open(PROFILE_SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_buffer(_profile_backup)
	elif FileAccess.file_exists(PROFILE_SAVE_PATH):
		DirAccess.remove_absolute(abs_path)


func _add_failure(message: String) -> void:
	_failures.append(message)


func _print_summary() -> void:
	for failure: String in _failures:
		printerr("[PlayerProgressionServiceTest][FAIL] %s" % failure)
	if _failures.is_empty():
		print("Player progression service test: PASS")
	else:
		print("Player progression service test: FAIL (%d failures)." % _failures.size())
