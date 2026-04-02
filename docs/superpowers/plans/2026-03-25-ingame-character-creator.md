# In-Game Character Creator Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the menu-embedded `CharacterCreatorPanel` with an in-world HUD that appears after the player spawns on the first play-through only, lets them preview cosmetics live, and unlocks movement after "Begin Adventure".

**Architecture:** On Play press, `overworld.gd` always hides the menu and starts the session immediately (no gate). `OverworldCharacterCreatorController` listens to `PlayerEvents.player_spawned`; if `has_completed_setup()` is false it locks `PlayerInputComponent`, shows `OverworldCreatorHud`, and waits for `confirmed`. `OverworldCreatorHud` is a self-contained `CanvasLayer` that builds its own UI in `_ready()`, cycles cosmetic slots live via `player.apply_appearance()`, and emits `confirmed(appearance)` on "Begin Adventure". `PlayerProfileService` now persists `setup_completed` to `user://player_profile.cfg` so the flow only runs once.

**Tech Stack:** GDScript 4.6, Godot 4.6 CanvasLayer/Control nodes, ConfigFile persistence, `PlayerEvents` autoload signals.

---

## File Map

| Action   | Path                                                                      | Responsibility                                          |
|----------|---------------------------------------------------------------------------|---------------------------------------------------------|
| Modify   | `src/Core/player_profile_service.gd`                                      | Add `_setup_completed` field + ConfigFile persistence   |
| Rewrite  | `src/World/Overworld/overworld_character_creator_controller.gd`           | New `player_spawned`-based flow; remove all old methods |
| Create   | `src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.gd`        | HUD CanvasLayer — slot controls, live preview, confirm  |
| Modify   | `src/World/Overworld/overworld.gd`                                        | Simplify play-pressed; remove `begin_adventure_pressed` |
| Modify   | `src/Ui/Desktop/Gui/MainScreen/main_screen.gd`                            | Strip all CharacterCreatorPanel wiring                  |
| Delete   | `src/Ui/Desktop/CharacterCreator/character_creator_panel.gd`              | Replaced by OverworldCreatorHud                         |
| Delete   | `src/Ui/Desktop/CharacterCreator/character_creator_panel.tscn`            | Replaced by OverworldCreatorHud                         |

> **No `.tscn` for OverworldCreatorHud.** The HUD creates all child nodes programmatically in `_ready()`. The controller spawns the HUD instance in its own `_ready()`, so no Godot editor scene edit is required.

---

## Chunk 1: Foundation — Profile Persistence + Controller Rewrite

### Task 1: Add `setup_completed` persistence to `player_profile_service.gd`

**Files:**
- Modify: `src/Core/player_profile_service.gd`

Current state (relevant lines):
- Line 8: `const PROFILE_SAVE_PATH: String = "user://player_profile.cfg"`
- Line 44: `func set_appearance(appearance: Resource, _mark_completed: bool = true) -> void:`
- Line 54–56: `func has_completed_setup() -> bool: return false`
- Line 59–60: `func mark_setup_completed(_completed: bool = true) -> void: pass`
- Line 26–29: `func _ready()` calls `_load_locale_preference()` and `_load_combat_profile()`

- [ ] **Step 1.1: Add section/key constants after the existing combat constants (after line 14)**

  In `src/Core/player_profile_service.gd`, add after `KEY_PLAYER_XP` (line 13 — the line reads `const KEY_PLAYER_XP: String = "player_xp"`):
  ```gdscript
  const PROFILE_SECTION: String = "profile"
  const KEY_SETUP_COMPLETED: String = "setup_completed"
  ```

- [ ] **Step 1.2: Add `_setup_completed` field after `_player_xp` (after line 23)**

  ```gdscript
  var _setup_completed: bool = false
  ```

- [ ] **Step 1.3: Call `_load_setup_completed()` in `_ready()` (after `_load_combat_profile()`)**

  Change `_ready()` from:
  ```gdscript
  func _ready() -> void:
  	_appearance = _resolve_default_appearance()
  	_load_locale_preference()
  	_load_combat_profile()
  ```
  To:
  ```gdscript
  func _ready() -> void:
  	_appearance = _resolve_default_appearance()
  	_load_locale_preference()
  	_load_combat_profile()
  	_load_setup_completed()
  ```

- [ ] **Step 1.4: Implement `set_appearance` persistence — rename param and add save call**

  Change line 44:
  ```gdscript
  func set_appearance(appearance: Resource, _mark_completed: bool = true) -> void:
  	if appearance == null:
  		push_warning("PlayerProfileService: cannot save null appearance.")
  		return

  	_appearance = _sanitize_appearance(appearance)
  	# Persistence is intentionally disabled for now.
  	# Keep selected appearance only for the current runtime session.
  ```
  To:
  ```gdscript
  func set_appearance(appearance: Resource, mark_complete: bool = true) -> void:
  	if appearance == null:
  		push_warning("PlayerProfileService: cannot save null appearance.")
  		return

  	_appearance = _sanitize_appearance(appearance)
  	if mark_complete and not _setup_completed:
  		_setup_completed = true
  		_save_setup_completed()
  ```

- [ ] **Step 1.5: Implement `has_completed_setup()` — return field instead of hardcoded false**

  Change lines 54–56:
  ```gdscript
  func has_completed_setup() -> bool:
  	# Force creator flow on every Play for now.
  	return false
  ```
  To:
  ```gdscript
  func has_completed_setup() -> bool:
  	return _setup_completed
  ```

- [ ] **Step 1.6: Implement `mark_setup_completed()` — was a no-op**

  Change lines 59–60:
  ```gdscript
  func mark_setup_completed(_completed: bool = true) -> void:
  	pass
  ```
  To:
  ```gdscript
  func mark_setup_completed(completed: bool = true) -> void:
  	if _setup_completed == completed:
  		return
  	_setup_completed = completed
  	_save_setup_completed()
  ```

- [ ] **Step 1.7: Add `_load_setup_completed()` — follow the same ConfigFile pattern as `_load_combat_profile()`**

  Add after `_load_combat_profile()` (around line 162):
  ```gdscript
  func _load_setup_completed() -> void:
  	var profile_data: ConfigFile = ConfigFile.new()
  	if profile_data.load(PROFILE_SAVE_PATH) != OK:
  		return
  	_setup_completed = bool(profile_data.get_value(PROFILE_SECTION, KEY_SETUP_COMPLETED, false))
  ```

- [ ] **Step 1.8: Add `_save_setup_completed()` — follow the same pattern as `_save_locale_preference()`**

  Add after `_load_setup_completed()`:
  ```gdscript
  func _save_setup_completed() -> void:
  	var profile_data: ConfigFile = ConfigFile.new()
  	profile_data.load(PROFILE_SAVE_PATH)
  	profile_data.set_value(PROFILE_SECTION, KEY_SETUP_COMPLETED, _setup_completed)
  	var save_error: Error = profile_data.save(PROFILE_SAVE_PATH)
  	if save_error != OK and OS.is_debug_build():
  		push_warning("PlayerProfileService: failed to save setup_completed (%d)." % int(save_error))
  ```

- [ ] **Step 1.9: Verify the file has no parse errors**

  Run:
  ```bash
  "C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
  ```
  Expected: exit code 0. (This validates the project parses without errors.)

- [ ] **Step 1.10: Commit**

  ```bash
  git add src/Core/player_profile_service.gd
  git commit -m "feat(profile): persist setup_completed flag to player_profile.cfg"
  ```

---

### Task 2: Rewrite `overworld_character_creator_controller.gd`

**Files:**
- Modify (full rewrite): `src/World/Overworld/overworld_character_creator_controller.gd`

Current state: 93-line file with `open_panel()`, `_on_appearance_confirmed()`, `_on_creation_cancelled()`, `initialize(main_screen, session_controller)`, etc.

- [ ] **Step 2.1: Replace the entire file content**

  Replace `src/World/Overworld/overworld_character_creator_controller.gd` with:

  ```gdscript
  class_name OverworldCharacterCreatorController
  extends Node

  ## Manages the in-game character creator flow.
  ## On first Play: intercepts PlayerEvents.player_spawned, locks movement,
  ## shows OverworldCreatorHud. On "Begin Adventure": saves appearance, unlocks.

  var _creator_hud: OverworldCreatorHud
  var _session_controller: OverworldSessionController
  var _locked_player: Player


  func _ready() -> void:
  	_creator_hud = OverworldCreatorHud.new()
  	_creator_hud.name = "OverworldCreatorHud"
  	add_child(_creator_hud)


  func initialize(session_controller: OverworldSessionController) -> void:
  	_session_controller = session_controller
  	if not PlayerEvents.player_spawned.is_connected(_on_player_spawned):
  		PlayerEvents.player_spawned.connect(_on_player_spawned)


  ## Used by OverworldCreatureSelectionController to block tap selection while HUD is open.
  func is_visible() -> bool:
  	return _creator_hud != null and _creator_hud.visible


  func should_open() -> bool:
  	return not PlayerProfileService.has_completed_setup()


  func _on_player_spawned(player: Node) -> void:
  	var p := player as Player
  	if p == null or not should_open():
  		return

  	_locked_player = p
  	_set_player_input_enabled(p, false)

  	var catalog: PlayerCosmeticCatalog = PlayerProfileService.get_catalog() as PlayerCosmeticCatalog
  	var appearance: Resource = PlayerProfileService.get_appearance()

  	if not _creator_hud.confirmed.is_connected(_on_hud_confirmed):
  		_creator_hud.confirmed.connect(_on_hud_confirmed)

  	_creator_hud.show_for_player(p, catalog, appearance)


  func _on_hud_confirmed(appearance: Resource) -> void:
  	PlayerProfileService.set_appearance(appearance, true)

  	if _locked_player != null and is_instance_valid(_locked_player):
  		_set_player_input_enabled(_locked_player, true)
  	_locked_player = null

  	_creator_hud.hide_hud()


  func _set_player_input_enabled(player: Player, enabled: bool) -> void:
  	var input_comp := player.get_node_or_null("PlayerInputComponent") as PlayerInputComponent
  	if input_comp == null:
  		return
  	input_comp.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
  ```

- [ ] **Step 2.2: Run validation to confirm no parse errors**

  ```bash
  "C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
  ```
  Expected: exit code 0.

- [ ] **Step 2.3: Commit**

  ```bash
  git add src/World/Overworld/overworld_character_creator_controller.gd
  git add src/World/Overworld/overworld_character_creator_controller.gd.uid
  git commit -m "feat(creator): rewrite controller to use player_spawned signal flow"
  ```

---

## Chunk 2: HUD + Wiring + Cleanup

> **Spec deviation note:** The approved spec calls for `OverworldCreatorHud` to be added as a child of `OverworldCharacterCreatorController` in `overworld.tscn` via the Godot editor, and accessed via `@onready`. This plan instead instantiates the HUD in `OverworldCharacterCreatorController._ready()` via `add_child(OverworldCreatorHud.new())`. The behavior is identical. No `overworld.tscn` editor edit is required.

### Task 3: Create `OverworldCreatorHud`

**Files:**
- Create: `src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.gd`

- [ ] **Step 3.1: Create the directory and file**

  Create `src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.gd` with the full content below.

  This is a self-contained `CanvasLayer` that:
  - Builds its entire UI in `_build_panel()` called from `_ready()`
  - Stores per-slot index arrays and refreshes labels on each cycle
  - Calls `player.apply_appearance(appearance, catalog)` live on every change
  - Adds a "CUSTOMIZING" `Label` as a child of the player for world-space display
  - Emits `confirmed(appearance)` when "Begin Adventure" is pressed

  ```gdscript
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
  ```

- [ ] **Step 3.2: Run validation**

  ```bash
  "C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
  ```
  Expected: exit code 0. If you see `Identifier 'OverworldCreatorHud' not declared`, ensure the file is in the correct path and the `class_name` line is present.

- [ ] **Step 3.3: Commit**

  ```bash
  git add src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.gd
  git add src/World/Overworld/OverworldCreatorHud/overworld_creator_hud.gd.uid
  git commit -m "feat(creator): add OverworldCreatorHud with live slot cycling"
  ```

---

### Task 4: Update `overworld.gd`

**Files:**
- Modify: `src/World/Overworld/overworld.gd`

Three changes needed:

**Change A — `_wire_main_screen_signals()` (lines 138–149):** Remove the `begin_adventure_pressed` connection.

**Change B — `_on_main_screen_play_pressed()` (lines 160–169):** Remove the `should_open()` gate; always hide menu and start session.

**Change C — `_on_begin_adventure_pressed()` (lines 172–177):** Delete this method entirely.

**Change D — `_initialize_character_creator_controller()` (line 248):** Change `initialize(main_screen, session_controller)` → `initialize(session_controller)`.

- [ ] **Step 4.1: Remove `begin_adventure_pressed` connection from `_wire_main_screen_signals()`**

  In `_wire_main_screen_signals()`, remove:
  ```gdscript
  if not main_screen.begin_adventure_pressed.is_connected(_on_begin_adventure_pressed):
  	main_screen.begin_adventure_pressed.connect(_on_begin_adventure_pressed)
  ```

- [ ] **Step 4.2: Simplify `_on_main_screen_play_pressed()`**

  Change from:
  ```gdscript
  func _on_main_screen_play_pressed() -> void:
  	creature_selection_controller.clear_selection()
  	print("[Overworld] play_started")
  	if character_creator_controller and character_creator_controller.should_open():
  		character_creator_controller.open_panel()
  		return
  	if main_screen:
  		main_screen.hide_menu()
  	if session_controller:
  		session_controller.start_session()
  ```
  To:
  ```gdscript
  func _on_main_screen_play_pressed() -> void:
  	creature_selection_controller.clear_selection()
  	if main_screen:
  		main_screen.hide_menu()
  	if session_controller:
  		session_controller.start_session()
  ```

- [ ] **Step 4.3: Delete `_on_begin_adventure_pressed()` method**

  Remove lines 172–177:
  ```gdscript
  func _on_begin_adventure_pressed() -> void:
  	if main_screen:
  		main_screen.hide_menu()
  	if session_controller:
  		session_controller.start_session()
  ```

- [ ] **Step 4.4: Update `_initialize_character_creator_controller()`**

  Change line 248:
  ```gdscript
  func _initialize_character_creator_controller() -> void:
  	if character_creator_controller:
  		character_creator_controller.initialize(main_screen, session_controller)
  ```
  To:
  ```gdscript
  func _initialize_character_creator_controller() -> void:
  	if character_creator_controller:
  		character_creator_controller.initialize(session_controller)
  ```

- [ ] **Step 4.5: Run validation**

  ```bash
  "C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
  ```
  Expected: exit code 0.

- [ ] **Step 4.6: Commit**

  ```bash
  git add src/World/Overworld/overworld.gd
  git commit -m "feat(creator): simplify overworld play-pressed flow, remove begin_adventure_pressed"
  ```

---

### Task 5: Strip CharacterCreatorPanel wiring from `main_screen.gd`

**Files:**
- Modify: `src/Ui/Desktop/Gui/MainScreen/main_screen.gd`

This file has many `CharacterCreatorPanel` references scattered across it. Remove them all in one pass.

- [ ] **Step 5.1: Remove `signal begin_adventure_pressed` (line 7)**

  Remove:
  ```gdscript
  signal begin_adventure_pressed()
  ```

- [ ] **Step 5.2: Remove `@export var creator_panel_path` (line 25)**

  Remove:
  ```gdscript
  @export var creator_panel_path: NodePath = ^"Root/MenuStrip/CharacterCreatorPanel"
  ```

- [ ] **Step 5.3: Remove `var _creator_panel` and `var _creator_overlay_mode` fields (lines 49, 61)**

  Remove:
  ```gdscript
  var _creator_panel: CharacterCreatorPanel
  ```
  And:
  ```gdscript
  var _creator_overlay_mode: bool = false
  ```

- [ ] **Step 5.4: Remove `set_creator_overlay_mode(false)` call and `_creator_panel.visible` line from `show_menu()` (lines 98, 109–110)**

  In `show_menu()`, remove:
  ```gdscript
  set_creator_overlay_mode(false)
  ```
  And remove:
  ```gdscript
  if _creator_panel != null:
  	_creator_panel.visible = false
  ```

- [ ] **Step 5.5: Remove `set_creator_overlay_mode(false)` from `hide_menu()` (line 121)**

  In `hide_menu()`, remove:
  ```gdscript
  set_creator_overlay_mode(false)
  ```

- [ ] **Step 5.6: Remove all five creator methods: `animate_menu_out()`, `animate_play_transition()`, `_on_begin_pressed()`, `_on_creator_cancelled()`, `set_creator_overlay_mode()`**

  Remove the following methods in their entirety (lines 128–245):
  - `animate_menu_out(on_complete: Callable)` (lines 128–147)
  - `animate_play_transition()` (lines 152–195)
  - `_on_begin_pressed()` (lines 198–200)
  - `_on_creator_cancelled()` (lines 203–241)
  - `set_creator_overlay_mode(enabled: bool)` (lines 244–245)

- [ ] **Step 5.7: Remove `_creator_panel` cache line from `_cache_nodes()` (line 256)**

  In `_cache_nodes()`, remove:
  ```gdscript
  _creator_panel = get_node_or_null(creator_panel_path) as CharacterCreatorPanel
  ```

- [ ] **Step 5.8: Remove `_creator_panel` signal connections from `_connect_signals()` (lines 326–329)**

  In `_connect_signals()`, remove:
  ```gdscript
  if _creator_panel and not _creator_panel.confirmed.is_connected(_on_begin_pressed):
  	_creator_panel.confirmed.connect(_on_begin_pressed)
  if _creator_panel and not _creator_panel.creation_cancelled.is_connected(_on_creator_cancelled):
  	_creator_panel.creation_cancelled.connect(_on_creator_cancelled)
  ```

- [ ] **Step 5.9: Remove `_compute_creator_anchors()` method (lines 728–744)**

  Remove the entire method:
  ```gdscript
  func _compute_creator_anchors() -> Dictionary:
  	var viewport_size := _resolve_viewport_size()
  	...
  ```

- [ ] **Step 5.10: Run validation**

  ```bash
  "C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
  ```
  Expected: exit code 0. If you see `CharacterCreatorPanel` identifier errors, check that all references in the file were removed. Also verify there are no remaining references with:
  ```bash
  grep -n "CharacterCreatorPanel\|creator_panel\|_creator_overlay\|animate_play_transition\|animate_menu_out\|begin_adventure_pressed\|_compute_creator_anchors\|_on_creator_cancelled\|_on_begin_pressed\|set_creator_overlay_mode" src/Ui/Desktop/Gui/MainScreen/main_screen.gd
  ```
  Expected: no output.

- [ ] **Step 5.11: Commit**

  ```bash
  git add src/Ui/Desktop/Gui/MainScreen/main_screen.gd
  git commit -m "feat(creator): strip CharacterCreatorPanel wiring from main_screen"
  ```

---

### Task 6: Delete old CharacterCreatorPanel files

**Files:**
- Delete: `src/Ui/Desktop/CharacterCreator/character_creator_panel.gd`
- Delete: `src/Ui/Desktop/CharacterCreator/character_creator_panel.tscn`

- [ ] **Step 6.1: Delete the files**

  ```bash
  git rm "src/Ui/Desktop/CharacterCreator/character_creator_panel.gd"
  git rm "src/Ui/Desktop/CharacterCreator/character_creator_panel.gd.uid"
  git rm "src/Ui/Desktop/CharacterCreator/character_creator_panel.tscn"
  git rm "src/Ui/Desktop/CharacterCreator/character_creator_panel.tscn.uid"
  ```
  (The `.uid` files may not exist; skip if git rm reports them as missing.)

- [ ] **Step 6.2: Run validation to confirm nothing still references these files**

  ```bash
  "C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
  ```
  Expected: exit code 0.

  Also check for stray references:
  ```bash
  grep -rn "character_creator_panel\|CharacterCreatorPanel" src/ --include="*.gd" --include="*.tscn"
  ```
  Expected: no output (or only comment-only mentions if any).

- [ ] **Step 6.3: Commit**

  All deletions are already staged by the `git rm` commands above.
  ```bash
  git commit -m "feat(creator): delete old CharacterCreatorPanel files"
  ```

---

### Task 7: Manual Integration Test

- [ ] **Step 7.1: Launch the game**

  Open Godot 4.6, press F5 (or run `"C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe" --path .`). Expected: main menu appears with parallax background, music plays, buttons are responsive.

- [ ] **Step 7.2: Test first-run flow**

  If `user://player_profile.cfg` exists and contains `setup_completed = true`, delete it first.
  On Windows, user data lives at `%APPDATA%\Godot\app_userdata\<project-name>\` — delete `player_profile.cfg` from there (or simply open it in a text editor and remove the `[profile]` section and `setup_completed` key).
  Click **Play**. Expected:
  - Main menu hides immediately (no more panel animation)
  - Player spawns in the overworld
  - Player **cannot** move (click-to-move produces no response)
  - `OverworldCreatorHud` panel fades in on the right side
  - "CUSTOMIZING" label floats above the player sprite
  - All three slots (HEAD, BODY, LEGS) show a name and counter (e.g. "1 / 4")

- [ ] **Step 7.3: Test live slot cycling**

  Click `‹` and `›` on each slot. Expected: player's in-world sprite updates immediately to reflect the new head/body/legs.

- [ ] **Step 7.4: Test Randomize**

  Click **RANDOMIZE**. Expected: all three slots jump to random values and the player sprite updates.

- [ ] **Step 7.5: Test "Begin Adventure"**

  Click **BEGIN ADVENTURE**. Expected:
  - HUD fades out
  - "CUSTOMIZING" label disappears
  - Player can now move (click-to-move works)
  - Gameplay proceeds normally

- [ ] **Step 7.6: Test persistence — setup_completed skips the HUD**

  Quit and relaunch. Click **Play** again. Expected:
  - Main menu hides, player spawns
  - **No HUD appears** — creator flow is skipped
  - Player can move immediately

- [ ] **Step 7.7: Final commit**

  ```bash
  git status --short
  git add src/ docs/
  git commit -m "feat(creator): in-game character creator complete — first-run HUD with live preview"
  ```
