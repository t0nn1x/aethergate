## Headless unit tests for CombatRoundResolver.

var _pass_count: int = 0
var _fail_count: int = 0


func run() -> bool:
	test_phase_attack_deals_damage()
	test_phase_defend_deals_no_damage()
	test_phase_heal_restores_attacker_hp()
	test_phase_combat_ends_when_defender_dies()
	test_phase_auto_attack_minimum_damage()
	test_phase_player_loses_when_hp_reaches_zero()
	test_phase_level_scaled_attack()
	print("[CombatResolverTest] %d passed, %d failed." % [_pass_count, _fail_count])
	return _fail_count == 0


func test_phase_attack_deals_damage() -> void:
	var resolver := CombatRoundResolver.new()
	var attacker := _make_snapshot(&"player", 100, 10.0, 0.0)
	var defender := _make_snapshot(&"enemy", 100, 5.0, 5.0)

	var action := CombatAction.make(&"player", null)
	var result: CombatPhaseResult = resolver.resolve_phase(action, attacker, defender, 100)

	_assert(result.defender_hp_delta == -5, "10 atk - 5 def = 5 damage, delta should be -5")
	_assert(result.attacker_hp_delta == 0, "attacker should not self-heal on attack")
	_assert(result.defender_hp_after == 95, "100 - 5 = 95 HP remaining")
	_assert(not result.combat_ended, "combat should not end at 95 HP")
	_assert(result.attacker_id == &"player", "attacker_id should be player")
	_assert(result.defender_id == &"enemy", "defender_id should be enemy")


func test_phase_defend_deals_no_damage() -> void:
	var resolver := CombatRoundResolver.new()
	var attacker := _make_snapshot(&"enemy", 100, 10.0, 0.0)
	var defender := _make_snapshot(&"player", 100, 5.0, 0.0)

	var defend_skill := SkillData.new()
	defend_skill.skill_type = SkillData.SkillType.DEFEND
	defend_skill.base_power = 0.0
	defend_skill.energy_cost = 5

	var action := CombatAction.make(&"enemy", defend_skill)
	var result: CombatPhaseResult = resolver.resolve_phase(action, attacker, defender, 100)

	_assert(result.defender_hp_delta == 0, "defend action should deal 0 damage")
	_assert(result.defender_hp_after == 100, "defender HP unchanged by defend")


func test_phase_heal_restores_attacker_hp() -> void:
	var resolver := CombatRoundResolver.new()
	var attacker := _make_snapshot(&"player", 100, 10.0, 0.0)
	var defender := _make_snapshot(&"enemy", 100, 5.0, 0.0)

	var heal_skill := SkillData.new()
	heal_skill.skill_type = SkillData.SkillType.HEAL
	heal_skill.base_power = 20.0
	heal_skill.energy_cost = 15

	var action := CombatAction.make(&"player", heal_skill)
	var result: CombatPhaseResult = resolver.resolve_phase(action, attacker, defender, 80)

	_assert(result.attacker_hp_delta == 25, "heal should restore 25 HP (20 + 10*0.5)")
	_assert(result.defender_hp_delta == 0, "defender takes no damage from attacker heal")
	_assert(result.defender_hp_after == 80, "defender HP unchanged by attacker heal")


func test_phase_combat_ends_when_defender_dies() -> void:
	var resolver := CombatRoundResolver.new()
	var attacker := _make_snapshot(&"player", 100, 999.0, 0.0)
	var defender := _make_snapshot(&"enemy", 100, 5.0, 0.0)

	var action := CombatAction.make(&"player", null)
	var result: CombatPhaseResult = resolver.resolve_phase(action, attacker, defender, 1)

	_assert(result.combat_ended, "combat should end when defender HP reaches 0")
	_assert(result.defender_hp_after == 0, "defender HP should be clamped to 0")


func test_phase_auto_attack_minimum_damage() -> void:
	var resolver := CombatRoundResolver.new()
	var attacker := _make_snapshot(&"player", 100, 1.0, 0.0)
	var defender := _make_snapshot(&"enemy", 100, 999.0, 0.0)

	var action := CombatAction.make(&"player", null)
	var result: CombatPhaseResult = resolver.resolve_phase(action, attacker, defender, 50)

	_assert(result.defender_hp_delta == -1, "minimum damage should be 1 even with high defense")
	_assert(result.defender_hp_after == 49, "50 - 1 = 49")


func test_phase_player_loses_when_hp_reaches_zero() -> void:
	var resolver := CombatRoundResolver.new()
	var attacker := _make_snapshot(&"enemy", 100, 999.0, 0.0)
	var defender := _make_snapshot(&"player", 100, 5.0, 0.0)

	var action := CombatAction.make(&"enemy", null)
	var result: CombatPhaseResult = resolver.resolve_phase(action, attacker, defender, 1)

	_assert(result.combat_ended, "combat should end when player HP reaches 0")
	_assert(result.defender_hp_after == 0, "defender HP should be 0")


func test_phase_level_scaled_attack() -> void:
	var resolver := CombatRoundResolver.new()
	var attacker := _make_snapshot(&"player", 100, 16.0, 0.0)
	var defender := _make_snapshot(&"enemy", 100, 5.0, 5.0)

	var action := CombatAction.make(&"player", null)
	var result: CombatPhaseResult = resolver.resolve_phase(action, attacker, defender, 100)

	_assert(result.defender_hp_delta == -11,
		"level-scaled player (attack=16) vs defense=5 should deal 11 damage")
	_assert(result.defender_hp_after == 89, "100 - 11 = 89")


# --- Helpers ---

func _make_snapshot(id: StringName, hp: int, atk: float, def: float) -> CombatantSnapshot:
	var stats := CombatStats.new()
	stats.max_hp = hp
	stats.max_energy = 100
	stats.attack = atk
	stats.defense = def
	var snap := CombatantSnapshot.new()
	snap.combatant_id = id
	snap.base_stats = stats
	return snap


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
		_pass_count += 1
	else:
		push_error("[FAIL] %s" % message)
		_fail_count += 1
