class_name PlayerMovement
extends Node
## Handles click-to-move functionality for the player.
## Uses NavigationAgent2D for pathfinding around obstacles.

signal movement_started()
signal movement_finished()
signal target_reached()

@export var speed: float = 200.0
@export var stopping_distance: float = 5.0

var _player: Player = null
var _navigation_agent: NavigationAgent2D = null
var _is_moving: bool = false
var _target_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_player = get_parent() as Player
	if not _player:
		push_error("PlayerMovement: Parent must be a Player node!")
		return
	
	# Get NavigationAgent2D directly from the player's children
	_navigation_agent = _player.get_node("NavigationAgent2D") as NavigationAgent2D
	if not _navigation_agent:
		push_error("PlayerMovement: Player must have a NavigationAgent2D child!")
		return
	
	# Wait for navigation map to be ready
	call_deferred("_setup_navigation")


## Setup navigation after the navigation map is ready
func _setup_navigation() -> void:
	# Connect to navigation finished signal
	_navigation_agent.navigation_finished.connect(_on_navigation_finished)
	_navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Ensure input processing is enabled
	set_process_input(true)
	set_process_unhandled_input(true)


func _input(event: InputEvent) -> void:
	if not _player or not _navigation_agent:
		return
	
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Check if click is on UI (to be expanded later)
			if not _is_clicking_ui():
				var target: Vector2 = _player.get_global_mouse_position()
				set_target(target)


func _physics_process(_delta: float) -> void:
	if not _is_moving or not _player or not _navigation_agent:
		return
	
	if _navigation_agent.is_navigation_finished():
		_stop_movement()
		return
	
	var next_position: Vector2 = _navigation_agent.get_next_path_position()
	var direction: Vector2 = (_player.global_position.direction_to(next_position))
	var desired_velocity: Vector2 = direction * speed
	
	# Use avoidance if enabled
	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(desired_velocity)
	else:
		_player.velocity = desired_velocity
		_player.move_and_slide()
		_update_sprite_direction(direction)


## Sets the movement target position
func set_target(target_pos: Vector2) -> void:
	if not _navigation_agent:
		return
	
	_target_position = target_pos
	_navigation_agent.target_position = target_pos
	
	if not _is_moving:
		_is_moving = true
		movement_started.emit()


## Stops all movement immediately
func stop_movement() -> void:
	_stop_movement()


## Returns true if the player is currently moving
func is_moving() -> bool:
	return _is_moving


## Returns the current target position
func get_target_position() -> Vector2:
	return _target_position


## Internal method to stop movement
func _stop_movement() -> void:
	_is_moving = false
	if _player:
		_player.velocity = Vector2.ZERO
	movement_finished.emit()


## Checks if the click is on a UI element
## Will be expanded when UI system is implemented
func _is_clicking_ui() -> bool:
	# Simple implementation - check if mouse is over a Control node
	# For now, allow all clicks
	# TODO: Implement proper UI click detection when UI is added
	return false


## Updates sprite direction based on movement
## Will be expanded when animations are added
func _update_sprite_direction(direction: Vector2) -> void:
	if not _player or not _player.sprite:
		return
	
	# Simple horizontal flip based on movement direction
	if abs(direction.x) > 0.1:
		_player.sprite.flip_h = direction.x < 0


## Callback for NavigationAgent2D velocity computed (for avoidance)
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if not _player or not _is_moving:
		return
	
	_player.velocity = safe_velocity
	_player.move_and_slide()
	
	if safe_velocity.length() > 0.1:
		_update_sprite_direction(safe_velocity.normalized())


## Callback when navigation is finished
func _on_navigation_finished() -> void:
	if _is_moving:
		target_reached.emit()
		_stop_movement()
