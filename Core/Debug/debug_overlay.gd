class_name DebugOverlay
extends CanvasLayer

@export var enabled: bool = true
@export var update_interval_seconds: float = 0.2
@export var player_path: NodePath
@export var chunk_manager_path: NodePath = ^"../ChunkManager"
@export var speed_step: float = 25.0
@export var speed_hold_rate: float = 150.0
@export var speed_min: float = 0.0
@export var speed_max: float = 1000.0
@export var speed_increase_action: StringName = "debug_speed_up"
@export var speed_decrease_action: StringName = "debug_speed_down"

@onready var label: Label = $Label

var _player: Node2D = null
var _chunk_manager: ChunkManager = null
var _time_accum: float = 0.0

func _ready() -> void:
	visible = enabled
	_resolve_nodes()
	_update_text()

func _process(delta: float) -> void:
	if not enabled:
		return
	_handle_speed_input(delta)
	_time_accum += delta
	if _time_accum < update_interval_seconds:
		return
	_time_accum = 0.0
	_resolve_nodes()
	_update_text()

func _resolve_nodes() -> void:
	if player_path != NodePath():
		var found = get_node_or_null(player_path)
		if found is Node2D:
			_player = found
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Node2D:
			_player = players[0]
	if chunk_manager_path != NodePath():
		var found = get_node_or_null(chunk_manager_path)
		if found is ChunkManager:
			_chunk_manager = found

func _update_text() -> void:
	if not label:
		return
	var lines: Array[String] = []
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	if _player:
		lines.append("Player: (%.0f, %.0f)" % [_player.global_position.x, _player.global_position.y])
		lines.append("Speed: %.0f" % _player.movement_speed)
		if _player is CharacterBody2D:
			var body := _player as CharacterBody2D
			lines.append("Velocity: (%.1f, %.1f)" % [body.velocity.x, body.velocity.y])
		var state_machine := _player.get_node_or_null("StateMachine") as StateMachine
		if state_machine and state_machine.current_state:
			lines.append("State: %s" % state_machine.current_state.name)
		elif state_machine:
			lines.append("State: <none>")
		var camera = _player.get_node_or_null("Camera2D")
		if camera and camera is Camera2D:
			lines.append("Zoom: %.2f" % camera.zoom.x)
		if _chunk_manager:
			var chunk = _chunk_manager.world_to_chunk(_player.global_position)
			lines.append("Chunk: (%d, %d)" % [chunk.x, chunk.y])
	if _chunk_manager:
		var coords = _chunk_manager.get_loaded_chunk_coords()
		var coord_strings: Array[String] = []
		for coord in coords:
			coord_strings.append("(%d,%d)" % [coord.x, coord.y])
		if coord_strings.size() > 0:
			lines.append("Loaded: %d %s" % [coord_strings.size(), ", ".join(coord_strings)])
		else:
			lines.append("Loaded: 0")
	label.text = "\n".join(lines)

func _handle_speed_input(delta: float) -> void:
	if not _player:
		_resolve_nodes()
	if not _player:
		return
	if Input.is_action_just_pressed(speed_increase_action):
		_adjust_player_speed(speed_step)
	if Input.is_action_just_pressed(speed_decrease_action):
		_adjust_player_speed(-speed_step)
	var direction = Input.get_action_strength(speed_increase_action) - Input.get_action_strength(speed_decrease_action)
	if direction != 0.0 and speed_hold_rate > 0.0:
		_adjust_player_speed(direction * speed_hold_rate * delta)

func _adjust_player_speed(delta: float) -> void:
	_player.movement_speed = clamp(_player.movement_speed + delta, speed_min, speed_max)
