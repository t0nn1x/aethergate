class_name UiShowcase
extends CanvasLayer

## UI element showcase scene — triggered from the debug panel.
## Displays multiple style variations of buttons, panels, cards, and labels
## so the developer can pick favorites for the final game UI.

const COMPASS_FONT_PATH := "res://Assets/Fonts/compass/Compass 9.ttf"
const AWESOME_FONT_PATH := "res://Assets/Fonts/awesome/Awesome 9.ttf"

# 9-slice panel textures
const PANEL_PATHS: Array[String] = [
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_A.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_B.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_C.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_D.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_E.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_F.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_G.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_H.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_I.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_L.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_M.png",
	"res://src/Ui/Assets/UI-v1/Panels/Panels/F_UI_Panel_N.png",
]

const TITLE_PATHS: Array[String] = [
	"res://src/Ui/Assets/UI-v1/Panels/Titles/F_UI_Title A.png",
	"res://src/Ui/Assets/UI-v1/Panels/Titles/F_UI_Title B.png",
	"res://src/Ui/Assets/UI-v1/Panels/Titles/F_UI_Title C.png",
	"res://src/Ui/Assets/UI-v1/Panels/Titles/F_UI_Title D.png",
	"res://src/Ui/Assets/UI-v1/Panels/Titles/F_UI_Title E.png",
]

const FRAME_PATHS: Array[String] = [
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame0.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame1.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame2.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame3.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame4.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame5.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame6.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame7.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame8.png",
	"res://src/Ui/Assets/UI-v1/Panels/Frames/F_U_Frame9.png",
]

const SLOT_PATHS: Array[String] = [
	"res://src/Ui/Assets/UI-v1/Panels/Slots/F_U_SlotA1.png",
	"res://src/Ui/Assets/UI-v1/Panels/Slots/F_U_SlotB1.png",
	"res://src/Ui/Assets/UI-v1/Panels/Slots/F_U_SlotC1.png",
	"res://src/Ui/Assets/UI-v1/Panels/Slots/F_U_SlotD1.png",
	"res://src/Ui/Assets/UI-v1/Panels/Slots/F_U_SlotE1.png",
	"res://src/Ui/Assets/UI-v1/Panels/Slots/F_U_SlotF1.png",
]

# Palette
const GOLD := Color(0.92, 0.85, 0.62)
const GOLD_BRIGHT := Color(1.0, 0.98, 0.78)
const PARCHMENT := Color(0.976, 0.906, 0.616)
const WARM_WHITE := Color(0.98, 0.95, 0.88)
const DIM := Color(0.55, 0.52, 0.45)
const DARK_BG := Color(0.04, 0.05, 0.08, 0.96)

var _compass_font: Font
var _awesome_font: Font
var _bg: ColorRect
var _scroll: ScrollContainer
var _current_page: int = 0
var _pages: Array[Control] = []
var _page_label: Label
var _page_names: Array[String] = [
	"FLAT BUTTONS", "FLAT PANELS",
	"TEXTURED PANELS", "TITLE BARS", "FRAMES & SLOTS",
	"COMPOSED CARDS", "CIRCLE BUTTONS & SLOTS",
	"NOTIFICATIONS & DIALOGS", "FULL MOCKUPS", "TYPOGRAPHY"
]


func _ready() -> void:
	layer = 110
	_compass_font = load(COMPASS_FONT_PATH)
	_awesome_font = load(AWESOME_FONT_PATH)
	_build_ui()
	add_to_group(&"ui_panels_block_movement")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()
		elif kc == KEY_RIGHT or kc == KEY_D:
			_next_page()
			get_viewport().set_input_as_handled()
		elif kc == KEY_LEFT or kc == KEY_A:
			_prev_page()
			get_viewport().set_input_as_handled()


func _close() -> void:
	queue_free()


func _next_page() -> void:
	_current_page = (_current_page + 1) % _pages.size()
	_show_page()


func _prev_page() -> void:
	_current_page = (_current_page - 1 + _pages.size()) % _pages.size()
	_show_page()


func _show_page() -> void:
	for i: int in _pages.size():
		_pages[i].visible = (i == _current_page)
	_page_label.text = "%s  (%d/%d)" % [_page_names[_current_page], _current_page + 1, _pages.size()]


# ─── BUILD ──────────────────────────────────────────────

func _build_ui() -> void:
	# Full-screen dim bg
	_bg = ColorRect.new()
	_bg.color = DARK_BG
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.gui_input.connect(func(_e: InputEvent) -> void:
		get_viewport().set_input_as_handled()
	)
	add_child(_bg)

	# Root margin
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 40)
	root_margin.add_theme_constant_override("margin_right", 40)
	root_margin.add_theme_constant_override("margin_top", 30)
	root_margin.add_theme_constant_override("margin_bottom", 30)
	add_child(root_margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	root_margin.add_child(outer)

	# ── Top bar ──
	var top_bar := _build_top_bar()
	outer.add_child(top_bar)

	_add_spacer(outer, 16)

	# ── Page container (scroll) ──
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	outer.add_child(_scroll)

	var page_host := Control.new()
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(page_host)

	# Build all pages
	_pages.append(_build_flat_buttons_page())
	_pages.append(_build_flat_panels_page())
	_pages.append(_build_textured_panels_page())
	_pages.append(_build_title_bars_page())
	_pages.append(_build_frames_slots_page())
	_pages.append(_build_composed_cards_page())
	_pages.append(_build_circle_buttons_slots_page())
	_pages.append(_build_notifications_dialogs_page())
	_pages.append(_build_full_mockups_page())
	_pages.append(_build_typography_page())

	for page: Control in _pages:
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll.add_child(page)

	# Remove the unused placeholder host
	page_host.queue_free()

	_show_page()


func _build_top_bar() -> PanelContainer:
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.06, 0.07, 0.10, 0.85)
	bar_style.border_width_bottom = 2
	bar_style.border_color = Color(GOLD, 0.35)
	bar_style.corner_radius_top_left = 10
	bar_style.corner_radius_top_right = 10
	bar_style.content_margin_left = 20.0
	bar_style.content_margin_right = 20.0
	bar_style.content_margin_top = 12.0
	bar_style.content_margin_bottom = 12.0

	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", bar_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	bar.add_child(hbox)

	# Close
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(48, 40)
	_apply_font(close_btn, _awesome_font, 20)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.48, 0.42))
	_apply_flat_btn_style(close_btn, Color(0.20, 0.06, 0.06, 0.6), Color(0.85, 0.2, 0.15, 0.5), 6)
	close_btn.pressed.connect(_close)
	hbox.add_child(close_btn)

	# Prev
	var prev_btn := Button.new()
	prev_btn.text = "<"
	prev_btn.custom_minimum_size = Vector2(48, 40)
	_apply_font(prev_btn, _awesome_font, 20)
	prev_btn.add_theme_color_override("font_color", GOLD)
	_apply_flat_btn_style(prev_btn, Color(GOLD, 0.06), Color(GOLD, 0.3), 6)
	prev_btn.pressed.connect(_prev_page)
	hbox.add_child(prev_btn)

	# Page name
	_page_label = _make_label("", GOLD_BRIGHT, _compass_font, 24)
	_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(_page_label)

	# Next
	var next_btn := Button.new()
	next_btn.text = ">"
	next_btn.custom_minimum_size = Vector2(48, 40)
	_apply_font(next_btn, _awesome_font, 20)
	next_btn.add_theme_color_override("font_color", GOLD)
	_apply_flat_btn_style(next_btn, Color(GOLD, 0.06), Color(GOLD, 0.3), 6)
	next_btn.pressed.connect(_next_page)
	hbox.add_child(next_btn)

	return bar


# ════════════════════════════════════════════════════════════
#  PAGE 1: FLAT BUTTONS
# ════════════════════════════════════════════════════════════

func _build_flat_buttons_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 24)

	# --- Style A: "Raised Tab" (bottom gold edge) ---
	page.add_child(_section_label("A: Raised Tab — bottom gold edge"))
	var row_a := _hbox(8)
	for text: String in ["Play", "Inventory", "Settings"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 52)
		_apply_font(btn, _awesome_font, 20)
		btn.add_theme_color_override("font_color", GOLD)
		var ns := _flat(Color(0.10, 0.10, 0.14, 0.85), 8)
		ns.border_width_bottom = 3
		ns.border_color = Color(GOLD, 0.6)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := _flat(Color(0.15, 0.15, 0.19, 0.95), 8)
		hs.border_width_bottom = 3
		hs.border_width_top = 1
		hs.border_width_left = 1
		hs.border_width_right = 1
		hs.border_color = Color(GOLD, 0.7)
		btn.add_theme_stylebox_override("hover", hs)
		var ps := _flat(Color(0.18, 0.17, 0.14, 0.95), 8)
		ps.border_width_top = 3
		ps.border_color = Color(GOLD, 0.5)
		btn.add_theme_stylebox_override("pressed", ps)
		row_a.add_child(btn)
	page.add_child(row_a)

	# --- Style B: "Glass Pill" (rounded, semi-transparent) ---
	page.add_child(_section_label("B: Glass Pill — rounded, semi-transparent"))
	var row_b := _hbox(8)
	for text: String in ["Accept", "Decline", "Cancel"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 52)
		_apply_font(btn, _awesome_font, 20)
		btn.add_theme_color_override("font_color", WARM_WHITE)
		btn.add_theme_stylebox_override("normal", _flat(Color(0.25, 0.25, 0.30, 0.40), 22))
		var hs := _flat(Color(0.35, 0.35, 0.42, 0.55), 22)
		hs.border_width_bottom = 1
		hs.border_width_top = 1
		hs.border_width_left = 1
		hs.border_width_right = 1
		hs.border_color = Color(GOLD, 0.5)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", _flat(Color(0.20, 0.20, 0.24, 0.65), 22))
		row_b.add_child(btn)
	page.add_child(row_b)

	# --- Style C: "Bordered Slab" (thick border, sharp corners) ---
	page.add_child(_section_label("C: Bordered Slab — thick border, no radius"))
	var row_c := _hbox(8)
	for text: String in ["Fight", "Flee", "Talk"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 52)
		_apply_font(btn, _awesome_font, 20)
		btn.add_theme_color_override("font_color", PARCHMENT)
		var ns := _flat(Color(0.06, 0.08, 0.12, 0.80), 0)
		ns.border_width_bottom = 2
		ns.border_width_top = 2
		ns.border_width_left = 2
		ns.border_width_right = 2
		ns.border_color = Color(GOLD, 0.45)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(0.10, 0.12, 0.18, 0.90)
		hs.border_color = Color(GOLD, 0.85)
		btn.add_theme_stylebox_override("hover", hs)
		var ps := ns.duplicate() as StyleBoxFlat
		ps.bg_color = Color(0.14, 0.12, 0.10, 0.90)
		ps.border_color = Color(GOLD, 0.65)
		btn.add_theme_stylebox_override("pressed", ps)
		row_c.add_child(btn)
	page.add_child(row_c)

	# --- Style D: "Left Accent" (colored left bar) ---
	page.add_child(_section_label("D: Left Accent — colored left bar"))
	var row_d := VBoxContainer.new()
	row_d.add_theme_constant_override("separation", 6)
	var accent_colors: Array[Color] = [
		Color(0.92, 0.78, 0.28), Color(0.45, 0.78, 0.95), Color(0.85, 0.35, 0.30),
	]
	var accent_texts: Array[String] = ["Quest Log", "Bestiary", "Danger Zone"]
	for i: int in 3:
		var btn := Button.new()
		btn.text = accent_texts[i]
		btn.custom_minimum_size = Vector2(300, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_font(btn, _awesome_font, 18)
		btn.add_theme_color_override("font_color", WARM_WHITE)
		var ns := _flat(Color(0.08, 0.08, 0.11, 0.70), 4)
		ns.border_width_left = 4
		ns.border_color = accent_colors[i]
		ns.content_margin_left = 18.0
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(0.12, 0.12, 0.16, 0.85)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row_d.add_child(btn)
	page.add_child(row_d)

	# --- Style E: "Embossed" (inset top shadow, outer glow bottom) ---
	page.add_child(_section_label("E: Embossed — gradient depth illusion"))
	var row_e := _hbox(8)
	for text: String in ["Craft", "Enchant", "Forge"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 56)
		_apply_font(btn, _compass_font, 22)
		btn.add_theme_color_override("font_color", GOLD_BRIGHT)
		var ns := _flat(Color(0.08, 0.07, 0.05, 0.90), 10)
		ns.border_width_bottom = 3
		ns.border_width_top = 1
		ns.border_color = Color(0.45, 0.38, 0.22, 0.50)
		ns.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		ns.shadow_size = 6
		ns.shadow_offset = Vector2(0, 3)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(0.12, 0.10, 0.06, 0.95)
		hs.border_color = Color(GOLD, 0.70)
		btn.add_theme_stylebox_override("hover", hs)
		var ps := _flat(Color(0.06, 0.06, 0.04, 0.95), 10)
		ps.border_width_top = 3
		ps.border_color = Color(0.30, 0.28, 0.18, 0.5)
		btn.add_theme_stylebox_override("pressed", ps)
		row_e.add_child(btn)
	page.add_child(row_e)

	# --- Style F: "Danger / CTA" (red tinted, pulsing feel) ---
	page.add_child(_section_label("F: Danger CTA — red accent, heavy"))
	var row_f := _hbox(8)
	for text: String in ["Delete Character", "Reset Progress"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(240, 52)
		_apply_font(btn, _awesome_font, 18)
		btn.add_theme_color_override("font_color", Color(1.0, 0.50, 0.45))
		var ns := _flat(Color(0.18, 0.04, 0.04, 0.80), 8)
		ns.border_width_bottom = 3
		ns.border_color = Color(0.85, 0.18, 0.12, 0.55)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := _flat(Color(0.28, 0.06, 0.06, 0.90), 8)
		hs.border_width_bottom = 3
		hs.border_width_top = 1
		hs.border_width_left = 1
		hs.border_width_right = 1
		hs.border_color = Color(1.0, 0.30, 0.25, 0.75)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", _flat(Color(0.14, 0.03, 0.03, 0.95), 8))
		row_f.add_child(btn)
	page.add_child(row_f)

	# --- Style G: "Outline Only" (transparent bg, border only) ---
	page.add_child(_section_label("G: Outline Only — transparent body"))
	var row_g := _hbox(8)
	for text: String in ["Map", "Journal", "Skills"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 52)
		_apply_font(btn, _awesome_font, 20)
		btn.add_theme_color_override("font_color", GOLD)
		var ns := _flat(Color(0.0, 0.0, 0.0, 0.0), 8)
		ns.border_width_bottom = 2
		ns.border_width_top = 2
		ns.border_width_left = 2
		ns.border_width_right = 2
		ns.border_color = Color(GOLD, 0.40)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(GOLD, 0.08)
		hs.border_color = Color(GOLD, 0.80)
		btn.add_theme_stylebox_override("hover", hs)
		var ps := ns.duplicate() as StyleBoxFlat
		ps.bg_color = Color(GOLD, 0.15)
		btn.add_theme_stylebox_override("pressed", ps)
		row_g.add_child(btn)
	page.add_child(row_g)

	# --- Style H: "Tag / Chip" (small pill, compact) ---
	page.add_child(_section_label("H: Tag / Chip — small rounded labels"))
	var row_h := _hbox(6)
	var tag_colors: Array[Color] = [
		Color(0.92, 0.78, 0.28), Color(0.45, 0.78, 0.95), Color(0.85, 0.35, 0.30),
		Color(0.55, 0.85, 0.45), Color(0.70, 0.50, 0.90),
	]
	var tag_texts: Array[String] = ["Common", "Rare", "Epic", "Quest", "Legendary"]
	for i: int in 5:
		var btn := Button.new()
		btn.text = tag_texts[i]
		btn.custom_minimum_size = Vector2(90, 36)
		_apply_font(btn, _awesome_font, 14)
		btn.add_theme_color_override("font_color", tag_colors[i])
		var ns := _flat(Color(tag_colors[i], 0.08), 16)
		ns.border_width_bottom = 1
		ns.border_width_top = 1
		ns.border_width_left = 1
		ns.border_width_right = 1
		ns.border_color = Color(tag_colors[i], 0.35)
		ns.content_margin_left = 14.0
		ns.content_margin_right = 14.0
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(tag_colors[i], 0.18)
		hs.border_color = Color(tag_colors[i], 0.65)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row_h.add_child(btn)
	page.add_child(row_h)

	# --- Style I: "Icon-Left Action" (wide, left-aligned with prefix) ---
	page.add_child(_section_label("I: Wide Action — icon prefix"))
	var row_i := VBoxContainer.new()
	row_i.add_theme_constant_override("separation", 6)
	var action_data: Array[Array] = [
		[">  Attack", Color(0.85, 0.30, 0.25)],
		["#  Defend", Color(0.45, 0.65, 0.95)],
		["~  Magic", Color(0.70, 0.50, 0.90)],
		["*  Item", Color(0.55, 0.85, 0.45)],
	]
	for data: Array in action_data:
		var btn := Button.new()
		btn.text = data[0] as String
		btn.custom_minimum_size = Vector2(400, 50)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_font(btn, _compass_font, 22)
		btn.add_theme_color_override("font_color", Color(data[1] as Color, 0.90))
		var c: Color = data[1] as Color
		var ns := _flat(Color(c, 0.06), 6)
		ns.border_width_left = 4
		ns.border_width_bottom = 1
		ns.border_color = Color(c, 0.45)
		ns.content_margin_left = 18.0
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(c, 0.14)
		hs.border_color = Color(c, 0.70)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row_i.add_child(btn)
	page.add_child(row_i)

	# --- Style J: "Soft Glow" (subtle radial feel via shadow) ---
	page.add_child(_section_label("J: Soft Glow — shadow haze, round"))
	var row_j := _hbox(10)
	for text: String in ["Select", "Confirm", "Back"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 54)
		_apply_font(btn, _compass_font, 22)
		btn.add_theme_color_override("font_color", GOLD_BRIGHT)
		var ns := _flat(Color(0.10, 0.09, 0.07, 0.85), 12)
		ns.shadow_color = Color(GOLD, 0.10)
		ns.shadow_size = 12
		ns.shadow_offset = Vector2(0, 0)
		ns.border_width_bottom = 2
		ns.border_color = Color(GOLD, 0.30)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.shadow_color = Color(GOLD, 0.25)
		hs.shadow_size = 18
		hs.border_color = Color(GOLD, 0.60)
		btn.add_theme_stylebox_override("hover", hs)
		var ps := ns.duplicate() as StyleBoxFlat
		ps.shadow_color = Color(GOLD, 0.05)
		ps.shadow_size = 6
		btn.add_theme_stylebox_override("pressed", ps)
		row_j.add_child(btn)
	page.add_child(row_j)

	# --- Style K: "Gradient Split" (top/bottom color split via two borders) ---
	page.add_child(_section_label("K: Split Tone — dual border coloring"))
	var row_k := _hbox(8)
	for text: String in ["Equip", "Unequip", "Drop"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 52)
		_apply_font(btn, _awesome_font, 20)
		btn.add_theme_color_override("font_color", WARM_WHITE)
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(0.08, 0.08, 0.12, 0.82)
		ns.border_width_top = 2
		ns.border_width_bottom = 2
		ns.border_width_left = 1
		ns.border_width_right = 1
		ns.set_border_width_all(0)
		ns.border_width_top = 2
		ns.border_width_bottom = 2
		ns.border_color = Color(GOLD, 0.30)
		ns.corner_radius_top_left = 10
		ns.corner_radius_top_right = 10
		ns.corner_radius_bottom_left = 10
		ns.corner_radius_bottom_right = 10
		ns.content_margin_left = 16.0
		ns.content_margin_right = 16.0
		ns.content_margin_top = 8.0
		ns.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(0.12, 0.12, 0.16, 0.92)
		hs.border_color = Color(GOLD, 0.70)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row_k.add_child(btn)
	page.add_child(row_k)

	# --- Style L: "Underline Text" (minimal, text-link feel) ---
	page.add_child(_section_label("L: Underline Text — minimal text link"))
	var row_l := _hbox(16)
	for text: String in ["Save", "Load", "Options", "Quit"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(100, 40)
		_apply_font(btn, _awesome_font, 18)
		btn.add_theme_color_override("font_color", Color(GOLD, 0.70))
		var ns := _flat(Color(0, 0, 0, 0), 0)
		ns.border_width_bottom = 1
		ns.border_color = Color(GOLD, 0.25)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.border_color = Color(GOLD, 0.70)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		btn.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
		row_l.add_child(btn)
	page.add_child(row_l)

	# --- Style M: "Dual-Tone Tab" (top colored strip + dark body) ---
	page.add_child(_section_label("M: Dual-Tone Tab — colored cap"))
	var row_m := _hbox(8)
	var tab_colors: Array[Color] = [Color(0.85, 0.30, 0.25), Color(0.35, 0.65, 0.95), Color(0.55, 0.85, 0.45)]
	var tab_texts: Array[String] = ["Combat", "Social", "Crafting"]
	for i: int in 3:
		var btn := Button.new()
		btn.text = tab_texts[i]
		btn.custom_minimum_size = Vector2(180, 52)
		_apply_font(btn, _awesome_font, 18)
		btn.add_theme_color_override("font_color", WARM_WHITE)
		var ns := _flat(Color(0.07, 0.065, 0.06, 0.88), 0)
		ns.border_width_top = 4
		ns.border_color = tab_colors[i]
		ns.corner_radius_top_left = 6
		ns.corner_radius_top_right = 6
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(tab_colors[i], 0.10)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row_m.add_child(btn)
	page.add_child(row_m)

	# --- Style N: "Stamped / Seal" (thick border all around, square, heavy feel) ---
	page.add_child(_section_label("N: Stamped Seal — heavy square, inset"))
	var row_n := _hbox(10)
	for text: String in ["Confirm", "Deny"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(200, 58)
		_apply_font(btn, _compass_font, 24)
		btn.add_theme_color_override("font_color", PARCHMENT)
		var ns := _flat(Color(0.05, 0.04, 0.03, 0.92), 2)
		ns.border_width_bottom = 4
		ns.border_width_top = 4
		ns.border_width_left = 4
		ns.border_width_right = 4
		ns.border_color = Color(0.55, 0.45, 0.30, 0.50)
		ns.shadow_color = Color(0, 0, 0, 0.40)
		ns.shadow_size = 4
		ns.shadow_offset = Vector2(2, 2)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(0.09, 0.07, 0.05, 0.95)
		hs.border_color = Color(GOLD, 0.65)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row_n.add_child(btn)
	page.add_child(row_n)

	# --- Style O: "Gradient Bar" (top-bottom color shift via two borders) ---
	page.add_child(_section_label("O: Gradient Bar — warm-to-cool shift"))
	var row_o := _hbox(8)
	for text: String in ["Explore", "Rest", "Trade"]:
		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(180, 52)
		_apply_font(btn, _awesome_font, 20)
		btn.add_theme_color_override("font_color", WARM_WHITE)
		var ns_o := _flat(Color(0.09, 0.07, 0.05, 0.88), 6)
		ns_o.border_width_top = 3
		ns_o.border_width_bottom = 3
		ns_o.border_color = Color(0.85, 0.60, 0.25, 0.40)
		ns_o.shadow_color = Color(0.30, 0.50, 0.90, 0.08)
		ns_o.shadow_size = 8
		ns_o.shadow_offset = Vector2(0, 4)
		btn.add_theme_stylebox_override("normal", ns_o)
		var hs_o := ns_o.duplicate() as StyleBoxFlat
		hs_o.bg_color = Color(0.12, 0.10, 0.07, 0.92)
		hs_o.border_color = Color(0.95, 0.70, 0.30, 0.65)
		btn.add_theme_stylebox_override("hover", hs_o)
		btn.add_theme_stylebox_override("pressed", ns_o)
		row_o.add_child(btn)
	page.add_child(row_o)

	# --- Style P: "Icon Badge" (circle icon prefix + label) ---
	page.add_child(_section_label("P: Icon Badge — circle prefix + text"))
	var row_p := VBoxContainer.new()
	row_p.add_theme_constant_override("separation", 6)
	var badge_data: Array[Array] = [
		["!", "New Quest Available", Color(0.95, 0.78, 0.20)],
		["+", "Add to Party", Color(0.45, 0.85, 0.55)],
		["?", "Unknown Region", Color(0.55, 0.65, 0.95)],
	]
	for bd: Array in badge_data:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(340, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_font(btn, _awesome_font, 17)
		btn.text = "   %s   %s" % [bd[0] as String, bd[1] as String]
		var bc: Color = bd[2] as Color
		btn.add_theme_color_override("font_color", WARM_WHITE)
		var ns_p := _flat(Color(0.06, 0.055, 0.05, 0.85), 24)
		ns_p.border_width_left = 0
		ns_p.border_width_bottom = 1
		ns_p.border_color = Color(bc, 0.25)
		ns_p.content_margin_left = 6.0
		btn.add_theme_stylebox_override("normal", ns_p)
		var hs_p := ns_p.duplicate() as StyleBoxFlat
		hs_p.bg_color = Color(bc, 0.08)
		hs_p.border_color = Color(bc, 0.50)
		btn.add_theme_stylebox_override("hover", hs_p)
		btn.add_theme_stylebox_override("pressed", ns_p)
		row_p.add_child(btn)
	page.add_child(row_p)

	# --- Style Q: "Toggle State" (on/off visual difference) ---
	page.add_child(_section_label("Q: Toggle — on vs off states"))
	var row_q := _hbox(8)
	var toggle_data: Array[Array] = [
		["Sound: ON", true], ["Music: OFF", false], ["Vibration: ON", true], ["Hints: OFF", false],
	]
	for td: Array in toggle_data:
		var btn := Button.new()
		btn.text = td[0] as String
		btn.custom_minimum_size = Vector2(160, 44)
		_apply_font(btn, _awesome_font, 15)
		var on: bool = td[1] as bool
		btn.add_theme_color_override("font_color", GOLD if on else Color(0.45, 0.42, 0.38))
		var ns_q := _flat(Color(GOLD, 0.06) if on else Color(0.06, 0.055, 0.05, 0.75), 6)
		ns_q.border_width_bottom = 2
		ns_q.border_width_top = 1
		ns_q.border_width_left = 1
		ns_q.border_width_right = 1
		ns_q.border_color = Color(GOLD, 0.45) if on else Color(0.20, 0.18, 0.16, 0.40)
		btn.add_theme_stylebox_override("normal", ns_q)
		btn.add_theme_stylebox_override("hover", ns_q)
		btn.add_theme_stylebox_override("pressed", ns_q)
		row_q.add_child(btn)
	page.add_child(row_q)

	return page


# ════════════════════════════════════════════════════════════
#  FLAT PANELS
# ════════════════════════════════════════════════════════════

func _build_flat_panels_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)

	# Style 1: Dark Navy + Gold Border (existing inventory board style)
	page.add_child(_section_label("1: Dark Brown + Gold (inventory board)"))
	page.add_child(_demo_flat_panel(
		Color(0.108, 0.074, 0.045, 0.66), Color(0.83, 0.69, 0.46, 0.6), 2, 10,
		"Inventory / Equipment panel",
		"This is the warm-tone panel used in the inventory board. Brown fill with antique gold border."
	))

	# Style 2: Deep Navy + Steel Blue (default from style system)
	page.add_child(_section_label("2: Deep Navy + Steel Blue (default profile)"))
	page.add_child(_demo_flat_panel(
		Color(0.07, 0.10, 0.14, 0.58), Color(0.68, 0.78, 0.92, 0.72), 1, 8,
		"Default Panel Style",
		"The standard panel from UiPanelStyleProfile. Cool tone, subtle border."
	))

	# Style 3: Parchment Dark + Left Accent
	page.add_child(_section_label("3: Left Accent + Dark Fill"))
	var p3 := _demo_flat_panel(
		Color(0.06, 0.07, 0.10, 0.75), Color.TRANSPARENT, 0, 4,
		"Left Accent Card",
		"A modern card style with a colored left stripe. Good for lists, quest entries, etc."
	)
	(p3.get_theme_stylebox("panel") as StyleBoxFlat).border_width_left = 4
	(p3.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(0.50, 0.75, 1.0, 0.6)
	page.add_child(p3)

	# Style 4: Glass Panel (very rounded, semi-transparent)
	page.add_child(_section_label("4: Glass — rounded, very transparent"))
	page.add_child(_demo_flat_panel(
		Color(0.20, 0.22, 0.28, 0.35), Color(0.80, 0.80, 0.85, 0.20), 1, 18,
		"Glass Overlay",
		"Frosted glass look. Best layered over background blur. Very soft presence."
	))

	# Style 5: Obsidian Slab (hard corners, heavy border)
	page.add_child(_section_label("5: Obsidian Slab — sharp, heavy"))
	page.add_child(_demo_flat_panel(
		Color(0.04, 0.04, 0.06, 0.92), Color(GOLD, 0.50), 2, 0,
		"Obsidian Panel",
		"Hard-edged, imposing. Suits combat, boss encounters, serious UI."
	))

	# Style 6: Warm Sepia + Double Border
	page.add_child(_section_label("6: Sepia + Double Border"))
	var p6_style := _flat(Color(0.09, 0.065, 0.040, 0.70), 8)
	p6_style.border_width_bottom = 3
	p6_style.border_width_top = 3
	p6_style.border_width_left = 3
	p6_style.border_width_right = 3
	p6_style.border_color = Color(0.72, 0.58, 0.37, 0.40)
	p6_style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	p6_style.shadow_size = 12
	p6_style.shadow_offset = Vector2(0, 4)
	var p6 := _demo_panel_from_style(p6_style, "Sepia Heavy", "Double-weight border with shadow. Warm, grounded feel.")
	page.add_child(p6)

	# Style 7: Frosted Dark + Top Glow
	page.add_child(_section_label("7: Top Glow — soft gradient ceiling"))
	var p7_style := _flat(Color(0.05, 0.05, 0.07, 0.88), 10)
	p7_style.border_width_top = 2
	p7_style.border_color = Color(GOLD, 0.45)
	p7_style.shadow_color = Color(GOLD, 0.06)
	p7_style.shadow_size = 20
	p7_style.shadow_offset = Vector2(0, -8)
	page.add_child(_demo_panel_from_style(p7_style, "Top Glow", "Warm halo above the panel. Feels elevated, premium."))

	# Style 8: Inset / Recessed (dark with inner shadow)
	page.add_child(_section_label("8: Inset — recessed into the background"))
	var p8_style := _flat(Color(0.03, 0.03, 0.04, 0.95), 6)
	p8_style.border_width_bottom = 1
	p8_style.border_width_top = 1
	p8_style.border_width_left = 1
	p8_style.border_width_right = 1
	p8_style.border_color = Color(0.02, 0.02, 0.02, 0.60)
	p8_style.shadow_color = Color(0.0, 0.0, 0.0, 0.50)
	p8_style.shadow_size = 8
	p8_style.shadow_offset = Vector2(0, 2)
	page.add_child(_demo_panel_from_style(p8_style, "Inset / Well", "Sunken look. Feels embedded. Good for input fields or slots."))

	# Style 9: Gradient Stripe (colored accent top + bottom)
	page.add_child(_section_label("9: Dual Accent — top + bottom stripe"))
	var p9_style := _flat(Color(0.06, 0.055, 0.05, 0.90), 4)
	p9_style.border_width_top = 3
	p9_style.border_width_bottom = 3
	p9_style.border_color = Color(0.50, 0.75, 1.0, 0.45)
	page.add_child(_demo_panel_from_style(p9_style, "Dual Accent", "Cool blue stripes on top and bottom. Map / status panel feel."))

	# Style 10: Sidebar Panel (left accent wide + lighter inner region)
	page.add_child(_section_label("10: Wide Sidebar — split region"))
	var p10 := HBoxContainer.new()
	p10.add_theme_constant_override("separation", 0)
	var p10_side := PanelContainer.new()
	p10_side.custom_minimum_size = Vector2(60, 100)
	var p10s_sb := _flat(Color(GOLD, 0.08), 0)
	p10s_sb.border_width_right = 2
	p10s_sb.border_color = Color(GOLD, 0.30)
	p10_side.add_theme_stylebox_override("panel", p10s_sb)
	var p10_icon := Label.new()
	p10_icon.text = "!"
	p10_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p10_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(p10_icon, _compass_font, 28)
	p10_icon.add_theme_color_override("font_color", GOLD)
	p10_side.add_child(p10_icon)
	p10.add_child(p10_side)
	var p10_body := PanelContainer.new()
	p10_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p10b_sb := _flat(Color(0.06, 0.055, 0.05, 0.90), 0)
	p10b_sb.content_margin_left = 16.0
	p10b_sb.content_margin_top = 12.0
	p10b_sb.content_margin_bottom = 12.0
	p10_body.add_theme_stylebox_override("panel", p10b_sb)
	var p10_vb := VBoxContainer.new()
	p10_vb.add_theme_constant_override("separation", 4)
	p10_vb.add_child(_make_label("Wide Sidebar", GOLD_BRIGHT, _compass_font, 20))
	p10_vb.add_child(_make_label("Icon sits in the accent strip. Body is a separate region.", Color(WARM_WHITE, 0.60), _awesome_font, 14))
	p10_body.add_child(p10_vb)
	p10.add_child(p10_body)
	page.add_child(p10)

	# Style 11: Stacked Header panel (dark header + lighter body)
	page.add_child(_section_label("11: Stacked Header — two-tone"))
	var p11 := VBoxContainer.new()
	p11.add_theme_constant_override("separation", 0)
	var p11_hdr := PanelContainer.new()
	var p11h_sb := _flat(Color(GOLD, 0.06), 0)
	p11h_sb.corner_radius_top_left = 8
	p11h_sb.corner_radius_top_right = 8
	p11h_sb.border_width_bottom = 2
	p11h_sb.border_color = Color(GOLD, 0.30)
	p11h_sb.content_margin_top = 10.0
	p11h_sb.content_margin_bottom = 10.0
	p11_hdr.add_theme_stylebox_override("panel", p11h_sb)
	var p11_hl := _make_label("Panel Header", GOLD_BRIGHT, _compass_font, 20)
	p11_hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p11_hdr.add_child(p11_hl)
	p11.add_child(p11_hdr)
	var p11_bdy := PanelContainer.new()
	var p11b_sb := _flat(Color(0.05, 0.045, 0.04, 0.92), 0)
	p11b_sb.corner_radius_bottom_left = 8
	p11b_sb.corner_radius_bottom_right = 8
	p11b_sb.content_margin_top = 12.0
	p11b_sb.content_margin_bottom = 12.0
	p11_bdy.add_theme_stylebox_override("panel", p11b_sb)
	p11_bdy.add_child(_make_label("Content area below the header. Two-tone vertical split.", Color(WARM_WHITE, 0.60), _awesome_font, 15))
	p11.add_child(p11_bdy)
	page.add_child(p11)

	return page


# ════════════════════════════════════════════════════════════
#  PAGE 4: TEXTURED PANELS (9-slice)
# ════════════════════════════════════════════════════════════

func _build_textured_panels_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)

	page.add_child(_section_label("9-Slice Panel Textures (A through N)"))

	# Show each panel texture as a demo card
	var panel_labels: Array[String] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "L", "M", "N"]
	for i: int in PANEL_PATHS.size():
		var tex := load(PANEL_PATHS[i]) as Texture2D
		if not tex:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var label := _make_label("Panel %s" % panel_labels[i], DIM, _awesome_font, 16)
		label.custom_minimum_size.x = 100
		row.add_child(label)

		var nine := NinePatchRect.new()
		nine.texture = tex
		nine.custom_minimum_size = Vector2(500, 120)
		nine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Pixel-art panels are 96x96 — use ~30% margin for the ornate borders
		var margin_x: int = clampi(int(tex.get_width() * 0.30), 10, 30)
		var margin_y: int = clampi(int(tex.get_height() * 0.30), 10, 30)
		nine.patch_margin_left = margin_x
		nine.patch_margin_right = margin_x
		nine.patch_margin_top = margin_y
		nine.patch_margin_bottom = margin_y

		# Overlay text inside
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var inner_lbl := _make_label("Panel %s — Sample Content" % panel_labels[i], WARM_WHITE, _compass_font, 20)
		center.add_child(inner_lbl)
		nine.add_child(center)

		row.add_child(nine)
		page.add_child(row)

	_add_spacer(page, 16)

	# Combined showcase: textured panel with flat inner elements
	page.add_child(_section_label("Combo: Textured Panel + Flat Inner Cards"))
	var combo_tex := load(PANEL_PATHS[0]) as Texture2D
	if combo_tex:
		var combo_nine := NinePatchRect.new()
		combo_nine.texture = combo_tex
		combo_nine.custom_minimum_size = Vector2(500, 200)
		combo_nine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cm: int = clampi(int(combo_tex.get_width() * 0.30), 10, 30)
		combo_nine.patch_margin_left = cm
		combo_nine.patch_margin_right = cm
		combo_nine.patch_margin_top = cm
		combo_nine.patch_margin_bottom = cm
		var combo_margin := MarginContainer.new()
		combo_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		combo_margin.add_theme_constant_override("margin_left", 16)
		combo_margin.add_theme_constant_override("margin_right", 16)
		combo_margin.add_theme_constant_override("margin_top", 12)
		combo_margin.add_theme_constant_override("margin_bottom", 12)
		var combo_vb := VBoxContainer.new()
		combo_vb.add_theme_constant_override("separation", 8)
		combo_vb.add_child(_make_label("Panel A — with inner cards", GOLD_BRIGHT, _compass_font, 20))
		for item_text: String in ["Iron Sword  +15 ATK", "Oak Shield  +8 DEF"]:
			var inner := PanelContainer.new()
			var isb := _flat(Color(0.04, 0.035, 0.03, 0.70), 4)
			isb.border_width_left = 3
			isb.border_color = Color(GOLD, 0.35)
			isb.content_margin_left = 12.0
			isb.content_margin_top = 6.0
			isb.content_margin_bottom = 6.0
			inner.add_theme_stylebox_override("panel", isb)
			inner.add_child(_make_label(item_text, WARM_WHITE, _awesome_font, 15))
			combo_vb.add_child(inner)
		combo_margin.add_child(combo_vb)
		combo_nine.add_child(combo_margin)
		page.add_child(combo_nine)

	# Combo 2: Panel with slot grid overlaid
	var combo2_tex := load(PANEL_PATHS[2]) as Texture2D
	if combo2_tex:
		page.add_child(_section_label("Combo: Textured Panel C + Slot Grid"))
		var c2_nine := NinePatchRect.new()
		c2_nine.texture = combo2_tex
		c2_nine.custom_minimum_size = Vector2(500, 160)
		c2_nine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c2m: int = clampi(int(combo2_tex.get_width() * 0.30), 10, 30)
		c2_nine.patch_margin_left = c2m
		c2_nine.patch_margin_right = c2m
		c2_nine.patch_margin_top = c2m
		c2_nine.patch_margin_bottom = c2m
		var c2_margin := MarginContainer.new()
		c2_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c2_margin.add_theme_constant_override("margin_left", 20)
		c2_margin.add_theme_constant_override("margin_right", 20)
		c2_margin.add_theme_constant_override("margin_top", 14)
		c2_margin.add_theme_constant_override("margin_bottom", 14)
		var c2_hb := HBoxContainer.new()
		c2_hb.add_theme_constant_override("separation", 8)
		for j: int in 5:
			var s := PanelContainer.new()
			s.custom_minimum_size = Vector2(56, 56)
			var ssb := _flat(Color(0.04, 0.035, 0.03, 0.75), 4)
			ssb.border_width_bottom = 1
			ssb.border_width_top = 1
			ssb.border_width_left = 1
			ssb.border_width_right = 1
			ssb.border_color = Color(GOLD, 0.20) if j >= 2 else Color(GOLD, 0.50)
			s.add_theme_stylebox_override("panel", ssb)
			if j < 2:
				var ql := Label.new()
				ql.text = str(j + 1)
				ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ql.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				_apply_font(ql, _awesome_font, 14)
				ql.add_theme_color_override("font_color", GOLD)
				s.add_child(ql)
			c2_hb.add_child(s)
		c2_margin.add_child(c2_hb)
		c2_nine.add_child(c2_margin)
		page.add_child(c2_nine)

	return page


# ════════════════════════════════════════════════════════════
#  PAGE 5: TITLE BARS
# ════════════════════════════════════════════════════════════

func _build_title_bars_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)

	# Textured titles
	page.add_child(_section_label("Textured Title Bars (A-E)"))
	for i: int in TITLE_PATHS.size():
		var tex := load(TITLE_PATHS[i]) as Texture2D
		if not tex:
			continue
		var nine := NinePatchRect.new()
		nine.texture = tex
		nine.custom_minimum_size = Vector2(0, 64)
		nine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Title textures are 78x18 — use ~25% for borders
		var mx: int = clampi(int(tex.get_width() * 0.25), 6, 20)
		var my: int = clampi(int(tex.get_height() * 0.25), 3, 8)
		nine.patch_margin_left = mx
		nine.patch_margin_right = mx
		nine.patch_margin_top = my
		nine.patch_margin_bottom = my

		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.add_child(_make_label("Title Bar %s — %s" % [["A","B","C","D","E"][i], "Inventory"], GOLD_BRIGHT, _compass_font, 22))
		nine.add_child(center)
		page.add_child(nine)

	_add_spacer(page, 16)

	# Flat title bars
	page.add_child(_section_label("Flat Title Bar Variations"))

	# Centered gold underline
	var t1 := PanelContainer.new()
	var t1s := _flat(Color(GOLD, 0.04), 0)
	t1s.border_width_bottom = 2
	t1s.border_color = Color(GOLD, 0.45)
	t1s.content_margin_top = 10.0
	t1s.content_margin_bottom = 10.0
	t1.add_theme_stylebox_override("panel", t1s)
	var t1l := _make_label("FLAT: Gold Underline", GOLD_BRIGHT, _compass_font, 24)
	t1l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_child(t1l)
	page.add_child(t1)

	# Accent left bar
	var t2 := PanelContainer.new()
	var t2s := _flat(Color(0.06, 0.06, 0.09, 0.70), 4)
	t2s.border_width_left = 4
	t2s.border_color = Color(0.50, 0.75, 1.0, 0.65)
	t2s.content_margin_left = 16.0
	t2s.content_margin_top = 10.0
	t2s.content_margin_bottom = 10.0
	t2.add_theme_stylebox_override("panel", t2s)
	t2.add_child(_make_label("FLAT: Left Accent Title", Color(0.50, 0.75, 1.0), _compass_font, 24))
	page.add_child(t2)

	# Full border small radius
	var t3 := PanelContainer.new()
	var t3s := _flat(Color(0.08, 0.07, 0.05, 0.75), 6)
	t3s.border_width_bottom = 2
	t3s.border_width_top = 2
	t3s.border_width_left = 2
	t3s.border_width_right = 2
	t3s.border_color = Color(GOLD, 0.35)
	t3s.content_margin_top = 10.0
	t3s.content_margin_bottom = 10.0
	t3.add_theme_stylebox_override("panel", t3s)
	var t3l := _make_label("FLAT: Framed Title", PARCHMENT, _compass_font, 24)
	t3l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.add_child(t3l)
	page.add_child(t3)

	# Pill / Capsule title
	var t4 := PanelContainer.new()
	var t4s := _flat(Color(GOLD, 0.08), 20)
	t4s.border_width_bottom = 1
	t4s.border_width_top = 1
	t4s.border_width_left = 1
	t4s.border_width_right = 1
	t4s.border_color = Color(GOLD, 0.30)
	t4s.content_margin_top = 8.0
	t4s.content_margin_bottom = 8.0
	t4s.content_margin_left = 24.0
	t4s.content_margin_right = 24.0
	t4.add_theme_stylebox_override("panel", t4s)
	var t4l := _make_label("FLAT: Pill / Capsule Title", GOLD, _compass_font, 22)
	t4l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t4.add_child(t4l)
	page.add_child(t4)

	# Shadow Drop title
	var t5 := PanelContainer.new()
	var t5s := _flat(Color(0.04, 0.04, 0.05, 0.85), 0)
	t5s.border_width_bottom = 3
	t5s.border_color = GOLD
	t5s.shadow_color = Color(0, 0, 0, 0.35)
	t5s.shadow_size = 8
	t5s.shadow_offset = Vector2(0, 3)
	t5s.content_margin_top = 12.0
	t5s.content_margin_bottom = 12.0
	t5.add_theme_stylebox_override("panel", t5s)
	var t5l := _make_label("FLAT: Shadow Drop Title", GOLD_BRIGHT, _compass_font, 26)
	t5l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t5.add_child(t5l)
	page.add_child(t5)

	# Split bar (left colored, right dark)
	var t6 := HBoxContainer.new()
	t6.add_theme_constant_override("separation", 0)
	var t6_left := PanelContainer.new()
	var t6ls := _flat(Color(0.50, 0.75, 1.0, 0.15), 0)
	t6ls.border_width_left = 4
	t6ls.border_color = Color(0.50, 0.75, 1.0, 0.65)
	t6ls.content_margin_left = 16.0
	t6ls.content_margin_right = 12.0
	t6ls.content_margin_top = 10.0
	t6ls.content_margin_bottom = 10.0
	t6_left.add_theme_stylebox_override("panel", t6ls)
	t6_left.add_child(_make_label("Category", Color(0.55, 0.80, 1.0), _compass_font, 20))
	t6.add_child(t6_left)
	var t6_right := PanelContainer.new()
	t6_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t6rs := _flat(Color(0.05, 0.05, 0.07, 0.70), 0)
	t6rs.border_width_bottom = 1
	t6rs.border_color = Color(0.30, 0.28, 0.25, 0.40)
	t6rs.content_margin_left = 12.0
	t6rs.content_margin_top = 10.0
	t6rs.content_margin_bottom = 10.0
	t6_right.add_theme_stylebox_override("panel", t6rs)
	t6_right.add_child(_make_label("FLAT: Split Title Bar", DIM, _awesome_font, 18))
	t6.add_child(t6_right)
	page.add_child(t6)

	# Notched title (top tabs feel)
	var t7 := PanelContainer.new()
	var t7s := _flat(Color(0.06, 0.055, 0.05, 0.80), 0)
	t7s.border_width_top = 4
	t7s.border_width_bottom = 1
	t7s.border_color = GOLD
	t7s.corner_radius_top_left = 12
	t7s.corner_radius_top_right = 12
	t7s.content_margin_top = 10.0
	t7s.content_margin_bottom = 10.0
	t7.add_theme_stylebox_override("panel", t7s)
	var t7l := _make_label("FLAT: Notched Tab Title", GOLD_BRIGHT, _compass_font, 22)
	t7l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t7.add_child(t7l)
	page.add_child(t7)

	# Badge title (centered badge with side lines simulated via border)
	var t8 := HBoxContainer.new()
	t8.add_theme_constant_override("separation", 0)
	var t8_line_l := PanelContainer.new()
	t8_line_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t8ls := _flat(Color(0, 0, 0, 0), 0)
	t8ls.border_width_bottom = 1
	t8ls.border_color = Color(GOLD, 0.25)
	t8ls.content_margin_top = 18.0
	t8ls.content_margin_bottom = 18.0
	t8_line_l.add_theme_stylebox_override("panel", t8ls)
	t8_line_l.add_child(Control.new())
	t8.add_child(t8_line_l)
	var t8_badge := PanelContainer.new()
	var t8bs := _flat(Color(GOLD, 0.10), 16)
	t8bs.border_width_bottom = 2
	t8bs.border_width_top = 2
	t8bs.border_width_left = 2
	t8bs.border_width_right = 2
	t8bs.border_color = Color(GOLD, 0.45)
	t8bs.content_margin_left = 24.0
	t8bs.content_margin_right = 24.0
	t8bs.content_margin_top = 6.0
	t8bs.content_margin_bottom = 6.0
	t8_badge.add_theme_stylebox_override("panel", t8bs)
	t8_badge.add_child(_make_label("BADGE TITLE", GOLD_BRIGHT, _compass_font, 20))
	t8.add_child(t8_badge)
	var t8_line_r := PanelContainer.new()
	t8_line_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t8_line_r.add_theme_stylebox_override("panel", t8ls.duplicate())
	t8_line_r.add_child(Control.new())
	t8.add_child(t8_line_r)
	page.add_child(t8)

	# Gradient fade title
	var t9 := PanelContainer.new()
	var t9s := _flat(Color(0.08, 0.075, 0.06, 0.85), 0)
	t9s.border_width_bottom = 2
	t9s.border_color = Color(GOLD, 0.35)
	t9s.shadow_color = Color(GOLD, 0.04)
	t9s.shadow_size = 16
	t9s.shadow_offset = Vector2(0, -6)
	t9s.content_margin_top = 12.0
	t9s.content_margin_bottom = 12.0
	t9.add_theme_stylebox_override("panel", t9s)
	var t9l := _make_label("FLAT: Gradient Fade Title", PARCHMENT, _compass_font, 24)
	t9l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t9.add_child(t9l)
	page.add_child(t9)

	return page


# ════════════════════════════════════════════════════════════
#  PAGE 6: FRAMES & SLOTS
# ════════════════════════════════════════════════════════════

func _build_frames_slots_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)

	# Frames
	page.add_child(_section_label("Frames (F_U_Frame 0-9)"))
	var frame_grid := _wrap_flow(8)
	for path: String in FRAME_PATHS:
		var tex := load(path) as Texture2D
		if not tex:
			continue
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(96, 96)
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame_grid.add_child(tr)
	page.add_child(frame_grid)

	_add_spacer(page, 16)

	# Slots
	page.add_child(_section_label("Item Slots (A-F)"))
	var slot_grid := _wrap_flow(8)
	for path: String in SLOT_PATHS:
		var tex := load(path) as Texture2D
		if not tex:
			continue
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(80, 80)
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_grid.add_child(tr)
	page.add_child(slot_grid)

	_add_spacer(page, 16)

	# Flat circle slots (no texture, pure code)
	page.add_child(_section_label("Flat Circle Frames (code-only)"))
	var flat_circle_row := _hbox(10)
	var frame_colors: Array[Color] = [GOLD, Color(0.50, 0.75, 1.0), Color(0.85, 0.35, 0.30), Color(0.55, 0.85, 0.45), Color(0.70, 0.50, 0.90)]
	for i: int in 5:
		var fc: Color = frame_colors[i]
		var frame := PanelContainer.new()
		frame.custom_minimum_size = Vector2(88, 88)
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = Color(0.04, 0.035, 0.03, 0.85)
		fsb.set_corner_radius_all(44)
		fsb.border_width_bottom = 3
		fsb.border_width_top = 3
		fsb.border_width_left = 3
		fsb.border_width_right = 3
		fsb.border_color = Color(fc, 0.50)
		fsb.shadow_color = Color(fc, 0.08)
		fsb.shadow_size = 6
		frame.add_theme_stylebox_override("panel", fsb)
		var fl := Label.new()
		fl.text = str(i + 1)
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(fl, _compass_font, 24)
		fl.add_theme_color_override("font_color", fc)
		frame.add_child(fl)
		flat_circle_row.add_child(frame)
	page.add_child(flat_circle_row)

	# Flat square slots with inner glow
	page.add_child(_section_label("Flat Square Slots + Inner Glow"))
	var flat_sq_row := _hbox(8)
	for i: int in 6:
		var sq := PanelContainer.new()
		sq.custom_minimum_size = Vector2(76, 76)
		var sqsb := StyleBoxFlat.new()
		sqsb.bg_color = Color(0.05, 0.045, 0.04, 0.90)
		sqsb.set_corner_radius_all(6)
		sqsb.border_width_bottom = 2
		sqsb.border_width_top = 1
		sqsb.border_width_left = 1
		sqsb.border_width_right = 1
		sqsb.border_color = Color(GOLD, 0.25) if i >= 2 else Color(GOLD, 0.60)
		sqsb.shadow_color = Color(GOLD, 0.04) if i >= 2 else Color(GOLD, 0.12)
		sqsb.shadow_size = 6
		sq.add_theme_stylebox_override("panel", sqsb)
		if i < 2:
			var ql := Label.new()
			ql.text = ["Sw", "Sh"][i]
			ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ql.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_apply_font(ql, _compass_font, 18)
			ql.add_theme_color_override("font_color", GOLD)
			sq.add_child(ql)
		flat_sq_row.add_child(sq)
	page.add_child(flat_sq_row)

	# Diamond / rotated slots
	page.add_child(_section_label("Diamond Slots — rotated feel"))
	var diamond_row := _hbox(14)
	var dia_colors: Array[Color] = [Color(1.0, 0.80, 0.25), Color(0.70, 0.45, 0.90), Color(0.40, 0.60, 0.95), Color(0.85, 0.35, 0.30)]
	for i: int in 4:
		var dc: Color = dia_colors[i]
		var dia := PanelContainer.new()
		dia.custom_minimum_size = Vector2(72, 72)
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color(0.06, 0.055, 0.05, 0.88)
		# Asymmetric corners to create a diamond feel
		dsb.corner_radius_top_left = 24
		dsb.corner_radius_top_right = 4
		dsb.corner_radius_bottom_left = 4
		dsb.corner_radius_bottom_right = 24
		dsb.border_width_bottom = 2
		dsb.border_width_top = 2
		dsb.border_width_left = 2
		dsb.border_width_right = 2
		dsb.border_color = Color(dc, 0.45)
		dsb.shadow_color = Color(dc, 0.06)
		dsb.shadow_size = 4
		dia.add_theme_stylebox_override("panel", dsb)
		var dl := Label.new()
		dl.text = ["L", "E", "R", "M"][i]
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(dl, _compass_font, 20)
		dl.add_theme_color_override("font_color", dc)
		dia.add_child(dl)
		diamond_row.add_child(dia)
	page.add_child(diamond_row)

	# Ornate flat frames (multi-layer border simulation)
	page.add_child(_section_label("Ornate Flat Frames — double layer"))
	var ornate_row := _hbox(12)
	for i: int in 4:
		var oframe := PanelContainer.new()
		oframe.custom_minimum_size = Vector2(88, 88)
		var ofsb := StyleBoxFlat.new()
		ofsb.bg_color = Color(0, 0, 0, 0)
		ofsb.set_corner_radius_all(6)
		ofsb.border_width_bottom = 3
		ofsb.border_width_top = 3
		ofsb.border_width_left = 3
		ofsb.border_width_right = 3
		ofsb.border_color = Color(GOLD, 0.25)
		oframe.add_theme_stylebox_override("panel", ofsb)
		var of_inner := PanelContainer.new()
		of_inner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		of_inner.custom_minimum_size = Vector2(68, 68)
		var oisb := StyleBoxFlat.new()
		oisb.bg_color = Color(0.06, 0.055, 0.05, 0.90) if i < 2 else Color(0.04, 0.035, 0.03, 0.70)
		oisb.set_corner_radius_all(4)
		oisb.border_width_bottom = 2
		oisb.border_width_top = 2
		oisb.border_width_left = 2
		oisb.border_width_right = 2
		oisb.border_color = Color(GOLD, 0.50) if i < 2 else Color(GOLD, 0.18)
		of_inner.add_theme_stylebox_override("panel", oisb)
		if i < 2:
			var ol := Label.new()
			ol.text = ["Sw", "Sh"][i]
			ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_apply_font(ol, _compass_font, 16)
			ol.add_theme_color_override("font_color", GOLD)
			of_inner.add_child(ol)
		oframe.add_child(of_inner)
		ornate_row.add_child(oframe)
	page.add_child(ornate_row)

	return page


# ════════════════════════════════════════════════════════════
#  PAGE 7: COMPOSED CARDS
# ════════════════════════════════════════════════════════════

func _build_composed_cards_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 24)

	page.add_child(_section_label("Composed Card: Quest Entry"))
	page.add_child(_build_quest_card("The Lost Amulet", "Find the ancient amulet in the Shadow Caves.", "Active", Color(0.50, 0.75, 1.0)))
	page.add_child(_build_quest_card("Goblin Menace", "Defeat 10 goblins near the village outskirts.", "Completed", Color(0.40, 0.85, 0.45)))
	page.add_child(_build_quest_card("Dragon's Pact", "Negotiate with the elder dragon. Beware.", "Failed", Color(0.85, 0.30, 0.25)))

	_add_spacer(page, 16)

	page.add_child(_section_label("Composed Card: Creature Info"))
	page.add_child(_build_creature_card("Forest Sprite", "Common", "HP: 45 / ATK: 12 / DEF: 8", Color(0.45, 0.78, 0.55)))
	page.add_child(_build_creature_card("Shadow Wraith", "Rare", "HP: 120 / ATK: 35 / DEF: 18", Color(0.65, 0.45, 0.90)))
	page.add_child(_build_creature_card("Flame Drake", "Legendary", "HP: 350 / ATK: 80 / DEF: 45", Color(1.0, 0.70, 0.20)))

	_add_spacer(page, 16)

	page.add_child(_section_label("Composed Card: Item Tooltip"))
	page.add_child(_build_item_card("Iron Sword", "A sturdy blade forged by village blacksmiths.", "+15 ATK", "Common", Color(0.70, 0.70, 0.75)))
	page.add_child(_build_item_card("Aether Crystal", "Hums with arcane energy. Used in enchanting.", "+40 MANA", "Epic", Color(0.55, 0.40, 0.95)))
	page.add_child(_build_item_card("Moonveil Ring", "Shimmers with lunar magic. Grants night vision.", "+8 DEF  +12 LCK", "Rare", Color(0.40, 0.60, 0.95)))

	_add_spacer(page, 16)

	# --- Ability Card (new style) ---
	page.add_child(_section_label("Composed Card: Ability / Skill"))
	var ability_data: Array[Array] = [
		["Fireball", "Launch a blazing sphere. 60 mana.", Color(0.95, 0.45, 0.20), "3.2s CD"],
		["Frost Nova", "Freeze enemies in a radius. 40 mana.", Color(0.40, 0.70, 0.95), "8.0s CD"],
		["Shadow Step", "Teleport behind the target. 25 mana.", Color(0.65, 0.40, 0.90), "1.5s CD"],
	]
	for ad: Array in ability_data:
		var acard := PanelContainer.new()
		var ac: Color = ad[2] as Color
		var acsb := _flat(Color(0.06, 0.055, 0.05, 0.88), 8)
		acsb.border_width_left = 5
		acsb.border_width_bottom = 1
		acsb.border_color = ac
		acsb.content_margin_left = 16.0
		acsb.content_margin_right = 16.0
		acsb.content_margin_top = 10.0
		acsb.content_margin_bottom = 10.0
		acard.add_theme_stylebox_override("panel", acsb)
		var avb := VBoxContainer.new()
		avb.add_theme_constant_override("separation", 4)
		var atop := HBoxContainer.new()
		atop.add_child(_make_label(ad[0] as String, GOLD_BRIGHT, _compass_font, 20))
		var acd := _make_label(ad[3] as String, Color(ac, 0.70), _awesome_font, 14)
		acd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acd.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		atop.add_child(acd)
		avb.add_child(atop)
		avb.add_child(_make_label(ad[1] as String, Color(WARM_WHITE, 0.65), _awesome_font, 14))
		acard.add_child(avb)
		page.add_child(acard)

	_add_spacer(page, 16)

	# --- NPC / Character Card ---
	page.add_child(_section_label("Composed Card: NPC / Character"))
	var npc_data: Array[Array] = [
		["Elder Mirael", "Quest Giver", "Village of Ashvale", Color(0.92, 0.78, 0.28)],
		["Kira the Scout", "Companion", "Currently following", Color(0.45, 0.85, 0.55)],
	]
	for nd: Array in npc_data:
		var ncard := PanelContainer.new()
		var nc: Color = nd[3] as Color
		var ncsb := _flat(Color(0.07, 0.065, 0.06, 0.85), 6)
		ncsb.border_width_bottom = 2
		ncsb.border_width_top = 1
		ncsb.border_color = Color(nc, 0.40)
		ncsb.content_margin_left = 16.0
		ncsb.content_margin_right = 16.0
		ncsb.content_margin_top = 10.0
		ncsb.content_margin_bottom = 10.0
		ncard.add_theme_stylebox_override("panel", ncsb)
		var nvb := HBoxContainer.new()
		nvb.add_theme_constant_override("separation", 14)
		# Icon circle
		var ico := PanelContainer.new()
		ico.custom_minimum_size = Vector2(48, 48)
		var icsb := StyleBoxFlat.new()
		icsb.bg_color = Color(nc, 0.12)
		icsb.set_corner_radius_all(24)
		icsb.border_width_bottom = 2
		icsb.border_width_top = 2
		icsb.border_width_left = 2
		icsb.border_width_right = 2
		icsb.border_color = Color(nc, 0.35)
		ico.add_theme_stylebox_override("panel", icsb)
		var icl := Label.new()
		icl.text = (nd[0] as String).left(1)
		icl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(icl, _compass_font, 20)
		icl.add_theme_color_override("font_color", nc)
		ico.add_child(icl)
		nvb.add_child(ico)
		var ntxt := VBoxContainer.new()
		ntxt.add_theme_constant_override("separation", 2)
		ntxt.add_child(_make_label(nd[0] as String, WARM_WHITE, _awesome_font, 17))
		var nrole := _make_label("%s  —  %s" % [nd[1] as String, nd[2] as String], Color(nc, 0.65), _awesome_font, 13)
		ntxt.add_child(nrole)
		nvb.add_child(ntxt)
		ncard.add_child(nvb)
		page.add_child(ncard)

	_add_spacer(page, 16)

	# --- Loot Drop Card ---
	page.add_child(_section_label("Composed Card: Loot Drop"))
	var loot_items: Array[Array] = [
		["Ruby Pendant", "x1", Color(0.85, 0.30, 0.30), "Rare"],
		["Gold Coins", "x120", Color(1.0, 0.85, 0.30), "Common"],
		["Shadow Essence", "x3", Color(0.65, 0.40, 0.90), "Epic"],
	]
	var loot_panel := PanelContainer.new()
	var lpsb := _flat(Color(0.055, 0.05, 0.045, 0.92), 6)
	lpsb.border_width_top = 3
	lpsb.border_color = Color(GOLD, 0.45)
	lpsb.content_margin_left = 14.0
	lpsb.content_margin_right = 14.0
	lpsb.content_margin_top = 12.0
	lpsb.content_margin_bottom = 12.0
	loot_panel.add_theme_stylebox_override("panel", lpsb)
	var lpvb := VBoxContainer.new()
	lpvb.add_theme_constant_override("separation", 8)
	lpvb.add_child(_make_label("Loot Acquired!", GOLD_BRIGHT, _compass_font, 22))
	for li: Array in loot_items:
		var lr := HBoxContainer.new()
		lr.add_theme_constant_override("separation", 10)
		var lslot := PanelContainer.new()
		lslot.custom_minimum_size = Vector2(36, 36)
		var lssb := StyleBoxFlat.new()
		lssb.bg_color = Color(li[2] as Color, 0.08)
		lssb.set_corner_radius_all(4)
		lssb.border_width_bottom = 1
		lssb.border_width_top = 1
		lssb.border_width_left = 1
		lssb.border_width_right = 1
		lssb.border_color = Color(li[2] as Color, 0.35)
		lslot.add_theme_stylebox_override("panel", lssb)
		lr.add_child(lslot)
		var ln := _make_label(li[0] as String, WARM_WHITE, _awesome_font, 15)
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lr.add_child(ln)
		lr.add_child(_make_label(li[1] as String, Color(li[2] as Color, 0.80), _awesome_font, 15))
		lr.add_child(_make_label(li[3] as String, Color(li[2] as Color, 0.60), _awesome_font, 12))
		lpvb.add_child(lr)
	loot_panel.add_child(lpvb)
	page.add_child(loot_panel)

	_add_spacer(page, 16)

	# --- Achievement Card ---
	page.add_child(_section_label("Composed Card: Achievement"))
	var ach_data: Array[Array] = [
		["First Blood", "Defeat your first enemy", Color(0.70, 0.70, 0.75)],
		["Master Alchemist", "Craft 100 potions", Color(1.0, 0.80, 0.25)],
	]
	for ad: Array in ach_data:
		var acard := PanelContainer.new()
		var ac: Color = ad[2] as Color
		var acsb := _flat(Color(0.06, 0.055, 0.05, 0.88), 6)
		acsb.border_width_bottom = 2
		acsb.border_color = Color(ac, 0.40)
		acsb.content_margin_left = 14.0
		acsb.content_margin_right = 14.0
		acsb.content_margin_top = 10.0
		acsb.content_margin_bottom = 10.0
		acard.add_theme_stylebox_override("panel", acsb)
		var ahb := HBoxContainer.new()
		ahb.add_theme_constant_override("separation", 12)
		# Trophy circle
		var trophy := PanelContainer.new()
		trophy.custom_minimum_size = Vector2(44, 44)
		var tsb := StyleBoxFlat.new()
		tsb.bg_color = Color(ac, 0.12)
		tsb.set_corner_radius_all(22)
		tsb.border_width_bottom = 2
		tsb.border_width_top = 2
		tsb.border_width_left = 2
		tsb.border_width_right = 2
		tsb.border_color = Color(ac, 0.40)
		trophy.add_theme_stylebox_override("panel", tsb)
		var tl := Label.new()
		tl.text = "*"
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(tl, _compass_font, 20)
		tl.add_theme_color_override("font_color", ac)
		trophy.add_child(tl)
		ahb.add_child(trophy)
		var avb := VBoxContainer.new()
		avb.add_theme_constant_override("separation", 2)
		avb.add_child(_make_label(ad[0] as String, GOLD_BRIGHT, _awesome_font, 17))
		avb.add_child(_make_label(ad[1] as String, Color(WARM_WHITE, 0.55), _awesome_font, 13))
		ahb.add_child(avb)
		acard.add_child(ahb)
		page.add_child(acard)

	_add_spacer(page, 16)

	# --- Status Effect Card ---
	page.add_child(_section_label("Composed Card: Status Effects"))
	var status_row := _hbox(8)
	var status_data: Array[Array] = [
		["Poison", "3 turns", Color(0.40, 0.85, 0.30)],
		["Burn", "2 turns", Color(0.95, 0.50, 0.20)],
		["Frozen", "1 turn", Color(0.40, 0.70, 0.95)],
		["Blessed", "5 turns", Color(1.0, 0.90, 0.40)],
	]
	for sd: Array in status_data:
		var scard := PanelContainer.new()
		scard.custom_minimum_size = Vector2(110, 0)
		var sc: Color = sd[2] as Color
		var scsb := _flat(Color(sc, 0.06), 8)
		scsb.border_width_bottom = 2
		scsb.border_width_top = 1
		scsb.border_width_left = 1
		scsb.border_width_right = 1
		scsb.border_color = Color(sc, 0.35)
		scsb.content_margin_left = 10.0
		scsb.content_margin_right = 10.0
		scsb.content_margin_top = 8.0
		scsb.content_margin_bottom = 8.0
		scard.add_theme_stylebox_override("panel", scsb)
		var svb := VBoxContainer.new()
		svb.add_theme_constant_override("separation", 2)
		var sn := _make_label(sd[0] as String, sc, _awesome_font, 14)
		sn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		svb.add_child(sn)
		var st := _make_label(sd[1] as String, Color(sc, 0.55), _awesome_font, 11)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		svb.add_child(st)
		scard.add_child(svb)
		status_row.add_child(scard)
	page.add_child(status_row)

	return page


# ════════════════════════════════════════════════════════════
#  CIRCLE BUTTONS & SLOTS (HUD elements)
# ════════════════════════════════════════════════════════════

func _build_circle_buttons_slots_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)

	# --- Row 1: Basic circle action buttons (HUD style) ---
	page.add_child(_section_label("Circle Action Buttons — HUD primary"))
	var row1 := _hbox(12)
	var action_icons: Array[Array] = [
		["ATK", Color(0.85, 0.30, 0.25)],
		["DEF", Color(0.30, 0.55, 0.90)],
		["MGC", Color(0.65, 0.40, 0.90)],
		["ITM", Color(0.50, 0.80, 0.40)],
		["FLE", Color(0.80, 0.70, 0.35)],
	]
	for data: Array in action_icons:
		var c: Color = data[1] as Color
		var btn := Button.new()
		btn.text = data[0] as String
		btn.custom_minimum_size = Vector2(72, 72)
		_apply_font(btn, _compass_font, 18)
		btn.add_theme_color_override("font_color", Color(c, 0.95))
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(0.07, 0.06, 0.05, 0.90)
		ns.set_corner_radius_all(36)
		ns.border_width_bottom = 3
		ns.border_width_top = 1
		ns.border_width_left = 1
		ns.border_width_right = 1
		ns.border_color = Color(c, 0.45)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(c, 0.12)
		hs.border_color = Color(c, 0.80)
		btn.add_theme_stylebox_override("hover", hs)
		var ps := ns.duplicate() as StyleBoxFlat
		ps.bg_color = Color(c, 0.20)
		ps.border_width_top = 3
		ps.border_width_bottom = 1
		btn.add_theme_stylebox_override("pressed", ps)
		row1.add_child(btn)
	page.add_child(row1)

	# --- Row 2: Small circle toggles (buff/status indicators) ---
	page.add_child(_section_label("Small Circle Toggles — buffs / status"))
	var row2 := _hbox(8)
	var buff_data: Array[Array] = [
		["+", Color(0.45, 0.85, 0.50)],
		["F", Color(0.95, 0.55, 0.20)],
		["S", Color(0.40, 0.65, 0.95)],
		["P", Color(0.80, 0.30, 0.55)],
		["R", Color(0.60, 0.55, 0.90)],
		["H", Color(0.90, 0.85, 0.40)],
		["X", Color(0.75, 0.25, 0.25)],
	]
	for data: Array in buff_data:
		var c: Color = data[1] as Color
		var btn := Button.new()
		btn.text = data[0] as String
		btn.custom_minimum_size = Vector2(44, 44)
		_apply_font(btn, _awesome_font, 16)
		btn.add_theme_color_override("font_color", c)
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(c, 0.06)
		ns.set_corner_radius_all(22)
		ns.border_width_bottom = 2
		ns.border_width_top = 2
		ns.border_width_left = 2
		ns.border_width_right = 2
		ns.border_color = Color(c, 0.30)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(c, 0.18)
		hs.border_color = Color(c, 0.65)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row2.add_child(btn)
	page.add_child(row2)

	# --- Row 3: Bordered circle slots (equipment / inventory) ---
	page.add_child(_section_label("Circle Slots — equipment grid"))
	var row3 := _hbox(10)
	var slot_labels: Array[String] = ["H", "C", "L", "B", "W", "R"]
	var slot_tips: Array[String] = ["Helm", "Chest", "Legs", "Boots", "Weapon", "Ring"]
	for i: int in 6:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(80, 80)
		slot.tooltip_text = slot_tips[i]
		var sb := StyleBoxFlat.new()
		var occupied: bool = i < 3
		sb.bg_color = Color(0.09, 0.08, 0.07, 0.90) if occupied else Color(0.05, 0.045, 0.04, 0.80)
		sb.set_corner_radius_all(40)
		sb.border_width_bottom = 2
		sb.border_width_top = 2
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_color = Color(GOLD, 0.50) if occupied else Color(0.30, 0.28, 0.24, 0.40)
		slot.add_theme_stylebox_override("panel", sb)
		var lbl := Label.new()
		lbl.text = slot_labels[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(lbl, _compass_font, 24)
		lbl.add_theme_color_override("font_color", GOLD if occupied else Color(0.35, 0.32, 0.28))
		slot.add_child(lbl)
		row3.add_child(slot)
	page.add_child(row3)

	# --- Row 4: Glowing large circle (special / ultimate ability) ---
	page.add_child(_section_label("Large Circle — ultimate / special ability"))
	var row4 := _hbox(20)
	var ult_data: Array[Array] = [
		["ULT", Color(1.0, 0.85, 0.30), 96],
		["SP1", Color(0.45, 0.80, 1.0), 80],
		["SP2", Color(0.90, 0.40, 0.55), 80],
	]
	for data: Array in ult_data:
		var c: Color = data[1] as Color
		var sz: int = data[2] as int
		var btn := Button.new()
		btn.text = data[0] as String
		btn.custom_minimum_size = Vector2(sz, sz)
		_apply_font(btn, _compass_font, 20 if sz >= 96 else 16)
		btn.add_theme_color_override("font_color", c)
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(0.06, 0.055, 0.05, 0.92)
		ns.set_corner_radius_all(sz / 2)
		ns.border_width_bottom = 3
		ns.border_width_top = 2
		ns.border_width_left = 2
		ns.border_width_right = 2
		ns.border_color = Color(c, 0.50)
		ns.shadow_color = Color(c, 0.12)
		ns.shadow_size = 10
		ns.shadow_offset = Vector2(0, 0)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(c, 0.10)
		hs.border_color = Color(c, 0.85)
		hs.shadow_color = Color(c, 0.30)
		hs.shadow_size = 16
		btn.add_theme_stylebox_override("hover", hs)
		var ps := ns.duplicate() as StyleBoxFlat
		ps.bg_color = Color(c, 0.18)
		ps.shadow_size = 4
		btn.add_theme_stylebox_override("pressed", ps)
		row4.add_child(btn)
	page.add_child(row4)

	# --- Row 5: Square slots with rounded corners (item grid style) ---
	page.add_child(_section_label("Rounded Square Slots — item grid"))
	var row5 := _hbox(8)
	var rarity_colors: Array[Color] = [
		Color(0.50, 0.50, 0.55),  # Common (grey)
		Color(0.35, 0.75, 0.45),  # Uncommon (green)
		Color(0.40, 0.60, 0.95),  # Rare (blue)
		Color(0.70, 0.45, 0.90),  # Epic (purple)
		Color(1.0, 0.80, 0.25),   # Legendary (gold)
		Color(0.90, 0.35, 0.30),  # Mythic (red)
	]
	var rarity_names: Array[String] = ["C", "U", "R", "E", "L", "M"]
	for i: int in 6:
		var rc: Color = rarity_colors[i]
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(72, 72)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.055, 0.05, 0.90)
		sb.set_corner_radius_all(12)
		sb.border_width_bottom = 2
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_color = Color(rc, 0.55)
		sb.shadow_color = Color(rc, 0.08)
		sb.shadow_size = 4
		slot.add_theme_stylebox_override("panel", sb)
		var lbl := Label.new()
		lbl.text = rarity_names[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(lbl, _compass_font, 22)
		lbl.add_theme_color_override("font_color", rc)
		slot.add_child(lbl)
		row5.add_child(slot)
	page.add_child(row5)

	# --- Row 6: Mini circle counters (resource/currency HUD) ---
	page.add_child(_section_label("Mini Counters — resource HUD"))
	var row6 := _hbox(14)
	var counter_data: Array[Array] = [
		["G", "1,247", Color(1.0, 0.85, 0.30)],
		["D", "42", Color(0.55, 0.85, 0.95)],
		["E", "8", Color(0.80, 0.50, 0.95)],
		["K", "156", Color(0.85, 0.35, 0.30)],
	]
	for data: Array in counter_data:
		var c: Color = data[2] as Color
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		# Circle icon
		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(36, 36)
		var isb := StyleBoxFlat.new()
		isb.bg_color = Color(c, 0.15)
		isb.set_corner_radius_all(18)
		isb.border_width_bottom = 1
		isb.border_width_top = 1
		isb.border_width_left = 1
		isb.border_width_right = 1
		isb.border_color = Color(c, 0.40)
		icon_panel.add_theme_stylebox_override("panel", isb)
		var icon_lbl := Label.new()
		icon_lbl.text = data[0] as String
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(icon_lbl, _compass_font, 14)
		icon_lbl.add_theme_color_override("font_color", c)
		icon_panel.add_child(icon_lbl)
		hb.add_child(icon_panel)
		# Value text
		var val := Label.new()
		val.text = data[1] as String
		_apply_font(val, _awesome_font, 16)
		val.add_theme_color_override("font_color", WARM_WHITE)
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(val)
		row6.add_child(hb)
	page.add_child(row6)

	# --- Row 7: Hexagonal-feel buttons (6-sided approximation via corners) ---
	page.add_child(_section_label("Hex-Feel Buttons — angular shape"))
	var row7 := _hbox(10)
	var hex_data: Array[Array] = [
		["I", Color(0.95, 0.70, 0.20)],
		["II", Color(0.40, 0.80, 0.95)],
		["III", Color(0.90, 0.40, 0.40)],
		["IV", Color(0.50, 0.90, 0.50)],
	]
	for data: Array in hex_data:
		var c: Color = data[1] as Color
		var btn := Button.new()
		btn.text = data[0] as String
		btn.custom_minimum_size = Vector2(68, 68)
		_apply_font(btn, _compass_font, 18)
		btn.add_theme_color_override("font_color", c)
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(0.06, 0.055, 0.05, 0.90)
		# Use different corner radii to create a hex feel
		ns.corner_radius_top_left = 18
		ns.corner_radius_top_right = 4
		ns.corner_radius_bottom_left = 4
		ns.corner_radius_bottom_right = 18
		ns.border_width_bottom = 2
		ns.border_width_top = 2
		ns.border_width_left = 2
		ns.border_width_right = 2
		ns.border_color = Color(c, 0.45)
		btn.add_theme_stylebox_override("normal", ns)
		var hs := ns.duplicate() as StyleBoxFlat
		hs.bg_color = Color(c, 0.12)
		hs.border_color = Color(c, 0.75)
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", ns)
		row7.add_child(btn)
	page.add_child(row7)

	# --- Row 8: Concentric ring slot (double border) ---
	page.add_child(_section_label("Concentric Ring Slots — double border"))
	var row8 := _hbox(12)
	for i: int in 4:
		var outer := PanelContainer.new()
		outer.custom_minimum_size = Vector2(84, 84)
		var osb := StyleBoxFlat.new()
		var occupied: bool = i < 2
		osb.bg_color = Color(0, 0, 0, 0)
		osb.set_corner_radius_all(42)
		osb.border_width_bottom = 2
		osb.border_width_top = 2
		osb.border_width_left = 2
		osb.border_width_right = 2
		osb.border_color = Color(GOLD, 0.35) if occupied else Color(0.25, 0.23, 0.20, 0.30)
		outer.add_theme_stylebox_override("panel", osb)
		var inner := PanelContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		inner.custom_minimum_size = Vector2(60, 60)
		var isb := StyleBoxFlat.new()
		isb.bg_color = Color(0.07, 0.06, 0.05, 0.90) if occupied else Color(0.04, 0.035, 0.03, 0.70)
		isb.set_corner_radius_all(30)
		isb.border_width_bottom = 2
		isb.border_width_top = 2
		isb.border_width_left = 2
		isb.border_width_right = 2
		isb.border_color = Color(GOLD, 0.50) if occupied else Color(0.20, 0.18, 0.16, 0.30)
		inner.add_theme_stylebox_override("panel", isb)
		var il := Label.new()
		il.text = str(i + 1) if occupied else ""
		il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		il.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(il, _compass_font, 20)
		il.add_theme_color_override("font_color", GOLD if occupied else DIM)
		inner.add_child(il)
		outer.add_child(inner)
		row8.add_child(outer)
	page.add_child(row8)

	# --- Row 9: Cooldown timer circles ---
	page.add_child(_section_label("Cooldown Timers — partial fill"))
	var row9 := _hbox(12)
	var cd_data: Array[Array] = [
		["ATK", 0.75, Color(0.85, 0.30, 0.25)],
		["MAG", 0.40, Color(0.65, 0.40, 0.90)],
		["HEL", 0.90, Color(0.40, 0.85, 0.50)],
		["ULT", 0.15, Color(1.0, 0.85, 0.30)],
	]
	for data: Array in cd_data:
		var c: Color = data[2] as Color
		var pct: float = data[1] as float
		var cd_panel := PanelContainer.new()
		cd_panel.custom_minimum_size = Vector2(72, 72)
		var cdsb := StyleBoxFlat.new()
		cdsb.bg_color = Color(0.06, 0.055, 0.05, 0.90)
		cdsb.set_corner_radius_all(36)
		cdsb.border_width_bottom = 3
		cdsb.border_width_top = 3
		cdsb.border_width_left = 3
		cdsb.border_width_right = 3
		cdsb.border_color = Color(c, 0.50)
		if pct < 0.5:
			cdsb.bg_color = Color(c, 0.04)
			cdsb.border_color = Color(c, 0.20)
		cd_panel.add_theme_stylebox_override("panel", cdsb)
		var cd_vb := VBoxContainer.new()
		cd_vb.add_theme_constant_override("separation", 0)
		cd_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		var cd_lbl := Label.new()
		cd_lbl.text = data[0] as String
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_font(cd_lbl, _compass_font, 14)
		cd_lbl.add_theme_color_override("font_color", c if pct >= 0.5 else Color(c, 0.45))
		cd_vb.add_child(cd_lbl)
		var pct_lbl := Label.new()
		pct_lbl.text = "%d%%" % int(pct * 100.0)
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_font(pct_lbl, _awesome_font, 11)
		pct_lbl.add_theme_color_override("font_color", Color(c, 0.60))
		cd_vb.add_child(pct_lbl)
		cd_panel.add_child(cd_vb)
		row9.add_child(cd_panel)
	page.add_child(row9)

	# --- Row 10: Pip/dot indicators ---
	page.add_child(_section_label("Pip Indicators — filled vs empty"))
	var row10 := _hbox(6)
	for i: int in 8:
		var pip := PanelContainer.new()
		pip.custom_minimum_size = Vector2(20, 20)
		var psb := StyleBoxFlat.new()
		var filled: bool = i < 5
		psb.bg_color = Color(GOLD, 0.70) if filled else Color(0.15, 0.14, 0.12, 0.50)
		psb.set_corner_radius_all(10)
		psb.border_width_bottom = 1
		psb.border_width_top = 1
		psb.border_width_left = 1
		psb.border_width_right = 1
		psb.border_color = Color(GOLD, 0.40) if filled else Color(0.25, 0.23, 0.20, 0.30)
		pip.add_theme_stylebox_override("panel", psb)
		pip.add_child(Control.new())
		row10.add_child(pip)
	var pip_label := _make_label("  5 / 8 charges", DIM, _awesome_font, 13)
	pip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row10.add_child(pip_label)
	page.add_child(row10)

	return page


# ════════════════════════════════════════════════════════════
#  NOTIFICATIONS & DIALOGS
# ════════════════════════════════════════════════════════════

func _build_notifications_dialogs_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)

	# --- Toast banner: success / warning / error / info ---
	page.add_child(_section_label("Toast Notifications"))
	var toast_data: Array[Array] = [
		["Quest completed!", Color(0.35, 0.78, 0.40), "SUCCESS"],
		["Inventory nearly full", Color(0.92, 0.78, 0.28), "WARNING"],
		["Connection lost", Color(0.85, 0.30, 0.25), "ERROR"],
		["New area discovered", Color(0.45, 0.70, 0.95), "INFO"],
	]
	for td: Array in toast_data:
		var toast := PanelContainer.new()
		toast.custom_minimum_size = Vector2(0, 56)
		var sb := StyleBoxFlat.new()
		var c: Color = td[1] as Color
		sb.bg_color = Color(0.08, 0.07, 0.06, 0.92)
		sb.border_width_left = 5
		sb.border_color = c
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.content_margin_left = 18.0
		sb.content_margin_right = 12.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		toast.add_theme_stylebox_override("panel", sb)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var badge := Label.new()
		badge.text = td[2] as String
		_apply_font(badge, _awesome_font, 12)
		badge.add_theme_color_override("font_color", c)
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(badge)
		var msg := Label.new()
		msg.text = td[0] as String
		_apply_font(msg, _awesome_font, 18)
		msg.add_theme_color_override("font_color", WARM_WHITE)
		msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(msg)
		toast.add_child(hb)
		page.add_child(toast)

	# --- Confirmation dialog ---
	page.add_child(_section_label("Confirmation Dialog"))
	var dlg := PanelContainer.new()
	dlg.custom_minimum_size = Vector2(480, 0)
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color(0.06, 0.055, 0.05, 0.96)
	dsb.border_width_top = 3
	dsb.border_color = GOLD
	dsb.corner_radius_top_left = 8
	dsb.corner_radius_top_right = 8
	dsb.corner_radius_bottom_left = 4
	dsb.corner_radius_bottom_right = 4
	dsb.content_margin_left = 24.0
	dsb.content_margin_right = 24.0
	dsb.content_margin_top = 20.0
	dsb.content_margin_bottom = 20.0
	dsb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	dsb.shadow_size = 8
	dlg.add_theme_stylebox_override("panel", dsb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	var title := Label.new()
	title.text = "Discard item?"
	_apply_font(title, _compass_font, 24)
	title.add_theme_color_override("font_color", GOLD_BRIGHT)
	vb.add_child(title)
	var body := Label.new()
	body.text = "This action cannot be undone.\nThe Iron Shield will be permanently removed."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(body, _awesome_font, 16)
	body.add_theme_color_override("font_color", Color(0.80, 0.76, 0.68))
	vb.add_child(body)
	var btn_row := _hbox(10)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(120, 44)
	_apply_font(cancel, _awesome_font, 16)
	cancel.add_theme_color_override("font_color", Color(0.65, 0.60, 0.55))
	var cnl_sb := _flat(Color(0.15, 0.14, 0.12, 0.80), 6)
	cnl_sb.border_width_bottom = 1
	cnl_sb.border_color = Color(0.35, 0.32, 0.28)
	cancel.add_theme_stylebox_override("normal", cnl_sb)
	cancel.add_theme_stylebox_override("hover", cnl_sb)
	cancel.add_theme_stylebox_override("pressed", cnl_sb)
	btn_row.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "Discard"
	confirm.custom_minimum_size = Vector2(120, 44)
	_apply_font(confirm, _awesome_font, 16)
	confirm.add_theme_color_override("font_color", Color(1.0, 0.90, 0.85))
	var cfm_sb := _flat(Color(0.75, 0.25, 0.20, 0.85), 6)
	cfm_sb.border_width_bottom = 2
	cfm_sb.border_color = Color(0.95, 0.35, 0.25)
	confirm.add_theme_stylebox_override("normal", cfm_sb)
	var cfm_h := cfm_sb.duplicate() as StyleBoxFlat
	cfm_h.bg_color = Color(0.85, 0.30, 0.25, 0.95)
	confirm.add_theme_stylebox_override("hover", cfm_h)
	confirm.add_theme_stylebox_override("pressed", cfm_sb)
	btn_row.add_child(confirm)
	vb.add_child(btn_row)
	dlg.add_child(vb)
	page.add_child(dlg)

	# --- Banner announcement ---
	page.add_child(_section_label("Banner Announcement"))
	var banner := PanelContainer.new()
	banner.custom_minimum_size = Vector2(0, 72)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.10, 0.08, 0.06, 0.95)
	bsb.border_width_top = 2
	bsb.border_width_bottom = 2
	bsb.border_color = Color(GOLD, 0.40)
	bsb.content_margin_left = 20.0
	bsb.content_margin_right = 20.0
	bsb.content_margin_top = 8.0
	bsb.content_margin_bottom = 8.0
	banner.add_theme_stylebox_override("panel", bsb)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 4)
	bvb.alignment = BoxContainer.ALIGNMENT_CENTER
	var bt := Label.new()
	bt.text = "LEVEL UP!"
	bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(bt, _compass_font, 28)
	bt.add_theme_color_override("font_color", GOLD_BRIGHT)
	bvb.add_child(bt)
	var bs := Label.new()
	bs.text = "You reached Level 12  —  +3 STR  +2 DEX"
	bs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(bs, _awesome_font, 16)
	bs.add_theme_color_override("font_color", Color(0.82, 0.78, 0.70))
	bvb.add_child(bs)
	banner.add_child(bvb)
	page.add_child(banner)

	# --- Inline progress bar ---
	page.add_child(_section_label("Progress / XP Bars"))
	for pdata: Array in [["HP", 0.72, Color(0.78, 0.22, 0.18)], ["MP", 0.45, Color(0.30, 0.50, 0.90)], ["XP", 0.88, Color(0.92, 0.78, 0.28)]]:
		var bar_row := HBoxContainer.new()
		bar_row.add_theme_constant_override("separation", 10)
		var lbl := Label.new()
		lbl.text = pdata[0] as String
		lbl.custom_minimum_size.x = 32.0
		_apply_font(lbl, _awesome_font, 14)
		lbl.add_theme_color_override("font_color", Color(0.60, 0.56, 0.50))
		bar_row.add_child(lbl)
		var track := PanelContainer.new()
		track.custom_minimum_size = Vector2(320, 22)
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tsb := StyleBoxFlat.new()
		tsb.bg_color = Color(0.06, 0.05, 0.04, 0.90)
		tsb.corner_radius_top_left = 4
		tsb.corner_radius_top_right = 4
		tsb.corner_radius_bottom_left = 4
		tsb.corner_radius_bottom_right = 4
		tsb.border_width_bottom = 1
		tsb.border_width_top = 1
		tsb.border_width_left = 1
		tsb.border_width_right = 1
		tsb.border_color = Color(0.25, 0.23, 0.20, 0.50)
		track.add_theme_stylebox_override("panel", tsb)
		var fill := ColorRect.new()
		fill.custom_minimum_size = Vector2(320.0 * (pdata[1] as float), 0)
		fill.color = pdata[2] as Color
		fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		track.add_child(fill)
		var val := Label.new()
		val.text = "%d%%" % int((pdata[1] as float) * 100.0)
		val.custom_minimum_size.x = 44.0
		_apply_font(val, _awesome_font, 14)
		val.add_theme_color_override("font_color", WARM_WHITE)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bar_row.add_child(val)
		page.add_child(bar_row)

	# --- Floating tooltip ---
	page.add_child(_section_label("Floating Tooltip"))
	var tip := PanelContainer.new()
	tip.custom_minimum_size = Vector2(320, 0)
	var tip_sb := StyleBoxFlat.new()
	tip_sb.bg_color = Color(0.04, 0.035, 0.03, 0.96)
	tip_sb.set_corner_radius_all(6)
	tip_sb.border_width_bottom = 1
	tip_sb.border_width_top = 1
	tip_sb.border_width_left = 1
	tip_sb.border_width_right = 1
	tip_sb.border_color = Color(GOLD, 0.30)
	tip_sb.shadow_color = Color(0, 0, 0, 0.50)
	tip_sb.shadow_size = 12
	tip_sb.content_margin_left = 14.0
	tip_sb.content_margin_right = 14.0
	tip_sb.content_margin_top = 10.0
	tip_sb.content_margin_bottom = 10.0
	tip.add_theme_stylebox_override("panel", tip_sb)
	var tip_vb := VBoxContainer.new()
	tip_vb.add_theme_constant_override("separation", 4)
	tip_vb.add_child(_make_label("Iron Helm", GOLD_BRIGHT, _compass_font, 18))
	tip_vb.add_child(_make_label("Armor — Head Slot", DIM, _awesome_font, 12))
	tip_vb.add_child(_make_label("+8 DEF   +2 VIT", Color(0.45, 0.85, 0.55), _awesome_font, 14))
	tip_vb.add_child(_make_label("Reduces incoming damage by 5%.", Color(WARM_WHITE, 0.60), _awesome_font, 13))
	tip.add_child(tip_vb)
	page.add_child(tip)

	# --- Segmented bar (multi-section HP / shield) ---
	page.add_child(_section_label("Segmented Bar — HP + Shield"))
	var seg_outer := HBoxContainer.new()
	seg_outer.add_theme_constant_override("separation", 2)
	var seg_parts: Array[Array] = [
		[0.50, Color(0.78, 0.22, 0.18)],
		[0.20, Color(0.30, 0.55, 0.90)],
		[0.30, Color(0.15, 0.14, 0.12)],
	]
	var seg_labels: Array[String] = ["HP", "Shield", "Lost"]
	for i: int in 3:
		var seg := PanelContainer.new()
		seg.custom_minimum_size = Vector2(420.0 * (seg_parts[i][0] as float), 28)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ssb := StyleBoxFlat.new()
		var sc: Color = seg_parts[i][1] as Color
		ssb.bg_color = sc
		ssb.corner_radius_top_left = 4 if i == 0 else 0
		ssb.corner_radius_bottom_left = 4 if i == 0 else 0
		ssb.corner_radius_top_right = 4 if i == 2 else 0
		ssb.corner_radius_bottom_right = 4 if i == 2 else 0
		seg.add_theme_stylebox_override("panel", ssb)
		var sl := Label.new()
		sl.text = seg_labels[i]
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(sl, _awesome_font, 11)
		sl.add_theme_color_override("font_color", WARM_WHITE)
		seg.add_child(sl)
		seg_outer.add_child(seg)
	page.add_child(seg_outer)

	# --- System message panel ---
	page.add_child(_section_label("System Message Panel"))
	var sys_msg := PanelContainer.new()
	var sm_sb := _flat(Color(0.04, 0.04, 0.06, 0.94), 4)
	sm_sb.border_width_bottom = 1
	sm_sb.border_width_top = 1
	sm_sb.border_width_left = 1
	sm_sb.border_width_right = 1
	sm_sb.border_color = Color(0.25, 0.23, 0.20, 0.35)
	sm_sb.content_margin_left = 16.0
	sm_sb.content_margin_right = 16.0
	sm_sb.content_margin_top = 10.0
	sm_sb.content_margin_bottom = 10.0
	sys_msg.add_theme_stylebox_override("panel", sm_sb)
	var sm_vb := VBoxContainer.new()
	sm_vb.add_theme_constant_override("separation", 4)
	sm_vb.add_child(_make_label("[System]", Color(0.55, 0.52, 0.48), _awesome_font, 12))
	sm_vb.add_child(_make_label("Server maintenance scheduled at 02:00 UTC.", Color(WARM_WHITE, 0.70), _awesome_font, 15))
	sm_vb.add_child(_make_label("All progress will be saved automatically.", Color(WARM_WHITE, 0.45), _awesome_font, 13))
	sys_msg.add_child(sm_vb)
	page.add_child(sys_msg)

	# --- Currency gain popup ---
	page.add_child(_section_label("Currency Gain Popup"))
	var curr_popup := PanelContainer.new()
	curr_popup.custom_minimum_size = Vector2(280, 0)
	var cp_sb := _flat(Color(0.08, 0.07, 0.05, 0.92), 10)
	cp_sb.border_width_bottom = 2
	cp_sb.border_color = Color(GOLD, 0.40)
	cp_sb.shadow_color = Color(GOLD, 0.06)
	cp_sb.shadow_size = 8
	cp_sb.content_margin_left = 16.0
	cp_sb.content_margin_right = 16.0
	cp_sb.content_margin_top = 12.0
	cp_sb.content_margin_bottom = 12.0
	curr_popup.add_theme_stylebox_override("panel", cp_sb)
	var cp_hb := HBoxContainer.new()
	cp_hb.add_theme_constant_override("separation", 12)
	cp_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	var coin_icon := PanelContainer.new()
	coin_icon.custom_minimum_size = Vector2(40, 40)
	var ci_sb := StyleBoxFlat.new()
	ci_sb.bg_color = Color(GOLD, 0.15)
	ci_sb.set_corner_radius_all(20)
	ci_sb.border_width_bottom = 2
	ci_sb.border_width_top = 2
	ci_sb.border_width_left = 2
	ci_sb.border_width_right = 2
	ci_sb.border_color = Color(GOLD, 0.45)
	coin_icon.add_theme_stylebox_override("panel", ci_sb)
	var ci_lbl := Label.new()
	ci_lbl.text = "G"
	ci_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ci_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(ci_lbl, _compass_font, 18)
	ci_lbl.add_theme_color_override("font_color", GOLD)
	coin_icon.add_child(ci_lbl)
	cp_hb.add_child(coin_icon)
	cp_hb.add_child(_make_label("+350 Gold", GOLD_BRIGHT, _compass_font, 24))
	curr_popup.add_child(cp_hb)
	page.add_child(curr_popup)

	# --- Achievement unlock banner ---
	page.add_child(_section_label("Achievement Unlock"))
	var ach := PanelContainer.new()
	var ach_sb := _flat(Color(0.07, 0.065, 0.05, 0.94), 6)
	ach_sb.border_width_top = 3
	ach_sb.border_width_bottom = 1
	ach_sb.border_color = Color(1.0, 0.80, 0.25, 0.55)
	ach_sb.shadow_color = Color(1.0, 0.85, 0.30, 0.08)
	ach_sb.shadow_size = 10
	ach_sb.content_margin_left = 16.0
	ach_sb.content_margin_right = 16.0
	ach_sb.content_margin_top = 12.0
	ach_sb.content_margin_bottom = 12.0
	ach.add_theme_stylebox_override("panel", ach_sb)
	var ach_vb := VBoxContainer.new()
	ach_vb.add_theme_constant_override("separation", 4)
	var ach_top := _make_label("ACHIEVEMENT UNLOCKED", Color(1.0, 0.85, 0.30, 0.70), _awesome_font, 12)
	ach_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_vb.add_child(ach_top)
	var ach_name := _make_label("Dragon Slayer", GOLD_BRIGHT, _compass_font, 24)
	ach_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_vb.add_child(ach_name)
	var ach_desc := _make_label("Defeat the Elder Dragon in under 5 minutes", Color(WARM_WHITE, 0.55), _awesome_font, 14)
	ach_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_vb.add_child(ach_desc)
	ach.add_child(ach_vb)
	page.add_child(ach)

	return page


# ════════════════════════════════════════════════════════════
#  PAGE 10: FULL MOCKUPS
# ════════════════════════════════════════════════════════════

func _build_full_mockups_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 24)

	# --- Mockup A: Inventory Slot Grid inside Textured Panel ---
	page.add_child(_section_label("Mockup A: Inventory Panel"))
	var inv_panel := PanelContainer.new()
	var inv_sb := StyleBoxFlat.new()
	inv_sb.bg_color = Color(0.055, 0.05, 0.045, 0.95)
	inv_sb.border_width_top = 3
	inv_sb.border_color = GOLD
	inv_sb.corner_radius_top_left = 6
	inv_sb.corner_radius_top_right = 6
	inv_sb.content_margin_left = 16.0
	inv_sb.content_margin_right = 16.0
	inv_sb.content_margin_top = 16.0
	inv_sb.content_margin_bottom = 16.0
	inv_sb.shadow_color = Color(0, 0, 0, 0.30)
	inv_sb.shadow_size = 6
	inv_panel.add_theme_stylebox_override("panel", inv_sb)
	var inv_vb := VBoxContainer.new()
	inv_vb.add_theme_constant_override("separation", 12)
	var inv_title := Label.new()
	inv_title.text = "Inventory"
	_apply_font(inv_title, _compass_font, 24)
	inv_title.add_theme_color_override("font_color", GOLD_BRIGHT)
	inv_vb.add_child(inv_title)
	# Slot grid
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for i: int in 18:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(64, 64)
		var ssb := StyleBoxFlat.new()
		ssb.bg_color = Color(0.08, 0.07, 0.06, 0.85) if i >= 5 else Color(0.12, 0.10, 0.08, 0.90)
		ssb.corner_radius_top_left = 4
		ssb.corner_radius_top_right = 4
		ssb.corner_radius_bottom_left = 4
		ssb.corner_radius_bottom_right = 4
		ssb.border_width_bottom = 1
		ssb.border_width_top = 1
		ssb.border_width_left = 1
		ssb.border_width_right = 1
		ssb.border_color = Color(GOLD, 0.15) if i >= 5 else Color(GOLD, 0.50)
		slot.add_theme_stylebox_override("panel", ssb)
		if i < 5:
			var qty := Label.new()
			qty.text = str(randi_range(1, 64))
			qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			qty.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			_apply_font(qty, _awesome_font, 11)
			qty.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
			slot.add_child(qty)
		grid.add_child(slot)
	inv_vb.add_child(grid)
	# Gold display
	var gold_row := HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_END
	gold_row.add_theme_constant_override("separation", 6)
	var coin := Label.new()
	coin.text = "Gold:"
	_apply_font(coin, _awesome_font, 14)
	coin.add_theme_color_override("font_color", Color(0.60, 0.56, 0.50))
	gold_row.add_child(coin)
	var gold_val := Label.new()
	gold_val.text = "1,247"
	_apply_font(gold_val, _awesome_font, 16)
	gold_val.add_theme_color_override("font_color", GOLD)
	gold_row.add_child(gold_val)
	inv_vb.add_child(gold_row)
	inv_panel.add_child(inv_vb)
	page.add_child(inv_panel)

	# --- Mockup B: Quest Log Panel ---
	page.add_child(_section_label("Mockup B: Quest Log"))
	var quest_panel := PanelContainer.new()
	var qsb := StyleBoxFlat.new()
	qsb.bg_color = Color(0.05, 0.045, 0.04, 0.95)
	qsb.border_width_left = 4
	qsb.border_color = Color(0.45, 0.70, 0.95)
	qsb.corner_radius_top_right = 6
	qsb.corner_radius_bottom_right = 6
	qsb.content_margin_left = 20.0
	qsb.content_margin_right = 16.0
	qsb.content_margin_top = 16.0
	qsb.content_margin_bottom = 16.0
	quest_panel.add_theme_stylebox_override("panel", qsb)
	var qvb := VBoxContainer.new()
	qvb.add_theme_constant_override("separation", 14)
	var qt := Label.new()
	qt.text = "Active Quests"
	_apply_font(qt, _compass_font, 22)
	qt.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))
	qvb.add_child(qt)
	var quests: Array[Array] = [
		["The Lost Amulet", "Find the amulet in the Dark Forest", "2/3 clues found", false],
		["Village Defense", "Defeat 10 goblins near the gate", "7/10 defeated", false],
		["Herb Gathering", "Collect 5 moonblossoms", "5/5 collected", true],
	]
	for q: Array in quests:
		var qcard := PanelContainer.new()
		var qcsb := StyleBoxFlat.new()
		qcsb.bg_color = Color(0.07, 0.065, 0.06, 0.80)
		qcsb.corner_radius_top_left = 4
		qcsb.corner_radius_top_right = 4
		qcsb.corner_radius_bottom_left = 4
		qcsb.corner_radius_bottom_right = 4
		qcsb.content_margin_left = 12.0
		qcsb.content_margin_right = 12.0
		qcsb.content_margin_top = 8.0
		qcsb.content_margin_bottom = 8.0
		if q[3] as bool:
			qcsb.border_width_left = 3
			qcsb.border_color = Color(0.35, 0.78, 0.40)
		qcard.add_theme_stylebox_override("panel", qcsb)
		var qcvb := VBoxContainer.new()
		qcvb.add_theme_constant_override("separation", 4)
		var qn := Label.new()
		qn.text = q[0] as String
		_apply_font(qn, _awesome_font, 17)
		var done: bool = q[3] as bool
		qn.add_theme_color_override("font_color", Color(0.40, 0.75, 0.45) if done else WARM_WHITE)
		qcvb.add_child(qn)
		var qd := Label.new()
		qd.text = q[1] as String
		_apply_font(qd, _awesome_font, 13)
		qd.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))
		qcvb.add_child(qd)
		var qp := Label.new()
		qp.text = q[2] as String
		_apply_font(qp, _awesome_font, 13)
		qp.add_theme_color_override("font_color", Color(GOLD, 0.70))
		qcvb.add_child(qp)
		qcard.add_child(qcvb)
		qvb.add_child(qcard)
	quest_panel.add_child(qvb)
	page.add_child(quest_panel)

	# --- Mockup C: Stat Panel ---
	page.add_child(_section_label("Mockup C: Character Stats"))
	var stat_panel := PanelContainer.new()
	var stsb := StyleBoxFlat.new()
	stsb.bg_color = Color(0.055, 0.05, 0.045, 0.95)
	stsb.border_width_top = 2
	stsb.border_width_bottom = 1
	stsb.border_color = Color(GOLD, 0.35)
	stsb.corner_radius_top_left = 6
	stsb.corner_radius_top_right = 6
	stsb.corner_radius_bottom_left = 6
	stsb.corner_radius_bottom_right = 6
	stsb.content_margin_left = 20.0
	stsb.content_margin_right = 20.0
	stsb.content_margin_top = 16.0
	stsb.content_margin_bottom = 16.0
	stat_panel.add_theme_stylebox_override("panel", stsb)
	var stvb := VBoxContainer.new()
	stvb.add_theme_constant_override("separation", 10)
	var stt := Label.new()
	stt.text = "Aetherian Wanderer  Lv.12"
	_apply_font(stt, _compass_font, 22)
	stt.add_theme_color_override("font_color", GOLD_BRIGHT)
	stvb.add_child(stt)
	var stats: Array[Array] = [
		["STR", "24", Color(0.85, 0.35, 0.30)],
		["DEX", "18", Color(0.45, 0.85, 0.50)],
		["INT", "31", Color(0.50, 0.55, 0.95)],
		["VIT", "22", Color(0.90, 0.72, 0.30)],
		["LCK", "14", Color(0.75, 0.55, 0.90)],
	]
	for s: Array in stats:
		var sr := HBoxContainer.new()
		sr.add_theme_constant_override("separation", 8)
		var sn := Label.new()
		sn.text = s[0] as String
		sn.custom_minimum_size.x = 40.0
		_apply_font(sn, _awesome_font, 15)
		sn.add_theme_color_override("font_color", s[2] as Color)
		sr.add_child(sn)
		# stat bar
		var bar_bg := PanelContainer.new()
		bar_bg.custom_minimum_size = Vector2(200, 16)
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bbsb := StyleBoxFlat.new()
		bbsb.bg_color = Color(0.06, 0.05, 0.04, 0.90)
		bbsb.corner_radius_top_left = 3
		bbsb.corner_radius_top_right = 3
		bbsb.corner_radius_bottom_left = 3
		bbsb.corner_radius_bottom_right = 3
		bar_bg.add_theme_stylebox_override("panel", bbsb)
		var fill_rect := ColorRect.new()
		var fill_pct: float = float(s[1] as String) / 40.0
		fill_rect.custom_minimum_size = Vector2(200.0 * fill_pct, 0)
		fill_rect.color = Color(s[2] as Color, 0.60)
		fill_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bar_bg.add_child(fill_rect)
		sr.add_child(bar_bg)
		var sv := Label.new()
		sv.text = s[1] as String
		sv.custom_minimum_size.x = 32.0
		sv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_apply_font(sv, _awesome_font, 15)
		sv.add_theme_color_override("font_color", WARM_WHITE)
		sr.add_child(sv)
		stvb.add_child(sr)
	stat_panel.add_child(stvb)
	page.add_child(stat_panel)

	# --- Mockup D: Combat HUD Bar ---
	page.add_child(_section_label("Mockup D: Combat HUD Bar"))
	var combat_bar := PanelContainer.new()
	var cbsb := _flat(Color(0.04, 0.035, 0.03, 0.94), 0)
	cbsb.border_width_top = 2
	cbsb.border_color = Color(GOLD, 0.35)
	cbsb.content_margin_left = 16.0
	cbsb.content_margin_right = 16.0
	cbsb.content_margin_top = 10.0
	cbsb.content_margin_bottom = 10.0
	combat_bar.add_theme_stylebox_override("panel", cbsb)
	var cb_hb := HBoxContainer.new()
	cb_hb.add_theme_constant_override("separation", 16)
	# Player name + level
	var cb_name := VBoxContainer.new()
	cb_name.add_theme_constant_override("separation", 2)
	cb_name.add_child(_make_label("Wanderer", GOLD_BRIGHT, _compass_font, 18))
	cb_name.add_child(_make_label("Lv. 12", DIM, _awesome_font, 12))
	cb_hb.add_child(cb_name)
	# HP bar
	var cb_hp_track := PanelContainer.new()
	cb_hp_track.custom_minimum_size = Vector2(180, 18)
	cb_hp_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cb_hp_track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cb_hp_sb := _flat(Color(0.06, 0.05, 0.04), 3)
	cb_hp_sb.border_width_bottom = 1
	cb_hp_sb.border_color = Color(0.20, 0.18, 0.15, 0.50)
	cb_hp_track.add_theme_stylebox_override("panel", cb_hp_sb)
	var cb_hp_fill := ColorRect.new()
	cb_hp_fill.custom_minimum_size = Vector2(130, 0)
	cb_hp_fill.color = Color(0.78, 0.22, 0.18)
	cb_hp_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cb_hp_track.add_child(cb_hp_fill)
	cb_hb.add_child(cb_hp_track)
	# MP bar
	var cb_mp_track := PanelContainer.new()
	cb_mp_track.custom_minimum_size = Vector2(120, 18)
	cb_mp_track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cb_mp_sb := _flat(Color(0.06, 0.05, 0.04), 3)
	cb_mp_sb.border_width_bottom = 1
	cb_mp_sb.border_color = Color(0.20, 0.18, 0.15, 0.50)
	cb_mp_track.add_theme_stylebox_override("panel", cb_mp_sb)
	var cb_mp_fill := ColorRect.new()
	cb_mp_fill.custom_minimum_size = Vector2(55, 0)
	cb_mp_fill.color = Color(0.30, 0.50, 0.90)
	cb_mp_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cb_mp_track.add_child(cb_mp_fill)
	cb_hb.add_child(cb_mp_track)
	# Action buttons
	for txt: String in ["ATK", "DEF", "FLE"]:
		var ab := Button.new()
		ab.text = txt
		ab.custom_minimum_size = Vector2(56, 56)
		_apply_font(ab, _compass_font, 14)
		ab.add_theme_color_override("font_color", GOLD)
		var abs := StyleBoxFlat.new()
		abs.bg_color = Color(0.08, 0.07, 0.06, 0.90)
		abs.set_corner_radius_all(28)
		abs.border_width_bottom = 2
		abs.border_color = Color(GOLD, 0.40)
		ab.add_theme_stylebox_override("normal", abs)
		ab.add_theme_stylebox_override("hover", abs)
		ab.add_theme_stylebox_override("pressed", abs)
		cb_hb.add_child(ab)
	combat_bar.add_child(cb_hb)
	page.add_child(combat_bar)

	# --- Mockup E: Shop / Merchant Panel ---
	page.add_child(_section_label("Mockup E: Shop Panel"))
	var shop := PanelContainer.new()
	var shsb := _flat(Color(0.055, 0.05, 0.045, 0.95), 8)
	shsb.border_width_top = 3
	shsb.border_color = Color(0.92, 0.78, 0.28)
	shsb.content_margin_left = 16.0
	shsb.content_margin_right = 16.0
	shsb.content_margin_top = 14.0
	shsb.content_margin_bottom = 14.0
	shsb.shadow_color = Color(0, 0, 0, 0.30)
	shsb.shadow_size = 8
	shop.add_theme_stylebox_override("panel", shsb)
	var sh_vb := VBoxContainer.new()
	sh_vb.add_theme_constant_override("separation", 10)
	sh_vb.add_child(_make_label("Blacksmith's Wares", GOLD_BRIGHT, _compass_font, 22))
	var shop_items: Array[Array] = [
		["Iron Sword", "120 G", Color(0.70, 0.70, 0.75)],
		["Steel Shield", "240 G", Color(0.40, 0.60, 0.95)],
		["Healing Potion x5", "50 G", Color(0.45, 0.85, 0.50)],
	]
	for si: Array in shop_items:
		var si_row := HBoxContainer.new()
		si_row.add_theme_constant_override("separation", 8)
		# Item slot
		var si_slot := PanelContainer.new()
		si_slot.custom_minimum_size = Vector2(40, 40)
		var sisb := StyleBoxFlat.new()
		sisb.bg_color = Color(0.08, 0.07, 0.06, 0.85)
		sisb.set_corner_radius_all(4)
		sisb.border_width_bottom = 1
		sisb.border_width_top = 1
		sisb.border_width_left = 1
		sisb.border_width_right = 1
		sisb.border_color = Color(si[2] as Color, 0.40)
		si_slot.add_theme_stylebox_override("panel", sisb)
		si_row.add_child(si_slot)
		var si_name := _make_label(si[0] as String, WARM_WHITE, _awesome_font, 15)
		si_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		si_row.add_child(si_name)
		si_row.add_child(_make_label(si[1] as String, GOLD, _awesome_font, 15))
		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(64, 32)
		_apply_font(buy_btn, _awesome_font, 13)
		buy_btn.add_theme_color_override("font_color", GOLD)
		var bsb := _flat(Color(GOLD, 0.08), 4)
		bsb.border_width_bottom = 1
		bsb.border_color = Color(GOLD, 0.35)
		buy_btn.add_theme_stylebox_override("normal", bsb)
		buy_btn.add_theme_stylebox_override("hover", bsb)
		buy_btn.add_theme_stylebox_override("pressed", bsb)
		si_row.add_child(buy_btn)
		sh_vb.add_child(si_row)
	shop.add_child(sh_vb)
	page.add_child(shop)

	# --- Mockup F: Dialogue Panel ---
	page.add_child(_section_label("Mockup F: Dialogue Panel"))
	var dlg_panel := PanelContainer.new()
	var dp_sb := _flat(Color(0.05, 0.045, 0.04, 0.95), 0)
	dp_sb.border_width_top = 3
	dp_sb.border_color = Color(0.50, 0.75, 1.0, 0.50)
	dp_sb.content_margin_left = 20.0
	dp_sb.content_margin_right = 20.0
	dp_sb.content_margin_top = 16.0
	dp_sb.content_margin_bottom = 16.0
	dlg_panel.add_theme_stylebox_override("panel", dp_sb)
	var dp_vb := VBoxContainer.new()
	dp_vb.add_theme_constant_override("separation", 10)
	# Speaker name
	var dp_name := _make_label("Elder Mirael", Color(0.55, 0.80, 1.0), _compass_font, 22)
	dp_vb.add_child(dp_name)
	# Dialogue text
	var dp_text := Label.new()
	dp_text.text = "The amulet you seek lies deep within the Shadow Caves.\nBut beware — the path is guarded by creatures of the dark."
	dp_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(dp_text, _awesome_font, 16)
	dp_text.add_theme_color_override("font_color", Color(WARM_WHITE, 0.80))
	dp_vb.add_child(dp_text)
	# Choice buttons
	var dp_choices := VBoxContainer.new()
	dp_choices.add_theme_constant_override("separation", 6)
	var choices: Array[String] = ["1. Tell me more about the caves.", "2. I'm ready. Let's go.", "3. Maybe later."]
	for ch: String in choices:
		var ch_btn := Button.new()
		ch_btn.text = ch
		ch_btn.custom_minimum_size = Vector2(0, 40)
		ch_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_font(ch_btn, _awesome_font, 15)
		ch_btn.add_theme_color_override("font_color", GOLD)
		var ch_ns := _flat(Color(GOLD, 0.03), 4)
		ch_ns.border_width_left = 3
		ch_ns.border_color = Color(GOLD, 0.15)
		ch_ns.content_margin_left = 14.0
		ch_btn.add_theme_stylebox_override("normal", ch_ns)
		var ch_hs := ch_ns.duplicate() as StyleBoxFlat
		ch_hs.bg_color = Color(GOLD, 0.08)
		ch_hs.border_color = Color(GOLD, 0.45)
		ch_btn.add_theme_stylebox_override("hover", ch_hs)
		ch_btn.add_theme_stylebox_override("pressed", ch_ns)
		ch_btn.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
		dp_choices.add_child(ch_btn)
	dp_vb.add_child(dp_choices)
	dlg_panel.add_child(dp_vb)
	page.add_child(dlg_panel)

	# --- Mockup G: Party Composition ---
	page.add_child(_section_label("Mockup G: Party Composition"))
	var party := PanelContainer.new()
	var pt_sb := _flat(Color(0.055, 0.05, 0.045, 0.94), 6)
	pt_sb.border_width_top = 2
	pt_sb.border_color = Color(GOLD, 0.30)
	pt_sb.content_margin_left = 16.0
	pt_sb.content_margin_right = 16.0
	pt_sb.content_margin_top = 14.0
	pt_sb.content_margin_bottom = 14.0
	party.add_theme_stylebox_override("panel", pt_sb)
	var pt_vb := VBoxContainer.new()
	pt_vb.add_theme_constant_override("separation", 10)
	pt_vb.add_child(_make_label("Party", GOLD_BRIGHT, _compass_font, 22))
	var party_data: Array[Array] = [
		["Wanderer", "Lv.12", "Swordsman", 0.72, Color(0.78, 0.22, 0.18)],
		["Kira", "Lv.10", "Scout", 0.90, Color(0.45, 0.85, 0.50)],
		["Thorn", "Lv.11", "Mage", 0.55, Color(0.30, 0.50, 0.90)],
	]
	for pd: Array in party_data:
		var pr := PanelContainer.new()
		var prsb := _flat(Color(0.07, 0.065, 0.06, 0.80), 4)
		prsb.content_margin_left = 10.0
		prsb.content_margin_right = 10.0
		prsb.content_margin_top = 8.0
		prsb.content_margin_bottom = 8.0
		pr.add_theme_stylebox_override("panel", prsb)
		var pr_hb := HBoxContainer.new()
		pr_hb.add_theme_constant_override("separation", 10)
		# Avatar circle
		var av := PanelContainer.new()
		av.custom_minimum_size = Vector2(40, 40)
		var avsb := StyleBoxFlat.new()
		avsb.bg_color = Color(pd[4] as Color, 0.12)
		avsb.set_corner_radius_all(20)
		avsb.border_width_bottom = 2
		avsb.border_width_top = 2
		avsb.border_width_left = 2
		avsb.border_width_right = 2
		avsb.border_color = Color(pd[4] as Color, 0.40)
		av.add_theme_stylebox_override("panel", avsb)
		var av_l := Label.new()
		av_l.text = (pd[0] as String).left(1)
		av_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		av_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(av_l, _compass_font, 16)
		av_l.add_theme_color_override("font_color", pd[4] as Color)
		av.add_child(av_l)
		pr_hb.add_child(av)
		# Info
		var pr_info := VBoxContainer.new()
		pr_info.add_theme_constant_override("separation", 2)
		pr_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pr_top := HBoxContainer.new()
		pr_top.add_child(_make_label(pd[0] as String, WARM_WHITE, _awesome_font, 15))
		var pr_lv := _make_label(pd[1] as String, DIM, _awesome_font, 12)
		pr_lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pr_lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pr_top.add_child(pr_lv)
		pr_info.add_child(pr_top)
		pr_info.add_child(_make_label(pd[2] as String, Color(pd[4] as Color, 0.65), _awesome_font, 12))
		# HP bar
		var hp_track := PanelContainer.new()
		hp_track.custom_minimum_size = Vector2(0, 10)
		var htsb := _flat(Color(0.06, 0.05, 0.04), 2)
		htsb.content_margin_left = 0.0
		htsb.content_margin_right = 0.0
		htsb.content_margin_top = 0.0
		htsb.content_margin_bottom = 0.0
		hp_track.add_theme_stylebox_override("panel", htsb)
		var hp_fill := ColorRect.new()
		hp_fill.custom_minimum_size = Vector2(180.0 * (pd[3] as float), 0)
		hp_fill.color = pd[4] as Color
		hp_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		hp_track.add_child(hp_fill)
		pr_info.add_child(hp_track)
		pr_hb.add_child(pr_info)
		pr.add_child(pr_hb)
		pt_vb.add_child(pr)
	party.add_child(pt_vb)
	page.add_child(party)

	return page


# ════════════════════════════════════════════════════════════
#  PAGE 11: TYPOGRAPHY
# ════════════════════════════════════════════════════════════

func _build_typography_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)

	page.add_child(_section_label("Compass 9 Font — Title / Display"))
	for size: int in [16, 20, 24, 28, 32, 40]:
		page.add_child(_make_label("Compass 9 at %dpx — The quick brown fox" % size, PARCHMENT, _compass_font, size))

	_add_spacer(page, 24)

	page.add_child(_section_label("Awesome 9 Font — Body / UI"))
	for size: int in [14, 18, 22, 26, 30, 36]:
		page.add_child(_make_label("Awesome 9 at %dpx — The quick brown fox" % size, WARM_WHITE, _awesome_font, size))

	_add_spacer(page, 24)

	page.add_child(_section_label("Color Samples"))
	var color_samples: Array[Array] = [
		["Gold", GOLD], ["Gold Bright", GOLD_BRIGHT], ["Parchment", PARCHMENT],
		["Warm White", WARM_WHITE], ["Dim", DIM],
		["HP Red", Color(0.78, 0.14, 0.14)], ["Energy Blue", Color(0.18, 0.42, 0.82)],
		["Status Green", Color(0.40, 0.95, 0.55)], ["Danger Red", Color(1.0, 0.48, 0.42)],
		["Section Blue", Color(0.50, 0.75, 1.0)],
	]
	for sample: Array in color_samples:
		page.add_child(_make_label("## %s" % sample[0], sample[1] as Color, _compass_font, 22))

	_add_spacer(page, 24)

	# Font pairing comparison
	page.add_child(_section_label("Font Pairing — Title + Body"))
	var pair1 := VBoxContainer.new()
	pair1.add_theme_constant_override("separation", 4)
	pair1.add_child(_make_label("Quest: The Lost Amulet", GOLD_BRIGHT, _compass_font, 26))
	pair1.add_child(_make_label("Journey deep into the Shadow Caves to recover the ancient relic.", Color(WARM_WHITE, 0.70), _awesome_font, 16))
	page.add_child(pair1)
	var pair2 := VBoxContainer.new()
	pair2.add_theme_constant_override("separation", 4)
	pair2.add_child(_make_label("Inventory — Iron Equipment Set", GOLD, _compass_font, 22))
	pair2.add_child(_make_label("Iron Sword / Iron Shield / Iron Helm — Total DEF: +31", Color(0.70, 0.70, 0.75), _awesome_font, 15))
	page.add_child(pair2)

	_add_spacer(page, 24)

	# Text on colored backgrounds
	page.add_child(_section_label("Text on Panel Backgrounds"))
	var bg_samples: Array[Array] = [
		[Color(0.06, 0.06, 0.09, 0.92), "Dark Navy", GOLD_BRIGHT],
		[Color(0.10, 0.065, 0.04, 0.90), "Warm Brown", PARCHMENT],
		[Color(0.04, 0.04, 0.04, 0.96), "Near Black", WARM_WHITE],
		[Color(0.15, 0.14, 0.12, 0.80), "Medium Grey", GOLD],
	]
	for bg: Array in bg_samples:
		var samp := PanelContainer.new()
		var ssb := _flat(bg[0] as Color, 6)
		ssb.content_margin_left = 16.0
		ssb.content_margin_right = 16.0
		ssb.content_margin_top = 8.0
		ssb.content_margin_bottom = 8.0
		samp.add_theme_stylebox_override("panel", ssb)
		var svb := HBoxContainer.new()
		svb.add_theme_constant_override("separation", 16)
		svb.add_child(_make_label("Bg: %s" % (bg[1] as String), DIM, _awesome_font, 13))
		svb.add_child(_make_label("Title Text Sample", bg[2] as Color, _compass_font, 20))
		svb.add_child(_make_label("Body text at normal reading size", Color(bg[2] as Color, 0.70), _awesome_font, 15))
		samp.add_child(svb)
		page.add_child(samp)

	_add_spacer(page, 24)

	# Heading hierarchy
	page.add_child(_section_label("Heading Hierarchy"))
	var headings: Array[Array] = [
		["H1 — Screen Title", _compass_font, 36, GOLD_BRIGHT],
		["H2 — Section Header", _compass_font, 26, GOLD],
		["H3 — Subsection", _compass_font, 22, Color(GOLD, 0.80)],
		["H4 — Card Title", _awesome_font, 18, WARM_WHITE],
		["H5 — Label / Caption", _awesome_font, 15, Color(WARM_WHITE, 0.70)],
		["H6 — Fine Print", _awesome_font, 12, DIM],
	]
	for h: Array in headings:
		page.add_child(_make_label(h[0] as String, h[3] as Color, h[1] as Font, h[2] as int))

	_add_spacer(page, 24)

	# Number/stat display styles
	page.add_child(_section_label("Number / Stat Displays"))
	var num_row := _hbox(20)
	var num_data: Array[Array] = [
		["1,247", "Gold", GOLD],
		["42", "Level", Color(0.50, 0.75, 1.0)],
		["+15", "ATK", Color(0.85, 0.35, 0.30)],
		["88%", "Crit", Color(0.70, 0.50, 0.90)],
	]
	for nd: Array in num_data:
		var nv := VBoxContainer.new()
		nv.add_theme_constant_override("separation", 2)
		var n_val := _make_label(nd[0] as String, nd[2] as Color, _compass_font, 32)
		n_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nv.add_child(n_val)
		var n_cap := _make_label(nd[1] as String, Color(nd[2] as Color, 0.50), _awesome_font, 12)
		n_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nv.add_child(n_cap)
		num_row.add_child(nv)
	page.add_child(num_row)

	_add_spacer(page, 24)

	# Long paragraph readability
	page.add_child(_section_label("Paragraph Readability"))
	var para := Label.new()
	para.text = "The ancient ruins stretch before you, their crumbling walls covered in moss and forgotten runes. A faint glow emanates from deep within, promising both treasure and danger. Your companion draws their weapon, ready for whatever lies ahead."
	para.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(para, _awesome_font, 16)
	para.add_theme_color_override("font_color", Color(WARM_WHITE, 0.75))
	page.add_child(para)
	var para2 := Label.new()
	para2.text = "Same text in Compass 9 at 18px for comparison. The ancient ruins stretch before you, their crumbling walls covered in moss and forgotten runes."
	para2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(para2, _compass_font, 18)
	para2.add_theme_color_override("font_color", Color(PARCHMENT, 0.75))
	page.add_child(para2)

	return page


# ─── COMPONENT BUILDERS ─────────────────────────────────────

func _build_quest_card(title: String, desc: String, status: String, status_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var s := _flat(Color(0.06, 0.07, 0.10, 0.75), 6)
	s.border_width_left = 4
	s.border_color = status_color
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 12.0
	s.content_margin_bottom = 12.0
	card.add_theme_stylebox_override("panel", s)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(_make_label(title, GOLD_BRIGHT, _compass_font, 22))
	var status_lbl := _make_label("[%s]" % status, status_color, _awesome_font, 16)
	status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(status_lbl)
	vbox.add_child(top)

	vbox.add_child(_make_label(desc, Color(WARM_WHITE, 0.7), _awesome_font, 16))
	return card


func _build_creature_card(creature_name: String, rarity: String, stats: String, rarity_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var s := _flat(Color(0.08, 0.08, 0.11, 0.80), 8)
	s.border_width_bottom = 2
	s.border_color = rarity_color
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 12.0
	s.content_margin_bottom = 12.0
	s.shadow_color = Color(0, 0, 0, 0.20)
	s.shadow_size = 8
	card.add_theme_stylebox_override("panel", s)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var top := HBoxContainer.new()
	top.add_child(_make_label(creature_name, WARM_WHITE, _compass_font, 22))
	var rarity_lbl := _make_label(rarity, rarity_color, _awesome_font, 16)
	rarity_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(rarity_lbl)
	vbox.add_child(top)

	vbox.add_child(_make_label(stats, DIM, _awesome_font, 16))
	return card


func _build_item_card(item_name: String, desc: String, stat: String, rarity: String, rarity_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var s := _flat(Color(0.07, 0.07, 0.10, 0.85), 10)
	s.border_width_bottom = 2
	s.border_width_top = 1
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_color = Color(rarity_color, 0.40)
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 14.0
	s.content_margin_bottom = 14.0
	card.add_theme_stylebox_override("panel", s)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var top := HBoxContainer.new()
	top.add_child(_make_label(item_name, GOLD_BRIGHT, _compass_font, 22))
	var rarity_lbl := _make_label(rarity, rarity_color, _awesome_font, 14)
	rarity_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(rarity_lbl)
	vbox.add_child(top)

	vbox.add_child(_make_label(desc, Color(WARM_WHITE, 0.7), _awesome_font, 16))

	var stat_lbl := _make_label(stat, Color(0.40, 0.95, 0.55), _awesome_font, 18)
	vbox.add_child(stat_lbl)
	return card


# ─── PRIMITIVE HELPERS ──────────────────────────────────────

func _make_label(text: String, color: Color, font: Font, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", size)
	return lbl


func _apply_font(control: Control, font: Font, size: int) -> void:
	if font:
		control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)


func _flat(bg: Color, corner: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.content_margin_left = 12.0
	s.content_margin_right = 12.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	return s


func _apply_flat_btn_style(btn: Button, bg: Color, border: Color, corner: int) -> void:
	var ns := _flat(bg, corner)
	ns.border_width_bottom = 1
	ns.border_width_top = 1
	ns.border_width_left = 1
	ns.border_width_right = 1
	ns.border_color = border
	btn.add_theme_stylebox_override("normal", ns)
	var hs := ns.duplicate() as StyleBoxFlat
	hs.bg_color = Color(bg.r + 0.08, bg.g + 0.08, bg.b + 0.08, min(bg.a + 0.15, 1.0))
	hs.border_color = Color(border.r, border.g, border.b, min(border.a + 0.3, 1.0))
	btn.add_theme_stylebox_override("hover", hs)
	btn.add_theme_stylebox_override("pressed", ns)


func _demo_flat_panel(fill: Color, border: Color, border_w: int, corner: int, title: String, desc: String) -> PanelContainer:
	var s := _flat(fill, corner)
	s.border_width_bottom = border_w
	s.border_width_top = border_w
	s.border_width_left = border_w
	s.border_width_right = border_w
	s.border_color = border
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 14.0
	s.content_margin_bottom = 14.0
	return _demo_panel_from_style(s, title, desc)


func _demo_panel_from_style(style: StyleBoxFlat, title: String, desc: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.y = 80

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	vbox.add_child(_make_label(title, GOLD_BRIGHT, _compass_font, 20))
	vbox.add_child(_make_label(desc, Color(WARM_WHITE, 0.65), _awesome_font, 16))
	return panel


func _section_label(text: String) -> Label:
	return _make_label(text, Color(0.50, 0.75, 1.0, 0.80), _awesome_font, 18)


func _hbox(separation: int) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", separation)
	return hb


func _wrap_flow(separation: int) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", separation)
	flow.add_theme_constant_override("v_separation", separation)
	return flow


func _add_spacer(parent: Control, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)
