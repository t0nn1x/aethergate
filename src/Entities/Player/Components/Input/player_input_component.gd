class_name PlayerInputComponent
extends Node

## Coordinates player move input and delegates move application to PlayerMoveRequestService.

const FULL_PHYSICS_MASK: int = 2147483647
const CREATURE_PRESS_FEEDBACK_SCRIPT: Script = preload(
	"res://src/Entities/Creatures/Effects/creature_press_feedback.gd"
)

signal move_target_queued(world_position: Vector2, from_hold: bool)
signal pointer_hold_changed(is_held: bool)

var creature: Creature

@export var move_request_service_path: NodePath = ^"PlayerMoveRequestService"
@export var project_config_service_path: NodePath = ^"/root/ProjectConfig"
@export var input_config = preload("res://src/Entities/Player/Config/player_input_config.tres")

@export var click_move_action: StringName = "click_move"
@export var hold_retarget_enabled: bool = true
@export var touch_hold_retarget_enabled_mobile: bool = false
@export var touch_tap_max_drag_distance: float = 12.0
@export var hold_retarget_interval: float = 0.06
@export var hold_retarget_min_distance: float = 8.0
@export var reject_targets_inside_navigation_polygons: bool = true
@export var disable_move_while_multitouch: bool = true
@export var enable_creature_tap_selection: bool = true
@export_flags_2d_physics var creature_tap_collision_mask: int = 3
@export_range(1, 32, 1) var creature_tap_max_results: int = 8
@export_range(1.0, 64.0, 1.0) var creature_tap_pick_radius: float = 12.0
@export var consume_ground_tap_while_creature_selected: bool = true

var _is_pointer_held: bool = false
var _active_touch_index: int = -1
var _last_pointer_screen_position: Vector2 = Vector2.ZERO
var _hold_retarget_timer: float = 0.0
var _has_last_hold_target: bool = false
var _last_hold_target_world: Vector2 = Vector2.ZERO
var _selected_creature: Creature = null

var _move_request_service: PlayerMoveRequestService
var _platform_profile: GamePlatformProfile
var _allow_mouse_pointer_input: bool = true
var _allow_touch_input: bool = true
var _mouse_adapter: PlayerMouseInputAdapter = PlayerMouseInputAdapter.new()
var _touch_adapter: PlayerTouchInputAdapter = PlayerTouchInputAdapter.new()
var _creature_pick_shape: CircleShape2D = CircleShape2D.new()


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerInputComponent must be a child of a Creature.")

	_apply_project_config()
	_apply_input_config()
	_move_request_service = creature.get_node_or_null(move_request_service_path) as PlayerMoveRequestService
	if _move_request_service:
		_sync_move_request_service_config()
		if not _move_request_service.move_target_queued.is_connected(_on_move_target_queued):
			_move_request_service.move_target_queued.connect(_on_move_target_queued)
	elif OS.is_debug_build():
		push_warning("PlayerInputComponent: PlayerMoveRequestService is missing.")


func _process(delta: float) -> void:
	if not _has_input_authority():
		return

	_refresh_local_creature_selection_state()
	if _is_movement_blocked_by_ui():
		if _is_pointer_held:
			_set_pointer_held(false)
		return
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
	if not _has_input_authority():
		return
	if _is_movement_blocked_by_ui():
		if _is_pointer_held:
			_set_pointer_held(false)
		return

	if event is InputEventMouseButton:
		if not _allow_mouse_pointer_input:
			return
		var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
		_mouse_adapter.handle_button(self, mouse_button_event, click_move_action)
		return

	if event is InputEventMouseMotion:
		if not _allow_mouse_pointer_input:
			return
		var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		_mouse_adapter.handle_motion(self, mouse_motion_event)
		return

	if event is InputEventScreenTouch:
		if not _allow_touch_input:
			return
		_touch_adapter.handle_touch(
			self,
			event as InputEventScreenTouch,
			disable_move_while_multitouch,
			touch_tap_max_drag_distance
		)
		return

	if event is InputEventScreenDrag:
		if not _allow_touch_input:
			return
		_touch_adapter.handle_drag(self, event as InputEventScreenDrag, disable_move_while_multitouch)


## Backward-compatible legacy API (move requests are now applied by service immediately).
func consume_move_target_request() -> Variant:
	return null


func _should_process_hold_retarget() -> bool:
	if consume_ground_tap_while_creature_selected and _selected_creature != null:
		return false
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
	var viewport: Viewport = creature.get_viewport()
	if viewport:
		_last_pointer_screen_position = viewport.get_mouse_position()


func _queue_hold_retarget_target() -> void:
	_queue_move_target(_last_pointer_screen_position, true)


func _queue_move_target(screen_position: Vector2, from_hold: bool) -> void:
	var world_position: Vector2 = _screen_to_world(screen_position)
	_queue_move_target_world(world_position, screen_position, from_hold)


func _try_select_creature_at_screen_position(screen_position: Vector2) -> bool:
	if not enable_creature_tap_selection:
		return false
	if _is_pointer_over_ui(screen_position):
		return false

	var selected_creature: Creature = _find_creature_at_screen_position(screen_position)
	if selected_creature == null:
		if consume_ground_tap_while_creature_selected and _selected_creature != null:
			_emit_creature_deselected_event()
			return true
		return false

	_emit_creature_selected_event(selected_creature)
	return true


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
		_last_hold_target_world = accepted_target as Vector2
		_has_last_hold_target = true


func _screen_to_world(screen_position: Vector2) -> Vector2:
	var viewport: Viewport = creature.get_viewport()
	if viewport == null:
		return creature.global_position
	return viewport.get_canvas_transform().affine_inverse() * screen_position


func _find_creature_at_screen_position(screen_position: Vector2) -> Creature:
	if creature == null:
		return null

	var world_position: Vector2 = _screen_to_world(screen_position)
	var world_2d: World2D = creature.get_world_2d()
	if world_2d == null:
		return null

	var space_state: PhysicsDirectSpaceState2D = world_2d.direct_space_state
	if space_state == null:
		return null

	_creature_pick_shape.radius = maxf(creature_tap_pick_radius, 1.0)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _creature_pick_shape
	query.transform = Transform2D(0.0, world_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [creature.get_rid()]
	var requested_mask: int = creature_tap_collision_mask
	if requested_mask <= 0:
		requested_mask = FULL_PHYSICS_MASK

	query.collision_mask = requested_mask
	var hits: Array[Dictionary] = _intersect_shape_with_limit(space_state, query)
	if hits.is_empty() and requested_mask != FULL_PHYSICS_MASK:
		query.collision_mask = FULL_PHYSICS_MASK
		hits = _intersect_shape_with_limit(space_state, query)
	var nearest: Creature = null
	var nearest_distance_sq: float = INF
	for hit in hits:
		var collider: Node = hit.get("collider", null) as Node
		var candidate: Creature = collider as Creature
		if candidate == null:
			continue
		if candidate.is_in_group("player"):
			continue
		if not candidate.is_alive:
			continue
		if candidate.is_queued_for_deletion():
			continue

		var distance_sq: float = candidate.global_position.distance_squared_to(world_position)
		if nearest == null or distance_sq < nearest_distance_sq:
			nearest = candidate
			nearest_distance_sq = distance_sq

	return nearest


func _intersect_shape_with_limit(
	space_state: PhysicsDirectSpaceState2D,
	query: PhysicsShapeQueryParameters2D
) -> Array[Dictionary]:
	return space_state.intersect_shape(
		query,
		maxi(creature_tap_max_results, 1)
	)


func _emit_creature_selected_event(selected_creature: Creature) -> void:
	_selected_creature = selected_creature
	_spawn_creature_press_feedback(selected_creature)

	CreatureEvents.creature_selected.emit(selected_creature)


func _emit_creature_deselected_event() -> void:
	_selected_creature = null
	CreatureEvents.creature_deselected.emit()


func _spawn_creature_press_feedback(target_creature: Creature) -> void:
	if target_creature == null or not is_instance_valid(target_creature):
		return
	if CREATURE_PRESS_FEEDBACK_SCRIPT == null:
		return

	var feedback_node: Node2D = CREATURE_PRESS_FEEDBACK_SCRIPT.new() as Node2D
	if feedback_node == null:
		return

	var parent_node: Node = target_creature.get_parent()
	if parent_node == null:
		return

	parent_node.add_child(feedback_node)
	feedback_node.global_position = target_creature.global_position


func _is_pointer_over_ui(_screen_position: Vector2) -> bool:
	var viewport: Viewport = creature.get_viewport()
	if viewport == null:
		return false

	var hovered: Control = viewport.gui_get_hovered_control()
	if _is_interactive_ui_control_at_position(hovered, _screen_position):
		return true

	var focused: Control = viewport.gui_get_focus_owner()
	return _is_interactive_ui_control_at_position(focused, _screen_position)


func _is_movement_blocked_by_ui() -> bool:
	var scene_tree: SceneTree = get_tree()
	if scene_tree == null:
		return false

	var blockers: Array[Node] = scene_tree.get_nodes_in_group("ui_panels_block_movement")
	for blocker in blockers:
		if blocker == null or not is_instance_valid(blocker):
			continue
		if blocker is CanvasLayer:
			if (blocker as CanvasLayer).visible:
				return true
			continue
		if blocker is Control and (blocker as Control).is_visible_in_tree():
			return true
	return false


func _is_interactive_ui_control_at_position(control: Control, screen_position: Vector2) -> bool:
	if control == null:
		return false
	if not control.is_visible_in_tree():
		return false
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false

	var global_rect: Rect2 = control.get_global_rect()
	return global_rect.has_point(screen_position)


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
	if _platform_profile != null:
		return _platform_profile.touch_hold_retarget_enabled
	return touch_hold_retarget_enabled_mobile


func _on_move_target_queued(world_position: Vector2, from_hold: bool) -> void:
	move_target_queued.emit(world_position, from_hold)


func _sync_move_request_service_config() -> void:
	if _move_request_service:
		_move_request_service.reject_targets_inside_navigation_polygons = reject_targets_inside_navigation_polygons


func _refresh_local_creature_selection_state() -> void:
	if _selected_creature == null:
		return
	if not is_instance_valid(_selected_creature):
		_selected_creature = null
		return
	if _selected_creature.is_queued_for_deletion():
		_selected_creature = null
		return
	if not _selected_creature.is_alive:
		_selected_creature = null


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
	enable_creature_tap_selection = input_config.enable_creature_tap_selection
	creature_tap_collision_mask = input_config.creature_tap_collision_mask
	creature_tap_max_results = input_config.creature_tap_max_results
	creature_tap_pick_radius = input_config.creature_tap_pick_radius
	consume_ground_tap_while_creature_selected = input_config.consume_ground_tap_while_creature_selected


func _apply_project_config() -> void:
	var project_config_service: ProjectConfigService = _resolve_project_config_service()
	if project_config_service == null:
		if OS.is_debug_build():
			push_warning("PlayerInputComponent: ProjectConfig autoload is missing.")
		return

	var project_input_config = project_config_service.get_player_input_config()
	if project_input_config != null:
		input_config = project_input_config

	_platform_profile = project_config_service.get_platform_profile()
	if _platform_profile == null:
		return

	_allow_mouse_pointer_input = _platform_profile.allow_mouse_pointer_input
	_allow_touch_input = _platform_profile.allow_touch_input


func _resolve_project_config_service() -> ProjectConfigService:
	if project_config_service_path == NodePath():
		return null
	return get_node_or_null(project_config_service_path) as ProjectConfigService


func _has_input_authority() -> bool:
	if creature == null:
		return false
	if creature.has_method("has_input_authority"):
		return bool(creature.call("has_input_authority"))
	return true
