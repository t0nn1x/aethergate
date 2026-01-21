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
var _facing_left: bool = false
var _is_moving: bool = false
var _bob_time: float = 0.0

@export var idle_bob_speed: float = 3
@export var move_bob_speed: float = 6
@export var bob_amplitude_pixels: float = 1.5

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
	z_index = 10
	_base_collision_offset = collision_shape.position
	_base_sprite_offset = sprite.position
	if animator and animator.has_animation("idle"):
		animator.play("idle")

func setup_camera() -> void:
	camera.enabled = true
	camera.zoom = Vector2(2, 2)  # Adjust based on your tile size
	camera.position_smoothing_enabled = false

func set_facing(direction_x: float) -> void:
	if direction_x == 0.0:
		return
	var should_face_left = direction_x < 0.0
	if _facing_left == should_face_left:
		return
	_facing_left = should_face_left
	sprite.flip_h = _facing_left
	collision_shape.position = Vector2(
		_base_collision_offset.x * (-1 if _facing_left else 1),
		_base_collision_offset.y
	)

func set_moving(is_moving: bool) -> void:
	_is_moving = is_moving

func _process(delta: float) -> void:
	var speed = move_bob_speed if _is_moving else idle_bob_speed
	_bob_time += delta * speed
	var offset = int(round(sin(_bob_time) * bob_amplitude_pixels))
	sprite.position = Vector2(_base_sprite_offset.x, _base_sprite_offset.y + offset)

func _on_death() -> void:
	print("Player died!")
	# Don't queue_free - handle respawn instead
	GameManager.change_state(GameManager.GameState.PAUSED)
