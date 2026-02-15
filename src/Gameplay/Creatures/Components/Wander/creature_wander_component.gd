class_name CreatureWanderComponent
extends Node

## Lightweight ambient wander around the creature spawn origin.
## No combat AI/state-machine logic lives here.

@export var movement_component_path: NodePath = ^"CreatureMovementComponent"
@export var enabled_by_default: bool = true
@export_range(0.5, 32.0, 0.5) var arrive_distance: float = 3.0
@export_range(0.1, 30.0, 0.1) var stuck_timeout_seconds: float = 5.0
@export_range(0.1, 30.0, 0.1) var fallback_wander_interval_seconds: float = 7.0
@export_range(0.1, 5.0, 0.1) var failed_pick_retry_seconds: float = 0.8
@export_range(1, 16, 1) var target_pick_attempts: int = 8
@export_range(0.1, 1.0, 0.01) var wander_speed_multiplier: float = 0.45
@export_range(0.0, 1.0, 0.01) var course_jitter_strength: float = 0.3
@export_range(0.0, 1.0, 0.01) var retarget_chance_per_second: float = 0.08
@export_range(0.0, 2.0, 0.05) var interval_randomness: float = 1.0

var creature: Creature
var movement_component: CreatureMovementComponent

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_origin: Vector2 = Vector2.ZERO
var _has_spawn_origin: bool = false
var _wander_target: Vector2 = Vector2.ZERO
var _has_wander_target: bool = false
var _idle_timer: float = 0.0
var _travel_timer: float = 0.0


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "CreatureWanderComponent must be a child of Creature.")

	movement_component = creature.get_node_or_null(movement_component_path) as CreatureMovementComponent
	if movement_component == null:
		push_warning("CreatureWanderComponent: CreatureMovementComponent is missing.")
		set_physics_process(false)
		return

	_rng.randomize()
	if not creature.creature_data_applied.is_connected(_on_creature_data_applied):
		creature.creature_data_applied.connect(_on_creature_data_applied)
	if not creature.died.is_connected(_on_creature_died):
		creature.died.connect(_on_creature_died)
	_schedule_next_wander()


func _physics_process(delta: float) -> void:
	if creature == null or movement_component == null:
		return
	if not creature.is_alive:
		_clear_wander_target()
		return
	if not _has_spawn_origin:
		_spawn_origin = creature.global_position
		_has_spawn_origin = true

	if not _is_ambient_wander_enabled():
		_clear_wander_target()
		return

	_enforce_spawn_radius()

	if _has_wander_target:
		_travel_timer += delta
		var to_target: Vector2 = _wander_target - creature.global_position
		if to_target.length() <= arrive_distance:
			_clear_wander_target()
			_schedule_next_wander()
			return
		if _travel_timer >= stuck_timeout_seconds:
			_clear_wander_target()
			_idle_timer = failed_pick_retry_seconds
			return
		if retarget_chance_per_second > 0.0 and _rng.randf() < retarget_chance_per_second * delta:
			_pick_next_wander_target()
			to_target = _wander_target - creature.global_position

		var move_direction: Vector2 = to_target
		if course_jitter_strength > 0.0:
			var jitter_angle: float = _rng.randf_range(-1.0, 1.0) * course_jitter_strength * 0.5
			move_direction = to_target.normalized().rotated(jitter_angle)
		movement_component.apply_direction_scaled(move_direction, wander_speed_multiplier)
		return

	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	if _pick_next_wander_target():
		_travel_timer = 0.0
	else:
		_idle_timer = failed_pick_retry_seconds


func _on_creature_data_applied(_data: CreatureData) -> void:
	if _has_spawn_origin:
		_spawn_origin = creature.global_position
	_clear_wander_target()
	_schedule_next_wander()


func _on_creature_died() -> void:
	_clear_wander_target()
	set_physics_process(false)


func _is_ambient_wander_enabled() -> bool:
	if not enabled_by_default:
		return false
	if creature == null or creature.creature_data == null:
		return enabled_by_default
	return creature.creature_data.enable_ambient_wander


func _get_wander_radius() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.wander_radius, 0.0)
	return 32.0


func _get_wander_interval() -> float:
	if creature and creature.creature_data:
		return maxf(creature.creature_data.wander_interval_seconds, 0.1)
	return fallback_wander_interval_seconds


func _schedule_next_wander() -> void:
	var base_interval: float = _get_wander_interval()
	if interval_randomness <= 0.0:
		_idle_timer = base_interval
		return

	var randomness: float = clampf(interval_randomness, 0.0, 2.0)
	var min_factor: float = maxf(0.3, 1.0 - 0.4 * randomness)
	var max_factor: float = 1.0 + 0.8 * randomness
	_idle_timer = base_interval * _rng.randf_range(min_factor, max_factor)


func _pick_next_wander_target() -> bool:
	if not _has_spawn_origin:
		return false

	var radius: float = _get_wander_radius()
	if radius <= 0.0:
		return false

	var min_distance: float = minf(radius, arrive_distance * 2.0)
	for _attempt in range(maxi(target_pick_attempts, 1)):
		var angle: float = _rng.randf_range(0.0, TAU)
		var distance: float = _rng.randf_range(min_distance, radius)
		var candidate: Vector2 = _spawn_origin + Vector2.RIGHT.rotated(angle) * distance
		if candidate.distance_to(creature.global_position) > arrive_distance:
			_wander_target = candidate
			_has_wander_target = true
			return true
	return false


func _enforce_spawn_radius() -> void:
	if not _has_spawn_origin:
		return
	var radius: float = _get_wander_radius()
	if radius <= 0.0:
		return
	if creature.global_position.distance_to(_spawn_origin) <= radius + arrive_distance:
		return
	_wander_target = _spawn_origin
	_has_wander_target = true
	_travel_timer = 0.0


func _clear_wander_target() -> void:
	_has_wander_target = false
	_travel_timer = 0.0
	if movement_component:
		movement_component.stop_movement()
