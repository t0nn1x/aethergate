class_name OverworldCreatorHud
extends CanvasLayer

## Bottom-bar in-world customization panel.
## Call show_for_player() to display. Emits confirmed(appearance) on "Begin Adventure".

signal confirmed(appearance: Resource)
signal hidden()

const APPEARANCE_SCRIPT := preload("res://src/Entities/Player/Resources/player_appearance_data.gd")
const PANEL_TEXTURE_PATH := "res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_A.png"
const TITLE_TEXTURE_PATH := "res://src/Ui/Assets/UI-v1/Panels/Titles/F_UI_Title A.png"
const COMPASS_FONT_PATH := "res://Assets/Fonts/compass/Compass 9.ttf"
const AWESOME_FONT_PATH := "res://Assets/Fonts/awesome/Awesome 9.ttf"
const GOLD := Color(0.92, 0.85, 0.62)
const GOLD_BRIGHT := Color(1.0, 0.98, 0.78)
const DIM := Color(0.55, 0.52, 0.45)
const PANEL_HEIGHT: float = 300.0
const PREVIEW_FRAME_SIZE := Vector2(156.0, 156.0)
const PREVIEW_IMAGE_SIZE := Vector2(140.0, 140.0)

var _player: Player
var _catalog: PlayerCosmeticCatalog

## Array[StringName] per slot key
var _slot_ids: Dictionary = {&"head": [], &"body": [], &"legs": []}
var _slot_indices: Dictionary = {&"head": 0, &"body": 0, &"legs": 0}

## Label refs updated on each slot change
var _value_labels: Dictionary = {}
var _counter_labels: Dictionary = {}
var _preview_rects: Dictionary = {}
var _title_bar: Control = null
var _panel: Control = null
var _compass_font: Font
var _button_font: Font


func _ready() -> void:
	layer = 28
	_compass_font = load(COMPASS_FONT_PATH) as Font
	_button_font = load(AWESOME_FONT_PATH) as Font
	_build_panel()
	hide()


# initial_appearance is typed Resource because PlayerAppearanceData has no class_name.
func show_for_player(player: Player, catalog: PlayerCosmeticCatalog, initial_appearance: Resource) -> void:
	_player = player
	_catalog = catalog

	for slot: StringName in [&"head", &"body", &"legs"]:
		_slot_ids[slot] = catalog.get_ids_for_slot(slot)
		var field: String = String(slot) + "_id"
		var current_id: StringName = StringName(str(initial_appearance.get(field)))
		var idx: int = (_slot_ids[slot] as Array).find(current_id)
		_slot_indices[slot] = max(0, idx)

	_refresh_all_labels()

	if _title_bar:
		_title_bar.modulate.a = 0.0
	if _panel:
		_panel.modulate.a = 0.0
	show()
	var tween := create_tween()
	if _title_bar:
		tween.parallel().tween_property(_title_bar, "modulate:a", 1.0, 0.35) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func hide_hud() -> void:
	var tween := create_tween()
	if _title_bar:
		tween.parallel().tween_property(_title_bar, "modulate:a", 0.0, 0.25) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.25) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(hide)
	tween.tween_callback(func() -> void: hidden.emit())


# --- Internals ---

func _step_slot(slot: StringName, delta: int) -> void:
	var ids: Array = _slot_ids[slot]
	if ids.is_empty():
		return
	_slot_indices[slot] = (_slot_indices[slot] + delta + ids.size()) % ids.size()
	_refresh_slot_label(slot)
	_apply_appearance()


func _randomize_all() -> void:
	for slot: StringName in [&"head", &"body", &"legs"]:
		var ids: Array = _slot_ids[slot]
		if not ids.is_empty():
			_slot_indices[slot] = randi() % ids.size()
	_refresh_all_labels()
	_apply_appearance()


func _build_appearance() -> Resource:
	var appearance: Resource = APPEARANCE_SCRIPT.new()
	for slot: StringName in [&"head", &"body", &"legs"]:
		var ids: Array = _slot_ids[slot]
		if not ids.is_empty():
			appearance.set(String(slot) + "_id", ids[_slot_indices[slot]])
	return appearance


func _apply_appearance() -> void:
	if _player == null or not is_instance_valid(_player) or _catalog == null:
		return
	_player.apply_appearance(_build_appearance(), _catalog)


func _refresh_all_labels() -> void:
	for slot: StringName in [&"head", &"body", &"legs"]:
		_refresh_slot_label(slot)


func _refresh_slot_label(slot: StringName) -> void:
	var ids: Array = _slot_ids[slot]
	var idx: int = _slot_indices[slot]

	if _value_labels.has(slot):
		var raw_id: StringName = ids[idx] if not ids.is_empty() else StringName()
		(_value_labels[slot] as Label).text = _id_to_display(raw_id)
		if _preview_rects.has(slot):
			var preview_rect := _preview_rects[slot] as TextureRect
			if preview_rect:
				preview_rect.texture = _get_preview_texture(slot, raw_id)

	if _counter_labels.has(slot):
		(_counter_labels[slot] as Label).text = "%d / %d" % [idx + 1, ids.size()]


func _id_to_display(slot_id: StringName) -> String:
	if slot_id == StringName():
		return "—"
	return String(slot_id).replace("_", " ").capitalize()


# --- UI Construction ---

func _build_panel() -> void:
	_build_title_bar()

	var nine := NinePatchRect.new()
	_panel = nine
	_panel.name = "Panel"
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = -PANEL_HEIGHT
	_panel.offset_bottom = 0.0

	var tex := load(PANEL_TEXTURE_PATH) as Texture2D
	if tex:
		nine.texture = tex
		var patch_margin: int = clampi(int(tex.get_width() * 0.30), 10, 30)
		nine.patch_margin_left = patch_margin
		nine.patch_margin_right = patch_margin
		nine.patch_margin_top = patch_margin
		nine.patch_margin_bottom = patch_margin
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	for slot: StringName in [&"head", &"body", &"legs"]:
		_build_slot_column(hbox, slot)

	_build_action_column(hbox)


func _build_title_bar() -> void:
	var title_nine := NinePatchRect.new()
	_title_bar = title_nine
	title_nine.name = "CreatorTitleBar"
	title_nine.anchor_left = 0.5
	title_nine.anchor_right = 0.5
	title_nine.anchor_top = 0.0
	title_nine.anchor_bottom = 0.0
	title_nine.offset_left = -360.0
	title_nine.offset_right = 360.0
	title_nine.offset_top = 14.0
	title_nine.offset_bottom = 98.0

	var tex := load(TITLE_TEXTURE_PATH) as Texture2D
	if tex:
		title_nine.texture = tex
		var margin_x: int = clampi(int(tex.get_width() * 0.25), 6, 20)
		var margin_y: int = clampi(int(tex.get_height() * 0.25), 3, 8)
		title_nine.patch_margin_left = margin_x
		title_nine.patch_margin_right = margin_x
		title_nine.patch_margin_top = margin_y
		title_nine.patch_margin_bottom = margin_y
	add_child(_title_bar)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_bar.add_child(center)

	var title_lbl := Label.new()
	title_lbl.text = "CREATE YOUR ADVENTURER"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", GOLD_BRIGHT)
	title_lbl.add_theme_font_size_override("font_size", 34)
	if _compass_font:
		title_lbl.add_theme_font_override("font", _compass_font)
	center.add_child(title_lbl)


func _build_slot_column(parent: HBoxContainer, slot: StringName) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_inner_card_style())
	parent.add_child(card)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)

	var header := Label.new()
	header.text = String(slot).to_upper()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", GOLD)
	header.add_theme_font_size_override("font_size", 22)
	if _compass_font:
		header.add_theme_font_override("font", _compass_font)
	col.add_child(header)

	var preview_row := HBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 10)
	col.add_child(preview_row)

	var s := slot

	var prev_btn := _make_nav_button("‹")
	prev_btn.pressed.connect(func() -> void: _step_slot(s, -1))
	preview_row.add_child(prev_btn)

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = PREVIEW_FRAME_SIZE
	preview_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_frame.add_theme_stylebox_override("panel", _make_preview_frame_style())
	preview_row.add_child(preview_frame)

	var preview_center := CenterContainer.new()
	preview_frame.add_child(preview_center)

	var preview := TextureRect.new()
	preview.custom_minimum_size = PREVIEW_IMAGE_SIZE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_center.add_child(preview)
	_preview_rects[slot] = preview

	var next_btn := _make_nav_button("›")
	next_btn.pressed.connect(func() -> void: _step_slot(s, 1))
	preview_row.add_child(next_btn)

	var value_lbl := Label.new()
	value_lbl.text = "—"
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.add_theme_color_override("font_color", GOLD_BRIGHT)
	value_lbl.add_theme_font_size_override("font_size", 20)
	if _compass_font:
		value_lbl.add_theme_font_override("font", _compass_font)
	col.add_child(value_lbl)
	_value_labels[slot] = value_lbl

	var counter_lbl := Label.new()
	counter_lbl.text = "1 / 1"
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_lbl.add_theme_color_override("font_color", DIM)
	counter_lbl.add_theme_font_size_override("font_size", 14)
	col.add_child(counter_lbl)
	_counter_labels[slot] = counter_lbl


func _build_action_column(parent: HBoxContainer) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_inner_card_style())
	parent.add_child(card)

	var col := VBoxContainer.new()
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	card.add_child(col)

	var randomize_btn := _make_action_button("RANDOMIZE")
	randomize_btn.pressed.connect(_randomize_all)
	col.add_child(randomize_btn)

	var begin_btn := _make_action_button("BEGIN ADVENTURE")
	begin_btn.pressed.connect(func() -> void: confirmed.emit(_build_appearance()))
	col.add_child(begin_btn)


func _make_nav_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(52.0, 52.0)
	btn.add_theme_color_override("font_color", GOLD_BRIGHT)
	btn.add_theme_font_size_override("font_size", 28)
	if _button_font:
		btn.add_theme_font_override("font", _button_font)
	btn.add_theme_stylebox_override("normal", _make_embossed_style())
	btn.add_theme_stylebox_override("hover", _make_embossed_hover_style())
	btn.add_theme_stylebox_override("pressed", _make_embossed_pressed_style())
	return btn


func _make_action_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260.0, 64.0)
	btn.add_theme_color_override("font_color", GOLD_BRIGHT)
	btn.add_theme_font_size_override("font_size", 22)
	if _button_font:
		btn.add_theme_font_override("font", _button_font)
	btn.add_theme_stylebox_override("normal", _make_embossed_style())
	btn.add_theme_stylebox_override("hover", _make_embossed_hover_style())
	btn.add_theme_stylebox_override("pressed", _make_embossed_pressed_style())
	return btn


func _make_embossed_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.05, 0.90)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.border_width_bottom = 3
	s.border_width_top = 1
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_color = Color(0.45, 0.38, 0.22, 0.50)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0.0, 3.0)
	s.content_margin_left = 12.0
	s.content_margin_right = 12.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


func _make_inner_card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.035, 0.03, 0.72)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.border_width_left = 3
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(GOLD, 0.35)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0.0, 2.0)
	s.content_margin_left = 14.0
	s.content_margin_top = 12.0
	s.content_margin_right = 14.0
	s.content_margin_bottom = 12.0
	return s


func _make_preview_frame_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.08, 0.06, 0.86)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.border_width_top = 1
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_bottom = 2
	s.border_color = Color(GOLD, 0.28)
	s.content_margin_left = 8.0
	s.content_margin_top = 8.0
	s.content_margin_right = 8.0
	s.content_margin_bottom = 8.0
	return s


func _make_embossed_hover_style() -> StyleBoxFlat:
	var s := _make_embossed_style()
	s.bg_color = Color(0.12, 0.10, 0.06, 0.95)
	s.border_color = Color(0.92, 0.85, 0.62, 0.70)
	return s


func _make_embossed_pressed_style() -> StyleBoxFlat:
	var s := _make_embossed_style()
	s.bg_color = Color(0.06, 0.06, 0.04, 0.95)
	s.border_width_top = 3
	s.border_width_bottom = 1
	return s


func _get_preview_texture(slot: StringName, slot_id: StringName) -> Texture2D:
	if _catalog == null or slot_id == StringName():
		return null

	var source: Texture2D = null
	match slot:
		&"head":
			source = _catalog.get_head_texture(slot_id)
		&"body":
			source = _catalog.get_body_texture(slot_id)
		&"legs":
			source = _catalog.get_legs_texture(slot_id)
		_:
			return null

	if source == null:
		return null

	var source_size: Vector2 = source.get_size()
	if source_size.x <= source_size.y:
		return source

	var frame_width: int = int(source_size.y)
	if frame_width <= 0:
		return source

	var source_image: Image = source.get_image()
	if source_image == null or source_image.is_empty():
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = source
		atlas_texture.region = Rect2(0.0, 0.0, float(frame_width), source_size.y)
		return atlas_texture

	var frame_height: int = int(source_size.y)
	var frame_image := Image.create(frame_width, frame_height, false, source_image.get_format())
	frame_image.blit_rect(source_image, Rect2i(0, 0, frame_width, frame_height), Vector2i.ZERO)

	var used_rect: Rect2i = frame_image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		var fallback_texture := AtlasTexture.new()
		fallback_texture.atlas = source
		fallback_texture.region = Rect2(0.0, 0.0, float(frame_width), source_size.y)
		return fallback_texture

	var cropped_image := Image.create(
		used_rect.size.x,
		used_rect.size.y,
		false,
		source_image.get_format()
	)
	cropped_image.blit_rect(frame_image, used_rect, Vector2i.ZERO)
	return ImageTexture.create_from_image(cropped_image)
