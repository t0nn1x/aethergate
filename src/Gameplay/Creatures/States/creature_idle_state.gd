class_name CreatureIdleState
extends "res://src/Gameplay/Creatures/States/creature_state_base.gd"

@export var wander_state_path: NodePath = ^"../WanderState"
@export var chase_state_path: NodePath = ^"../ChaseState"
@export var attack_state_path: NodePath = ^"../AttackState"
@export var dead_state_path: NodePath = ^"../DeadState"

var _wander_state: State
var _chase_state: State
var _attack_state: State
var _dead_state: State
var _wander_check_timer: float = 0.0


func enter() -> void:
	_cache_context()
	if _is_ready():
		navigation_component.clear_target()
		movement_component.stop_movement()
		_wander_check_timer = 0.0


func physics_update(delta: float) -> State:
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

	_wander_check_timer -= delta
	if _wander_check_timer <= 0.0:
		_wander_check_timer = brain.get_wander_interval()
		if brain.should_wander():
			return _wander_state

	movement_component.stop_movement()
	return null


func _ensure_transitions() -> void:
	if _wander_state == null:
		_wander_state = get_node_or_null(wander_state_path) as State
	if _chase_state == null:
		_chase_state = get_node_or_null(chase_state_path) as State
	if _attack_state == null:
		_attack_state = get_node_or_null(attack_state_path) as State
	if _dead_state == null:
		_dead_state = get_node_or_null(dead_state_path) as State
