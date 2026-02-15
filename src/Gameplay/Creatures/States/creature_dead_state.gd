class_name CreatureDeadState
extends "res://src/Gameplay/Creatures/States/creature_state_base.gd"


func enter() -> void:
	_cache_context()
	if movement_component:
		movement_component.stop_movement()
	if navigation_component:
		navigation_component.clear_target()


func physics_update(_delta: float) -> State:
	return null
