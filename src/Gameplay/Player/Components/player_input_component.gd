class_name PlayerInputComponent
extends Node

## Coordinates player move input and delegates move application to PlayerMoveRequestService.

signal move_target_queued(world_position: Vector2, from_hold: bool)
signal pointer_hold_changed(is_held: bool)

const MOBILE_FEATURES: PackedStringArray = ["android", "ios", "mobile"]

var creature: Creature

@export var move_request_service_path: NodePath = ^"PlayerMoveRequestService"
@export var input_config: PlayerInputConfig = preload("res://src/Gameplay/Player/Config/player_input_config.tres")

@export var click_move_action: StringName = "click_move"
@export var hold_retarget_enabled: bool = true
@export var touch_hold_retarget_enabled_mobile: bool = false
@export var touch_tap_max_drag_distance: float = 12.0
@export var hold_retarget_interval: float = 0.06
@export var hold_retarget_min_distance: float = 8.0
@export var reject_targets_inside_navigation_polygons: bool = true
@export var disable_move_while_multitouch: bool = true

var _is_pointer_held: bool = false
var _active_touch_index: int = -1
var _last_pointer_screen_position: Vector2 = Vector2.ZERO
var _hold_retarget_timer: float = 0.0
var _has_last_hold_target: bool = false
var _last_hold_target_world: Vector2 = Vector2.ZERO

var _move_request_service: PlayerMoveRequestService
var _mouse_adapter: PlayerMouseInputAdapter = PlayerMouseInputAdapter.new()
var _touch_adapter: PlayerTouchInputAdapter = PlayerTouchInputAdapter.new()


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerInputComponent must be a child of a Creature.")

	_apply_input_config()
	_move_request_service = creature.get_node_or_null(move_request_service_path) as PlayerMoveRequestService
	if _move_request_service:
		_sync_move_request_service_config()
		if not _move_request_service.move_target_queued.is_connected(_on_move_target_queued):
			_move_request_service.move_target_queued.connect(_on_move_target_queued)
	elif OS.is_debug_build():
		push_warning("PlayerInputComponent: PlayerMoveRequestService is missing.")


func _process(delta: float) -> void:
	if not _should_process_hold_retarget():
		return
	_sync_pointer_position_for_hold_retarget()
	_hold_retarget_timer -= delta
	if _hold_retarget_timer > 0.0:
		return
	_hold_retarget_timer = maxf(hold_retarget_interval, 0.01)
	_queue_hold_retarget_target()


func _unhandled_input(event: InputEvent) -> void:
	if not creature or not creature.is_alive:
		return

	if event is InputEventMouseButton:
		_mouse_adapter.handle_button(self, event as InputEventMouseButton, click_move_action)
		return

	if event is InputEventMouseMotion:
		_mouse_adapter.handle_motion(self, event as InputEventMouseMotion)
		return

	if event is InputEventScreenTouch:
		_touch_adapter.handle_touch(
			self,
			event as InputEventScreenTouch,
			disable_move_while_multitouch,
			touch_tap_max_drag_distance
		)
		return

	if event is InputEventScreenDrag:
		_touch_adapter.handle_drag(self, event as InputEventScreenDrag, disable_move_while_multitouch)


## Backward-compatible legacy API (move requests are now applied by service immediately).
func consume_move_target_request() -> Variant:
	return null


func _should_process_hold_retarget() -> bool:
	if not _is_pointer_held:
		return false
	if not creature or not creature.is_alive:
		return false
	if _active_touch_index == -1:
		if not hold_retarget_enabled:
			return false
	elif not _is_touch_hold_retarget_enabled():
		return false
	if disable_move_while_multitouch and _touch_adapter.is_multi_touch_active():
		return false
	return true


func _sync_pointer_position_for_hold_retarget() -> void:
	if _active_touch_index != -1:
		return
	var viewport := creature.get_viewport()
	if viewport:
		_last_pointer_screen_position = viewport.get_mouse_position()


func _queue_hold_retarget_target() -> void:
	if _active_touch_index == -1:
		_queue_move_target_world(_get_mouse_world_position(), _last_pointer_screen_position, true)
		return
	_queue_move_target(_last_pointer_screen_position, true)


func _queue_move_target(screen_position: Vector2, from_hold: bool) -> void:
	var world_position: Vector2 = _screen_to_world(screen_position)
	_queue_move_target_world(world_position, screen_position, from_hold)


func _queue_move_target_world(world_position: Vector2, screen_position: Vector2, from_hold: bool) -> void:
	if _is_pointer_over_ui(screen_position):
		return
	if from_hold and _has_last_hold_target:
		var min_distance: float = maxf(hold_retarget_min_distance, 0.0)
		if world_position.distance_to(_last_hold_target_world) < min_distance:
			return
	if _move_request_service == null:
		return

	_sync_move_request_service_config()
	var accepted_target: Variant = _move_request_service.request_move_target(world_position, from_hold)
	if accepted_target is Vector2:
		_last_hold_target_world = world_position
		_has_last_hold_target = true


func _screen_to_world(screen_position: Vector2) -> Vector2:
	var viewport := creature.get_viewport()
	if viewport == null:
		return creature.global_position
	return viewport.get_canvas_transform().affine_inverse() * screen_position


func _get_mouse_viewport_position(fallback_position: Vector2) -> Vector2:
	var viewport := creature.get_viewport()
	if viewport == null:
		return fallback_position
	return viewport.get_mouse_position()


func _get_mouse_world_position() -> Vector2:
	if creature == null:
		return Vector2.ZERO
	return creature.get_global_mouse_position()


func _is_pointer_over_ui(_screen_position: Vector2) -> bool:
	var viewport := creature.get_viewport()
	if viewport == null:
		return false

	var hovered: Control = viewport.gui_get_hovered_control()
	if hovered and hovered.is_visible_in_tree():
		return true

	var focused: Control = viewport.gui_get_focus_owner()
	return focused != null and focused.is_visible_in_tree()


func _set_pointer_held(value: bool, touch_index: int = -1) -> void:
	var was_held: bool = _is_pointer_held
	_is_pointer_held = value
	_active_touch_index = touch_index if value else -1
	_hold_retarget_timer = 0.0
	if not value:
		_has_last_hold_target = false
	if was_held != _is_pointer_held:
		pointer_hold_changed.emit(_is_pointer_held)


func _is_touch_hold_retarget_enabled() -> bool:
	if _is_mobile_platform():
		return touch_hold_retarget_enabled_mobile
	return hold_retarget_enabled


func _is_mobile_platform() -> bool:
	for feature in MOBILE_FEATURES:
		if OS.has_feature(feature):
			return true
	return false


func _on_move_target_queued(world_position: Vector2, from_hold: bool) -> void:
	move_target_queued.emit(world_position, from_hold)


func _sync_move_request_service_config() -> void:
	if _move_request_service:
		_move_request_service.reject_targets_inside_navigation_polygons = reject_targets_inside_navigation_polygons


func _apply_input_config() -> void:
	if input_config == null:
		return
	click_move_action = input_config.click_move_action
	hold_retarget_enabled = input_config.hold_retarget_enabled
	touch_hold_retarget_enabled_mobile = input_config.touch_hold_retarget_enabled_mobile
	touch_tap_max_drag_distance = input_config.touch_tap_max_drag_distance
	hold_retarget_interval = input_config.hold_retarget_interval
	hold_retarget_min_distance = input_config.hold_retarget_min_distance
	reject_targets_inside_navigation_polygons = input_config.reject_targets_inside_navigation_polygons
	disable_move_while_multitouch = input_config.disable_move_while_multitouch
