class_name MasteryServiceTest
extends RefCounted

## Tests for MasteryService: XP award, level thresholds, skill variant resolution.

const MASTERY_SCRIPT: Script = preload("res://src/core/mastery_service.gd")
const SKILL_SCRIPT: Script = preload("res://src/entities/skills/combat/skill_data.gd")

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()
	_test_mastery_level_zero_when_no_xp()
	_test_mastery_level_1_at_tier1_threshold()
	_test_mastery_level_2_at_tier2_threshold()
	_test_mastery_player_level_gates_tier()
	_test_get_active_skill_variant_base()
	_test_get_active_skill_variant_tier1()
	_test_award_mastery_xp_accumulates()
	_print_summary()
	return _failures.is_empty()


func _test_mastery_level_zero_when_no_xp() -> void:
	var svc: Node = _make_service()
	var level: int = svc.call("get_mastery_level", &"swords", 10)
	if level != 0:
		_add_failure("No XP should give mastery level 0, got %d" % level)


func _test_mastery_level_1_at_tier1_threshold() -> void:
	var svc: Node = _make_service()
	# Tier 1 threshold at player_level=1: 100 + 1*5 = 105 XP
	svc.call("_set_mastery_xp_for_test", &"swords", 105)
	var level: int = svc.call("get_mastery_level", &"swords", 1)
	if level != 1:
		_add_failure("105 XP at player level 1 should give mastery level 1, got %d" % level)


func _test_mastery_level_2_at_tier2_threshold() -> void:
	var svc: Node = _make_service()
	# Tier 2 threshold at player_level=1: 400 + 1*15 = 415 XP
	svc.call("_set_mastery_xp_for_test", &"swords", 415)
	var level: int = svc.call("get_mastery_level", &"swords", 1)
	if level != 2:
		_add_failure("415 XP at player level 1 should give mastery level 2, got %d" % level)


func _test_mastery_player_level_gates_tier() -> void:
	var svc: Node = _make_service()
	# 300 XP: tier1 threshold at pl=10 = 100 + 10*5 = 150 → should be tier 1
	# Same 300 XP: tier1 threshold at pl=41 = 100 + 41*5 = 305 → still tier 0
	svc.call("_set_mastery_xp_for_test", &"swords", 300)
	var level_low: int = svc.call("get_mastery_level", &"swords", 10)
	var level_high: int = svc.call("get_mastery_level", &"swords", 41)
	if level_low < 1:
		_add_failure("300 XP at player_level=10 should be at least mastery 1, got %d" % level_low)
	if level_high >= 1:
		_add_failure("300 XP at player_level=41 should be mastery 0 (gated), got %d" % level_high)


func _test_get_active_skill_variant_base() -> void:
	var svc: Node = _make_service()
	var skill: SkillData = _make_skill("slash", [])
	var result: SkillData = svc.call("get_active_skill_variant", skill, &"swords", 1)
	if result != skill:
		_add_failure("Mastery 0 should return the base skill")


func _test_get_active_skill_variant_tier1() -> void:
	var svc: Node = _make_service()
	var variant1: SkillData = _make_skill("slash_ii", [])
	var skill: SkillData = _make_skill("slash", [variant1])
	# Set XP above tier1 threshold for player_level=1
	svc.call("_set_mastery_xp_for_test", &"swords", 200)
	var result: SkillData = svc.call("get_active_skill_variant", skill, &"swords", 1)
	if result != variant1:
		_add_failure("Mastery 1 should return mastery_variants[0], got %s" % str(result))


func _test_award_mastery_xp_accumulates() -> void:
	var svc: Node = _make_service()
	svc.call("award_mastery_xp", &"swords", 50)
	svc.call("award_mastery_xp", &"swords", 50)
	var xp: int = svc.call("_get_mastery_xp_for_test", &"swords")
	if xp != 100:
		_add_failure("Two awards of 50 XP should accumulate to 100, got %d" % xp)


# --- Helpers ---

func _make_service() -> Node:
	var svc: Node = MASTERY_SCRIPT.new()
	return svc


func _make_skill(id: StringName, variants: Array) -> SkillData:
	var skill: SkillData = SKILL_SCRIPT.new()
	skill.skill_id = id
	skill.mastery_variants = variants
	return skill


func _add_failure(msg: String) -> void:
	_failures.append(msg)


func _print_summary() -> void:
	for f: String in _failures:
		printerr("[MasteryServiceTest][FAIL] %s" % f)
	if _failures.is_empty():
		print("MasteryServiceTest: PASS")
	else:
		print("MasteryServiceTest: FAIL (%d failures)" % _failures.size())
