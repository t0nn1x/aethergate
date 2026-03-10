class_name CombatPreviewPanel
extends AdaptiveOverlayPanel

## Pre-fight info card shown after tapping a creature.
## Emits fight_confirmed when player taps FIGHT, or dismissed on X.

signal fight_confirmed(enemy_snapshot: CombatantSnapshot)
signal dismissed()

@onready var _portrait: TextureRect = $Layout/EnemyPortrait
@onready var _name_label: Label = $Layout/NameLabel
@onready var _level_label: Label = $Layout/LevelLabel
@onready var _power_label: Label = $Layout/PowerLabel
@onready var _fight_button: Button = $Layout/Buttons/FightButton
@onready var _flee_button: Button = $Layout/Buttons/FleeButton

var _enemy_snapshot: CombatantSnapshot = null


func show_for_creature(creature_data: CreatureData) -> void:
	_enemy_snapshot = CombatantSnapshot.from_creature(creature_data)
	_populate_ui(creature_data)
	show()


func _ready() -> void:
	super()
	_fight_button.pressed.connect(_on_fight_pressed)
	_flee_button.pressed.connect(_on_flee_pressed)


func _populate_ui(creature_data: CreatureData) -> void:
	_name_label.text = creature_data.display_name
	_level_label.text = "Lv. %d" % _enemy_snapshot.level
	_portrait.texture = creature_data.sprite_sheet

	## Rough power indicator vs player (placeholder until player stats exist).
	_power_label.text = _get_power_label(creature_data)


func _get_power_label(creature_data: CreatureData) -> String:
	## Simple threshold — replace with real stat comparison once player stats exist.
	if creature_data.max_health >= 200 or creature_data.damage >= 30:
		return "Stronger"
	if creature_data.max_health <= 30 or creature_data.damage <= 5:
		return "Weaker"
	return "Even Match"


func _on_fight_pressed() -> void:
	hide()
	fight_confirmed.emit(_enemy_snapshot)


func _on_flee_pressed() -> void:
	hide()
	dismissed.emit()
