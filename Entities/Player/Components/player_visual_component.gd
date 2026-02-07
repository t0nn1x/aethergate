class_name PlayerVisualComponent
extends Node

## Handles player sprite bobbing, flip animation, and silhouette sync.
## Extracted from player.gd to follow the component pattern.

var creature: Creature

@onready var sprite: Sprite2D
@onready var silhouette: Sprite2D
@onready var collision_shape: CollisionShape2D

var _base_collision_offset: Vector2 = Vector2.ZERO
var _base_sprite_offset: Vector2 = Vector2.ZERO
var _base_sprite_scale: Vector2 = Vector2.ONE
var _facing_left: bool = false
var _is_moving: bool = false
var _bob_time: float = 0.0
var _flip_tween: Tween = null

@export var idle_bob_speed: float = 3.0
@export var move_bob_speed: float = 6.0
@export var bob_amplitude_pixels: float = 1.5
@export var flip_duration: float = 0.20

func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerVisualComponent must be a child of a Creature.")

	sprite = creature.get_node("Sprite2D") as Sprite2D
	silhouette = creature.get_node_or_null("Silhouette") as Sprite2D
	collision_shape = creature.get_node("CollisionShape2D") as CollisionShape2D

	_base_collision_offset = collision_shape.position
	_base_sprite_offset = sprite.position
	_base_sprite_scale = sprite.scale

	# Start idle animation if available.
	var animator: AnimationPlayer = creature.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animator and animator.has_animation("idle"):
		animator.play("idle")

func _process(delta: float) -> void:
	var speed: float = move_bob_speed if _is_moving else idle_bob_speed
	_bob_time += delta * speed
	var offset: int = int(round(sin(_bob_time) * bob_amplitude_pixels))
	sprite.position = Vector2(_base_sprite_offset.x, _base_sprite_offset.y + offset)
	_sync_silhouette()

## Set facing direction based on horizontal movement.
func set_facing(direction_x: float) -> void:
	if direction_x == 0.0:
		return
	var should_face_left: bool = direction_x < 0.0
	if _facing_left == should_face_left:
		return
	_animate_flip(should_face_left)

## Toggle moving state (affects bob speed).
func set_moving(moving: bool) -> void:
	_is_moving = moving

func _animate_flip(should_face_left: bool) -> void:
	_facing_left = should_face_left
	if _flip_tween and _flip_tween.is_running():
		_flip_tween.kill()
	var duration: float = max(flip_duration, 0.01)
	var target_scale_x: float = _base_sprite_scale.x

	# Instantly hide silhouette for the entire flip.
	if silhouette:
		silhouette.modulate.a = 0.0

	_flip_tween = creature.create_tween()
	_flip_tween.set_trans(Tween.TRANS_SINE)
	_flip_tween.set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(sprite, "scale:x", 0.0, duration * 0.5)
	_flip_tween.tween_callback(func() -> void:
		sprite.flip_h = _facing_left
		collision_shape.position = Vector2(
			_base_collision_offset.x * (-1 if _facing_left else 1),
			_base_collision_offset.y
		)
	)
	_flip_tween.tween_property(sprite, "scale:x", target_scale_x, duration * 0.5)
	# Restore silhouette after flip fully completes.
	_flip_tween.tween_callback(func() -> void:
		if silhouette:
			silhouette.modulate.a = 1.0
	)

## Keeps the silhouette sprite in sync with the main sprite.
func _sync_silhouette() -> void:
	if not silhouette:
		return
	silhouette.position = sprite.position
	silhouette.frame = sprite.frame
	silhouette.flip_h = sprite.flip_h
	silhouette.scale = sprite.scale
