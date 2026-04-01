class_name CreatureSpawnZoneTest
extends RefCounted

## Validates spawn-zone helper behavior (normalization + polygon sampling).

const CreatureData = preload("res://src/Entities/creatures/base/creature_data.gd")
const ZONE_SCRIPT: Script = preload("res://src/Entities/creatures/spawning/creature_spawn_zone.gd")

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()
	_test_filter_normalization()
	_test_polygon_sampling_and_containment()
	_test_config_validation()
	_print_summary()
	return _failures.is_empty()


func _test_filter_normalization() -> void:
	var zone: Node = _create_valid_zone()
	zone.allowed_creature_ids = PackedStringArray([
		" undead_adept_necromancer ",
		"UNDEAD_ADEPT_NECROMANCER",
		"animals_arctic_wolf",
		""
	])
	zone.allowed_creature_types = PackedInt32Array([
		int(CreatureData.CreatureType.UNDEAD),
		int(CreatureData.CreatureType.UNDEAD),
		-1,
		999
	])
	zone.allowed_source_categories = PackedStringArray([" Undead ", "undead", "Animals"])

	var ids: Array[String] = zone.get_normalized_creature_ids()
	_assert(ids.size() == 2, "Expected 2 unique normalized creature IDs.")
	_assert(ids.has("animals_arctic_wolf"), "Normalized IDs missing animals_arctic_wolf.")
	_assert(ids.has("undead_adept_necromancer"), "Normalized IDs missing undead_adept_necromancer.")

	var type_values: Array[int] = zone.get_sanitized_creature_type_values()
	_assert(type_values.size() == 1, "Expected 1 valid creature type value.")
	_assert(
		type_values.has(int(CreatureData.CreatureType.UNDEAD)),
		"Sanitized creature types missing UNDEAD value."
	)

	var categories: Array[String] = zone.get_normalized_source_categories()
	_assert(categories.size() == 2, "Expected 2 unique source categories.")
	_assert(categories.has("animals"), "Normalized categories missing animals.")
	_assert(categories.has("undead"), "Normalized categories missing undead.")


func _test_polygon_sampling_and_containment() -> void:
	var zone: Node = _create_valid_zone()
	zone.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(120.0, 0.0),
		Vector2(120.0, 90.0),
		Vector2(0.0, 90.0),
	])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	for _i in 40:
		var sample: Variant = zone.sample_world_position(rng, 8)
		_assert(sample is Vector2, "Sampled zone position must be a Vector2.")
		if sample is Vector2:
			_assert(
				zone.contains_world_position(sample as Vector2),
				"Sampled zone position must stay inside zone polygon."
			)


func _test_config_validation() -> void:
	var valid_zone: Node = _create_valid_zone()
	_assert(valid_zone.is_config_valid("CreatureSpawnZoneTest"), "Expected valid zone config.")

	var no_filter_zone: Node = _create_valid_zone()
	no_filter_zone.allowed_source_categories = PackedStringArray()
	_assert(
		not no_filter_zone.is_config_valid("CreatureSpawnZoneTest"),
		"Zone without filters should be invalid."
	)

	var invalid_polygon_zone: Node = _create_valid_zone()
	invalid_polygon_zone.polygon = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT])
	_assert(
		not invalid_polygon_zone.is_config_valid("CreatureSpawnZoneTest"),
		"Zone with <3 polygon points should be invalid."
	)


func _create_valid_zone() -> Node:
	var zone: Node = ZONE_SCRIPT.new()
	zone.enabled = true
	zone.spawn_rate_per_minute = 2.0
	zone.max_alive = 3
	zone.initial_spawn_count = 1
	zone.spawn_attempts_per_tick = 6
	zone.min_distance_to_player = 64.0
	zone.max_distance_to_player = 0.0
	zone.allowed_source_categories = PackedStringArray(["undead"])
	zone.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(80.0, 0.0),
		Vector2(80.0, 80.0),
		Vector2(0.0, 80.0),
	])
	return zone


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _print_summary() -> void:
	for failure in _failures:
		printerr("[CreatureSpawnZoneTest][FAIL] %s" % failure)

	if _failures.is_empty():
		print("Creature spawn zone test: PASS")
	else:
		print("Creature spawn zone test: FAIL (%d failures)." % _failures.size())
