class_name CreatureWanderState
extends "res://src/Gameplay/Creatures/States/creature_state_base.gd"

@export var idle_state_path: NodePath = ^"../IdleState"
@export var chase_state_path: NodePath = ^"../ChaseState"
@export var attack_state_path: NodePath = ^"../AttackState"
@export var dead_state_path: NodePath = ^"../DeadState"

var _idle_state: State
var _chase_state: State
var _attack_state: State
var _dead_state: State


func enter() -> void:
	_cache_context()
	if not _is_ready():
		return
	brain.mark_wander_started()
	var wander_target: Vector2 = brain.get_random_wander_target()
	navigation_component.set_target_position(wander_target)


func physics_update(_delta: float) -> State:
	_cache_context()
	if not _is_ready():
		return null
	_ensure_transitions()

	if not creature.is_alive:
		return _dead_state

	brain.request_target_refresh(false)
	if brain.is_target_within_attack_range():
		return _attack_state
	if brain.should_chase_target():
		return _chase_state

	if navigation_component.is_navigation_finished():
		movement_component.stop_movement()
		return _idle_state

	var direction: Vector2 = navigation_component.get_navigation_direction(creature.global_position)
	movement_component.apply_direction(direction)
	return null


func exit() -> void:
	if movement_component:
		movement_component.stop_movement()


func _ensure_transitions() -> void:
	if _idle_state == null:
		_idle_state = get_node_or_null(idle_state_path) as State
	if _chase_state == null:
		_chase_state = get_node_or_null(chase_state_path) as State
	if _attack_state == null:
		_attack_state = get_node_or_null(attack_state_path) as State
	if _dead_state == null:
		_dead_state = get_node_or_null(dead_state_path) as State
