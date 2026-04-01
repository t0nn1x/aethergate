extends Node

signal locale_changed(locale: StringName)

const PROFILE_SERVICE_PATH: NodePath = ^"/root/PlayerProfileService"
const TRANSLATION_FILE_TEMPLATE: String = "ui_%s.tres"
const DEFAULT_TRANSLATIONS: PackedStringArray = [
	"res://src/Localization/translations/ui_en.tres",
	"res://src/Localization/translations/ui_uk.tres",
]

@export var fallback_locale: StringName = &"en"
@export var supported_locales: PackedStringArray = ["en", "uk"]
@export_dir var translations_folder_path: String = "res://src/Localization/translations"

var _current_locale: StringName = StringName()
var _profile_service: Node
var _localized_messages_by_locale: Dictionary = {}


func _ready() -> void:
	_profile_service = get_node_or_null(PROFILE_SERVICE_PATH)
	_register_translations_from_files()
	var startup_locale: StringName = _resolve_startup_locale()
	set_locale(startup_locale, false)


func get_current_locale() -> StringName:
	if _current_locale == StringName():
		return _resolve_supported_locale(fallback_locale)
	return _current_locale


func get_supported_locales() -> PackedStringArray:
	return supported_locales


func translate_key(key: StringName) -> String:
	var key_text: String = String(key)
	var current_locale_code: String = String(get_current_locale()).strip_edges().to_lower()
	var localized_text: String = _lookup_message(current_locale_code, key_text)
	if not localized_text.is_empty():
		return localized_text

	var fallback_code: String = String(_resolve_supported_locale(fallback_locale)).strip_edges().to_lower()
	localized_text = _lookup_message(fallback_code, key_text)
	if not localized_text.is_empty():
		return localized_text

	return key_text


func set_locale(locale_code: StringName, persist: bool = true) -> void:
	var resolved_locale: StringName = _resolve_supported_locale(locale_code)
	if resolved_locale == _current_locale:
		if persist:
			_persist_locale_preference(resolved_locale)
		return

	_current_locale = resolved_locale
	TranslationServer.set_locale(String(_current_locale))
	if OS.is_debug_build():
		print(
			"[FIX][Localization] locale_set=%s sample_ui.main.play=%s"
			% [String(_current_locale), tr("ui.main.play")]
		)
	if persist:
		_persist_locale_preference(_current_locale)
	locale_changed.emit(_current_locale)


func _resolve_startup_locale() -> StringName:
	var saved_locale: StringName = _load_saved_locale()
	if saved_locale != StringName():
		return _resolve_supported_locale(saved_locale)

	var os_locale: StringName = StringName(OS.get_locale())
	if os_locale != StringName():
		return _resolve_supported_locale(os_locale)

	return _resolve_supported_locale(fallback_locale)


func _resolve_supported_locale(locale_code: StringName) -> StringName:
	var normalized: String = String(locale_code).strip_edges().to_lower()
	if normalized.is_empty():
		normalized = String(fallback_locale).strip_edges().to_lower()
	if normalized.is_empty():
		normalized = "en"

	if supported_locales.has(normalized):
		return StringName(normalized)

	var language_only: String = normalized.get_slice("_", 0).get_slice("-", 0)
	if not language_only.is_empty() and supported_locales.has(language_only):
		return StringName(language_only)

	var fallback: String = String(fallback_locale).strip_edges().to_lower()
	if supported_locales.has(fallback):
		return StringName(fallback)
	if not supported_locales.is_empty():
		return StringName(supported_locales[0])
	return StringName("en")


func _load_saved_locale() -> StringName:
	if _profile_service == null:
		return StringName()
	if not _profile_service.has_method("get_preferred_locale"):
		return StringName()
	return StringName(String(_profile_service.call("get_preferred_locale")))


func _persist_locale_preference(locale_code: StringName) -> void:
	if _profile_service == null:
		return
	if not _profile_service.has_method("set_preferred_locale"):
		return
	_profile_service.call("set_preferred_locale", locale_code)


func _register_translations_from_files() -> void:
	_localized_messages_by_locale.clear()
	for locale_code_variant in supported_locales:
		var locale_code: String = String(locale_code_variant).strip_edges().to_lower()
		if locale_code.is_empty():
			continue

		var translation_path: String = _build_translation_path(locale_code)
		var parsed_messages: Dictionary = _load_messages_from_translation_file(translation_path)
		if not parsed_messages.is_empty():
			_localized_messages_by_locale[locale_code] = parsed_messages
		elif OS.is_debug_build():
			push_warning(
				"[FIX][Localization] Failed to parse translation messages for locale '%s': %s"
				% [locale_code, translation_path]
			)

		var translation: Translation = load(translation_path) as Translation
		if translation == null:
			if OS.is_debug_build():
				push_warning(
					"[FIX][Localization] Failed to load translation resource for locale '%s': %s"
					% [locale_code, translation_path]
				)
			continue

		var translation_locale: String = String(translation.locale).strip_edges().to_lower()
		if translation_locale.is_empty():
			translation.locale = locale_code
		TranslationServer.add_translation(translation)
		print(
			"[FIX][Localization] loaded locale=%s path=%s"
			% [String(translation.locale).strip_edges().to_lower(), translation_path]
		)


func _build_translation_path(locale_code: String) -> String:
	var normalized_locale: String = locale_code.strip_edges().to_lower()
	var file_name: String = TRANSLATION_FILE_TEMPLATE % normalized_locale
	return "%s/%s" % [translations_folder_path.trim_suffix("/"), file_name]


func _lookup_message(locale_code: String, key_text: String) -> String:
	var messages_variant: Variant = _localized_messages_by_locale.get(locale_code, {})
	if not (messages_variant is Dictionary):
		return ""
	var messages: Dictionary = messages_variant as Dictionary
	if not messages.has(key_text):
		return ""
	return String(messages.get(key_text, ""))


func _load_messages_from_translation_file(translation_path: String) -> Dictionary:
	var messages: Dictionary = {}
	if not FileAccess.file_exists(translation_path):
		return messages

	var file: FileAccess = FileAccess.open(translation_path, FileAccess.READ)
	if file == null:
		return messages

	var in_messages_block: bool = false
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if not in_messages_block:
			if line.begins_with("messages = {"):
				in_messages_block = true
			continue
		if line == "}":
			break
		if not line.begins_with("\""):
			continue

		var key_end: int = line.find("\":")
		if key_end <= 1:
			continue
		var key_text: String = line.substr(1, key_end - 1)
		var value_start: int = line.find("\"", key_end + 2)
		if value_start < 0:
			continue
		var value_end: int = line.rfind("\"")
		if value_end <= value_start:
			continue
		var value_text: String = line.substr(value_start + 1, value_end - value_start - 1)
		value_text = value_text.replace("\\\"", "\"").replace("\\\\", "\\")
		messages[key_text] = value_text

	return messages
