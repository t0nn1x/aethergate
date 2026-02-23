class_name PlayerVisualComponent
extends Node

## Handles layered player visuals, bobbing, facing, and silhouette sync.

const PLAYER_APPEARANCE_DATA_SCRIPT := preload(
	"res://src/Entities/Player/Resources/player_appearance_data.gd"
)

const SLOT_HEAD: StringName = &"head"
const SLOT_BODY: StringName = &"body"
const SLOT_LEGS: StringName = &"legs"

var creature: Creature

@export var cosmetic_catalog: Resource = preload(
	"res://src/Entities/Player/Resources/player_cosmetic_catalog.tres"
)
@export var idle_bob_speed: float = 3.0
@export var move_bob_speed: float = 6.0
@export var bob_amplitude_pixels: float = 1.5

@onready var visual_root: Node2D = get_node_or_null("../VisualRoot") as Node2D
@onready var legs_sprite: Sprite2D = get_node_or_null("../VisualRoot/Legs") as Sprite2D
@onready var body_sprite: Sprite2D = get_node_or_null("../VisualRoot/Body") as Sprite2D
@onready var head_sprite: Sprite2D = get_node_or_null("../VisualRoot/Head") as Sprite2D
@onready var weapon_back_sprite: Sprite2D = get_node_or_null("../VisualRoot/WeaponBack") as Sprite2D
@onready var weapon_front_sprite: Sprite2D = get_node_or_null("../VisualRoot/WeaponFront") as Sprite2D
@onready var silhouette_legs_sprite: Sprite2D = get_node_or_null("../VisualRoot/SilhouetteLegs") as Sprite2D
@onready var silhouette_body_sprite: Sprite2D = get_node_or_null("../VisualRoot/SilhouetteBody") as Sprite2D
@onready var silhouette_head_sprite: Sprite2D = get_node_or_null("../VisualRoot/SilhouetteHead") as Sprite2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("../CollisionShape2D") as CollisionShape2D

var _base_collision_offset: Vector2 = Vector2.ZERO
var _base_visual_offset: Vector2 = Vector2.ZERO
var _facing_left: bool = false
var _is_moving: bool = false
var _bob_time: float = 0.0
var _appearance: Resource


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerVisualComponent must be a child of a Creature.")

	if visual_root == null or body_sprite == null or collision_shape == null:
		push_warning("PlayerVisualComponent: required visual nodes are missing.")
		return

	_base_collision_offset = collision_shape.position
	_base_visual_offset = visual_root.position

	# Start idle animation if available.
	var animator: AnimationPlayer = creature.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animator and animator.has_animation("idle"):
		animator.play("idle")

	_apply_default_appearance_if_needed()
	_sync_layer_frames()
	_sync_silhouette()


func _process(delta: float) -> void:
	if visual_root == null or body_sprite == null:
		return
	var speed: float = move_bob_speed if _is_moving else idle_bob_speed
	_bob_time += delta * speed
	var offset: int = int(round(sin(_bob_time) * bob_amplitude_pixels))
	visual_root.position = Vector2(_base_visual_offset.x, _base_visual_offset.y + offset)
	_sync_layer_frames()
	_sync_silhouette()


func apply_appearance(
	appearance_data: Resource,
	catalog_override: Resource = null
) -> void:
	if appearance_data == null:
		push_warning("PlayerVisualComponent: cannot apply null appearance data.")
		return

	if catalog_override != null:
		cosmetic_catalog = catalog_override

	if cosmetic_catalog == null:
		push_warning("PlayerVisualComponent: cosmetic catalog is missing.")
		return

	if appearance_data.has_method("duplicate_data"):
		_appearance = appearance_data.call("duplicate_data") as Resource
	else:
		_appearance = appearance_data

	_validate_appearance_ids()

	if legs_sprite:
		legs_sprite.texture = _catalog_get_texture("get_legs_texture", StringName(str(_appearance.get("legs_id"))))
	if body_sprite:
		body_sprite.texture = _catalog_get_texture("get_body_texture", StringName(str(_appearance.get("body_id"))))
	if head_sprite:
		head_sprite.texture = _catalog_get_texture("get_head_texture", StringName(str(_appearance.get("head_id"))))

	set_weapon_visual(StringName(str(_appearance.get("weapon_visual_id"))))
	_sync_layer_frames()
	_sync_silhouette()


func set_weapon_visual(weapon_visual_id: StringName) -> void:
	if _appearance == null:
		_appearance = PLAYER_APPEARANCE_DATA_SCRIPT.new()
	_appearance.set("weapon_visual_id", weapon_visual_id)

	if cosmetic_catalog == null:
		if weapon_back_sprite:
			weapon_back_sprite.visible = false
		if weapon_front_sprite:
			weapon_front_sprite.visible = false
		return

	var weapon_front_texture: Texture2D = _catalog_get_texture("get_weapon_front_texture", weapon_visual_id)
	var weapon_back_texture: Texture2D = _catalog_get_texture("get_weapon_back_texture", weapon_visual_id)
	if weapon_front_sprite:
		weapon_front_sprite.texture = weapon_front_texture
		weapon_front_sprite.visible = weapon_front_texture != null
	if weapon_back_sprite:
		weapon_back_sprite.texture = weapon_back_texture
		weapon_back_sprite.visible = weapon_back_texture != null


func get_current_appearance() -> Resource:
	if _appearance == null:
		return null
	if _appearance.has_method("duplicate_data"):
		return _appearance.call("duplicate_data") as Resource
	return _appearance


## Set facing direction based on horizontal movement.
func set_facing(direction_x: float) -> void:
	if direction_x == 0.0:
		return
	var should_face_left: bool = direction_x < 0.0
	if _facing_left == should_face_left:
		return
	_facing_left = should_face_left
	_apply_flip_to_all_layers(_facing_left)
	collision_shape.position = Vector2(
		_base_collision_offset.x * (-1 if _facing_left else 1),
		_base_collision_offset.y
	)


## Toggle moving state (affects bob speed).
func set_moving(moving: bool) -> void:
	_is_moving = moving


func _apply_default_appearance_if_needed() -> void:
	if _appearance != null:
		return
	if cosmetic_catalog == null or not cosmetic_catalog.has_method("get_default_appearance"):
		return
	apply_appearance(cosmetic_catalog.call("get_default_appearance") as Resource, cosmetic_catalog)


func _validate_appearance_ids() -> void:
	if _appearance == null or cosmetic_catalog == null or not cosmetic_catalog.has_method("is_valid_id"):
		return

	var defaults: Resource = null
	if cosmetic_catalog.has_method("get_default_appearance"):
		defaults = cosmetic_catalog.call("get_default_appearance") as Resource
	if defaults == null:
		defaults = PLAYER_APPEARANCE_DATA_SCRIPT.new()

	_validate_slot_id(SLOT_HEAD, "head_id", defaults)
	_validate_slot_id(SLOT_BODY, "body_id", defaults)
	_validate_slot_id(SLOT_LEGS, "legs_id", defaults)

	var weapon_id: StringName = StringName(str(_appearance.get("weapon_visual_id")))
	if weapon_id == StringName():
		return
	var has_weapon_front: bool = _catalog_get_texture("get_weapon_front_texture", weapon_id) != null
	var has_weapon_back: bool = _catalog_get_texture("get_weapon_back_texture", weapon_id) != null
	if not has_weapon_front and not has_weapon_back:
		push_warning(
			"PlayerVisualComponent: unknown weapon_visual_id '%s', clearing."
			% String(weapon_id)
		)
		_appearance.set("weapon_visual_id", StringName())


func _validate_slot_id(slot_name: StringName, field_name: String, defaults: Resource) -> void:
	var current_id: StringName = StringName(str(_appearance.get(field_name)))
	var valid: bool = bool(cosmetic_catalog.call("is_valid_id", slot_name, current_id))
	if valid:
		return
	push_warning("PlayerVisualComponent: invalid %s '%s', using default." % [field_name, String(current_id)])
	_appearance.set(field_name, StringName(str(defaults.get(field_name))))


func _catalog_get_texture(method_name: String, entry_id: StringName) -> Texture2D:
	if cosmetic_catalog == null or not cosmetic_catalog.has_method(method_name):
		return null
	return cosmetic_catalog.call(method_name, entry_id) as Texture2D


func _apply_flip_to_all_layers(flip_h: bool) -> void:
	if legs_sprite:
		legs_sprite.flip_h = flip_h
	if body_sprite:
		body_sprite.flip_h = flip_h
	if head_sprite:
		head_sprite.flip_h = flip_h
	if weapon_back_sprite:
		weapon_back_sprite.flip_h = flip_h
	if weapon_front_sprite:
		weapon_front_sprite.flip_h = flip_h
	if silhouette_legs_sprite:
		silhouette_legs_sprite.flip_h = flip_h
	if silhouette_body_sprite:
		silhouette_body_sprite.flip_h = flip_h
	if silhouette_head_sprite:
		silhouette_head_sprite.flip_h = flip_h


func _sync_layer_frames() -> void:
	if body_sprite == null:
		return
	var frame: int = body_sprite.frame
	var hframes: int = body_sprite.hframes

	if legs_sprite:
		legs_sprite.hframes = hframes
		legs_sprite.frame = frame
	if head_sprite:
		head_sprite.hframes = hframes
		head_sprite.frame = frame
	if weapon_back_sprite:
		weapon_back_sprite.hframes = hframes
		weapon_back_sprite.frame = frame
	if weapon_front_sprite:
		weapon_front_sprite.hframes = hframes
		weapon_front_sprite.frame = frame
	if silhouette_legs_sprite:
		silhouette_legs_sprite.hframes = hframes
		silhouette_legs_sprite.frame = frame
	if silhouette_body_sprite:
		silhouette_body_sprite.hframes = hframes
		silhouette_body_sprite.frame = frame
	if silhouette_head_sprite:
		silhouette_head_sprite.hframes = hframes
		silhouette_head_sprite.frame = frame


func _sync_silhouette() -> void:
	if silhouette_legs_sprite and legs_sprite:
		silhouette_legs_sprite.position = legs_sprite.position
		silhouette_legs_sprite.texture = legs_sprite.texture
		silhouette_legs_sprite.scale = legs_sprite.scale
		silhouette_legs_sprite.flip_h = legs_sprite.flip_h

	if silhouette_body_sprite and body_sprite:
		silhouette_body_sprite.position = body_sprite.position
		silhouette_body_sprite.texture = body_sprite.texture
		silhouette_body_sprite.scale = body_sprite.scale
		silhouette_body_sprite.flip_h = body_sprite.flip_h

	if silhouette_head_sprite and head_sprite:
		silhouette_head_sprite.position = head_sprite.position
		silhouette_head_sprite.texture = head_sprite.texture
		silhouette_head_sprite.scale = head_sprite.scale
		silhouette_head_sprite.flip_h = head_sprite.flip_h
