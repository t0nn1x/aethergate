class_name CombatResultPanel
extends AdaptiveOverlayPanel

## Post-combat overlay. Shows victory (XP reward + Continue) or defeat (Respawn).
## Call show_result() when combat ends. Emits continue_pressed when button is tapped.

signal continue_pressed

@onready var _panel_container: PanelContainer = $PanelContainer
@onready var _title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var _subtitle_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel
@antml:parameter name="xp_label: Label = $PanelContainer/MarginContainer/VBoxContainer/XpLabel
@onready var _level_up_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LevelUpLabel
@onready var _flavour_label: Label = $PanelContainer/MarginContainer/VBoxContainer/FlavourLabel
@onready var _action_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionButton


func _ready() -> void:
	super()
	_action_button.pressed.connect(func(): continue_pressed.emit())
	_apply_panel_style()
	_apply_button_style()


func show_result(is_victory: bool, enemy_name: String, xp_gained: int, leveled_up: bool = false, new_level: int = 1) -> void:
	if is_victory:
		_title_label.text = "✦ Victory! ✦"
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
		_subtitle_label.text = "You defeated %s" % enemy_name
		_xp_label.text = "+ %d XP" % xp_gained
		_level_up_label.text = "⬆ Level %d!" % new_level
		_level_up_label.visible = leveled_up
	else:
		_title_label.text = "✦ Defeated! ✦"
		_title_label.add_theme_color_override("font_color", Color(1.0, 0.33, 0.33, 1.0))
		_subtitle_label.text = "Bested by %s" % enemy_name
		_xp_label.text = ""
		_level_up_label.visible = false
	_xp_label.visible = is_victory
	_flavour_label.visible = not is_victory
	_action_button.text = "Continue" if is_victory else "Respawn"
	show()


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.09, 0.95)
	style.set_corner_radius_all(10)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.62, 0.48, 0.14, 0.65)
	_panel_container.add_theme_stylebox_override("panel", style)


func _apply_button_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.1, 0.18, 0.88)
	normal.set_corner_radius_all(7)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.62, 0.48, 0.14, 0.72)
	normal.content_margin_left = 12.0
	normal.content_margin_right = 12.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.14, 0.18, 0.32, 0.95)
	hover.border_color = Color(0.92, 0.78, 0.28, 1.0)

	_action_button.add_theme_stylebox_override("normal", normal)
	_action_button.add_theme_stylebox_override("hover", hover)
	_action_button.add_theme_color_override("font_color", Color(0.92, 0.82, 0.5, 1.0))
	_action_button.add_theme_font_size_override("font_size", 18)
