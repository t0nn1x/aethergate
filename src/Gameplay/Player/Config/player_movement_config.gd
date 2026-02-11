class_name PlayerMovementConfig
extends Resource

## Tunables for navigation-driven movement.

@export var path_desired_distance: float = 4.0
@export var target_desired_distance: float = 6.0
@export var avoidance_enabled: bool = true
@export var agent_radius: float = 14.0
@export var max_target_snap_distance: float = 2048.0
