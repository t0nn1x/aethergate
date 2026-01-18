class_name Organism
extends CharacterBody2D

## Base class for all living entities in the game
## Provides health, stats, and basic functionality

@export_group("Stats")
@export var organism_name: String = "Organism"
@export var max_health: float = 100.0
@export var movement_speed: float = 200.0

var current_health: float = 100.0
var is_alive: bool = true

signal health_changed(new_health: float, max_health: float)
signal died()

func _ready() -> void:
    current_health = max_health
    add_to_group("organisms")

## Deals damage to this organism
func take_damage(amount: float) -> void:
    if not is_alive:
        return

    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)

    if current_health <= 0:
        die()

## Heals this organism
func heal(amount: float) -> void:
    if not is_alive:
        return

    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

## Called when organism health reaches zero
func die() -> void:
    if not is_alive:
        return

    is_alive = false
    died.emit()

    # Override in derived classes
    _on_death()

## Override this in derived classes for custom death behavior
func _on_death() -> void:
    queue_free()

## Returns health as percentage (0.0 to 1.0)
func get_health_percentage() -> float:
    return current_health / max_health if max_health > 0 else 0.0
