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
