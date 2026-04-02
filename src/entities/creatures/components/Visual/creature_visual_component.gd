class_name CreatureVisualComponent
extends Node

## Handles creature-facing visual behavior (bob, flip, silhouette sync, idle animation).

const Creature = preload("res://src/entities/creatures/base/creature.gd")
const CreatureData = preload("res://src/entities/creatures/base/creature_data.gd")

var creature: Creature

@onready var _sprite: Sprite2D
@onready var _silhouette: Sprite2D

var _base_sprite_offset: Vector2 = Vector2.ZERO
var _is_moving: bool = false
var _facing_left: bool = false
var _bob_time: float = 0.0
var _anim_time: float = 0.0

@export var idle_bob_speed: float = 2.5
@export var move_bob_speed: float = 5.0
@export var bob_amplitude_pixels: float = 1.2


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "CreatureVisualComponent must be a child of Creature.")

	_sprite = creature.get_node_or_null("Sprite2D") as Sprite2D
	_silhouette = creature.get_node_or_null("Silhouette") as Sprite2D

	if _sprite == null:
		push_warning("CreatureVisualComponent: Sprite2D node is missing.")
		return

	_base_sprite_offset = _sprite.position
	if not creature.creature_data_applied.is_connected(_on_creature_data_applied):
		creature.creature_data_applied.connect(_on_creature_data_applied)
	if creature.creature_data:
		_on_creature_data_applied(creature.creature_data)


func _process(delta: float) -> void:
	if _sprite == null:
		return

	var speed: float = move_bob_speed if _is_moving else idle_bob_speed
	_bob_time += delta * speed
	var offset_y: float = sin(_bob_time) * bob_amplitude_pixels
	_sprite.position = Vector2(_base_sprite_offset.x, _base_sprite_offset.y + offset_y)

	_advance_idle_animation(delta)
	_sync_silhouette()


func set_facing(direction_x: float) -> void:
	if _sprite == null or direction_x == 0.0:
		return
	_facing_left = direction_x < 0.0
	_sprite.flip_h = _facing_left


func set_moving(moving: bool) -> void:
	_is_moving = moving


func _advance_idle_animation(delta: float) -> void:
	if creature == null or creature.creature_data == null:
		return

	var frame_count: int = _sprite.hframes * _sprite.vframes
	if frame_count <= 1:
		return

	var fps: float = maxf(creature.creature_data.idle_animation_fps, 0.1)
	_anim_time += delta * fps
	var cycle_index: int = int(floor(_anim_time)) % frame_count
	var start_frame: int = clampi(creature.creature_data.default_frame, 0, frame_count - 1)
	_sprite.frame = (start_frame + cycle_index) % frame_count


func _sync_silhouette() -> void:
	if _silhouette == null or _sprite == null:
		return
	_silhouette.position = _sprite.position
	_silhouette.frame = _sprite.frame
	_silhouette.flip_h = _sprite.flip_h


func _on_creature_data_applied(_data: CreatureData) -> void:
	_anim_time = 0.0
