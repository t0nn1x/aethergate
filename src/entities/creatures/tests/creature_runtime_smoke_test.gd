extends Node2D

## Runtime smoke test for creature spawn, baseline movement, and death cleanup.

signal completed(passed: bool)

const CATALOG_PATH := "res://src/entities/creatures/resources/creature_catalog.tres"
const Creature = preload("res://src/entities/creatures/base/creature.gd")
const CreatureData = preload("res://src/entities/creatures/base/creature_data.gd")
const FACTORY_SCRIPT: Script = preload("res://src/entities/creatures/base/creature_factory.gd")

var _failures: Array[String] = []
var _spawned_creatures: Array[Creature] = []
var _test_blocker_registry: NavigationBlockerRegistry


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_failures.clear()

	var catalog = load(CATALOG_PATH)
	if catalog == null:
		_add_failure("Could not load creature catalog at '%s'." % CATALOG_PATH)
		_finish()
		return
	catalog.call("rebuild_indices")

	var samples: Array[CreatureData] = _collect_samples(catalog)
	if samples.size() < 3:
		_add_failure("Expected at least 3 sample creatures but got %d." % samples.size())
		_finish()
		return

	var factory = FACTORY_SCRIPT.new()
	if factory == null:
		_add_failure("Could not instantiate CreatureFactory.")
		_finish()
		return

	for i in 3:
		var runtime_data: CreatureData = _create_runtime_data(samples[i], i)
		var creature: Creature = factory.create(runtime_data)
		if creature == null:
			_add_failure("Factory failed to create creature index %d." % i)
			continue

		add_child(creature)
		creature.global_position = Vector2(float(i) * 48.0, 0.0)
		_spawned_creatures.append(creature)

	await get_tree().process_frame
	await get_tree().physics_frame

	_test_blocker_registry = _build_test_blocker_registry()
	_wire_spawned_blocker_components(_test_blocker_registry)

	_validate_spawned_components()
	await _validate_move_state()
	await _validate_damage_death_cleanup()
	_cleanup_spawned_creatures()
	_finish()


func _collect_samples(catalog) -> Array[CreatureData]:
	var samples: Array[CreatureData] = []
	var categories: Array[String] = ["humanoids", "animals", "undead"]
	for category in categories:
		var entries: Array[CreatureData] = catalog.call("get_by_source_category", category) as Array[CreatureData]
		if not entries.is_empty():
			samples.append(entries[0])

	if samples.size() >= 3:
		return samples

	var all_entries: Array[CreatureData] = catalog.call("get_all") as Array[CreatureData]
	for entry in all_entries:
		if entry and not samples.has(entry):
			samples.append(entry)
		if samples.size() >= 3:
			break
	return samples


func _create_runtime_data(source: CreatureData, index: int) -> CreatureData:
	var runtime_data: CreatureData = source.duplicate() as CreatureData
	runtime_data.creature_id = "%s_smoke_%d" % [source.get_effective_creature_id(), index]
	runtime_data.movement_speed = maxf(runtime_data.movement_speed, 70.0)
	runtime_data.sprite_sheet = _create_dummy_sheet_texture(index)
	return runtime_data


func _create_dummy_sheet_texture(index: int) -> Texture2D:
	var image := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	var palette: Array[Color] = [
		Color(0.9, 0.3, 0.3, 1.0),
		Color(0.3, 0.9, 0.3, 1.0),
		Color(0.3, 0.6, 0.95, 1.0),
	]
	var base_color: Color = palette[index % palette.size()]
	image.fill(base_color)
	return ImageTexture.create_from_image(image)


func _validate_spawned_components() -> void:
	for creature in _spawned_creatures:
		_assert(creature != null and is_instance_valid(creature), "Spawned creature instance is invalid.")
		if creature == null or not is_instance_valid(creature):
			continue
		_assert(creature.is_alive, "Spawned creature is not alive.")
		_assert(
			creature.get_node_or_null("CreatureMovementComponent") != null,
			"CreatureMovementComponent is missing."
		)
		_assert(
			creature.get_node_or_null("CreatureVisualComponent") != null,
			"CreatureVisualComponent is missing."
		)
		_assert(
			creature.get_node_or_null("CreatureNavigationComponent") != null,
			"CreatureNavigationComponent is missing."
		)
		_assert(
			creature.get_node_or_null("CreatureWanderComponent") != null,
			"CreatureWanderComponent is missing."
		)
		var blocker_component: PlayerMoveTargetBlockerComponent = creature.get_node_or_null(
			"PlayerMoveTargetBlockerComponent"
		) as PlayerMoveTargetBlockerComponent
		_assert(
			blocker_component != null,
			"PlayerMoveTargetBlockerComponent is missing."
		)
		if blocker_component != null:
			var blocked_probe: Vector2 = Vector2(32.0, 32.0)
			_assert(
				blocker_component.is_world_position_blocked(blocked_probe),
				"Blocker probe should be blocked inside test polygon."
			)
			var resolved_target: Vector2 = blocker_component.resolve_world_target(blocked_probe)
			_assert(
				not blocker_component.is_world_position_blocked(resolved_target),
				"Resolved blocker target should be outside blocked polygon."
			)
		_assert(
			creature.get_node_or_null("CreatureBrainComponent") == null,
			"CreatureBrainComponent should be absent in non-autonomous mode."
		)
		_assert(
			creature.get_node_or_null("StateMachine") == null,
			"Creature StateMachine should be absent in non-autonomous mode."
		)


func _validate_move_state() -> void:
	if _spawned_creatures.is_empty():
		return
	var creature: Creature = _spawned_creatures[0]
	if creature == null or not is_instance_valid(creature):
		_add_failure("Movement test creature is invalid.")
		return

	var movement_component: Node = creature.get_node_or_null("CreatureMovementComponent")
	if movement_component == null:
		_add_failure("Movement test missing CreatureMovementComponent.")
		return

	movement_component.call("apply_direction", Vector2.RIGHT)
	_assert(creature.velocity.x > 0.0, "Movement apply_direction did not produce horizontal velocity.")
	movement_component.call("stop_movement")


func _validate_damage_death_cleanup() -> void:
	if _spawned_creatures.size() < 3:
		return
	var creature: Creature = _spawned_creatures[2]
	if creature == null or not is_instance_valid(creature):
		_add_failure("Damage/death test creature is invalid.")
		return

	creature.take_damage(999999.0, self)
	await get_tree().process_frame
	if is_instance_valid(creature):
		_assert(not creature.is_alive, "Creature should be dead after lethal damage.")
		_assert(creature.is_queued_for_deletion(), "Dead creature should be queued for deletion.")


func _cleanup_spawned_creatures() -> void:
	for creature in _spawned_creatures:
		if creature and is_instance_valid(creature) and not creature.is_queued_for_deletion():
			creature.queue_free()
	_spawned_creatures.clear()
	if _test_blocker_registry and is_instance_valid(_test_blocker_registry):
		_test_blocker_registry.queue_free()
		_test_blocker_registry = null


func _build_test_blocker_registry() -> NavigationBlockerRegistry:
	var registry := NavigationBlockerRegistry.new()
	registry.name = "TestNavigationBlockerRegistry"
	registry.auto_refresh_on_ready = false
	add_child(registry)

	var region := NavigationRegion2D.new()
	region.name = "TestNavigationRegion2D"
	registry.add_child(region)

	var polygon := Polygon2D.new()
	polygon.name = "TestBlockedPolygon"
	polygon.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(64.0, 0.0),
		Vector2(64.0, 64.0),
		Vector2(0.0, 64.0),
	])
	region.add_child(polygon)

	registry.refresh()
	return registry


func _wire_spawned_blocker_components(registry: NavigationBlockerRegistry) -> void:
	if registry == null:
		return
	for creature in _spawned_creatures:
		if creature == null or not is_instance_valid(creature):
			continue
		var blocker_component: PlayerMoveTargetBlockerComponent = creature.get_node_or_null(
			"PlayerMoveTargetBlockerComponent"
		) as PlayerMoveTargetBlockerComponent
		if blocker_component:
			blocker_component.set_blocker_registry(registry)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_add_failure(message)


func _add_failure(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	for failure in _failures:
		printerr("[CreatureRuntimeSmokeTest][FAIL] %s" % failure)

	var passed: bool = _failures.is_empty()
	if passed:
		print("Creature runtime smoke test: PASS")
	else:
		print("Creature runtime smoke test: FAIL (%d failures)." % _failures.size())

	completed.emit(passed)
	if DisplayServer.get_name() == "headless":
		get_tree().quit(0 if passed else 1)
