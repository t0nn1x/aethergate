class_name MenuButtonGroup
extends Node

## Reusable interactive behaviour for a group of menu buttons.
##
## Provides keyboard/mouse-synced focus, smooth font-size animation on hover,
## and a press-bounce animation. Drop it as a child node of any screen, then
## call setup() or setup_grid() once after the buttons are ready.
##
## Linear list usage:
##   group.setup([play_btn, settings_btn, quit_btn])
##
## 2-D grid usage (4-directional arrow nav):
##   group.setup_grid([
##       [language_btn, sound_btn],
##       [graphics_btn, controls_btn],
##       [back_btn],
##   ])

signal button_focused(button: Button)

@export var font_size_normal: int = 36
@export var font_size_hover: int = 40
@export var hover_duration: float = 0.10
@export var exit_duration: float = 0.12

var _buttons: Array[Button] = []
var _font_tweens: Dictionary = {}


func setup(buttons: Array) -> void:
	_buttons.clear()
	for node: Variant in buttons:
		var btn := node as Button
		if btn == null:
			continue
		_buttons.append(btn)
		_wire(btn)
	_build_focus_chain()


func _wire(btn: Button) -> void:
	# Mouse hover transfers focus so both systems share one highlight state.
	btn.mouse_entered.connect(func() -> void:
		btn.grab_focus()
	)
	btn.focus_entered.connect(func() -> void:
		_set_size(btn, font_size_hover, hover_duration)
		button_focused.emit(btn)
	)
	btn.focus_exited.connect(func() -> void:
		_set_size(btn, font_size_normal, exit_duration)
	)
	btn.button_down.connect(func() -> void:
		_play_press(btn)
	)


## Sets up a 2-D grid with 4-directional arrow key navigation.
## rows is Array[Array] — each inner array is one row of buttons.
## Rows can have different lengths; shorter rows clamp the column index.
func setup_grid(rows: Array) -> void:
	_buttons.clear()
	for row: Variant in rows:
		for node: Variant in row:
			var btn := node as Button
			if btn == null:
				continue
			if not _buttons.has(btn):
				_buttons.append(btn)
				_wire(btn)
	_build_grid_focus_chain(rows)


func _build_focus_chain() -> void:
	var focusable: Array[Button] = []
	for btn: Button in _buttons:
		if btn.visible and not btn.disabled:
			focusable.append(btn)
	var count: int = focusable.size()
	if count < 2:
		return
	for i in range(count):
		focusable[i].focus_neighbor_top    = focusable[(i - 1 + count) % count].get_path()
		focusable[i].focus_neighbor_bottom = focusable[(i + 1) % count].get_path()


func _build_grid_focus_chain(rows: Array) -> void:
	var row_count: int = rows.size()
	for r: int in row_count:
		var row: Array = rows[r]
		var col_count: int = row.size()
		for c: int in col_count:
			var btn := row[c] as Button
			if btn == null or not btn.visible or btn.disabled:
				continue
			var above: Button = _find_grid_neighbor(rows, r, c, -1)
			var below: Button = _find_grid_neighbor(rows, r, c, 1)
			if above != null:
				btn.focus_neighbor_top = above.get_path()
			if below != null:
				btn.focus_neighbor_bottom = below.get_path()
			if col_count > 1:
				btn.focus_neighbor_left  = (row[(c - 1 + col_count) % col_count] as Button).get_path()
				btn.focus_neighbor_right = (row[(c + 1) % col_count] as Button).get_path()


func _find_grid_neighbor(rows: Array, start_row: int, col: int, direction: int) -> Button:
	var row_count: int = rows.size()
	var r: int = (start_row + direction + row_count) % row_count
	for _attempt: int in row_count - 1:
		var row: Array = rows[r]
		var btn := row[mini(col, row.size() - 1)] as Button
		if btn != null and btn.visible and not btn.disabled:
			return btn
		r = (r + direction + row_count) % row_count
	return null


func _set_size(btn: Button, target: int, duration: float) -> void:
	var current: float = float(btn.get_theme_font_size("font_size"))
	if _font_tweens.has(btn):
		(_font_tweens[btn] as Tween).kill()
	var tween: Tween = create_tween()
	_font_tweens[btn] = tween
	tween.tween_method(
		func(s: float) -> void: btn.add_theme_font_size_override("font_size", roundi(s)),
		current, float(target), duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_press(btn: Button) -> void:
	var current: float = float(btn.get_theme_font_size("font_size"))
	var press_min: float = maxf(float(font_size_normal) * 0.72, 8.0)
	var press_peak: float = maxf(float(font_size_hover) * 1.10, press_min)
	if _font_tweens.has(btn):
		(_font_tweens[btn] as Tween).kill()
	var tween: Tween = create_tween()
	_font_tweens[btn] = tween
	# Shrink → overshoot → settle back to hover size.
	tween.tween_method(
		func(s: float) -> void: btn.add_theme_font_size_override("font_size", roundi(s)),
		current, press_min, 0.07
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(
		func(s: float) -> void: btn.add_theme_font_size_override("font_size", roundi(s)),
		press_min, press_peak, 0.14
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(s: float) -> void: btn.add_theme_font_size_override("font_size", roundi(s)),
		press_peak, float(font_size_hover), 0.07
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
