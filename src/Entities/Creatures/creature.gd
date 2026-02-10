class_name Creature
extends CharacterBody2D

## Base class for all living entities in the game (player, enemies, NPCs).
## A thin shell: holds stats, a sprite, and hosts component child nodes.
## Configure via a CreatureData resource — no game logic lives here.

@export var creature_data: CreatureData

## --- Stats (applied from creature_data or set manually for Player) ---
var creature_name: String = "Creature"
var max_health: float = 100.0
var current_health: float = 100.0
var movement_speed: float = 200.0
var damage: float = 0.0
var armor: float = 0.0
var is_alive: bool = true

## --- Signals ---
signal health_changed(new_health: float, max_health: float)
signal died()

## --- Lifecycle ---

func _ready() -> void:
	add_to_group("creatures")
	if creature_data:
		_apply_creature_data()

## Applies stats and sprite config from a CreatureData resource.
func _apply_creature_data() -> void:
	creature_name = creature_data.display_name
	max_health = creature_data.max_health
	current_health = max_health
	movement_speed = creature_data.movement_speed
	damage = creature_data.damage
	armor = creature_data.armor

## --- Health ---

## Deals damage to this creature, reduced by armor.
func take_damage(amount: float) -> void:
	if not is_alive:
		return

	var effective_damage: float = max(1.0, amount - armor)
	current_health = max(0.0, current_health - effective_damage)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		die()

## Heals the creature by the given amount.
func heal(amount: float) -> void:
	if not is_alive:
		return

	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

## Kills the creature.
func die() -> void:
	if not is_alive:
		return

	is_alive = false
	died.emit()
	_on_death()

## Virtual — override in subclasses for custom death behavior.
func _on_death() -> void:
	queue_free()

## Returns the current health as a ratio 0.0–1.0.
func get_health_percentage() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health
