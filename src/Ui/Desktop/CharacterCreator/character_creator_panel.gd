class_name CharacterCreatorPanel
extends Control

signal appearance_confirmed(appearance: Resource)
signal creation_cancelled

const OVERWORLD_FRAME_SIZE: int = 16
const BATTLE_FRAME_SIZE: int = 32
const OVERWORLD_PREVIEW_SCALE: float = 8.0
const BATTLE_PREVIEW_SCALE: float = 4.0
const FONT_SIZE_BUTTON: int = 28
const FONT_SIZE_SECTION: int = 24
const FONT_SIZE_PRESET: int = 24
const FONT_SIZE_NAME: int = 28
const FONT_SIZE_DESCRIPTION: int = 22
const FONT_SIZE_TITLE: int = 24
const PRESET_BUTTON_MIN_SIZE: Vector2 = Vector2(0, 56)

@onready var _content_layout: BoxContainer = $Card/Padding/VStack/ContentLayout
@onready var _preset_panel: PanelContainer = $Card/Padding/VStack/ContentLayout/PresetPanel
@onready var _preset_section_label: Label = $Card/Padding/VStack/ContentLayout/PresetPanel/PresetMargin/PresetVBox/PresetLabel
@onready var _preset_scroll: ScrollContainer = $Card/Padding/VStack/ContentLayout/PresetPanel/PresetMargin/PresetVBox/PresetScroll
@onready var _preset_list: VBoxContainer = $Card/Padding/VStack/ContentLayout/PresetPanel/PresetMargin/PresetVBox/PresetScroll/PresetButtons
@onready var _preset_button_template: Button = $Card/Padding/VStack/ContentLayout/PresetPanel/PresetMargin/PresetVBox/PresetScroll/PresetButtons/PresetButtonTemplate
@onready var _preview_stack: VBoxContainer = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack
@onready var _overworld_preview_panel: PanelContainer = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/OverworldPreviewCard
@onready var _overworld_preview_title: Label = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/OverworldPreviewCard/CardMargin/CardVBox/PreviewTitle
@onready var _overworld_preview_area: Control = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/OverworldPreviewCard/CardMargin/CardVBox/PreviewHolder/PreviewArea
@onready var _overworld_preview_root: Node2D = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/OverworldPreviewCard/CardMargin/CardVBox/PreviewHolder/PreviewArea/PreviewRoot
@onready var _overworld_preview_sprite: Sprite2D = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/OverworldPreviewCard/CardMargin/CardVBox/PreviewHolder/PreviewArea/PreviewRoot/PreviewSprite
@onready var _battle_preview_panel: PanelContainer = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/BattlePreviewCard
@onready var _battle_preview_title: Label = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/BattlePreviewCard/CardMargin/CardVBox/PreviewTitle
@onready var _battle_preview_area: Control = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/BattlePreviewCard/CardMargin/CardVBox/PreviewHolder/PreviewArea
@onready var _battle_preview_root: Node2D = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/BattlePreviewCard/CardMargin/CardVBox/PreviewHolder/PreviewArea/PreviewRoot
@onready var _battle_preview_sprite: Sprite2D = $Card/Padding/VStack/ContentLayout/PreviewDetails/PreviewStack/BattlePreviewCard/CardMargin/CardVBox/PreviewHolder/PreviewArea/PreviewRoot/PreviewSprite
@onready var _details_section_label: Label = $Card/Padding/VStack/ContentLayout/PreviewDetails/DetailsPanel/DetailsMargin/DetailsVBox/DetailsLabel
@onready var _preset_name_label: Label = $Card/Padding/VStack/ContentLayout/PreviewDetails/DetailsPanel/DetailsMargin/DetailsVBox/SelectedPresetName
@onready var _preset_description_label: Label = $Card/Padding/VStack/ContentLayout/PreviewDetails/DetailsPanel/DetailsMargin/DetailsVBox/SelectedPresetDescription
@onready var _actions_row: BoxContainer = $Card/Padding/VStack/BottomButtons/TopRow
@onready var _confirm_button: Button = $Card/Padding/VStack/BottomButtons/TopRow/ConfirmButton
@onready var _randomize_button: Button = $Card/Padding/VStack/BottomButtons/TopRow/RandomizeButton
@onready var _cancel_button: Button = $Card/Padding/VStack/BottomButtons/BottomRow/CancelButton
@onready var _title_label: Label = $TitleBanner/BannerTexture/TitleLabel

var _button_group: MenuButtonGroup
var _preset_button_group: ButtonGroup
var _skin_catalog: PlayerSkinCatalog
var _presets: Array[PlayerSkinDefinition] = []
var _preset_buttons: Array[Button] = []
var _selected_preset_idx: int = -1
var _loaded_appearance: PlayerAppearanceData


func _ready() -> void:
	_reload_catalog_state()
	_build_preset_buttons()
	_apply_style()
	_setup_button_group()
	_wire_buttons()
	_overworld_preview_area.resized.connect(_on_preview_resized)
	_battle_preview_area.resized.connect(_on_preview_resized)
	call_deferred("_refresh")


func show_panel(_context: Variant = null) -> void:
	visible = true
	_reload_catalog_state()
	_build_preset_buttons()
	_apply_style()
	call_deferred("_refresh")


func hide_panel() -> void:
	visible = false


func _reload_catalog_state() -> void:
	_skin_catalog = PlayerProfileService.get_skin_catalog() as PlayerSkinCatalog
	_presets.clear()
	if _skin_catalog != null:
		_presets = _skin_catalog.get_selectable_skins()

	var saved_appearance: Resource = PlayerProfileService.get_appearance()
	if saved_appearance is PlayerAppearanceData and saved_appearance.has_method("duplicate_data"):
		_loaded_appearance = saved_appearance.call("duplicate_data") as PlayerAppearanceData
	elif saved_appearance is PlayerAppearanceData:
		_loaded_appearance = saved_appearance as PlayerAppearanceData
	else:
		_loaded_appearance = PlayerAppearanceData.new()

	if _loaded_appearance == null:
		_loaded_appearance = PlayerAppearanceData.new()
	_loaded_appearance.ensure_defaults()

	_selected_preset_idx = _resolve_initial_selection(_loaded_appearance.skin_id)


func _resolve_initial_selection(preferred_skin_id: StringName) -> int:
	if _presets.is_empty():
		return -1

	if preferred_skin_id != StringName():
		for i: int in _presets.size():
			var preset: PlayerSkinDefinition = _presets[i]
			if preset != null and preset.skin_id == preferred_skin_id:
				return i

	if _skin_catalog != null:
		var default_skin: PlayerSkinDefinition = _skin_catalog.get_default_skin()
		if default_skin != null:
			for i: int in _presets.size():
				var preset: PlayerSkinDefinition = _presets[i]
				if preset != null and preset.skin_id == default_skin.skin_id:
					return i

	return 0


func _build_preset_buttons() -> void:
	for button: Button in _preset_buttons:
		if is_instance_valid(button):
			if button.get_parent() == _preset_list:
				_preset_list.remove_child(button)
			button.queue_free()
	_preset_buttons.clear()

	_preset_button_group = ButtonGroup.new()
	_preset_button_template.visible = false

	for i: int in _presets.size():
		var preset: PlayerSkinDefinition = _presets[i]
		if preset == null:
			continue
		var button := _preset_button_template.duplicate() as Button
		button.name = "PresetButton_%s" % String(preset.skin_id)
		button.visible = true
		button.text = preset.display_name
		button.toggle_mode = true
		button.button_group = _preset_button_group
		button.pressed.connect(_on_preset_selected.bind(i))
		_preset_list.add_child(button)
		_preset_buttons.append(button)

	_update_preset_button_states()


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

	for label: Label in [_preset_section_label, _overworld_preview_title, _battle_preview_title, _details_section_label]:
		_style_section_label(label, font, gold)

	if _preset_name_label != null:
		if font:
			_preset_name_label.add_theme_font_override("font", font)
		_preset_name_label.add_theme_font_size_override("font_size", FONT_SIZE_NAME)
		_preset_name_label.add_theme_color_override("font_color", gold)

	if _preset_description_label != null:
		if font:
			_preset_description_label.add_theme_font_override("font", font)
		_preset_description_label.add_theme_font_size_override("font_size", FONT_SIZE_DESCRIPTION)
		_preset_description_label.add_theme_color_override("font_color", gold)

	if _title_label and font:
		_title_label.add_theme_font_override("font", font)
		_title_label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
		_title_label.add_theme_color_override("font_color", gold)

	for button: Button in _preset_buttons:
		_style_preset_button(button, font, gold, gold_hover)


func _style_section_label(label: Label, font: FontFile, color: Color) -> void:
	if label == null:
		return
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", FONT_SIZE_SECTION)
	label.add_theme_color_override("font_color", color)


func _style_preset_button(button: Button, font: FontFile, base_color: Color, hover_color: Color) -> void:
	if button == null:
		return

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.13, 0.10, 0.07, 0.68)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.50, 0.40, 0.24, 0.70)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	normal.content_margin_left = 14
	normal.content_margin_top = 10
	normal.content_margin_right = 14
	normal.content_margin_bottom = 10

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.21, 0.17, 0.11, 0.84)
	hover.border_color = Color(0.83, 0.73, 0.46, 0.95)

	var selected := normal.duplicate() as StyleBoxFlat
	selected.bg_color = Color(0.31, 0.24, 0.12, 0.92)
	selected.border_color = Color(1.0, 0.92, 0.62, 1.0)

	button.custom_minimum_size = PRESET_BUTTON_MIN_SIZE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_stylebox_override("disabled", normal)
	if font:
		button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", FONT_SIZE_PRESET)
	button.add_theme_color_override("font_color", base_color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", hover_color)
	button.add_theme_color_override("font_focus_color", hover_color)


func _setup_button_group() -> void:
	_button_group = MenuButtonGroup.new()
	_button_group.font_size_normal = FONT_SIZE_BUTTON
	_button_group.font_size_hover = FONT_SIZE_BUTTON + 4
	add_child(_button_group)
	_button_group.setup([_confirm_button, _randomize_button, _cancel_button])


func _wire_buttons() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_randomize_button.pressed.connect(_on_randomize_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func _on_preset_selected(index: int) -> void:
	_select_preset(index, false)


func _select_preset(index: int, should_grab_focus: bool) -> void:
	if index < 0 or index >= _presets.size():
		return
	_selected_preset_idx = index
	_update_preset_button_states()
	if should_grab_focus and index < _preset_buttons.size():
		_preset_buttons[index].grab_focus()
	_refresh()


func _update_preset_button_states() -> void:
	for i: int in _preset_buttons.size():
		var button: Button = _preset_buttons[i]
		if button == null:
			continue
		button.set_pressed_no_signal(i == _selected_preset_idx)


func _refresh() -> void:
	var selected_preset: PlayerSkinDefinition = _get_selected_preset()
	_confirm_button.disabled = selected_preset == null
	_randomize_button.disabled = _presets.is_empty()

	if selected_preset == null:
		_preset_name_label.text = "No Presets Available"
		_preset_description_label.text = "Add at least one complete skin preset to the player skin catalog."
		_clear_preview(_overworld_preview_sprite)
		_clear_preview(_battle_preview_sprite)
		_position_preview_roots()
		return

	_preset_name_label.text = selected_preset.display_name
	var description: String = selected_preset.description.strip_edges()
	if description.is_empty():
		description = "This preset is ready to use."
	_preset_description_label.text = description

	_update_preview(
		_overworld_preview_sprite,
		selected_preset.overworld_idle_texture,
		OVERWORLD_FRAME_SIZE,
		OVERWORLD_PREVIEW_SCALE
	)
	_update_preview(
		_battle_preview_sprite,
		selected_preset.battle_idle_texture,
		BATTLE_FRAME_SIZE,
		BATTLE_PREVIEW_SCALE
	)
	_position_preview_roots()


func _get_selected_preset() -> PlayerSkinDefinition:
	if _selected_preset_idx < 0 or _selected_preset_idx >= _presets.size():
		return null
	return _presets[_selected_preset_idx]


func _update_preview(sprite: Sprite2D, texture: Texture2D, frame_size: int, scale_multiplier: float) -> void:
	if sprite == null:
		return
	if texture == null:
		_clear_preview(sprite)
		return
	sprite.texture = texture
	var texture_width: int = texture.get_width()
	if texture_width < frame_size or texture_width % frame_size != 0:
		sprite.hframes = 1
	else:
		sprite.hframes = maxi(texture_width / frame_size, 1)
	sprite.frame = 0
	sprite.scale = Vector2.ONE * scale_multiplier


func _clear_preview(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.texture = null
	sprite.hframes = 1
	sprite.frame = 0
	sprite.scale = Vector2.ONE


func _position_preview_roots() -> void:
	_overworld_preview_root.position = _overworld_preview_area.size / 2.0
	_battle_preview_root.position = _battle_preview_area.size / 2.0


func _on_preview_resized() -> void:
	_position_preview_roots()


func _on_confirm_pressed() -> void:
	var selected_preset: PlayerSkinDefinition = _get_selected_preset()
	if selected_preset == null:
		return

	var appearance: PlayerAppearanceData = PlayerAppearanceData.new()
	if _loaded_appearance != null and _loaded_appearance.has_method("duplicate_data"):
		appearance = _loaded_appearance.call("duplicate_data") as PlayerAppearanceData
	elif _loaded_appearance != null:
		appearance = _loaded_appearance.duplicate(true) as PlayerAppearanceData

	if appearance == null:
		appearance = PlayerAppearanceData.new()

	appearance.skin_id = selected_preset.skin_id
	appearance.ensure_defaults()
	appearance_confirmed.emit(appearance)


func _on_randomize_pressed() -> void:
	if _presets.is_empty():
		return

	var next_index: int = randi() % _presets.size()
	if _presets.size() > 1 and next_index == _selected_preset_idx:
		next_index = (_selected_preset_idx + 1 + (randi() % (_presets.size() - 1))) % _presets.size()
	_select_preset(next_index, true)


func _on_cancel_pressed() -> void:
	creation_cancelled.emit()
