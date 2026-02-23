class_name PlayerMovePointerComponent
extends Node2D

## Click/tap indicator rendered from a sprite strip animation.

const POINTER_ANIMATION_NAME := &"pointer"
const DESKTOP_FEATURES: PackedStringArray = ["windows", "macos", "linuxbsd"]

@export_file("*.png") var pointer_strip_path: String = "res://Assets/VFX/move_pointer_strip.png"
@export var frame_size: Vector2i = Vector2i(32, 32)
@export var frame_count: int = 4
@export var animation_fps: float = 7.0
@export var sprite_scale: Vector2 = Vector2(0.7, 0.7)
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var apply_desktop_click_anchor_offset: bool = true
@export var desktop_click_anchor_offset_world: Vector2 = Vector2(-3.0, -21.5)

var creature: Creature
var input_component: PlayerInputComponent
var navigation_component: CreatureNavigationComponent
var pointer_strip_texture: Texture2D
var _pointer_sprite: AnimatedSprite2D
var _is_pointer_held: bool = false
var _animated_since_hold_start: bool = false
var _has_valid_pointer_position: bool = false


func _ready() -> void:
	creature = get_parent() as Creature
	assert(creature, "PlayerMovePointerComponent must be a child of a Creature.")

	top_level = true
	visible = false
	pointer_strip_texture = _load_pointer_texture()
	_build_pointer_sprite()

	input_component = creature.get_node_or_null("PlayerInputComponent") as PlayerInputComponent
	navigation_component = creature.get_node_or_null("CreatureNavigationComponent") as CreatureNavigationComponent
	if input_component:
		input_component.move_target_queued.connect(_on_move_target_queued)
		input_component.pointer_hold_changed.connect(_on_pointer_hold_changed)


func _process(_delta: float) -> void:
	var should_show: bool = _is_pointer_held and _has_valid_pointer_position
	if not should_show and navigation_component:
		should_show = not navigation_component.is_navigation_finished()

	if should_show:
		if not visible:
			visible = true
		_play_loop_animation(false)
		return

	_stop_animation()
	visible = false


func _on_move_target_queued(world_position: Vector2, _from_hold: bool) -> void:
	global_position = world_position + _get_click_anchor_offset_world()
	_has_valid_pointer_position = true

	if _is_pointer_held:
		# During an active hold, run intro animation only once (on initial press).
		if not _animated_since_hold_start:
			visible = true
			_animated_since_hold_start = true
			_play_loop_animation(true)
			return

		# Subsequent hold updates only move marker position; no animation restart.
		visible = true
		return

	_play_loop_animation(true)
	visible = true


func _on_pointer_hold_changed(is_held: bool) -> void:
	_is_pointer_held = is_held
	if _is_pointer_held:
		# Do not show pointer at stale/player position before first queued target.
		_has_valid_pointer_position = false
		_animated_since_hold_start = false


func _build_pointer_sprite() -> void:
	_pointer_sprite = AnimatedSprite2D.new()
	_pointer_sprite.name = "MovePointerSprite"
	_pointer_sprite.centered = true
	_pointer_sprite.position = sprite_offset
	_pointer_sprite.scale = sprite_scale

	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation(POINTER_ANIMATION_NAME)
	frames.set_animation_loop(POINTER_ANIMATION_NAME, true)
	frames.set_animation_speed(POINTER_ANIMATION_NAME, maxf(animation_fps, 1.0))

	if pointer_strip_texture == null:
		push_warning("PlayerMovePointerComponent: pointer strip texture failed to load (%s)." % pointer_strip_path)
	else:
		var safe_frame_width: int = max(frame_size.x, 1)
		var safe_frame_height: int = max(frame_size.y, 1)
		var safe_frame_count: int = max(frame_count, 1)
		for frame_i in range(safe_frame_count):
			var atlas_texture: AtlasTexture = AtlasTexture.new()
			atlas_texture.atlas = pointer_strip_texture
			atlas_texture.region = Rect2(
				frame_i * safe_frame_width,
				0.0,
				float(safe_frame_width),
				float(safe_frame_height)
			)
			frames.add_frame(POINTER_ANIMATION_NAME, atlas_texture)

	_pointer_sprite.sprite_frames = frames
	add_child(_pointer_sprite)


func _play_loop_animation(restart: bool) -> void:
	if _pointer_sprite == null:
		return
	if restart:
		_pointer_sprite.stop()
		_pointer_sprite.frame = 0
		_pointer_sprite.play(POINTER_ANIMATION_NAME)
		return
	if not _pointer_sprite.is_playing():
		_pointer_sprite.play(POINTER_ANIMATION_NAME)


func _stop_animation() -> void:
	if _pointer_sprite == null:
		return
	_pointer_sprite.stop()


func _load_pointer_texture() -> Texture2D:
	if pointer_strip_path.is_empty():
		return null

	if ResourceLoader.exists(pointer_strip_path, "Texture2D"):
		var resource: Resource = load(pointer_strip_path)
		return resource as Texture2D

	# Fallback for freshly added assets that are not imported yet.
	var image: Image = Image.new()
	var err: Error = image.load(pointer_strip_path)
	if err != OK:
		var absolute_path: String = ProjectSettings.globalize_path(pointer_strip_path)
		err = image.load(absolute_path)
		if err != OK:
			return null

	return ImageTexture.create_from_image(image)


func _get_click_anchor_offset_world() -> Vector2:
	if not apply_desktop_click_anchor_offset:
		return Vector2.ZERO
	for feature in DESKTOP_FEATURES:
		if OS.has_feature(feature):
			return desktop_click_anchor_offset_world
	return Vector2.ZERO
