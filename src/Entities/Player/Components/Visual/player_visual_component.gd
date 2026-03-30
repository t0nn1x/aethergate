class_name PlayerVisualComponent
extends Node

## Handles overworld player visuals, bobbing, facing, and silhouette sync.

const PLAYER_APPEARANCE_DATA_SCRIPT := preload(
	"res://src/Entities/Player/Resources/player_appearance_data.gd"
)

const PLAYER_SKIN_CATALOG := preload(
	"res://src/Entities/Player/Resources/player_skin_catalog.tres"
) as PlayerSkinCatalog
const OVERWORLD_IDLE_FRAME_COUNT: int = 4
const OVERWORLD_FRAME_WIDTH: int = 16

var creature: Creature

@export var skin_catalog: PlayerSkinCatalog = PLAYER_SKIN_CATALOG
@export var idle_bob_speed: float = 3.0
@export var move_bob_speed: float = 6.0
@export var bob_amplitude_pixels: float = 1.5

@onready var visual_root: Node2D = get_node_or_null("../VisualRoot") as Node2D
@onready var overworld_sprite: Sprite2D = get_node_or_null("../VisualRoot/OverworldSprite") as Sprite2D
@onready var silhouette_sprite: Sprite2D = get_node_or_null("../VisualRoot/Silhouette") as Sprite2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("../CollisionShape2D") as CollisionShape2D
@onready var animation_player: AnimationPlayer = get_node_or_null("../AnimationPlayer") as AnimationPlayer

var _base_collision_offset: Vector2 = Vector2.ZERO
var _base_visual_offset: Vector2 = Vector2.ZERO
var _facing_left: bool = false
var _is_moving: bool = false
var _bob_time: float = 0.0
var _appearance: PlayerAppearanceData


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerVisualComponent must be a child of a Creature.")

	if visual_root == null or overworld_sprite == null or collision_shape == null:
		push_warning("PlayerVisualComponent: required visual nodes are missing.")
		return

	_base_collision_offset = collision_shape.position
	_base_visual_offset = visual_root.position

	_apply_overworld_texture(null)
	_consume_primed_spawn_appearance_if_any()
	_apply_default_appearance_if_needed()
	_refresh_idle_animation_state()
	_sync_silhouette()


func _process(delta: float) -> void:
	if visual_root == null or overworld_sprite == null:
		return

	var speed: float = move_bob_speed if _is_moving else idle_bob_speed
	_bob_time += delta * speed
	var offset: int = int(round(sin(_bob_time) * bob_amplitude_pixels))
	visual_root.position = Vector2(_base_visual_offset.x, _base_visual_offset.y + offset)
	_sync_silhouette()


func apply_appearance(appearance_data: PlayerAppearanceData, catalog_override: PlayerSkinCatalog = null) -> void:
	if appearance_data == null:
		push_warning("PlayerVisualComponent: cannot apply null appearance data.")
		return

	if catalog_override != null:
		skin_catalog = catalog_override

	if skin_catalog == null:
		push_warning("PlayerVisualComponent: skin catalog is missing.")
		return

	_appearance = _duplicate_appearance(appearance_data)
	if _appearance != null:
		_appearance.ensure_defaults()

	_validate_skin_id()
	_apply_overworld_texture(_resolve_overworld_texture())
	_refresh_idle_animation_state()
	_sync_silhouette()


func set_weapon_visual(weapon_visual_id: StringName) -> void:
	if _appearance == null:
		_appearance = PlayerAppearanceData.new()
		_appearance.ensure_defaults()
	_appearance.weapon_visual_id = weapon_visual_id


func get_current_appearance() -> PlayerAppearanceData:
	if _appearance == null:
		return null
	return _duplicate_appearance(_appearance)


func set_facing(direction_x: float) -> void:
	if direction_x == 0.0:
		return

	var should_face_left: bool = direction_x < 0.0
	if _facing_left == should_face_left:
		return

	_facing_left = should_face_left
	_apply_flip(_facing_left)
	collision_shape.position = Vector2(
		_base_collision_offset.x * (-1 if _facing_left else 1),
		_base_collision_offset.y
	)


func set_moving(moving: bool) -> void:
	_is_moving = moving


func _apply_default_appearance_if_needed() -> void:
	if _appearance != null:
		return

	var default_appearance := PlayerAppearanceData.new()
	if default_appearance == null:
		return

	var default_skin_id: StringName = _resolve_default_skin_id()
	if default_skin_id != StringName():
		default_appearance.skin_id = default_skin_id
	default_appearance.ensure_defaults()
	apply_appearance(default_appearance, skin_catalog)


func _consume_primed_spawn_appearance_if_any() -> void:
	var player: Player = creature as Player
	if player == null:
		return

	var primed_skin_catalog: PlayerSkinCatalog = player.consume_primed_spawn_skin_catalog()
	if primed_skin_catalog != null:
		skin_catalog = primed_skin_catalog

	var primed_appearance: PlayerAppearanceData = player.consume_primed_spawn_appearance()
	if primed_appearance == null:
		return

	apply_appearance(primed_appearance, skin_catalog)


func _validate_skin_id() -> void:
	if _appearance == null:
		return

	_appearance.skin_id = _resolve_valid_skin_id(_appearance.skin_id)


func _resolve_valid_skin_id(candidate_skin_id: StringName) -> StringName:
	if skin_catalog != null:
		var resolved_skin: PlayerSkinDefinition = skin_catalog.get_skin(candidate_skin_id)
		if resolved_skin != null:
			return candidate_skin_id

	var fallback_skin_id: StringName = _resolve_default_skin_id()
	if candidate_skin_id != StringName():
		push_warning(
			"PlayerVisualComponent: invalid skin_id '%s', using default."
			% String(candidate_skin_id)
		)
	return fallback_skin_id


func _resolve_default_skin_id() -> StringName:
	if skin_catalog != null:
		var default_skin: PlayerSkinDefinition = skin_catalog.get_default_skin()
		if default_skin != null:
			if default_skin.skin_id != StringName():
				return default_skin.skin_id
	return PLAYER_APPEARANCE_DATA_SCRIPT.DEFAULT_SKIN_ID


func _refresh_idle_animation_state() -> void:
	if animation_player == null or not animation_player.has_animation("idle"):
		return

	if _can_play_idle_animation():
		animation_player.play("idle")
		return

	animation_player.stop()
	if overworld_sprite != null:
		overworld_sprite.frame = 0


func _apply_overworld_texture(texture: Texture2D) -> void:
	if overworld_sprite == null:
		return

	overworld_sprite.texture = texture
	overworld_sprite.visible = texture != null
	if texture != null:
		var derived_hframes: int = _resolve_hframes(texture)
		overworld_sprite.hframes = derived_hframes
		if derived_hframes != OVERWORLD_IDLE_FRAME_COUNT:
			push_warning(
				"PlayerVisualComponent: skin '%s' resolved %d overworld frames; idle animation disabled because %d are required."
				% [String(_resolve_current_skin_id()), derived_hframes, OVERWORLD_IDLE_FRAME_COUNT]
			)
		overworld_sprite.frame = clampi(
			overworld_sprite.frame,
			0,
			maxi(overworld_sprite.hframes * overworld_sprite.vframes - 1, 0)
		)
	else:
		overworld_sprite.hframes = OVERWORLD_IDLE_FRAME_COUNT
		overworld_sprite.frame = 0


func _resolve_overworld_texture() -> Texture2D:
	if skin_catalog == null:
		return null
	return skin_catalog.get_overworld_idle_texture(_resolve_current_skin_id())


func _resolve_current_skin_id() -> StringName:
	if _appearance == null:
		return _resolve_default_skin_id()
	return _appearance.skin_id


func _resolve_hframes(texture: Texture2D) -> int:
	if texture == null:
		return OVERWORLD_IDLE_FRAME_COUNT
	var texture_width: int = texture.get_width()
	if texture_width < OVERWORLD_FRAME_WIDTH:
		return 1
	if texture_width % OVERWORLD_FRAME_WIDTH != 0:
		return 1
	return maxi(texture_width / OVERWORLD_FRAME_WIDTH, 1)


func _can_play_idle_animation() -> bool:
	return (
		overworld_sprite != null
		and overworld_sprite.texture != null
		and overworld_sprite.hframes == OVERWORLD_IDLE_FRAME_COUNT
	)


func _duplicate_appearance(source: PlayerAppearanceData) -> PlayerAppearanceData:
	if source == null:
		return null
	var duplicated: Resource = source.duplicate_data()
	return duplicated as PlayerAppearanceData


func _apply_flip(flip_h: bool) -> void:
	if overworld_sprite:
		overworld_sprite.flip_h = flip_h
	if silhouette_sprite:
		silhouette_sprite.flip_h = flip_h


func _sync_silhouette() -> void:
	if silhouette_sprite == null or overworld_sprite == null:
		return

	silhouette_sprite.position = overworld_sprite.position
	silhouette_sprite.texture = overworld_sprite.texture
	silhouette_sprite.scale = overworld_sprite.scale
	silhouette_sprite.hframes = overworld_sprite.hframes
	silhouette_sprite.vframes = overworld_sprite.vframes
	silhouette_sprite.frame = overworld_sprite.frame
	silhouette_sprite.flip_h = overworld_sprite.flip_h
	silhouette_sprite.visible = overworld_sprite.visible
