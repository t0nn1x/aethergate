class_name CreatureAttackState
extends "res://src/Gameplay/Creatures/States/creature_state_base.gd"

@export var idle_state_path: NodePath = ^"../IdleState"
@export var chase_state_path: NodePath = ^"../ChaseState"
@export var dead_state_path: NodePath = ^"../DeadState"

var _idle_state: State
var _chase_state: State
var _dead_state: State
var _attack_cooldown_timer: float = 0.0


func enter() -> void:
	_cache_context()
	_attack_cooldown_timer = 0.0
	if movement_component:
		movement_component.stop_movement()


func physics_update(delta: float) -> State:
	_cache_context()
	if not _is_ready():
		return null
	_ensure_transitions()

	if not creature.is_alive:
		return _dead_state

	brain.request_target_refresh(false)
	if not brain.has_valid_target():
		return _idle_state
	if not brain.is_target_within_attack_range():
		return _chase_state

	_attack_cooldown_timer -= delta
	if _attack_cooldown_timer <= 0.0:
		_perform_attack()
		_attack_cooldown_timer = brain.get_attack_cooldown()

	movement_component.stop_movement()
	return null


func _perform_attack() -> void:
	var target: Node2D = brain.get_target()
	if target == null:
		return
	if target.has_method("take_damage"):
		target.call("take_damage", creature.damage, creature)


func _ensure_transitions() -> void:
	if _idle_state == null:
		_idle_state = get_node_or_null(idle_state_path) as State
	if _chase_state == null:
		_chase_state = get_node_or_null(chase_state_path) as State
	if _dead_state == null:
		_dead_state = get_node_or_null(dead_state_path) as State
