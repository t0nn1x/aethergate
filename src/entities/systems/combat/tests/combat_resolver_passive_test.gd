class_name CombatResolverPassiveTest
extends RefCounted

## Tests passive proc evaluation in CombatRoundResolver.

const RESOLVER_SCRIPT: Script = preload(
	"res://src/entities/systems/combat/combat_round_resolver.gd"
)
const PASSIVE_SCRIPT: Script = preload(
	"res://src/entities/items/passive_effect_data.gd"
)

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()
	_test_no_passive_no_change()
	_test_poison_on_hit_always_triggers()
	_test_regen_energy_always_triggers()
	_test_thorns_applies_to_attacker()
	_print_summary()
	return _failures.is_empty()


func _test_no_passive_no_change() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, null)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, null)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_attacker_hp_delta != 0 or result.passive_defender_hp_delta != 0:
		_add_failure("No passive — passive deltas should be 0")


func _test_poison_on_hit_always_triggers() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var poison: PassiveEffectData = PASSIVE_SCRIPT.new()
	poison.effect_type = PassiveEffectData.PassiveEffectType.POISON_ON_HIT
	poison.trigger_chance = 1.0  # always trigger
	poison.value = 8.0
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, poison)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, null)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_defender_hp_delta != -8:
		_add_failure(
			"POISON_ON_HIT(1.0, 8.0) should deal 8 poison, got %d"
			% result.passive_defender_hp_delta
		)


func _test_regen_energy_always_triggers() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var regen: PassiveEffectData = PASSIVE_SCRIPT.new()
	regen.effect_type = PassiveEffectData.PassiveEffectType.REGEN_ENERGY
	regen.trigger_chance = 1.0
	regen.value = 10.0
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, regen)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, null)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_attacker_energy_delta != 10:
		_add_failure(
			"REGEN_ENERGY(1.0, 10.0) should grant 10 energy, got %d"
			% result.passive_attacker_energy_delta
		)


func _test_thorns_applies_to_attacker() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var thorns: PassiveEffectData = PASSIVE_SCRIPT.new()
	thorns.effect_type = PassiveEffectData.PassiveEffectType.THORNS
	thorns.trigger_chance = 1.0
	thorns.value = 5.0
	# Defender has THORNS passive
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, null)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, thorns)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_attacker_hp_delta != -5:
		_add_failure(
			"THORNS(1.0, 5.0) on defender should deal 5 to attacker, got %d"
			% result.passive_attacker_hp_delta
		)


# --- Helpers ---

func _make_snapshot(attack: float, defense: float, passive: PassiveEffectData) -> CombatantSnapshot:
	var snap: CombatantSnapshot = CombatantSnapshot.new()
	snap.combatant_id = &"test"
	snap.base_stats = CombatStats.new()
	snap.base_stats.attack = attack
	snap.base_stats.defense = defense
	snap.base_stats.max_hp = 100
	snap.passive_effect = passive
	return snap


func _make_attack_action() -> CombatAction:
	var action: CombatAction = CombatAction.new()
	action.actor_id = &"test"
	action.skill_used = null
	return action


func _add_failure(msg: String) -> void:
	_failures.append(msg)


func _print_summary() -> void:
	for f: String in _failures:
		printerr("[CombatResolverPassiveTest][FAIL] %s" % f)
	if _failures.is_empty():
		print("CombatResolverPassiveTest: PASS")
	else:
		print("CombatResolverPassiveTest: FAIL (%d failures)" % _failures.size())
