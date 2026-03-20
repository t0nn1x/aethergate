class_name ScreenLocalization
extends Node

## Reusable localization wiring for any UI node.
##
## Wraps LocalizationService (when available) and falls back to TranslationServer.
## Drop it as a child node of any screen, then connect locale_updated to refresh texts.
##
## Usage:
##   var _loc := ScreenLocalization.new()
##   add_child(_loc)
##   _loc.locale_updated.connect(func(_l: StringName) -> void: _apply_localized_texts())

signal locale_updated(locale: StringName)

@export var service_path: NodePath = ^"/root/LocalizationService"

var _service: Node


func _ready() -> void:
	_service = get_node_or_null(service_path)
	if _service and _service.has_signal("locale_changed"):
		if not _service.locale_changed.is_connected(_on_locale_changed):
			_service.locale_changed.connect(_on_locale_changed)


func translate(key: StringName) -> String:
	if _service:
		return _service.translate_key(key)
	return tr(String(key))


func get_current_locale() -> String:
	if _service:
		return String(_service.get_current_locale()).strip_edges().to_lower()
	return String(TranslationServer.get_locale()).get_slice("_", 0).get_slice("-", 0).to_lower()


func get_supported_locales() -> PackedStringArray:
	if _service:
		var locales: Variant = _service.get_supported_locales()
		if locales is PackedStringArray:
			return locales
	return PackedStringArray(["en", "uk"])


func set_next_locale() -> void:
	var supported := get_supported_locales()
	if supported.is_empty():
		return
	var current := get_current_locale()
	var idx := supported.find(current)
	var next := supported[(maxi(idx, 0) + 1) % supported.size()]
	if _service:
		_service.set_locale(StringName(next), true)
	else:
		TranslationServer.set_locale(next)
		locale_updated.emit(StringName(next))


func _on_locale_changed(locale: StringName) -> void:
	locale_updated.emit(locale)
