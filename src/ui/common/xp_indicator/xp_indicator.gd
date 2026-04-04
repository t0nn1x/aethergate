# xp_indicator.gd
# XpIndicator component for showing player level and XP with smart number scaling
# Follows project conventions: static typing, class_name, signals at top

extends Control
class_name XpIndicator

signal clicked()

@onready var _level_label: Label = $VBoxContainer/LevelLabel
@onready var _bar: ProgressBar = $VBoxContainer/XpContainer/ProgressBar
@onready var _xp_label: Label = $VBoxContainer/XpContainer/XpLabel

const K:       int = 1_000
const KK:      int = 1_000_000
const KKK:     int = 1_000_000_000     # requires 64-bit int throughout XP pipeline
const BIG_K:   int = 10_000
const BIG_KK:  int = 10_000_000
const BIG_KKK: int = 10_000_000_000   # 64-bit only; exceeds 32-bit int range


func _ready() -> void:
	_connect_progression_signals()
	_initialize_from_profile()


func _connect_progression_signals() -> void:
	if not PlayerProgressionService.xp_gained.is_connected(_on_xp_gained):
		PlayerProgressionService.xp_gained.connect(_on_xp_gained)
	if not PlayerProgressionService.level_up.is_connected(_on_level_up):
		PlayerProgressionService.level_up.connect(_on_level_up)


func _initialize_from_profile() -> void:
	var level: int = int(PlayerProfileService.get_player_level())
	var xp: int    = int(PlayerProfileService.get_player_xp())
	var max_level: int = int(PlayerProgressionService._config.max_level) \
		if PlayerProgressionService._config != null else 100

	if level >= max_level:
		_update_level(level)
		_bar.value = 100.0
		_xp_label.text = "MAX"
		return

	var needed: int = PlayerProgressionService.xp_needed_for_level(level)
	_update_level(level)
	_update_progress(xp, needed)


func _on_xp_gained(_amount: int, new_xp: int, xp_needed: int) -> void:
	_update_progress(new_xp, xp_needed)


func _on_level_up(new_level: int, _new_stats: Variant, _bonus: int) -> void:
	_update_level(new_level)
	_update_progress(0, PlayerProgressionService.xp_needed_for_level(new_level))


func _update_level(level: int) -> void:
	_level_label.text = "Lv %d" % level


func _update_progress(current_xp: int, xp_needed: int) -> void:
	var level: int = int(PlayerProfileService.get_player_level())
	var fraction: float = _calculate_progress(current_xp, level)
	_bar.value = clampf(fraction * 100.0, 0.0, 100.0)
	_xp_label.text = _format_xp_text(current_xp, xp_needed, level)


func _calculate_progress(current_xp: int, level: int) -> float:
	var max_level: int = int(PlayerProgressionService._config.max_level) \
		if PlayerProgressionService._config != null else 100
	if level >= max_level:
		return 1.0
	var denom: int = maxi(1, PlayerProgressionService.xp_needed_for_level(level))
	return clampf(float(current_xp) / float(denom), 0.0, 1.0)


func _format_xp_text(current_xp: int, xp_needed: int, level: int) -> String:
	var max_level: int = int(PlayerProgressionService._config.max_level) \
		if PlayerProgressionService._config != null else 100
	if level >= max_level:
		return "MAX"
	return "%s / %s" % [_format_number(current_xp), _format_number(maxi(1, xp_needed))]


func _format_number(n: int) -> String:
	if n >= BIG_KKK:
		return "%dkkk" % int(round(float(n) / float(KKK)))
	elif n >= KKK:
		return _decimal_suffix(n, KKK, "kkk")
	elif n >= BIG_KK:
		return "%dkk" % int(round(float(n) / float(KK)))
	elif n >= KK:
		return _decimal_suffix(n, KK, "kk")
	elif n >= BIG_K:
		return "%dk" % int(round(float(n) / float(K)))
	elif n >= K:
		return _decimal_suffix(n, K, "k")
	else:
		return str(n)


func _decimal_suffix(n: int, unit: int, suffix: String) -> String:
	var val: float = round(float(n) / float(unit) * 10.0) / 10.0
	if is_equal_approx(val, float(int(val))):
		return "%d%s" % [int(val), suffix]
	return "%.1f%s" % [val, suffix]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
