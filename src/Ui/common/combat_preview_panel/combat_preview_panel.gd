class_name CombatPreviewPanel
extends AdaptiveOverlayPanel

## Pre-fight info card shown after tapping a creature.
## Emits fight_confirmed when player taps FIGHT, or dismissed on Flee.

signal fight_confirmed(enemy_snapshot: CombatantSnapshot)
signal dismissed()

@onready var _portrait: TextureRect = $Layout/EnemyPortrait
@onready var _name_label: Label = $Layout/NameLabel
@onready var _level_label: Label = $Layout/LevelLabel
@onready var _power_label: Label = $Layout/PowerLabel
@onready var _fight_button: Button = $Layout/Buttons/FightButton
@onready var _flee_button: Button = $Layout/Buttons/FleeButton

var _enemy_snapshot: CombatantSnapshot = null
var _creature_data: CreatureData = null
var _anim_time: float = 0.0
var _atlas_texture: AtlasTexture = null


func show_for_creature(creature_data: CreatureData) -> void:
	_enemy_snapshot = CombatantSnapshot.from_creature(creature_data)
	_creature_data = creature_data
	_anim_time = 0.0
	_populate_ui(creature_data)
	show()


func _ready() -> void:
	super()
	_fight_button.pressed.connect(_on_fight_pressed)
	_flee_button.pressed.connect(_on_flee_pressed)


func _process(delta: float) -> void:
	if _creature_data == null or _atlas_texture == null:
		return
	if not visible:
		return

	var frame_count: int = _creature_data.hframes * _creature_data.vframes
	if frame_count <= 1:
		return

	var fps: float = maxf(_creature_data.idle_animation_fps, 0.1)
	_anim_time += delta * fps
	var cycle_index: int = int(floor(_anim_time)) % frame_count
	var start_frame: int = clampi(_creature_data.default_frame, 0, frame_count - 1)
	var current_frame: int = (start_frame + cycle_index) % frame_count

	var fw: int = _creature_data.frame_width_pixels
	var fh: int = _creature_data.frame_height_pixels
	var col: int = current_frame % _creature_data.hframes
	var row: int = current_frame / _creature_data.hframes
	_atlas_texture.region = Rect2(col * fw, row * fh, fw, fh)


func _populate_ui(creature_data: CreatureData) -> void:
	_name_label.text = creature_data.display_name
	_level_label.text = "Lv. %d" % _enemy_snapshot.level

	_atlas_texture = AtlasTexture.new()
	_atlas_texture.atlas = creature_data.sprite_sheet
	var fw: int = creature_data.frame_width_pixels
	var fh: int = creature_data.frame_height_pixels
	var start_frame: int = clampi(creature_data.default_frame, 0, creature_data.hframes * creature_data.vframes - 1)
	var col: int = start_frame % creature_data.hframes
	var row: int = start_frame / creature_data.hframes
	_atlas_texture.region = Rect2(col * fw, row * fh, fw, fh)
	_portrait.texture = _atlas_texture

	_power_label.text = _get_power_label(creature_data)


func _get_power_label(creature_data: CreatureData) -> String:
	if creature_data.max_health >= 200 or creature_data.damage >= 30:
		return "Stronger"
	if creature_data.max_health <= 30 or creature_data.damage <= 5:
		return "Weaker"
	return "Even Match"


func _on_fight_pressed() -> void:
	hide()
	_creature_data = null
	fight_confirmed.emit(_enemy_snapshot)


func _on_flee_pressed() -> void:
	hide()
	_creature_data = null
	dismissed.emit()
