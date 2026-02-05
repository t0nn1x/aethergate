class_name Player
extends Organism

## The player character
## Handles player-specific initialization and references

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var movement: PlayerMovement = $PlayerMovement
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _base_collision_offset: Vector2 = Vector2.ZERO
var _base_sprite_offset: Vector2 = Vector2.ZERO
var _base_sprite_scale: Vector2 = Vector2.ONE
var _facing_left: bool = false
var _is_moving: bool = false
var _bob_time: float = 0.0
var _flip_tween: Tween = null
var _camera_zoom_target: float = 1.0

@export var idle_bob_speed: float = 3
@export var move_bob_speed: float = 6
@export var bob_amplitude_pixels: float = 1.5
@export var flip_duration: float = 0.20
@export var camera_zoom_step: float = 0.05
@export var camera_zoom_min: float = 0.05
@export var camera_zoom_max: float = 4.0
@export var camera_zoom_hold_speed: float = 0.5
@export var camera_zoom_in_action: StringName = "camera_zoom_in"
@export var camera_zoom_out_action: StringName = "camera_zoom_out"

func _ready() -> void:
	super._ready()

	organism_name = "Player"
	max_health = 100.0
	movement_speed = 200.0
	current_health = max_health

	setup_camera()
	setup_visuals()

	# Register with game systems
	add_to_group("player")
	EventBus.player_spawned.emit(self)

func setup_visuals() -> void:
	_base_collision_offset = collision_shape.position
	_base_sprite_offset = sprite.position
	_base_sprite_scale = sprite.scale
	if animator and animator.has_animation("idle"):
		animator.play("idle")

func setup_camera() -> void:
	camera.enabled = true
	camera.zoom = Vector2(2, 2)  # Adjust based on your tile size
	camera.position_smoothing_enabled = false
	_camera_zoom_target = camera.zoom.x
	_apply_camera_zoom(_camera_zoom_target)

func set_facing(direction_x: float) -> void:
	if direction_x == 0.0:
		return
	var should_face_left = direction_x < 0.0
	if _facing_left == should_face_left:
		return
	_animate_flip(should_face_left)

func set_moving(is_moving: bool) -> void:
	_is_moving = is_moving

func _process(delta: float) -> void:
	var speed = move_bob_speed if _is_moving else idle_bob_speed
	_bob_time += delta * speed
	var offset = int(round(sin(_bob_time) * bob_amplitude_pixels))
	sprite.position = Vector2(_base_sprite_offset.x, _base_sprite_offset.y + offset)
	_apply_camera_zoom_hold(delta)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(camera_zoom_in_action):
		_apply_camera_zoom(_camera_zoom_target + camera_zoom_step)
	if Input.is_action_just_pressed(camera_zoom_out_action):
		_apply_camera_zoom(_camera_zoom_target - camera_zoom_step)

func _apply_camera_zoom_hold(delta: float) -> void:
	if camera_zoom_hold_speed <= 0.0:
		return
	var direction = Input.get_action_strength(camera_zoom_in_action) - Input.get_action_strength(camera_zoom_out_action)
	if direction == 0.0:
		return
	_apply_camera_zoom(_camera_zoom_target + direction * camera_zoom_hold_speed * delta)

func _apply_camera_zoom(value: float) -> void:
	if not camera:
		return
	_camera_zoom_target = clamp(value, camera_zoom_min, camera_zoom_max)
	var snapped = _camera_zoom_target
	if camera_zoom_step > 0.0:
		snapped = snappedf(_camera_zoom_target, camera_zoom_step)
	snapped = clamp(snapped, camera_zoom_min, camera_zoom_max)
	camera.zoom = Vector2(snapped, snapped)

func _animate_flip(should_face_left: bool) -> void:
	_facing_left = should_face_left
	if _flip_tween and _flip_tween.is_running():
		_flip_tween.kill()
	var duration = max(flip_duration, 0.01)
	var target_scale_x = _base_sprite_scale.x
	_flip_tween = create_tween()
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

func _on_death() -> void:
	print("Player died!")
	# Don't queue_free - handle respawn instead
	GameManager.change_state(GameManager.GameState.PAUSED)
