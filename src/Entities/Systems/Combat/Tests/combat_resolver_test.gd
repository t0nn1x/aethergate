## Headless unit tests for CombatRoundResolver.

var _pass_count: int = 0
var _fail_count: int = 0


func run() -> bool:
	test_basic_attack_deals_damage()
	test_defend_halves_incoming_damage()
	test_combat_ends_when_enemy_hp_reaches_zero()
	test_player_loses_when_hp_reaches_zero()
	test_simultaneous_kill_has_no_winner()
	test_heal_restores_hp()
	print("[CombatResolverTest] %d passed, %d failed." % [_pass_count, _fail_count])
	return _fail_count == 0


func test_basic_attack_deals_damage() -> void:
	var resolver := CombatRoundResolver.new()
	var p_snap := _make_snapshot(&"player", 100, 10.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 100, 10.0, 0.0)

	var result: CombatRoundResult = resolver.resolve(
		1,
		CombatAction.make(&"player", null),
		CombatAction.make(&"enemy", null),
		p_snap, e_snap, 100, 100
	)

	_assert(result.hp_delta_enemy < 0, "player auto-attack should deal damage to enemy")
	_assert(result.hp_delta_player < 0, "enemy auto-attack should deal damage to player")
	_assert(not result.combat_ended, "combat should not end at full HP")


func test_defend_halves_incoming_damage() -> void:
	var resolver := CombatRoundResolver.new()
	var p_snap := _make_snapshot(&"player", 100, 10.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 100, 10.0, 0.0)

	var defend_skill := SkillData.new()
	defend_skill.skill_type = SkillData.SkillType.DEFEND
	defend_skill.base_power = 0.0
	defend_skill.energy_cost = 5

	var result_plain: CombatRoundResult = resolver.resolve(
		1,
		CombatAction.make(&"player", null),
		CombatAction.make(&"enemy", null),
		p_snap, e_snap, 100, 100
	)
	var result_defend: CombatRoundResult = resolver.resolve(
		1,
		CombatAction.make(&"player", defend_skill),
		CombatAction.make(&"enemy", null),
		p_snap, e_snap, 100, 100
	)

	_assert(
		result_defend.hp_delta_player > result_plain.hp_delta_player,
		"defending player should take less damage than plain auto-attack"
	)


func test_combat_ends_when_enemy_hp_reaches_zero() -> void:
	var resolver := CombatRoundResolver.new()
	var p_snap := _make_snapshot(&"player", 100, 999.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 1, 5.0, 0.0)

	var result: CombatRoundResult = resolver.resolve(
		1,
		CombatAction.make(&"player", null),
		CombatAction.make(&"enemy", null),
		p_snap, e_snap, 100, 1
	)

	_assert(result.combat_ended, "combat should end when enemy HP reaches 0")
	_assert(result.winner_id == &"player", "player should be declared winner")


func test_player_loses_when_hp_reaches_zero() -> void:
	var resolver := CombatRoundResolver.new()
	var p_snap := _make_snapshot(&"player", 1, 5.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 100, 999.0, 0.0)

	var result: CombatRoundResult = resolver.resolve(
		1,
		CombatAction.make(&"player", null),
		CombatAction.make(&"enemy", null),
		p_snap, e_snap, 1, 100
	)

	_assert(result.combat_ended, "combat should end when player HP reaches 0")
	_assert(result.winner_id == &"enemy", "enemy should be declared winner")


func test_simultaneous_kill_has_no_winner() -> void:
	var resolver := CombatRoundResolver.new()
	var p_snap := _make_snapshot(&"player", 1, 999.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 1, 999.0, 0.0)

	var result: CombatRoundResult = resolver.resolve(
		1,
		CombatAction.make(&"player", null),
		CombatAction.make(&"enemy", null),
		p_snap, e_snap, 1, 1
	)

	_assert(result.combat_ended, "combat should end on simultaneous kill")
	_assert(result.winner_id == &"", "simultaneous kill should have no winner (draw)")


func test_heal_restores_hp() -> void:
	var resolver := CombatRoundResolver.new()
	var p_snap := _make_snapshot(&"player", 100, 10.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 100, 5.0, 0.0)

	var heal_skill := SkillData.new()
	heal_skill.skill_type = SkillData.SkillType.HEAL
	heal_skill.base_power = 20.0
	heal_skill.energy_cost = 15

	var result: CombatRoundResult = resolver.resolve(
		1,
		CombatAction.make(&"player", heal_skill),
		CombatAction.make(&"enemy", null),
		p_snap, e_snap, 50, 100
	)

	_assert(result.hp_delta_player > 0, "heal skill should give positive HP delta to player")


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
