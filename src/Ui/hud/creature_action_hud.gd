class_name CreatureActionHud
extends CanvasLayer

signal fight_pressed(creature: Creature)

@export var root_path: NodePath = ^"Root"
@export var fight_button_path: NodePath = ^"Root/FightButton"
@export var fight_button_base_text: String = "Fight"
@export var localization_service_path: NodePath = ^"/root/LocalizationService"
@export var fight_button_text_key: StringName = &"ui.hud.fight"

var _selected_creature: Creature
var _localization_service: Node

@onready var _root: Control = get_node_or_null(root_path) as Control
@onready var _fight_button: Button = get_node_or_null(fight_button_path) as Button


func _ready() -> void:
	_setup_localization()
	fight_button_base_text = _translate_key(fight_button_text_key)
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

	var fight_label: String = _translate_key(fight_button_text_key)
	var creature_label: String = _resolve_creature_label(creature)
	if creature_label.is_empty():
		_fight_button.text = fight_label
		return
	_fight_button.text = "%s %s" % [fight_label, creature_label]


func _resolve_creature_label(creature: Creature) -> String:
	if creature == null:
		return ""

	var data: CreatureData = creature.creature_data
	if data != null and not data.creature_id.is_empty():
		return data.creature_id
	if not creature.creature_name.is_empty():
		return creature.creature_name
	return creature.name


func _setup_localization() -> void:
	_localization_service = get_node_or_null(localization_service_path)
	if (
		_localization_service
		and _localization_service.has_signal("locale_changed")
		and not _localization_service.is_connected("locale_changed", Callable(self, "_on_locale_changed"))
	):
		_localization_service.connect("locale_changed", Callable(self, "_on_locale_changed"))


func _on_locale_changed(_locale: StringName) -> void:
	fight_button_base_text = _translate_key(fight_button_text_key)
	if _selected_creature != null and is_instance_valid(_selected_creature):
		_update_fight_button_text_for_creature(_selected_creature)
		return
	if _fight_button:
		_fight_button.text = fight_button_base_text


func _translate_key(key: StringName) -> String:
	if _localization_service and _localization_service.has_method("translate_key"):
		return String(_localization_service.call("translate_key", key))
	return tr(String(key))
