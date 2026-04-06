class_name DebugPanel
extends CanvasLayer

## Full-screen debug control panel toggled with F3 (debug builds only).
## Provides buttons/toggles for common debug actions: overlay, skin/profile reset,
## game state changes, teleport, speed, etc.

# --- Palette ---
const BG_COLOR := Color(0.07, 0.07, 0.09, 0.97)
const PANEL_BORDER := Color(0.40, 0.35, 0.25, 0.45)
const HEADER_COLOR := Color(1.0, 0.92, 0.68)
const HEADER_GLOW := Color(1.0, 0.92, 0.68, 0.06)
const LABEL_COLOR := Color(0.94, 0.92, 0.86)
const DIM_COLOR := Color(0.55, 0.52, 0.45)
const SECTION_COLOR := Color(0.50, 0.75, 1.0)
const SECTION_BG := Color(0.08, 0.10, 0.14, 0.55)
const SECTION_ACCENT := Color(0.50, 0.75, 1.0, 0.55)
const STATUS_OK := Color(0.40, 0.95, 0.55)
const STATUS_BG := Color(0.40, 0.95, 0.55, 0.06)
const BTN_BG := Color(0.11, 0.11, 0.14, 0.80)
const BTN_BOTTOM := Color(0.65, 0.55, 0.38, 0.55)
const BTN_HOVER_BG := Color(0.15, 0.15, 0.19, 0.90)
const BTN_HOVER_BORDER := Color(1.0, 0.92, 0.68, 0.65)
const BTN_PRESSED_BG := Color(0.18, 0.17, 0.14, 0.90)
const COMPACT_BTN_BG := Color(0.09, 0.09, 0.12, 0.70)
const COMPACT_BTN_BORDER := Color(0.30, 0.28, 0.24, 0.28)
const COMPACT_BTN_HOVER := Color(0.14, 0.14, 0.17, 0.80)
const DANGER_BG := Color(0.18, 0.05, 0.05, 0.70)
const DANGER_BORDER := Color(0.85, 0.20, 0.15, 0.45)
const DANGER_BOTTOM := Color(0.85, 0.20, 0.15, 0.60)
const DANGER_HOVER_BG := Color(0.25, 0.08, 0.08, 0.85)
const DANGER_HOVER_BORDER := Color(1.0, 0.30, 0.25, 0.75)
const DANGER_TEXT := Color(1.0, 0.48, 0.42)
const SEP_COLOR := Color(0.4, 0.36, 0.30, 0.12)

var _panel: PanelContainer
var _bg: ColorRect
var _debug_overlay: DebugOverlay = null
var _status_label: Label
var _game_state_label: Label
var _setup_status_label: Label
var _speed_label: Label
var _font: Font
var _toggle_btn: Button
var _collision_btn: Button
var _paths_btn: Button
var _navigation_btn: Button


func _ready() -> void:
	layer = 105
	if not OS.is_debug_build():
		queue_free()
		return
	_font = load("res://Assets/Fonts/awesome/Awesome 9.ttf") as Font
	_build_ui()
	_build_toggle_button()
	_panel.hide()
	_bg.hide()
	add_to_group(&"ui_panels_block_movement")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_F3:
			_toggle_panel()
			get_viewport().set_input_as_handled()


func set_debug_overlay(overlay: DebugOverlay) -> void:
	_debug_overlay = overlay


func _toggle_panel() -> void:
	var opening := not _panel.visible
	_panel.visible = opening
	_bg.visible = opening
	if _toggle_btn:
		_toggle_btn.visible = not opening
	if opening:
		_refresh_status()


func is_open() -> bool:
	return _panel != null and _panel.visible


func _build_toggle_button() -> void:
	if not ProjectConfig.is_mobile_runtime():
		return
	_toggle_btn = Button.new()
	_toggle_btn.text = "DBG"
	_toggle_btn.custom_minimum_size = Vector2(72, 72)
	_toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_font(_toggle_btn, 16)
	_toggle_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 0.6))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.09, 0.55)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_color = Color(1.0, 0.92, 0.68, 0.25)
	_toggle_btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.12, 0.15, 0.75)
	hover.border_color = Color(1.0, 0.92, 0.68, 0.55)
	_toggle_btn.add_theme_stylebox_override("hover", hover)
	_toggle_btn.add_theme_stylebox_override("pressed", hover)
	# Safe area offset for mobile (system nav bar / gesture zone)
	var screen_size := DisplayServer.screen_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	var safe_bottom: float = maxf(screen_size.y - safe_area.end.y, 30.0)
	var safe_right: float = maxf(screen_size.x - safe_area.end.x, 10.0)
	_toggle_btn.anchor_left = 1.0
	_toggle_btn.anchor_right = 1.0
	_toggle_btn.anchor_top = 1.0
	_toggle_btn.anchor_bottom = 1.0
	_toggle_btn.offset_left = -(72.0 + safe_right)
	_toggle_btn.offset_right = -safe_right
	_toggle_btn.offset_top = -(72.0 + safe_bottom)
	_toggle_btn.offset_bottom = -safe_bottom
	_toggle_btn.pressed.connect(_toggle_panel)
	add_child(_toggle_btn)


func _refresh_status() -> void:
	if _game_state_label:
		_game_state_label.text = "Game State: %s" % GameManager.GameState.keys()[GameManager.current_state]
	if _setup_status_label:
		_setup_status_label.text = "Setup Completed: %s" % str(PlayerProfileService.has_completed_setup())
	if _speed_label:
		var player: Node = _find_player()
		if player:
			_speed_label.text = "Speed: %.0f" % player.movement_speed
		else:
			_speed_label.text = "Speed: (no player)"
	_sync_render_debug_buttons()


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


# --- Actions ---

func _on_toggle_debug_overlay() -> void:
	if _debug_overlay:
		_debug_overlay.enabled = not _debug_overlay.enabled
		_debug_overlay.visible = _debug_overlay.enabled
		_set_status("Debug overlay: %s" % ("ON" if _debug_overlay.enabled else "OFF"))
	else:
		_set_status("Debug overlay not found")


func _on_toggle_collision_shapes() -> void:
	get_tree().debug_collisions_hint = not get_tree().debug_collisions_hint
	_sync_render_debug_buttons()
	_set_status("Collision shapes: %s" % ("ON" if get_tree().debug_collisions_hint else "OFF"))


func _on_toggle_nav_paths() -> void:
	get_tree().debug_paths_hint = not get_tree().debug_paths_hint
	_sync_render_debug_buttons()
	_set_status("Nav paths: %s" % ("ON" if get_tree().debug_paths_hint else "OFF"))


func _on_toggle_navigation() -> void:
	get_tree().debug_navigation_hint = not get_tree().debug_navigation_hint
	_sync_render_debug_buttons()
	_set_status("Navigation: %s" % ("ON" if get_tree().debug_navigation_hint else "OFF"))


func _sync_render_debug_buttons() -> void:
	if _collision_btn:
		_collision_btn.text = "Collision Shapes  %s" % ("[ON]" if get_tree().debug_collisions_hint else "[OFF]")
	if _paths_btn:
		_paths_btn.text = "Nav Paths  %s" % ("[ON]" if get_tree().debug_paths_hint else "[OFF]")
	if _navigation_btn:
		_navigation_btn.text = "Navigation  %s" % ("[ON]" if get_tree().debug_navigation_hint else "[OFF]")


func _on_reset_appearance() -> void:
	PlayerProfileService.reset_profile()
	_set_status("Profile reset — skin selection and setup state will reload on next spawn")
	_refresh_status()


func _on_force_creator() -> void:
	PlayerProfileService.mark_setup_completed(false)
	_set_status("Setup flag cleared — creator will show on next spawn")
	_refresh_status()


func _on_mark_setup_done() -> void:
	PlayerProfileService.mark_setup_completed(true)
	_set_status("Setup marked complete — creator will be skipped")
	_refresh_status()


func _on_change_game_state(state: GameManager.GameState) -> void:
	var old_enforce: bool = GameManager.enforce_transition_map
	GameManager.enforce_transition_map = false
	GameManager.change_state(state)
	GameManager.enforce_transition_map = old_enforce
	_set_status("State → %s" % GameManager.GameState.keys()[state])
	_refresh_status()


func _on_set_speed(speed: float) -> void:
	var player: Node = _find_player()
	if player:
		player.movement_speed = speed
		_set_status("Speed → %.0f" % speed)
	else:
		_set_status("No player found")
	_refresh_status()


func _on_heal_player() -> void:
	var player: Node = _find_player()
	if player and "current_health" in player and "max_health" in player:
		player.current_health = player.max_health
		_set_status("Player healed to %.0f HP" % player.max_health)
	else:
		_set_status("No player found")


func _on_add_xp(amount: int) -> void:
	PlayerProgressionService.award_xp(amount)
	_set_status("Added %d XP (Level %d, XP %d)" % [amount, PlayerProfileService.get_player_level(), PlayerProfileService.get_player_xp()])


func _on_set_level(target_level: int) -> void:
	var max_level: int = int(PlayerProgressionService._config.max_level) \
		if PlayerProgressionService._config != null else 100
	target_level = clampi(target_level, 1, max_level)
	PlayerProfileService.set_xp_and_level(0, target_level)
	var stats := PlayerProgressionService.calculate_stats(target_level)
	PlayerProgressionService.level_up.emit(target_level, stats)
	PlayerProgressionService.xp_gained.emit(0, 0, PlayerProgressionService.xp_needed_for_level(target_level))
	_set_status("Level forced → %d" % target_level)
	_refresh_status()


func _on_teleport_origin() -> void:
	var player := _find_player() as Node2D
	if player:
		player.global_position = Vector2.ZERO
		_set_status("Teleported to origin")
	else:
		_set_status("No player found")


func _on_reload_scene() -> void:
	get_tree().reload_current_scene()


func _on_toggle_music() -> void:
	var music: Node = Engine.get_singleton("MusicPlayer") if Engine.has_singleton("MusicPlayer") else get_node_or_null("/root/MusicPlayer")
	if music and music.has_method("stop_music"):
		music.stop_music()
		_set_status("Music stopped")
	else:
		_set_status("MusicPlayer not found")


func _on_print_tree() -> void:
	get_tree().root.print_tree_pretty()
	_set_status("Scene tree printed to console")


func _on_open_ui_showcase() -> void:
	var ShowcaseScript: GDScript = load("res://src/ui/common/debug/ui_showcase.gd")
	var showcase: CanvasLayer = ShowcaseScript.new()
	get_tree().root.add_child(showcase)
	_on_close()
	_set_status("UI Showcase opened")


func _on_close() -> void:
	_panel.hide()
	_bg.hide()
	if _toggle_btn:
		_toggle_btn.show()


# --- Helpers ---

func _find_player() -> Node:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null


# --- UI Construction ---

func _build_ui() -> void:
	# Dim background — click to close and block all input from reaching the game
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.55)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.gui_input.connect(func(event: InputEvent) -> void:
		get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.pressed and not (event as InputEventMouseButton).double_click:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_on_close()
	)
	add_child(_bg)

	# Main panel — centered, narrower for a cleaner look
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.18
	_panel.anchor_right = 0.82
	_panel.anchor_top = 0.04
	_panel.anchor_bottom = 0.96
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0
	var panel_style := _make_style(BG_COLOR, PANEL_BORDER, 1, 16)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.50)
	panel_style.shadow_size = 36
	panel_style.shadow_offset = Vector2(0, 8)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(func(_event: InputEvent) -> void:
		get_viewport().set_input_as_handled()
	)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 0)
	margin.add_child(outer_vbox)

	# ── Header ──
	var header_bar := _make_header_bar()
	outer_vbox.add_child(header_bar)

	# ── Status bar ──
	var status_container := PanelContainer.new()
	var status_bar_style := _make_style(STATUS_BG, Color.TRANSPARENT, 0, 6)
	status_bar_style.border_width_left = 3
	status_bar_style.border_color = STATUS_OK
	status_container.add_theme_stylebox_override("panel", status_bar_style)
	outer_vbox.add_child(status_container)
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 10)
	status_margin.add_theme_constant_override("margin_right", 10)
	status_margin.add_theme_constant_override("margin_top", 5)
	status_margin.add_theme_constant_override("margin_bottom", 5)
	status_container.add_child(status_margin)
	_status_label = _make_label("Ready", STATUS_OK, 20)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_margin.add_child(_status_label)

	_add_spacer(outer_vbox, 12)

	# ── Scrollable content ──
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	outer_vbox.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	# ── INFO section ──
	var info_content := VBoxContainer.new()
	info_content.add_theme_constant_override("separation", 3)
	_game_state_label = _make_info_label("Game State", "—")
	info_content.add_child(_game_state_label)
	_setup_status_label = _make_info_label("Setup Completed", "—")
	info_content.add_child(_setup_status_label)
	_speed_label = _make_info_label("Speed", "—")
	info_content.add_child(_speed_label)
	vbox.add_child(_make_section_card("INFO", info_content))

	# ── DISPLAY section ──
	var display_content := VBoxContainer.new()
	display_content.add_theme_constant_override("separation", 4)
	display_content.add_child(_make_btn("Toggle Debug Overlay", _on_toggle_debug_overlay))
	_collision_btn = _make_btn("Collision Shapes  [OFF]", _on_toggle_collision_shapes)
	display_content.add_child(_collision_btn)
	_paths_btn = _make_btn("Nav Paths  [OFF]", _on_toggle_nav_paths)
	display_content.add_child(_paths_btn)
	_navigation_btn = _make_btn("Navigation  [OFF]", _on_toggle_navigation)
	display_content.add_child(_navigation_btn)
	display_content.add_child(_make_btn("Print Scene Tree", _on_print_tree))
	display_content.add_child(_make_btn("UI Showcase", _on_open_ui_showcase))
	vbox.add_child(_make_section_card("DISPLAY", display_content))

	# ── CHARACTER & PROFILE section ──
	var profile_content := VBoxContainer.new()
	profile_content.add_theme_constant_override("separation", 4)
	profile_content.add_child(_make_btn("Reset Entire Profile", _on_reset_appearance, true))
	profile_content.add_child(_make_btn("Clear Setup Flag (Force Creator)", _on_force_creator))
	profile_content.add_child(_make_btn("Mark Setup Complete (Skip Creator)", _on_mark_setup_done))
	profile_content.add_child(_make_btn("Heal Player to Full", _on_heal_player))
	vbox.add_child(_make_section_card("CHARACTER & PROFILE", profile_content))

	# ── XP & LEVEL section ──
	var xp_content := VBoxContainer.new()
	xp_content.add_theme_constant_override("separation", 4)
	var xp_row := _make_button_grid([
		["+10 XP", _on_add_xp.bind(10)],
		["+50 XP", _on_add_xp.bind(50)],
		["+100 XP", _on_add_xp.bind(100)],
		["+500 XP", _on_add_xp.bind(500)],
	], 4)
	xp_content.add_child(xp_row)
	var lvl_preset_row := _make_button_grid([
		["Lv 1",  _on_set_level.bind(1)],
		["Lv 10", _on_set_level.bind(10)],
		["Lv 25", _on_set_level.bind(25)],
		["Lv 50", _on_set_level.bind(50)],
		["Lv 75", _on_set_level.bind(75)],
		["Lv 100", _on_set_level.bind(100)],
	], 6)
	xp_content.add_child(lvl_preset_row)
	xp_content.add_child(_make_set_level_input_row())
	vbox.add_child(_make_section_card("XP & LEVEL", xp_content))

	# ── MOVEMENT SPEED section ──
	var speed_content := VBoxContainer.new()
	speed_content.add_theme_constant_override("separation", 4)
	var speed_row := _make_button_grid([
		["50", _on_set_speed.bind(50.0)],
		["100", _on_set_speed.bind(100.0)],
		["200", _on_set_speed.bind(200.0)],
		["500", _on_set_speed.bind(500.0)],
		["1000", _on_set_speed.bind(1000.0)],
	], 5)
	speed_content.add_child(speed_row)
	vbox.add_child(_make_section_card("MOVEMENT SPEED", speed_content))

	# ── GAME STATE section ──
	var state_content := VBoxContainer.new()
	state_content.add_theme_constant_override("separation", 4)
	var state_items: Array = []
	for state_name: String in GameManager.GameState.keys():
		var state_val: int = GameManager.GameState[state_name]
		state_items.append([state_name, _on_change_game_state.bind(state_val)])
	state_content.add_child(_make_button_grid(state_items, 3))
	vbox.add_child(_make_section_card("GAME STATE", state_content))

	# ── WORLD section ──
	var world_content := VBoxContainer.new()
	world_content.add_theme_constant_override("separation", 4)
	world_content.add_child(_make_btn("Teleport to Origin", _on_teleport_origin))
	world_content.add_child(_make_btn("Stop Music", _on_toggle_music))
	world_content.add_child(_make_btn("Reload Scene", _on_reload_scene, true))
	vbox.add_child(_make_section_card("WORLD", world_content))

	_add_spacer(vbox, 4)

	# ── Close button ──
	var close_btn := Button.new()
	close_btn.text = "CLOSE  [F3]"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.custom_minimum_size.y = 50
	_apply_font(close_btn, 22)
	close_btn.add_theme_color_override("font_color", HEADER_COLOR)
	close_btn.add_theme_stylebox_override("normal", _make_style(Color(1.0, 0.92, 0.68, 0.06), Color(1.0, 0.92, 0.68, 0.35), 2, 10))
	close_btn.add_theme_stylebox_override("hover", _make_style(Color(1.0, 0.92, 0.68, 0.14), Color(1.0, 0.92, 0.68, 0.65), 2, 10))
	close_btn.add_theme_stylebox_override("pressed", _make_style(BTN_PRESSED_BG, BTN_HOVER_BORDER, 2, 10))
	close_btn.pressed.connect(_on_close)
	vbox.add_child(close_btn)


# --- Component Builders ---

func _make_header_bar() -> PanelContainer:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)

	var icon_lbl := _make_label(">>", Color(1.0, 0.92, 0.68, 0.35), 18)
	hbox.add_child(icon_lbl)

	var title := _make_label("DEBUG PANEL", HEADER_COLOR, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(title)

	var badge := _make_label("[F3]", DIM_COLOR, 16)
	hbox.add_child(badge)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(hbox)

	var outer := PanelContainer.new()
	var header_style := _make_style(HEADER_GLOW, Color.TRANSPARENT, 0, 10)
	header_style.border_width_bottom = 1
	header_style.border_color = PANEL_BORDER
	outer.add_theme_stylebox_override("panel", header_style)
	outer.add_child(margin)
	return outer


func _make_section_card(title_text: String, content: Control) -> PanelContainer:
	var card := PanelContainer.new()
	var card_style := _make_style(SECTION_BG, Color.TRANSPARENT, 0, 6)
	card_style.border_width_left = 3
	card_style.border_color = SECTION_ACCENT
	card.add_theme_stylebox_override("panel", card_style)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_right", 16)
	card_margin.add_theme_constant_override("margin_top", 14)
	card_margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(card_margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	card_margin.add_child(inner)

	# Section title with decorative line
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	inner.add_child(title_row)

	var dot := _make_label(">", Color(0.50, 0.75, 1.0, 0.5), 16)
	title_row.add_child(dot)
	var title_lbl := _make_label(title_text, SECTION_COLOR, 18)
	title_row.add_child(title_lbl)

	# Decorative line fill
	var line := HSeparator.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_style := StyleBoxFlat.new()
	line_style.bg_color = Color(0.50, 0.75, 1.0, 0.12)
	line.add_theme_stylebox_override("separator", line_style)
	title_row.add_child(line)

	inner.add_child(content)
	return card


func _make_button_grid(items: Array, columns: int) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	var current_row: HBoxContainer = null
	for i: int in items.size():
		if i % columns == 0:
			current_row = HBoxContainer.new()
			current_row.add_theme_constant_override("separation", 4)
			container.add_child(current_row)
		var item: Array = items[i]
		var btn := _make_compact_btn(item[0] as String, item[1] as Callable)
		current_row.add_child(btn)
	return container


func _make_set_level_input_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var input := LineEdit.new()
	input.placeholder_text = "Level (1-100)"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size.y = 38
	_apply_font(input, 16)
	input.add_theme_color_override("font_color", LABEL_COLOR)
	input.add_theme_color_override("font_placeholder_color", DIM_COLOR)
	input.add_theme_stylebox_override("normal", _make_style(COMPACT_BTN_BG, COMPACT_BTN_BORDER, 1, 8))
	input.add_theme_stylebox_override("focus", _make_style(COMPACT_BTN_BG, BTN_HOVER_BORDER, 1, 8))

	var btn := _make_compact_btn("Set", func() -> void:
		var val: int = int(input.text.strip_edges())
		if val > 0:
			_on_set_level(val)
			input.text = ""
		else:
			_set_status("Enter a valid level number")
	)
	btn.custom_minimum_size.x = 60

	row.add_child(input)
	row.add_child(btn)
	return row


func _make_info_label(key: String, value: String) -> Label:
	var lbl := _make_label("%s:  %s" % [key, value], LABEL_COLOR, 18)
	return lbl


func _add_spacer(parent: Control, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)


# --- Style Helpers ---

func _apply_font(control: Control, size: int) -> void:
	if _font:
		control.add_theme_font_override("font", _font)
	control.add_theme_font_size_override("font_size", size)


func _make_label(text: String, color: Color, size: int = 12) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	_apply_font(lbl, size)
	return lbl


func _make_btn(text: String, callback: Callable, danger: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 44
	_apply_font(btn, 18)
	btn.add_theme_color_override("font_color", LABEL_COLOR if not danger else DANGER_TEXT)
	# Normal: colored bottom edge gives a raised-tab feel
	var normal_style := _make_style(DANGER_BG if danger else BTN_BG, Color.TRANSPARENT, 0, 8)
	normal_style.border_width_bottom = 2
	normal_style.border_color = DANGER_BOTTOM if danger else BTN_BOTTOM
	btn.add_theme_stylebox_override("normal", normal_style)
	# Hover: full border glow
	btn.add_theme_stylebox_override("hover", _make_style(
		DANGER_HOVER_BG if danger else BTN_HOVER_BG,
		DANGER_HOVER_BORDER if danger else BTN_HOVER_BORDER, 1, 8))
	# Pressed: inverted depth — top edge, no bottom
	var pressed_style := _make_style(BTN_PRESSED_BG, BTN_HOVER_BORDER, 0, 8)
	pressed_style.border_width_top = 2
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.pressed.connect(callback)
	return btn


func _make_compact_btn(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 38)
	_apply_font(btn, 16)
	btn.add_theme_color_override("font_color", LABEL_COLOR)
	btn.add_theme_stylebox_override("normal", _make_style(COMPACT_BTN_BG, COMPACT_BTN_BORDER, 1, 14))
	btn.add_theme_stylebox_override("hover", _make_style(COMPACT_BTN_HOVER, BTN_HOVER_BORDER, 1, 14))
	btn.add_theme_stylebox_override("pressed", _make_style(BTN_PRESSED_BG, BTN_HOVER_BORDER, 1, 14))
	btn.pressed.connect(callback)
	return btn


func _make_style(bg: Color, border: Color, border_width: int = 1, corner_radius: int = 0) -> StyleBoxFlat:
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
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style
