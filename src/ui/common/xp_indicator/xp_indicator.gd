# xp_indicator.gd
# XpIndicator component for showing player level and XP with smart number scaling
# Follows project conventions: static typing, class_name, signals at top

extends Control
class_name XpIndicator

signal clicked() # example signal if parent wants to listen

@onready var _level_label: Label = $VBoxContainer/LevelLabel
@onready var _progress_bar: ProgressBar = $VBoxContainer/XpContainer/ProgressBar
@onready var _xp_label: Label = $VBoxContainer/XpContainer/XpLabel

const K_THRESHOLD: int = 1000
const BIG_K_THRESHOLD: int = 10000

func _ready() -> void:
    # Connect to PlayerProgressionService signals if available
    if Engine.has_singleton("PlayerProgressionService"):
        _connect_progression_signals()
    # Ensure UI starts in a sane default
    _update_progress(0, 1)
    _update_level(1)

func _connect_progression_signals() -> void:
    # Use the autoloaded PlayerProgressionService signals and GDScript 4.6 connect syntax
    if not PlayerProgressionService.xp_gained.is_connected(_on_xp_gained):
        PlayerProgressionService.xp_gained.connect(_on_xp_gained)
    if not PlayerProgressionService.level_up.is_connected(_on_level_up):
        PlayerProgressionService.level_up.connect(_on_level_up)

func _on_xp_gained(amount: int, new_xp: int, xp_needed: int) -> void:
    _update_progress(new_xp, xp_needed)

func _on_level_up(new_level: int, new_stats, bonus_points_gained: int) -> void:
    _update_level(new_level)
    # reset progress display on level up
    _update_progress(0, 1)

func _update_level(level: int) -> void:
    _level_label.text = "Level %d" % level

func _update_progress(current_xp: int, xp_needed: int) -> void:
    var denom = xp_needed if xp_needed > 0 else 1
    var percent := clamp(float(current_xp) / float(denom) * 100.0, 0.0, 100.0)
    _progress_bar.value = percent
    _xp_label.text = "%s / %s" % (_format_number(current_xp), _format_number(denom))

func _format_number(n: int) -> String:
    # Smart scaling: show values in 'k' for thousands
    if n >= BIG_K_THRESHOLD:
        # 10k+: round to nearest thousand, no decimal
        var val := int(round(float(n) / 1000.0))
        return "%dk" % val
    elif n >= K_THRESHOLD:
        # 1k - 10k: show one decimal when needed (e.g., 1.2k)
        var val := round(float(n) / 100.0) / 10.0
        if is_equal_approx(val, float(int(val))):
            return "%dk" % int(val)
        return ("%sk" % str(val)).strip_edges()
    else:
        return str(n)

# Optional helper to allow clicking the control to emit clicked signal
func _gui_input(event) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.LEFT:
        emit_signal("clicked")
