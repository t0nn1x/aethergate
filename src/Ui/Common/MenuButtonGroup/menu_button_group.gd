class_name MenuButtonGroup
extends Node

## Reusable interactive behaviour for a group of menu buttons.
##
## Provides keyboard/mouse-synced focus, smooth font-size animation on hover,
## and a press-bounce animation. Drop it as a child node of any screen, then
## call setup() once after the buttons are ready.
##
## Usage:
##   var group := MenuButtonGroup.new()
##   add_child(group)
##   group.button_focused.connect(func(_b): play_hover_sound())
##   group.setup([play_btn, lang_btn, quit_btn])

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
	if _font_tweens.has(btn):
		(_font_tweens[btn] as Tween).kill()
	var tween: Tween = create_tween()
	_font_tweens[btn] = tween
	# Shrink → overshoot → settle back to hover size.
	tween.tween_method(
		func(s: float) -> void: btn.add_theme_font_size_override("font_size", roundi(s)),
		current, 26.0, 0.07
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(
		func(s: float) -> void: btn.add_theme_font_size_override("font_size", roundi(s)),
		26.0, 44.0, 0.14
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(s: float) -> void: btn.add_theme_font_size_override("font_size", roundi(s)),
		44.0, float(font_size_hover), 0.07
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
