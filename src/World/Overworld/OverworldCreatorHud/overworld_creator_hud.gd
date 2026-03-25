class_name OverworldCreatorHud
extends CanvasLayer

## Right-side in-world customization panel.
## Call show_for_player() to display. Emits confirmed(appearance) on "Begin Adventure".

signal confirmed(appearance: Resource)

const APPEARANCE_SCRIPT := preload("res://src/Entities/Player/Resources/player_appearance_data.gd")

const PANEL_WIDTH: float = 300.0
const BG_COLOR := Color(0.031, 0.055, 0.102, 0.93)
const BORDER_COLOR := Color(0.784, 0.659, 0.478, 0.25)
const SLOT_LABEL_COLOR := Color(0.478, 0.604, 0.800)
const VALUE_COLOR := Color(0.910, 0.847, 0.722)
const GOLD_COLOR := Color(0.784, 0.659, 0.478)

var _player: Player
var _catalog: PlayerCosmeticCatalog

## Array[StringName] per slot key
var _slot_ids: Dictionary = {&"head": [], &"body": [], &"legs": []}
var _slot_indices: Dictionary = {&"head": 0, &"body": 0, &"legs": 0}

## Label refs updated on each slot change
var _value_labels: Dictionary = {}
var _counter_labels: Dictionary = {}
var _customizing_label: Label = null


func _ready() -> void:
	layer = 28
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
	_add_customizing_label()

	modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func hide_hud() -> void:
	_remove_customizing_label()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(hide)


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

	if _counter_labels.has(slot):
		(_counter_labels[slot] as Label).text = "%d / %d" % [idx + 1, ids.size()]


func _id_to_display(slot_id: StringName) -> String:
	if slot_id == StringName():
		return "—"
	return String(slot_id).replace("_", " ").capitalize()


func _add_customizing_label() -> void:
	_remove_customizing_label()
	if _player == null or not is_instance_valid(_player):
		return
	_customizing_label = Label.new()
	_customizing_label.text = "CUSTOMIZING"
	_customizing_label.position = Vector2(-45.0, -68.0)
	_customizing_label.add_theme_color_override("font_color", GOLD_COLOR)
	_customizing_label.add_theme_font_size_override("font_size", 11)
	_player.add_child(_customizing_label)


func _remove_customizing_label() -> void:
	if _customizing_label != null and is_instance_valid(_customizing_label):
		_customizing_label.queue_free()
	_customizing_label = null


# --- UI Construction ---

func _build_panel() -> void:
	var panel := Panel.new()
	panel.name = "Panel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -PANEL_WIDTH
	panel.offset_right = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.add_theme_stylebox_override("panel", _make_flat_style(BG_COLOR, BORDER_COLOR, 1))
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	# Header
	var header_lbl := Label.new()
	header_lbl.text = "YOUR ADVENTURER"
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.add_theme_color_override("font_color", GOLD_COLOR)
	header_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(header_lbl)

	vbox.add_child(_make_hsep(Color(0.784, 0.659, 0.478, 0.15)))

	# Slots (fill middle)
	var slots_vbox := VBoxContainer.new()
	slots_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(slots_vbox)

	for slot: StringName in [&"head", &"body", &"legs"]:
		_build_slot_row(slots_vbox, slot)

	vbox.add_child(_make_hsep(Color(0.784, 0.659, 0.478, 0.12)))

	# Bottom buttons (always visible, not scrollable)
	var bottom_vbox := VBoxContainer.new()
	vbox.add_child(bottom_vbox)

	var randomize_btn := _make_text_button("RANDOMIZE", GOLD_COLOR * Color(0.85, 0.85, 0.85, 1.0))
	randomize_btn.pressed.connect(_randomize_all)
	bottom_vbox.add_child(randomize_btn)

	var begin_btn := _make_text_button("BEGIN ADVENTURE", GOLD_COLOR)
	begin_btn.add_theme_stylebox_override(
		"normal",
		_make_flat_style(Color(0.784, 0.659, 0.478, 0.2), Color(0.784, 0.659, 0.478, 0.55), 2)
	)
	begin_btn.add_theme_stylebox_override(
		"hover",
		_make_flat_style(Color(0.784, 0.659, 0.478, 0.3), Color(0.784, 0.659, 0.478, 0.75), 2)
	)
	begin_btn.pressed.connect(func() -> void: confirmed.emit(_build_appearance()))
	bottom_vbox.add_child(begin_btn)


func _build_slot_row(parent: VBoxContainer, slot: StringName) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override(
		"panel",
		_make_flat_style(Color(0.784, 0.659, 0.478, 0.06), Color(0.784, 0.659, 0.478, 0.18), 1, 6)
	)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var inner := VBoxContainer.new()
	row.add_child(inner)

	var title_lbl := Label.new()
	title_lbl.text = String(slot).to_upper()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", SLOT_LABEL_COLOR)
	title_lbl.add_theme_font_size_override("font_size", 10)
	inner.add_child(title_lbl)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(hbox)

	# Capture slot for closures
	var s := slot

	var prev_btn := _make_nav_button("‹")
	prev_btn.pressed.connect(func() -> void: _step_slot(s, -1))
	hbox.add_child(prev_btn)

	var center_vbox := VBoxContainer.new()
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(center_vbox)

	var value_lbl := Label.new()
	value_lbl.text = "—"
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.add_theme_color_override("font_color", VALUE_COLOR)
	value_lbl.add_theme_font_size_override("font_size", 12)
	center_vbox.add_child(value_lbl)
	_value_labels[slot] = value_lbl

	var counter_lbl := Label.new()
	counter_lbl.text = "1 / 1"
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_lbl.add_theme_color_override("font_color", Color(0.35, 0.42, 0.35))
	counter_lbl.add_theme_font_size_override("font_size", 9)
	center_vbox.add_child(counter_lbl)
	_counter_labels[slot] = counter_lbl

	var next_btn := _make_nav_button("›")
	next_btn.pressed.connect(func() -> void: _step_slot(s, 1))
	hbox.add_child(next_btn)


func _make_nav_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_color_override("font_color", GOLD_COLOR)
	btn.add_theme_font_size_override("font_size", 20)
	btn.custom_minimum_size = Vector2(32.0, 32.0)
	btn.add_theme_stylebox_override("normal",
		_make_flat_style(Color(0.784, 0.659, 0.478, 0.10), Color(0.784, 0.659, 0.478, 0.25), 1, 4))
	btn.add_theme_stylebox_override("hover",
		_make_flat_style(Color(0.784, 0.659, 0.478, 0.20), Color(0.784, 0.659, 0.478, 0.45), 1, 4))
	return btn


func _make_text_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_stylebox_override("normal",
		_make_flat_style(Color(0.784, 0.659, 0.478, 0.07), Color(0.784, 0.659, 0.478, 0.20), 1, 5))
	btn.add_theme_stylebox_override("hover",
		_make_flat_style(Color(0.784, 0.659, 0.478, 0.15), Color(0.784, 0.659, 0.478, 0.40), 1, 5))
	return btn


func _make_hsep(color: Color) -> HSeparator:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	sep.add_theme_stylebox_override("separator", style)
	return sep


func _make_flat_style(
	bg: Color,
	border: Color,
	border_width: int = 1,
	corner_radius: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style
