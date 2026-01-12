class_name Entity
extends CharacterBody2D
## Base class for all game entities (player, enemies, NPCs).
## Provides common functionality like health management and death handling.

signal health_changed(new_health: float, max_health: float)
signal died()

@export var entity_name: String = "Entity"
@export var max_health: float = 100.0

var current_health: float = 100.0


func _ready() -> void:
	_initialize_health()


## Initializes health to maximum value
func _initialize_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Applies damage to the entity
## Returns the actual damage dealt after any modifications
func take_damage(amount: float) -> float:
	if amount <= 0:
		return 0.0
	
	var actual_damage: float = min(amount, current_health)
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()
	
	return actual_damage


## Heals the entity by the specified amount
## Returns the actual amount healed
func heal(amount: float) -> float:
	if amount <= 0:
		return 0.0
	
	var actual_heal: float = min(amount, max_health - current_health)
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	
	return actual_heal


## Returns the current health percentage (0.0 to 1.0)
func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health


## Returns true if the entity is alive
func is_alive() -> bool:
	return current_health > 0


## Handles entity death - override in derived classes for custom behavior
func die() -> void:
	died.emit()
	queue_free()
