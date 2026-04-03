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
    # Initialize from profile (reads player level/xp and handles max-level display)
    _initialize_from_profile()
    _update_display()

func _initialize_from_profile() -> void:
    # Read player level/xp from the profile service and initialize display.
    var level: int = 1
    var xp: int = 0
    if Engine.has_singleton("PlayerProfileService"):
        level = int(PlayerProfileService.get_player_level())
        xp = int(PlayerProfileService.get_player_xp())
    # Determine max level from progression config if available (tests rely on _config.max_level)
    var max_level: int = 100
    if Engine.has_singleton("PlayerProgressionService"):
        # Plan expects direct access to _config.max_level
        if PlayerProgressionService._config != null and PlayerProgressionService._config.has_method("get"):
            # PlayerLevelConfig is a Resource; access field directly
            max_level = int(PlayerProgressionService._config.max_level)
        else:
            max_level = int(PlayerProgressionService._config.max_level) if PlayerProgressionService._config != null else 100
    # If at or above max level, show MAX LEVEL and full bar
    if level >= max_level:
        _update_level(level)
        _progress_bar.value = 100.0
        _xp_label.text = "MAX LEVEL"
        return
    # Otherwise compute needed XP and update normally
    var needed: int = 1
    if Engine.has_singleton("PlayerProgressionService"):
        needed = int(PlayerProgressionService.xp_needed_for_level(level))
    _update_level(level)
    _update_progress(xp, needed)

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
    # Use centralized progress calculation and formatting which handle max-level edge cases
    var level: int = 1
    if Engine.has_singleton("PlayerProfileService"):
        level = int(PlayerProfileService.get_player_level())
    var fraction := _calculate_progress(current_xp, level)
    # _calculate_progress returns a fraction [0.0, 1.0]; ProgressBar uses 0-100 range
    _progress_bar.value = clamp(fraction * 100.0, 0.0, 100.0)
    _xp_label.text = _format_xp_text(current_xp, xp_needed, level)

func _update_display() -> void:
    # Refresh display from the profile service (level, xp, xp_needed)
    var level: int = 1
    var xp: int = 0
    if Engine.has_singleton("PlayerProfileService"):
        level = int(PlayerProfileService.get_player_level())
        xp = int(PlayerProfileService.get_player_xp())
    var needed: int = 1
    if Engine.has_singleton("PlayerProgressionService"):
        needed = int(PlayerProgressionService.xp_needed_for_level(level))
    _update_level(level)
    _update_progress(xp, needed)

func _calculate_progress(current_xp: int, level: int) -> float:
    # Returns fraction [0.0, 1.0]. If at max level, returns 1.0 as the spec requires.
    var max_level: int = 100
    if Engine.has_singleton("PlayerProgressionService") and PlayerProgressionService._config != null:
        max_level = int(PlayerProgressionService._config.max_level)
    if level >= max_level:
        return 1.0
    var denom: int = 1
    if Engine.has_singleton("PlayerProgressionService"):
        denom = int(PlayerProgressionService.xp_needed_for_level(level))
    denom = denom if denom > 0 else 1
    return clamp(float(current_xp) / float(denom), 0.0, 1.0)

func _format_xp_text(current_xp: int, xp_needed: int, level: int) -> String:
    # Show 'MAX LEVEL' when at cap; otherwise format numbers smartly.
    var max_level: int = 100
    if Engine.has_singleton("PlayerProgressionService") and PlayerProgressionService._config != null:
        max_level = int(PlayerProgressionService._config.max_level)
    if level >= max_level:
        return "MAX LEVEL"
    var denom: int = xp_needed if xp_needed > 0 else 1
    return "%s / %s" % (_format_number(current_xp), _format_number(denom))

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
