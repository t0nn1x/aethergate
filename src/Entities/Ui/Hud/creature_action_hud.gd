class_name CreatureActionHud
extends CanvasLayer

signal fight_pressed(creature: Creature)

@export var root_path: NodePath = ^"Root"
@export var fight_button_path: NodePath = ^"Root/FightButton"
@export var fight_button_base_text: String = "Fight"

var _selected_creature: Creature

@onready var _root: Control = get_node_or_null(root_path) as Control
@onready var _fight_button: Button = get_node_or_null(fight_button_path) as Button


func _ready() -> void:
	if _fight_button and not _fight_button.pressed.is_connected(_on_fight_button_pressed):
		_fight_button.pressed.connect(_on_fight_button_pressed)
	hide_action()


func show_for_creature(creature: Creature) -> void:
	if creature == null or not is_instance_valid(creature):
		hide_action()
		return

	_selected_creature = creature
	_update_fight_button_text_for_creature(creature)
	if _root:
		_root.visible = true


func hide_action() -> void:
	_selected_creature = null
	if _fight_button:
		_fight_button.text = fight_button_base_text
	if _root:
		_root.visible = false


func is_open() -> bool:
	return _root != null and _root.visible


func _on_fight_button_pressed() -> void:
	if _selected_creature == null or not is_instance_valid(_selected_creature):
		hide_action()
		return
	fight_pressed.emit(_selected_creature)


func _update_fight_button_text_for_creature(creature: Creature) -> void:
	if _fight_button == null:
		return

	var creature_label: String = _resolve_creature_label(creature)
	if creature_label.is_empty():
		_fight_button.text = fight_button_base_text
		return
	_fight_button.text = "%s %s" % [fight_button_base_text, creature_label]


func _resolve_creature_label(creature: Creature) -> String:
	if creature == null:
		return ""

	var data: CreatureData = creature.creature_data
	if data != null and not data.creature_id.is_empty():
		return data.creature_id
	if not creature.creature_name.is_empty():
		return creature.creature_name
	return creature.name
