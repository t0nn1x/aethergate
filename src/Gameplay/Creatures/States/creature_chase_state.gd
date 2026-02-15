class_name CreatureChaseState
extends "res://src/Gameplay/Creatures/States/creature_state_base.gd"

@export var idle_state_path: NodePath = ^"../IdleState"
@export var attack_state_path: NodePath = ^"../AttackState"
@export var dead_state_path: NodePath = ^"../DeadState"

var _idle_state: State
var _attack_state: State
var _dead_state: State
var _repath_timer: float = 0.0


func enter() -> void:
	_cache_context()
	_repath_timer = 0.0


func physics_update(delta: float) -> State:
	_cache_context()
	if not _is_ready():
		return null
	_ensure_transitions()

	if not creature.is_alive:
		return _dead_state

	brain.request_target_refresh(false)
	if not brain.has_valid_target():
		navigation_component.clear_target()
		movement_component.stop_movement()
		return _idle_state

	if brain.is_target_within_attack_range():
		movement_component.stop_movement()
		return _attack_state

	if brain.is_target_outside_deaggro_range() and not brain.is_provoked:
		brain.clear_target()
		navigation_component.clear_target()
		movement_component.stop_movement()
		return _idle_state

	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = brain.get_chase_repath_interval()
		var target: Node2D = brain.get_target()
		if target:
			navigation_component.set_target_position(target.global_position)

	var direction: Vector2 = navigation_component.get_navigation_direction(creature.global_position)
	movement_component.apply_direction(direction)
	return null


func exit() -> void:
	if movement_component:
		movement_component.stop_movement()


func _ensure_transitions() -> void:
	if _idle_state == null:
		_idle_state = get_node_or_null(idle_state_path) as State
	if _attack_state == null:
		_attack_state = get_node_or_null(attack_state_path) as State
	if _dead_state == null:
		_dead_state = get_node_or_null(dead_state_path) as State
