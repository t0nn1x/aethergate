class_name PlayerCameraComponent
extends Node

## Handles camera zoom controls for the player.

const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]

var creature: Creature
var camera: Camera2D
var _zoom_target: float = 4.0

@export var camera_zoom_step: float = 1.0
@export var camera_zoom_min: float = 3.0
@export var camera_zoom_max: float = 6.0
@export var camera_zoom_hold_speed: float = 1.0
@export var camera_zoom_smooth_speed: float = 12.0
@export var camera_zoom_snap_threshold: float = 0.001
@export var camera_zoom_in_action: StringName = "camera_zoom_in"
@export var camera_zoom_out_action: StringName = "camera_zoom_out"
@export var default_zoom_mobile: float = 4.0
@export var default_zoom_desktop: float = 4.0


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerCameraComponent must be a child of a Creature.")

	camera = creature.get_node("Camera2D") as Camera2D
	assert(camera, "Player scene must have a Camera2D node.")

	camera.enabled = true
	camera.position_smoothing_enabled = false

	_zoom_target = _sanitize_zoom(_get_default_zoom_for_platform())
	camera.zoom = Vector2(_zoom_target, _zoom_target)


func _process(delta: float) -> void:
	_apply_camera_zoom_hold(delta)
	_update_zoom_smoothing(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _handle_mouse_wheel_zoom(event):
		return
	if Input.is_action_just_pressed(camera_zoom_in_action):
		_set_zoom_target(_zoom_target + camera_zoom_step)
	if Input.is_action_just_pressed(camera_zoom_out_action):
		_set_zoom_target(_zoom_target - camera_zoom_step)


func _apply_camera_zoom_hold(delta: float) -> void:
	if camera_zoom_hold_speed <= 0.0:
		return
	var axis: float = Input.get_action_strength(camera_zoom_in_action) - Input.get_action_strength(camera_zoom_out_action)
	if axis == 0.0:
		return
	_set_zoom_target(_zoom_target + axis * camera_zoom_hold_speed * delta)


func _update_zoom_smoothing(delta: float) -> void:
	if not camera:
		return

	var current_zoom: float = camera.zoom.x
	if absf(current_zoom - _zoom_target) <= camera_zoom_snap_threshold:
		if current_zoom != _zoom_target:
			camera.zoom = Vector2(_zoom_target, _zoom_target)
		return

	if camera_zoom_smooth_speed <= 0.0:
		camera.zoom = Vector2(_zoom_target, _zoom_target)
		return

	var blend: float = 1.0 - exp(-camera_zoom_smooth_speed * delta)
	var next_zoom: float = lerpf(current_zoom, _zoom_target, clampf(blend, 0.0, 1.0))
	camera.zoom = Vector2(next_zoom, next_zoom)


func _set_zoom_target(value: float) -> void:
	_zoom_target = _sanitize_zoom(value)


func _sanitize_zoom(value: float) -> float:
	var clamped: float = clampf(value, camera_zoom_min, camera_zoom_max)
	if camera_zoom_step > 0.0:
		clamped = snappedf(clamped, camera_zoom_step)
	return clampf(clamped, camera_zoom_min, camera_zoom_max)


func _get_default_zoom_for_platform() -> float:
	for feature in DESKTOP_FEATURES:
		if OS.has_feature(feature):
			return default_zoom_desktop
	return default_zoom_mobile


func _handle_mouse_wheel_zoom(event: InputEvent) -> bool:
	if event is not InputEventMouseButton:
		return false
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return false
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_zoom_target(_zoom_target + camera_zoom_step)
		return true
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_zoom_target(_zoom_target - camera_zoom_step)
		return true
	return false
