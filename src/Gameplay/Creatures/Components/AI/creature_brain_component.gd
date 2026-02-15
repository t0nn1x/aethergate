class_name CreatureBrainComponent
extends Node

## Basic AI coordinator for Creature states.

@export var state_machine_path: NodePath = ^"StateMachine"
@export var navigation_component_path: NodePath = ^"CreatureNavigationComponent"
@export var movement_component_path: NodePath = ^"CreatureMovementComponent"
@export var target_node_path: NodePath
@export var target_refresh_interval_seconds: float = 0.5
@export var wander_probability: float = 0.2

var creature: Creature
var state_machine: StateMachine
var navigation_component: Node
var movement_component: Node

var target_node: Node2D
var is_provoked: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _target_refresh_timer: float = 0.0
var _wander_cooldown: float = 0.0


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "CreatureBrainComponent must be a child of Creature.")

	state_machine = creature.get_node_or_null(state_machine_path) as StateMachine
	navigation_component = creature.get_node_or_null(navigation_component_path)
	movement_component = creature.get_node_or_null(movement_component_path)

	if navigation_component == null:
		push_warning("CreatureBrainComponent: CreatureNavigationComponent is missing.")
	if movement_component == null:
		push_warning("CreatureBrainComponent: CreatureMovementComponent is missing.")

	_rng.randomize()
	if not creature.damaged.is_connected(_on_creature_damaged):
		creature.damaged.connect(_on_creature_damaged)
	request_target_refresh(true)


func _physics_process(delta: float) -> void:
	_target_refresh_timer -= delta
	_wander_cooldown = maxf(0.0, _wander_cooldown - delta)
	if _target_refresh_timer <= 0.0:
		request_target_refresh(false)


func get_target() -> Node2D:
	if target_node and is_instance_valid(target_node):
		return target_node
	return null


func has_valid_target() -> bool:
	return get_target() != null


func set_target(target: Node2D) -> void:
	if target == null:
		clear_target()
		return

	var previous_target: Node2D = get_target()
	target_node = target
	_target_refresh_timer = maxf(target_refresh_interval_seconds, 0.1)
	if previous_target != target:
		_emit_creature_aggro(target)


func clear_target() -> void:
	if get_target() != null:
		_emit_creature_deaggro()
	target_node = null


func request_target_refresh(force: bool = false) -> void:
	if not force and _target_refresh_timer > 0.0:
		return
	_target_refresh_timer = maxf(target_refresh_interval_seconds, 0.1)

	if target_node_path != NodePath():
		var explicit_target: Node2D = creature.get_node_or_null(target_node_path) as Node2D
		if explicit_target:
			set_target(explicit_target)
			return

	if target_node and not is_instance_valid(target_node):
		clear_target()
	if target_node and is_instance_valid(target_node):
		return

	var local_player: Node2D = get_tree().get_first_node_in_group("local_player") as Node2D
	if local_player:
		set_target(local_player)


func get_distance_to_target() -> float:
	var target: Node2D = get_target()
	if target == null or creature == null:
		return INF
	return creature.global_position.distance_to(target.global_position)


func get_attack_range() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.attack_range, 1.0)
	return 24.0


func get_aggro_range() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.aggro_range, get_attack_range())
	return 72.0


func get_deaggro_range() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.deaggro_range, get_aggro_range())
	return 96.0


func get_wander_radius() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.wander_radius, 8.0)
	return 32.0


func get_wander_interval() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.wander_interval_seconds, 0.2)
	return 3.0


func get_behavior_profile() -> CreatureData.BehaviorProfile:
	if creature and creature.creature_data:
		return creature.creature_data.behavior_profile
	return CreatureData.BehaviorProfile.NEUTRAL


func should_chase_target() -> bool:
	if not has_valid_target():
		return false

	var profile: CreatureData.BehaviorProfile = get_behavior_profile()
	if profile == CreatureData.BehaviorProfile.PASSIVE:
		return false
	if profile == CreatureData.BehaviorProfile.NEUTRAL and not is_provoked:
		return false
	return get_distance_to_target() <= get_aggro_range()


func should_wander() -> bool:
	if _wander_cooldown > 0.0:
		return false
	if has_valid_target() and should_chase_target():
		return false
	return _rng.randf() <= clampf(wander_probability, 0.0, 1.0)


func mark_wander_started() -> void:
	_wander_cooldown = get_wander_interval()


func get_random_wander_target() -> Vector2:
	if creature == null:
		return Vector2.ZERO
	var radius: float = get_wander_radius()
	var angle: float = _rng.randf_range(0.0, TAU)
	var distance: float = _rng.randf_range(radius * 0.35, radius)
	return creature.global_position + Vector2.RIGHT.rotated(angle) * distance


func is_target_within_attack_range() -> bool:
	return has_valid_target() and get_distance_to_target() <= get_attack_range()


func is_target_outside_deaggro_range() -> bool:
	if not has_valid_target():
		return true
	return get_distance_to_target() > get_deaggro_range()


func get_attack_cooldown() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.attack_cooldown, 0.1)
	return 1.0


func get_chase_repath_interval() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.chase_repath_interval_seconds, 0.1)
	return 0.45


func _on_creature_damaged(_amount: float, source: Node) -> void:
	is_provoked = true
	if source is Node2D:
		set_target(source as Node2D)


func _emit_creature_aggro(target: Node2D) -> void:
	var creature_events: Node = get_node_or_null("/root/CreatureEvents")
	if creature_events and creature_events.has_signal("creature_aggro"):
		creature_events.emit_signal("creature_aggro", creature, target)
		return

	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("creature_aggro"):
		event_bus.emit_signal("creature_aggro", creature, target)


func _emit_creature_deaggro() -> void:
	var creature_events: Node = get_node_or_null("/root/CreatureEvents")
	if creature_events and creature_events.has_signal("creature_deaggro"):
		creature_events.emit_signal("creature_deaggro", creature)
		return

	var event_bus: Node = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("creature_deaggro"):
		event_bus.emit_signal("creature_deaggro", creature)
