class_name PlayerCameraComponent
extends Node

## Handles smooth camera zoom input for the player.

const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]

var creature: Creature
var camera: Camera2D
var _camera_zoom_target: float = 1.0
var _zoom_in_fallback_was_down: bool = false
var _zoom_out_fallback_was_down: bool = false

@export var camera_zoom_step: float = 0.2
@export var camera_zoom_min: float = 1.0
@export var camera_zoom_max: float = 6.0
@export var camera_zoom_hold_speed: float = 2.0
@export var camera_zoom_smooth_speed: float = 12.0
@export var camera_zoom_snap_threshold: float = 0.01
@export var camera_zoom_in_action: StringName = "camera_zoom_in"
@export var camera_zoom_out_action: StringName = "camera_zoom_out"
@export var default_zoom_mobile: float = 4.0
@export var default_zoom_desktop: float = 3.0


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerCameraComponent must be a child of a Creature.")

	camera = creature.get_node("Camera2D") as Camera2D
	assert(camera, "Player scene must have a Camera2D node.")

	camera.enabled = true
	camera.position_smoothing_enabled = false

	var startup_zoom: float = clampf(_get_default_zoom_for_platform(), camera_zoom_min, camera_zoom_max)
	_camera_zoom_target = startup_zoom
	camera.zoom = Vector2(_camera_zoom_target, _camera_zoom_target)


func _process(delta: float) -> void:
	_apply_camera_zoom_discrete_input()
	_apply_camera_zoom_hold(delta)
	_update_camera_zoom_smoothing(delta)


func _input(event: InputEvent) -> void:
	if _handle_mouse_wheel_zoom(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	_handle_mouse_wheel_zoom(event)


func _apply_camera_zoom_discrete_input() -> void:
	var zoom_in_pressed: bool = Input.is_action_just_pressed(camera_zoom_in_action) or _consume_zoom_in_fallback_press()
	var zoom_out_pressed: bool = Input.is_action_just_pressed(camera_zoom_out_action) or _consume_zoom_out_fallback_press()

	if zoom_in_pressed:
		_apply_camera_zoom(_camera_zoom_target + camera_zoom_step)
	if zoom_out_pressed:
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

	_camera_zoom_target = clampf(value, camera_zoom_min, camera_zoom_max)


func _update_camera_zoom_smoothing(delta: float) -> void:
	if not camera:
		return

	var current_zoom: float = camera.zoom.x
	if absf(_camera_zoom_target - current_zoom) <= camera_zoom_snap_threshold:
		if current_zoom != _camera_zoom_target:
			camera.zoom = Vector2(_camera_zoom_target, _camera_zoom_target)
		return

	if camera_zoom_smooth_speed <= 0.0:
		camera.zoom = Vector2(_camera_zoom_target, _camera_zoom_target)
		return

	var blend: float = 1.0 - exp(-camera_zoom_smooth_speed * delta)
	var next_zoom: float = lerpf(current_zoom, _camera_zoom_target, clampf(blend, 0.0, 1.0))
	camera.zoom = Vector2(next_zoom, next_zoom)


func _get_default_zoom_for_platform() -> float:
	for feature in DESKTOP_FEATURES:
		if OS.has_feature(feature):
			return default_zoom_desktop
	return default_zoom_mobile


func _consume_zoom_in_fallback_press() -> bool:
	var is_down: bool = (
		Input.is_key_pressed(KEY_EQUAL)
		or Input.is_physical_key_pressed(KEY_EQUAL)
		or Input.is_key_pressed(KEY_KP_ADD)
		or Input.is_key_pressed(KEY_PAGEUP)
	)
	var just_pressed: bool = is_down and not _zoom_in_fallback_was_down
	_zoom_in_fallback_was_down = is_down
	return just_pressed


func _consume_zoom_out_fallback_press() -> bool:
	var is_down: bool = (
		Input.is_key_pressed(KEY_MINUS)
		or Input.is_physical_key_pressed(KEY_MINUS)
		or Input.is_key_pressed(KEY_KP_SUBTRACT)
		or Input.is_key_pressed(KEY_PAGEDOWN)
	)
	var just_pressed: bool = is_down and not _zoom_out_fallback_was_down
	_zoom_out_fallback_was_down = is_down
	return just_pressed


func _handle_mouse_wheel_zoom(event: InputEvent) -> bool:
	if event is not InputEventMouseButton:
		return false
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return false
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_apply_camera_zoom(_camera_zoom_target + camera_zoom_step)
		return true
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_apply_camera_zoom(_camera_zoom_target - camera_zoom_step)
		return true
	return false
