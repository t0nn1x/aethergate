class_name PlayerCameraComponent
extends Node

## Handles camera zoom (scroll + hold) for the player.

const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]

var creature: Creature
var camera: Camera2D
var _camera_zoom_target: float = 1.0

@export var camera_zoom_step: float = 0.05
@export var camera_zoom_min: float = 0.05
@export var camera_zoom_max: float = 4.0
@export var camera_zoom_hold_speed: float = 0.5
@export var camera_zoom_in_action: StringName = "camera_zoom_in"
@export var camera_zoom_out_action: StringName = "camera_zoom_out"
@export var default_zoom_mobile: float = 4.0
@export var default_zoom_desktop: float = 2.5

func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerCameraComponent must be a child of a Creature.")

	camera = creature.get_node("Camera2D") as Camera2D
	assert(camera, "Player scene must have a Camera2D node.")

	camera.enabled = true
	var startup_zoom := _get_default_zoom_for_platform()
	camera.zoom = Vector2(startup_zoom, startup_zoom)
	camera.position_smoothing_enabled = false
	_camera_zoom_target = camera.zoom.x
	_apply_camera_zoom(_camera_zoom_target)

func _process(delta: float) -> void:
	_apply_camera_zoom_hold(delta)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(camera_zoom_in_action):
		_apply_camera_zoom(_camera_zoom_target + camera_zoom_step)
	if Input.is_action_just_pressed(camera_zoom_out_action):
		_apply_camera_zoom(_camera_zoom_target - camera_zoom_step)

func _apply_camera_zoom_hold(delta: float) -> void:
	if camera_zoom_hold_speed <= 0.0:
		return
	var direction: float = Input.get_action_strength(camera_zoom_in_action) - Input.get_action_strength(camera_zoom_out_action)
	if direction == 0.0:
		return
	_apply_camera_zoom(_camera_zoom_target + direction * camera_zoom_hold_speed * delta)

func _apply_camera_zoom(value: float) -> void:
	if not camera:
		return
	_camera_zoom_target = clamp(value, camera_zoom_min, camera_zoom_max)
	var snapped_zoom: float = _camera_zoom_target
	if camera_zoom_step > 0.0:
		snapped_zoom = snappedf(_camera_zoom_target, camera_zoom_step)
	snapped_zoom = clamp(snapped_zoom, camera_zoom_min, camera_zoom_max)
	camera.zoom = Vector2(snapped_zoom, snapped_zoom)

func _get_default_zoom_for_platform() -> float:
	for feature in DESKTOP_FEATURES:
		if OS.has_feature(feature):
			return default_zoom_desktop
	return default_zoom_mobile
