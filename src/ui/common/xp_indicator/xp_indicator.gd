# xp_indicator.gd
# XpIndicator component for showing player level and XP with smart number scaling
# Follows project conventions: static typing, class_name, signals at top

extends Control
class_name XpIndicator

signal clicked() # example signal if parent wants to listen

@onready var _level_label: Label = $VBoxContainer/LevelLabel
@onready var _progress_bar: ProgressBar = $VBoxContainer/XpContainer/ProgressBar
@onready var _xp_label: Label = $VBoxContainer/XpContainer/XpLabel

const THRESHOLD_K: int = 1000
const THRESHOLD_10K: int = 10000

func _ready() -> void:
    # Connect to PlayerProgressionService signals if available
    if Engine.has_singleton("PlayerProgressionService"):
        var svc = PlayerProgressionService
        if svc is Object:
            if svc.has_signal("xp_gained"):
                svc.xp_gained.connect(_on_xp_gained, callable(self))
            if svc.has_signal("level_up"):
                svc.level_up.connect(_on_level_up, callable(self))
    # Ensure UI starts in a sane default
    _update_progress(0, 1)
    _update_level(1)

func _on_xp_gained(amount: int, new_xp: int, xp_needed: int) -> void:
    _update_progress(new_xp, xp_needed)

func _on_level_up(new_level: int, new_stats, bonus_points_gained: int) -> void:
    _update_level(new_level)
    # reset progress display on level up
    _update_progress(0, 1)

func _update_level(level: int) -> void:
    _level_label.text = "Level %d".format(level)

func _update_progress(current_xp: int, xp_needed: int) -> void:
    var denom = xp_needed if xp_needed > 0 else 1
    var percent := clamp(float(current_xp) / float(denom) * 100.0, 0.0, 100.0)
    _progress_bar.value = percent
    _xp_label.text = "%s / %s".format(_format_number(current_xp), _format_number(denom))

func _format_number(n: int) -> String:
    # Smart scaling: show values in 'k' for thousands
    if n >= THRESHOLD_10K:
        # 10k+: round to nearest thousand, no decimal
        var val := int(round(float(n) / 1000.0))
        return "%dk".format(val)
    elif n >= THRESHOLD_K:
        # 1k - 10k: show one decimal when needed (e.g., 1.2k)
        var val := round(float(n) / 100.0) / 10.0
        if is_equal_approx(val, float(int(val))):
            return "%dk".format(int(val))
        return "%s k".format(str(val)).strip_edges()
    else:
        return str(n)

# Optional helper to allow clicking the control to emit clicked signal
func _gui_input(event) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.LEFT:
        emit_signal("clicked")
