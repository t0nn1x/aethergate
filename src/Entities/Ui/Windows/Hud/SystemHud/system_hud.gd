class_name SystemHud
extends AdaptiveOverlayPanel

signal hud_slot_pressed(action_id: StringName, slot_index: int)

const SLOT_COUNT: int = 5
const DEFAULT_ACTION_IDS := [
	"equipment",
	"guilds",
	"chat",
	"inventory",
	"systems"
]

@export var slot_texture: Texture2D = preload("res://src/Entities/Ui/Assets/Gui-Hud/Menu Buttons And Switch/Menu Buttons/button_slot.png")
@export var slot_actions: PackedStringArray = PackedStringArray(DEFAULT_ACTION_IDS)
@export var slot_icons: Array[Texture2D] = []
@export_range(0.7, 2.0, 0.05) var side_slot_scale: float = 1.0
@export_range(1.0, 3.0, 0.05) var center_slot_scale: float = 1.4
@export_range(0.02, 0.20, 0.005) var slot_size_ratio: float = 0.08
@export_range(32.0, 256.0, 1.0) var min_slot_size: float = 52.0
@export_range(32.0, 256.0, 1.0) var max_slot_size: float = 96.0
@export_range(0.0, 64.0, 1.0) var slot_spacing: float = 12.0
@export_range(0.5, 2.0, 0.05) var mobile_scale_multiplier: float = 1.1
@export_range(0.20, 0.90, 0.01) var icon_fill_ratio: float = 0.56
@export_range(0.0, 160.0, 1.0) var bottom_margin_extra: float = 20.0
@export_range(0.0, 120.0, 1.0) var horizontal_margin_extra: float = 16.0

@onready var _safe_area_margin: MarginContainer = %SafeAreaMargin
@onready var _slot_row: HBoxContainer = %SlotRow

var _slot_buttons: Array[TextureButton] = []


func _ready() -> void:
	content_margin_path = NodePath("%SafeAreaMargin")
	block_world_movement = false
	super._ready()
	_cache_slot_buttons()
	_sync_slot_icons_with_scene_defaults()
	_connect_slot_signals()
	_apply_slot_textures()
	_apply_responsive_layout()


func set_slot_icon(slot_index: int, icon: Texture2D) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return

	if slot_icons.size() < SLOT_COUNT:
		slot_icons.resize(SLOT_COUNT)

	slot_icons[slot_index] = icon
	_apply_icon(slot_index)


func _sync_slot_icons_with_scene_defaults() -> void:
	if slot_icons.size() < SLOT_COUNT:
		slot_icons.resize(SLOT_COUNT)

	for slot_index in range(_slot_buttons.size()):
		if slot_index >= slot_icons.size():
			break
		if slot_icons[slot_index] != null:
			continue

		var button: TextureButton = _slot_buttons[slot_index]
		var icon_node: TextureRect = button.get_node_or_null("Icon") as TextureRect
		if icon_node == null:
			continue
		slot_icons[slot_index] = icon_node.texture


func _cache_slot_buttons() -> void:
	_slot_buttons.clear()
	for child in _slot_row.get_children():
		var button: TextureButton = child as TextureButton
		if button == null:
			continue
		_slot_buttons.append(button)


func _connect_slot_signals() -> void:
	for index in range(_slot_buttons.size()):
		var button: TextureButton = _slot_buttons[index]
		if not button.pressed.is_connected(_on_slot_pressed.bind(index)):
			button.pressed.connect(_on_slot_pressed.bind(index))


func _on_overlay_viewport_resized() -> void:
	_apply_responsive_layout()


func _apply_slot_textures() -> void:
	for button in _slot_buttons:
		button.texture_normal = slot_texture
		button.texture_pressed = slot_texture
		button.texture_hover = slot_texture
		button.texture_disabled = slot_texture


func _apply_responsive_layout() -> void:
	if _slot_buttons.is_empty():
		return

	var viewport_size: Vector2 = get_overlay_viewport_size()
	var safe_insets: Dictionary = resolve_overlay_safe_insets(viewport_size)
	var safe_left: float = float(safe_insets.get("left", 0.0))
	var safe_right: float = float(safe_insets.get("right", 0.0))
	var safe_bottom: float = float(safe_insets.get("bottom", 0.0))
	var edge_margin: float = clampf(minf(viewport_size.x, viewport_size.y) * 0.02, 8.0, 32.0)

	_safe_area_margin.add_theme_constant_override("margin_left", int(round(edge_margin + safe_left + horizontal_margin_extra)))
	_safe_area_margin.add_theme_constant_override("margin_right", int(round(edge_margin + safe_right + horizontal_margin_extra)))
	_safe_area_margin.add_theme_constant_override("margin_bottom", int(round(_resolve_bottom_margin(viewport_size) + safe_bottom + bottom_margin_extra)))

	var separation: float = _resolve_slot_spacing(viewport_size)
	_slot_row.add_theme_constant_override("separation", int(round(separation)))

	var slot_scales: Array[float] = _build_slot_scales()
	var available_width: float = viewport_size.x
	available_width -= float(_safe_area_margin.get_theme_constant("margin_left") + _safe_area_margin.get_theme_constant("margin_right"))
	available_width -= separation * float(maxi(0, _slot_buttons.size() - 1))

	var desired_base_size: float = clampf(minf(viewport_size.x, viewport_size.y) * slot_size_ratio, min_slot_size, max_slot_size)
	if is_mobile_platform():
		desired_base_size *= mobile_scale_multiplier

	var sum_scales: float = 0.0
	for scale_value in slot_scales:
		sum_scales += float(scale_value)

	var max_fit_base_size: float = desired_base_size
	if available_width > 0.0 and sum_scales > 0.0:
		max_fit_base_size = minf(desired_base_size, available_width / sum_scales)

	var min_touch_size: float = 44.0 if is_mobile_platform() else 36.0
	var base_size: float = clampf(max_fit_base_size, min_touch_size, max_slot_size)

	for index in range(_slot_buttons.size()):
		var slot_size: float = round(base_size * slot_scales[index])
		var button: TextureButton = _slot_buttons[index]
		button.custom_minimum_size = Vector2(slot_size, slot_size)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_apply_icon(index)


func _apply_icon(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_buttons.size():
		return

	var button: TextureButton = _slot_buttons[slot_index]
	var icon_node: TextureRect = button.get_node_or_null("Icon") as TextureRect
	if icon_node == null:
		return

	var icon_texture: Texture2D = null
	if slot_index < slot_icons.size():
		icon_texture = slot_icons[slot_index]

	icon_node.texture = icon_texture
	icon_node.visible = icon_texture != null

	var icon_size: float = floor(minf(button.custom_minimum_size.x, button.custom_minimum_size.y) * icon_fill_ratio)
	icon_size = maxf(14.0, icon_size)
	var icon_rect_size: Vector2 = Vector2(icon_size, icon_size)
	icon_node.custom_minimum_size = icon_rect_size
	# Normalize icon rect geometry each frame so scene-authored offsets cannot drift per slot/platform.
	icon_node.anchor_left = 0.0
	icon_node.anchor_top = 0.0
	icon_node.anchor_right = 0.0
	icon_node.anchor_bottom = 0.0
	icon_node.offset_left = 0.0
	icon_node.offset_top = 0.0
	icon_node.offset_right = 0.0
	icon_node.offset_bottom = 0.0
	icon_node.position = ((button.custom_minimum_size - icon_rect_size) * 0.5).round()
	icon_node.size = icon_rect_size


func _build_slot_scales() -> Array[float]:
	var center_index: int = int(floor(float(SLOT_COUNT) * 0.5))
	var scales: Array[float] = []
	scales.resize(SLOT_COUNT)
	for index in range(SLOT_COUNT):
		scales[index] = center_slot_scale if index == center_index else side_slot_scale
	return scales


func _resolve_slot_spacing(viewport_size: Vector2) -> float:
	var shortest_side: float = minf(viewport_size.x, viewport_size.y)
	return clampf(slot_spacing + shortest_side * 0.005, 6.0, 26.0)


func _resolve_bottom_margin(viewport_size: Vector2) -> float:
	return clampf(viewport_size.y * 0.025, 12.0, 48.0)


func _resolve_action_id(slot_index: int) -> StringName:
	if slot_index >= 0 and slot_index < slot_actions.size():
		return StringName(slot_actions[slot_index])
	return StringName("slot_%d" % slot_index)


func _on_slot_pressed(slot_index: int) -> void:
	hud_slot_pressed.emit(_resolve_action_id(slot_index), slot_index)
