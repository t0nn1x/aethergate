class_name DebugOverlay
extends CanvasLayer

@export var enabled: bool = true
@export var update_interval_seconds: float = 0.2
@export var player_path: NodePath
@export var chunk_manager_path: NodePath = ^"../ChunkManager"
@export var creature_spawner_path: NodePath = ^"../OverworldCreatureSpawner"
@export var speed_step: float = 25.0
@export var speed_hold_rate: float = 150.0
@export var speed_min: float = 0.0
@export var speed_max: float = 1000.0
@export var speed_increase_action: StringName = "debug_speed_up"
@export var speed_decrease_action: StringName = "debug_speed_down"
@export var screen_padding: Vector2 = Vector2(8.0, 8.0)

@onready var label: Label = $Label

var _player: Node2D = null
var _chunk_manager: ChunkManager = null
var _creature_spawner: OverworldCreatureSpawner = null
var _time_accum: float = 0.0
var _player_metrics_provider: PlayerDebugMetricsProvider = PlayerDebugMetricsProvider.new()
var _chunk_metrics_provider: ChunkDebugMetricsProvider = ChunkDebugMetricsProvider.new()

func _ready() -> void:
	visible = enabled
	var viewport: Viewport = get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	_apply_safe_area_padding()
	_resolve_nodes_from_paths()
	_update_text()

func _process(delta: float) -> void:
	if not enabled:
		return
	_handle_speed_input(delta)
	_time_accum += delta
	if _time_accum < update_interval_seconds:
		return
	_time_accum = 0.0
	_update_text()

func _on_viewport_size_changed() -> void:
	_apply_safe_area_padding()

func _resolve_nodes_from_paths() -> void:
	if player_path != NodePath():
		var found: Node = get_node_or_null(player_path)
		if found is Node2D:
			_player = found
	if chunk_manager_path != NodePath():
		var chunk_manager_node: Node = get_node_or_null(chunk_manager_path)
		if chunk_manager_node is ChunkManager:
			_chunk_manager = chunk_manager_node
	if creature_spawner_path != NodePath():
		var spawner_node: Node = get_node_or_null(creature_spawner_path)
		if spawner_node is OverworldCreatureSpawner:
			_creature_spawner = spawner_node


func set_player_node(player_node: Node2D) -> void:
	_player = player_node


func set_chunk_manager(chunk_manager: ChunkManager) -> void:
	_chunk_manager = chunk_manager


func set_creature_spawner(creature_spawner: OverworldCreatureSpawner) -> void:
	_creature_spawner = creature_spawner


func _update_text() -> void:
	if not label:
		return
	var lines: Array[String] = []
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	if _player:
		lines.append_array(_player_metrics_provider.collect(_player, _chunk_manager))
	if _chunk_manager:
		lines.append_array(_chunk_metrics_provider.collect(_chunk_manager, _creature_spawner))
	label.text = "\n".join(lines)

func _apply_safe_area_padding() -> void:
	if not label:
		return
	var viewport: Viewport = get_viewport()
	if not viewport:
		label.position = screen_padding
		return
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var safe_position: Vector2i = safe_rect.position
	# On desktop, safe area position may be in global desktop coordinates.
	# Only apply offsets that are already in viewport-local bounds.
	if safe_position.x < 0 or safe_position.y < 0:
		safe_position = Vector2i.ZERO
	elif safe_position.x >= int(viewport_size.x) or safe_position.y >= int(viewport_size.y):
		safe_position = Vector2i.ZERO
	var safe_offset: Vector2 = Vector2(
		float(safe_position.x),
		float(safe_position.y)
	)
	label.position = screen_padding + safe_offset

func _handle_speed_input(delta: float) -> void:
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
	var creature: Creature = _player as Creature
	if creature == null:
		return
	creature.movement_speed = clampf(creature.movement_speed + delta, speed_min, speed_max)
