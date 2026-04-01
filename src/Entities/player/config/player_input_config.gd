class_name PlayerInputConfig
extends Resource

## Tunables for player input handling.

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
