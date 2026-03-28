class_name CharacterCreatorPanel
extends Control

signal confirmed
signal creation_cancelled

const PREVIEW_SCALE: float = 4.0
const PREVIEW_FRAME_SIZE: int = 32
const FONT_SIZE_BUTTON: int = 28
const FONT_SIZE_LABEL: int = 26
const FONT_SIZE_TITLE: int = 24

@onready var _preview_area: Control = $Card/Padding/VStack/ContentRow/PreviewPanel/PreviewArea
@onready var _preview_root: Node2D = $Card/Padding/VStack/ContentRow/PreviewPanel/PreviewArea/PreviewRoot
@onready var _preview_head: Sprite2D = $Card/Padding/VStack/ContentRow/PreviewPanel/PreviewArea/PreviewRoot/PreviewHead
@onready var _preview_body: Sprite2D = $Card/Padding/VStack/ContentRow/PreviewPanel/PreviewArea/PreviewRoot/PreviewBody
@onready var _preview_legs: Sprite2D = $Card/Padding/VStack/ContentRow/PreviewPanel/PreviewArea/PreviewRoot/PreviewLegs
@onready var _head_label: Label = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/HeadValueLabel
@onready var _body_label: Label = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/BodyValueLabel
@onready var _legs_label: Label = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/LegsValueLabel
@onready var _head_prev: Button = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/HeadPrevButton
@onready var _head_next: Button = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/HeadNextButton
@onready var _body_prev: Button = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/BodyPrevButton
@onready var _body_next: Button = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/BodyNextButton
@onready var _legs_prev: Button = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/LegsPrevButton
@onready var _legs_next: Button = $Card/Padding/VStack/ContentRow/RightPanel/OptionsGrid/LegsNextButton
@onready var _confirm_button: Button = $Card/Padding/VStack/BottomButtons/TopRow/ConfirmButton
@onready var _randomize_button: Button = $Card/Padding/VStack/BottomButtons/TopRow/RandomizeButton
@onready var _cancel_button: Button = $Card/Padding/VStack/BottomButtons/BottomRow/CancelButton
@onready var _title_label: Label = $TitleBanner/BannerTexture/TitleLabel

var _button_group: MenuButtonGroup
var _catalog: PlayerCosmeticCatalog
var _head_ids: Array[StringName] = []
var _body_ids: Array[StringName] = []
var _legs_ids: Array[StringName] = []
var _head_idx: int = 0
var _body_idx: int = 0
var _legs_idx: int = 0


func _ready() -> void:
	_catalog = PlayerProfileService.get_catalog() as PlayerCosmeticCatalog
	if _catalog:
		_head_ids = _catalog.get_ids_for_slot(PlayerCosmeticCatalog.SLOT_HEAD)
		_body_ids = _catalog.get_ids_for_slot(PlayerCosmeticCatalog.SLOT_BODY)
		_legs_ids = _catalog.get_ids_for_slot(PlayerCosmeticCatalog.SLOT_LEGS)
	var appearance: PlayerAppearanceData = PlayerProfileService.get_appearance() as PlayerAppearanceData
	if appearance:
		_head_idx = maxi(0, _head_ids.find(appearance.head_id))
		_body_idx = maxi(0, _body_ids.find(appearance.body_id))
		_legs_idx = maxi(0, _legs_ids.find(appearance.legs_id))
	_apply_style()
	_setup_button_group()
	_preview_area.resized.connect(_on_preview_resized)
	_wire_buttons()
	call_deferred("_refresh")


func _apply_style() -> void:
	var font := load("res://Assets/Fonts/awesome/Awesome 9.ttf") as FontFile
	var empty := StyleBoxEmpty.new()
	var gold := Color(0.92, 0.85, 0.62, 1.0)
	var gold_hover := Color(1.0, 0.98, 0.78, 1.0)
	var gold_press := Color(0.65, 0.60, 0.38, 1.0)

	for btn: Button in [_confirm_button, _randomize_button, _cancel_button]:
		if btn == null:
			continue
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state, empty)
		if font:
			btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", FONT_SIZE_BUTTON)
		btn.add_theme_color_override("font_color", gold)
		btn.add_theme_color_override("font_hover_color", gold_hover)
		btn.add_theme_color_override("font_pressed_color", gold_press)
		btn.add_theme_color_override("font_focus_color", gold_hover)

	for lbl: Label in [_head_label, _body_label, _legs_label]:
		if lbl == null:
			continue
		if font:
			lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", FONT_SIZE_LABEL)
		lbl.add_theme_color_override("font_color", gold)

	if _title_label and font:
		_title_label.add_theme_font_override("font", font)
		_title_label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
		_title_label.add_theme_color_override("font_color", gold)


func _setup_button_group() -> void:
	_button_group = MenuButtonGroup.new()
	_button_group.font_size_normal = FONT_SIZE_BUTTON
	_button_group.font_size_hover = FONT_SIZE_BUTTON + 4
	add_child(_button_group)
	_button_group.setup([_confirm_button, _randomize_button, _cancel_button])


func _wire_buttons() -> void:
	_head_prev.pressed.connect(func() -> void: _cycle(0, -1))
	_head_next.pressed.connect(func() -> void: _cycle(0, 1))
	_body_prev.pressed.connect(func() -> void: _cycle(1, -1))
	_body_next.pressed.connect(func() -> void: _cycle(1, 1))
	_legs_prev.pressed.connect(func() -> void: _cycle(2, -1))
	_legs_next.pressed.connect(func() -> void: _cycle(2, 1))
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_randomize_button.pressed.connect(_on_randomize_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func _cycle(slot: int, delta: int) -> void:
	match slot:
		0:
			if _head_ids.is_empty():
				return
			_head_idx = (_head_idx + delta + _head_ids.size()) % _head_ids.size()
		1:
			if _body_ids.is_empty():
				return
			_body_idx = (_body_idx + delta + _body_ids.size()) % _body_ids.size()
		2:
			if _legs_ids.is_empty():
				return
			_legs_idx = (_legs_idx + delta + _legs_ids.size()) % _legs_ids.size()
	_refresh()


func _refresh() -> void:
	_head_label.text = _slot_display(_head_ids, _head_idx, "Head")
	_body_label.text = _slot_display(_body_ids, _body_idx, "Body")
	_legs_label.text = _slot_display(_legs_ids, _legs_idx, "Legs")
	_preview_root.position = _preview_area.size / 2.0
	if _catalog == null:
		return
	if not _head_ids.is_empty():
		_update_sprite(_preview_head, _catalog.get_head_texture(_head_ids[_head_idx]))
	if not _body_ids.is_empty():
		_update_sprite(_preview_body, _catalog.get_body_texture(_body_ids[_body_idx]))
	if not _legs_ids.is_empty():
		_update_sprite(_preview_legs, _catalog.get_legs_texture(_legs_ids[_legs_idx]))


func _slot_display(ids: Array[StringName], idx: int, fallback: String) -> String:
	if ids.is_empty():
		return fallback
	var parts: PackedStringArray = String(ids[idx]).split("_")
	if parts.size() >= 2:
		return parts[0].capitalize() + " " + parts[parts.size() - 1]
	return String(ids[idx]).capitalize()


func _update_sprite(sprite: Sprite2D, texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.hframes = maxi(1, texture.get_width() / PREVIEW_FRAME_SIZE)
	sprite.frame = 0
	sprite.scale = Vector2.ONE * PREVIEW_SCALE


func _on_preview_resized() -> void:
	_preview_root.position = _preview_area.size / 2.0


func _on_confirm_pressed() -> void:
	var appearance := PlayerAppearanceData.new()
	if not _head_ids.is_empty():
		appearance.head_id = _head_ids[_head_idx]
	if not _body_ids.is_empty():
		appearance.body_id = _body_ids[_body_idx]
	if not _legs_ids.is_empty():
		appearance.legs_id = _legs_ids[_legs_idx]
	appearance.ensure_defaults()
	PlayerProfileService.set_appearance(appearance)
	confirmed.emit()


func _on_randomize_pressed() -> void:
	if not _head_ids.is_empty():
		_head_idx = randi() % _head_ids.size()
	if not _body_ids.is_empty():
		_body_idx = randi() % _body_ids.size()
	if not _legs_ids.is_empty():
		_legs_idx = randi() % _legs_ids.size()
	_refresh()


func _on_cancel_pressed() -> void:
	creation_cancelled.emit()
