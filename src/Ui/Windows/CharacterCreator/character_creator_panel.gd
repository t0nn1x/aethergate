class_name CharacterCreatorPanel
extends AdaptiveOverlayPanel

signal appearance_confirmed(appearance: Resource)
signal creation_cancelled()

const PREVIEW_IDLE_FRAMES := [1, 2, 3, 3]
const PREVIEW_IDLE_FRAME_STEP_SECONDS: float = 0.4

const PLAYER_APPEARANCE_DATA_SCRIPT := preload(
	"res://src/Entities/Player/Resources/player_appearance_data.gd"
)

const SLOT_HEAD: StringName = &"head"
const SLOT_BODY: StringName = &"body"
const SLOT_LEGS: StringName = &"legs"

@export var catalog: Resource = preload(
	"res://src/Entities/Player/Resources/player_cosmetic_catalog.tres"
)

@export var root_path: NodePath = ^"Root"
@export var content_margin_default_path: NodePath = ^"Root/ContentMargin"
@export var preview_area_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/PreviewArea"
@export var preview_root_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/PreviewArea/PreviewRoot"
@export var preview_fit_reference_size: Vector2 = Vector2(200.0, 100.0)
@export_range(1.0, 8.0, 0.1) var preview_scale_multiplier: float = 3.5
@export_range(1.0, 14.0, 0.1) var preview_min_scale: float = 1.0
@export_range(1.0, 14.0, 0.1) var preview_max_scale: float = 12.0
@export var preview_position_offset: Vector2 = Vector2(25.0, 0.0)
@export var head_prev_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/HeadPrevButton"
@export var head_next_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/HeadNextButton"
@export var body_prev_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/BodyPrevButton"
@export var body_next_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/BodyNextButton"
@export var legs_prev_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/LegsPrevButton"
@export var legs_next_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/LegsNextButton"
@export var head_value_label_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/HeadValueLabel"
@export var body_value_label_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/BodyValueLabel"
@export var legs_value_label_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/OptionsGrid/LegsValueLabel"
@export var randomize_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/BottomButtons/TopRow/RandomizeButton"
@export var cancel_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/BottomButtons/BottomRow/CancelButton"
@export var confirm_button_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/BottomButtons/TopRow/ConfirmButton"
@export var title_label_path: NodePath = ^"Root/ContentMargin/CenterContainer/Card/Padding/VStack/TitleBanner/BannerTexture/TitleLabel"
@export var localization_service_path: NodePath = ^"/root/LocalizationService"
@export var title_text_key: StringName = &"ui.creator.title"
@export var randomize_text_key: StringName = &"ui.creator.randomize"
@export var cancel_text_key: StringName = &"ui.creator.cancel"
@export var confirm_text_key: StringName = &"ui.creator.confirm"
@export var head_label_text_key: StringName = &"ui.creator.head"
@export var body_label_text_key: StringName = &"ui.creator.body"
@export var legs_label_text_key: StringName = &"ui.creator.legs"
@export var audio_service_path: NodePath = ^"/root/MusicPlayer"
@export_file("*.mp3", "*.wav", "*.ogg") var hover_sound_path: String = "res://src/Ui/Assets/Sounds/UI_Button_Click_2.mp3"
@export_file("*.mp3", "*.wav", "*.ogg") var click_sound_path: String = "res://src/Ui/Assets/Sounds/UI_Button_Click_8.mp3"
@export_range(-40.0, 12.0, 0.1) var hover_volume_db: float = -10.0
@export_range(-40.0, 12.0, 0.1) var click_volume_db: float = -3.0
@export var sfx_bus_name: String = "SFX"

@onready var _root: Control = get_node_or_null(root_path) as Control
@onready var _preview_area: Control = get_node_or_null(preview_area_path) as Control
@onready var _preview_root: Node2D = get_node_or_null(preview_root_path) as Node2D

@onready var _head_prev_button: Button = get_node_or_null(head_prev_button_path) as Button
@onready var _head_next_button: Button = get_node_or_null(head_next_button_path) as Button
@onready var _body_prev_button: Button = get_node_or_null(body_prev_button_path) as Button
@onready var _body_next_button: Button = get_node_or_null(body_next_button_path) as Button
@onready var _legs_prev_button: Button = get_node_or_null(legs_prev_button_path) as Button
@onready var _legs_next_button: Button = get_node_or_null(legs_next_button_path) as Button
@onready var _head_value_label: Label = get_node_or_null(head_value_label_path) as Label
@onready var _body_value_label: Label = get_node_or_null(body_value_label_path) as Label
@onready var _legs_value_label: Label = get_node_or_null(legs_value_label_path) as Label
@onready var _title_label: Label = get_node_or_null(title_label_path) as Label
@onready var _randomize_button: Button = get_node_or_null(randomize_button_path) as Button
@onready var _cancel_button: Button = get_node_or_null(cancel_button_path) as Button
@onready var _confirm_button: Button = get_node_or_null(confirm_button_path) as Button

@onready var _preview_weapon_back: Sprite2D = get_node_or_null(
	"Root/ContentMargin/CenterContainer/Card/Padding/VStack/PreviewArea/PreviewRoot/PreviewWeaponBack"
) as Sprite2D
@onready var _preview_legs: Sprite2D = get_node_or_null(
	"Root/ContentMargin/CenterContainer/Card/Padding/VStack/PreviewArea/PreviewRoot/PreviewLegs"
) as Sprite2D
@onready var _preview_body: Sprite2D = get_node_or_null(
	"Root/ContentMargin/CenterContainer/Card/Padding/VStack/PreviewArea/PreviewRoot/PreviewBody"
) as Sprite2D
@onready var _preview_head: Sprite2D = get_node_or_null(
	"Root/ContentMargin/CenterContainer/Card/Padding/VStack/PreviewArea/PreviewRoot/PreviewHead"
) as Sprite2D
@onready var _preview_weapon_front: Sprite2D = get_node_or_null(
	"Root/ContentMargin/CenterContainer/Card/Padding/VStack/PreviewArea/PreviewRoot/PreviewWeaponFront"
) as Sprite2D

var _current_appearance: Resource
var _head_ids: Array[StringName] = []
var _body_ids: Array[StringName] = []
var _legs_ids: Array[StringName] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _preview_idle_frame_index: int = 0
var _preview_idle_elapsed_seconds: float = 0.0
var _music_player_service: Node
var _localization_service: Node


func _ready() -> void:
	if content_margin_path == NodePath():
		content_margin_path = content_margin_default_path
	super._ready()

	_rng.randomize()
	_rebuild_ids()
	_setup_audio()
	_wire_ui_signals()
	_setup_localization()

	_current_appearance = _resolve_default_appearance()
	_refresh_preview()
	set_process(true)
	hide_panel()


func show_panel(initial_appearance: Resource = null) -> void:
	visible = true
	if initial_appearance:
		if initial_appearance.has_method("duplicate_data"):
			_current_appearance = initial_appearance.call("duplicate_data") as Resource
		else:
			_current_appearance = initial_appearance
	else:
		_current_appearance = _resolve_default_appearance()
	_validate_appearance()
	_reset_preview_idle_animation()
	_refresh_preview()
	call_deferred("_apply_layout")


func hide_panel() -> void:
	visible = false


func get_current_appearance() -> Resource:
	if _current_appearance == null:
		return null
	if _current_appearance.has_method("duplicate_data"):
		return _current_appearance.call("duplicate_data") as Resource
	return _current_appearance


func _on_overlay_viewport_resized() -> void:
	_apply_layout()


func _process(delta: float) -> void:
	if not visible:
		return
	_preview_idle_elapsed_seconds += maxf(delta, 0.0)
	if _preview_idle_elapsed_seconds < PREVIEW_IDLE_FRAME_STEP_SECONDS:
		return
	while _preview_idle_elapsed_seconds >= PREVIEW_IDLE_FRAME_STEP_SECONDS:
		_preview_idle_elapsed_seconds -= PREVIEW_IDLE_FRAME_STEP_SECONDS
		_preview_idle_frame_index = (_preview_idle_frame_index + 1) % PREVIEW_IDLE_FRAMES.size()
	_apply_preview_frame()


func _apply_layout() -> void:
	if not visible:
		return
	if _preview_area == null or _preview_root == null:
		return

	var viewport_size: Vector2 = get_overlay_viewport_size()
	var edge_margin: float = clampf(minf(viewport_size.x, viewport_size.y) * 0.03, 20.0, 72.0)
	apply_overlay_margins(edge_margin)

	var preview_rect: Rect2 = _preview_area.get_global_rect()
	_preview_root.global_position = preview_rect.position + preview_rect.size * 0.5 + preview_position_offset

	var reference_width: float = maxf(preview_fit_reference_size.x, 1.0)
	var reference_height: float = maxf(preview_fit_reference_size.y, 1.0)
	var scale_x: float = preview_rect.size.x / reference_width
	var scale_y: float = preview_rect.size.y / reference_height
	var fitted_scale: float = minf(scale_x, scale_y)
	var target_scale: float = clampf(
		fitted_scale * preview_scale_multiplier,
		preview_min_scale,
		preview_max_scale
	)
	_preview_root.scale = Vector2(target_scale, target_scale)


func _wire_ui_signals() -> void:
	_connect_button_signal(_head_prev_button, _on_head_prev_pressed)
	_connect_button_signal(_head_next_button, _on_head_next_pressed)
	_connect_button_signal(_body_prev_button, _on_body_prev_pressed)
	_connect_button_signal(_body_next_button, _on_body_next_pressed)
	_connect_button_signal(_legs_prev_button, _on_legs_prev_pressed)
	_connect_button_signal(_legs_next_button, _on_legs_next_pressed)
	_connect_button_signal(_randomize_button, _on_randomize_pressed)
	_connect_button_signal(_cancel_button, _on_cancel_pressed)
	_connect_button_signal(_confirm_button, _on_confirm_pressed)


func _setup_localization() -> void:
	_localization_service = get_node_or_null(localization_service_path)
	if (
		_localization_service
		and _localization_service.has_signal("locale_changed")
		and not _localization_service.is_connected("locale_changed", Callable(self, "_on_locale_changed"))
	):
		_localization_service.connect("locale_changed", Callable(self, "_on_locale_changed"))
	_apply_localized_texts()


func _on_locale_changed(_locale: StringName) -> void:
	_apply_localized_texts()


func _translate_key(key: StringName) -> String:
	if _localization_service and _localization_service.has_method("translate_key"):
		return String(_localization_service.call("translate_key", key))
	return tr(String(key))


func _apply_localized_texts() -> void:
	if _title_label:
		_title_label.text = _translate_key(title_text_key)
	if _randomize_button:
		_randomize_button.text = _translate_key(randomize_text_key)
	if _cancel_button:
		_cancel_button.text = _translate_key(cancel_text_key)
	if _confirm_button:
		_confirm_button.text = _translate_key(confirm_text_key)
	_update_value_labels()


func _connect_button_signal(button: Button, callback: Callable) -> void:
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	if not button.pressed.is_connected(_on_button_pressed_audio):
		button.pressed.connect(_on_button_pressed_audio)
	if not button.mouse_entered.is_connected(_on_button_hovered):
		button.mouse_entered.connect(_on_button_hovered)
	if not button.focus_entered.is_connected(_on_button_hovered):
		button.focus_entered.connect(_on_button_hovered)


func _setup_audio() -> void:
	_music_player_service = get_node_or_null(audio_service_path)
	if _music_player_service == null:
		push_warning("CharacterCreatorPanel: MusicPlayer service not found at '%s'." % audio_service_path)
		return

	if _music_player_service.has_method("configure_ui_sounds"):
		_music_player_service.call(
			"configure_ui_sounds",
			hover_sound_path,
			hover_volume_db,
			click_sound_path,
			click_volume_db,
			sfx_bus_name
		)


func _on_button_hovered() -> void:
	_play_hover_sound()


func _on_button_pressed_audio() -> void:
	_play_click_sound()


func _play_hover_sound() -> void:
	if _music_player_service and _music_player_service.has_method("play_ui_hover"):
		_music_player_service.call("play_ui_hover")


func _play_click_sound() -> void:
	if _music_player_service and _music_player_service.has_method("play_ui_click"):
		_music_player_service.call("play_ui_click")


func _rebuild_ids() -> void:
	if catalog == null or not catalog.has_method("get_ids_for_slot"):
		_head_ids.clear()
		_body_ids.clear()
		_legs_ids.clear()
		return
	_head_ids = _to_string_name_array(catalog.call("get_ids_for_slot", SLOT_HEAD))
	_body_ids = _to_string_name_array(catalog.call("get_ids_for_slot", SLOT_BODY))
	_legs_ids = _to_string_name_array(catalog.call("get_ids_for_slot", SLOT_LEGS))


func _resolve_default_appearance() -> Resource:
	if catalog and catalog.has_method("get_default_appearance"):
		return catalog.call("get_default_appearance") as Resource
	var fallback: Resource = PLAYER_APPEARANCE_DATA_SCRIPT.new()
	if fallback and fallback.has_method("ensure_defaults"):
		fallback.call("ensure_defaults")
	return fallback


func _validate_appearance() -> void:
	if _current_appearance == null:
		_current_appearance = _resolve_default_appearance()
	if catalog == null or not catalog.has_method("is_valid_id"):
		if _current_appearance and _current_appearance.has_method("ensure_defaults"):
			_current_appearance.call("ensure_defaults")
		return

	var defaults: Resource = _resolve_default_appearance()
	_validate_slot_id(SLOT_HEAD, "head_id", defaults)
	_validate_slot_id(SLOT_BODY, "body_id", defaults)
	_validate_slot_id(SLOT_LEGS, "legs_id", defaults)


func _validate_slot_id(slot_name: StringName, field_name: String, defaults: Resource) -> void:
	var current_id: StringName = StringName(str(_current_appearance.get(field_name)))
	var valid: bool = bool(catalog.call("is_valid_id", slot_name, current_id))
	if valid:
		return
	_current_appearance.set(field_name, StringName(str(defaults.get(field_name))))


func _on_head_prev_pressed() -> void:
	_cycle_slot(SLOT_HEAD, -1)


func _on_head_next_pressed() -> void:
	_cycle_slot(SLOT_HEAD, 1)


func _on_body_prev_pressed() -> void:
	_cycle_slot(SLOT_BODY, -1)


func _on_body_next_pressed() -> void:
	_cycle_slot(SLOT_BODY, 1)


func _on_legs_prev_pressed() -> void:
	_cycle_slot(SLOT_LEGS, -1)


func _on_legs_next_pressed() -> void:
	_cycle_slot(SLOT_LEGS, 1)


func _cycle_slot(slot: StringName, direction: int) -> void:
	var ids: Array[StringName] = _get_slot_ids(slot)
	if ids.is_empty() or _current_appearance == null:
		return

	var current_id: StringName = _get_slot_id(slot)
	var index: int = ids.find(current_id)
	if index < 0:
		index = 0
	index = posmod(index + direction, ids.size())
	_set_slot_id(slot, ids[index])
	_refresh_preview()


func _on_randomize_pressed() -> void:
	if _current_appearance == null:
		_current_appearance = _resolve_default_appearance()
	if not _head_ids.is_empty():
		_current_appearance.set("head_id", _head_ids[_rng.randi_range(0, _head_ids.size() - 1)])
	if not _body_ids.is_empty():
		_current_appearance.set("body_id", _body_ids[_rng.randi_range(0, _body_ids.size() - 1)])
	if not _legs_ids.is_empty():
		_current_appearance.set("legs_id", _legs_ids[_rng.randi_range(0, _legs_ids.size() - 1)])
	_refresh_preview()


func _on_cancel_pressed() -> void:
	hide_panel()
	creation_cancelled.emit()


func _on_confirm_pressed() -> void:
	if _current_appearance == null:
		_current_appearance = _resolve_default_appearance()
	hide_panel()
	var payload: Resource = _current_appearance
	if _current_appearance.has_method("duplicate_data"):
		payload = _current_appearance.call("duplicate_data") as Resource
	appearance_confirmed.emit(payload)


func _refresh_preview() -> void:
	if _current_appearance == null:
		return
	if catalog:
		if _preview_head:
			_preview_head.texture = _catalog_get_texture("get_head_texture", StringName(str(_current_appearance.get("head_id"))))
		if _preview_body:
			_preview_body.texture = _catalog_get_texture("get_body_texture", StringName(str(_current_appearance.get("body_id"))))
		if _preview_legs:
			_preview_legs.texture = _catalog_get_texture("get_legs_texture", StringName(str(_current_appearance.get("legs_id"))))
		if _preview_weapon_front:
			_preview_weapon_front.texture = _catalog_get_texture("get_weapon_front_texture", StringName(str(_current_appearance.get("weapon_visual_id"))))
			_preview_weapon_front.visible = _preview_weapon_front.texture != null
		if _preview_weapon_back:
			_preview_weapon_back.texture = _catalog_get_texture("get_weapon_back_texture", StringName(str(_current_appearance.get("weapon_visual_id"))))
			_preview_weapon_back.visible = _preview_weapon_back.texture != null

	for sprite in [_preview_head, _preview_body, _preview_legs, _preview_weapon_front, _preview_weapon_back]:
		if sprite == null:
			continue
		sprite.hframes = 4
	_apply_preview_frame()

	_update_value_labels()


func _catalog_get_texture(method_name: String, entry_id: StringName) -> Texture2D:
	if catalog == null or not catalog.has_method(method_name):
		return null
	return catalog.call(method_name, entry_id) as Texture2D


func _update_value_labels() -> void:
	if _current_appearance == null:
		return
	if _head_value_label:
		_head_value_label.text = _build_localized_slot_value(
			StringName(str(_current_appearance.get("head_id"))),
			head_label_text_key
		)
	if _body_value_label:
		_body_value_label.text = _build_localized_slot_value(
			StringName(str(_current_appearance.get("body_id"))),
			body_label_text_key
		)
	if _legs_value_label:
		_legs_value_label.text = _build_localized_slot_value(
			StringName(str(_current_appearance.get("legs_id"))),
			legs_label_text_key
		)


func _build_localized_slot_value(value: StringName, label_key: StringName) -> String:
	var fallback_label: String = _pretty_slot_value(StringName(str(label_key).trim_prefix("ui.creator.")))
	var localized_label: String = _translate_key(label_key)
	if localized_label == String(label_key):
		localized_label = fallback_label

	var raw_value: String = String(value).strip_edges()
	if raw_value.is_empty():
		return localized_label
	var parts: PackedStringArray = raw_value.split("_", false)
	if parts.size() < 2:
		return "%s %s" % [localized_label, _pretty_slot_value(value)]

	var suffix: String = parts[parts.size() - 1]
	if suffix.is_valid_int():
		return "%s %d" % [localized_label, int(suffix)]
	return "%s %s" % [localized_label, _pretty_slot_value(StringName(suffix))]


func _pretty_slot_value(value: StringName) -> String:
	return String(value).replace("_", " ").capitalize()


func _get_slot_ids(slot: StringName) -> Array[StringName]:
	match slot:
		SLOT_HEAD:
			return _head_ids
		SLOT_BODY:
			return _body_ids
		SLOT_LEGS:
			return _legs_ids
	return []


func _get_slot_id(slot: StringName) -> StringName:
	match slot:
		SLOT_HEAD:
			return StringName(str(_current_appearance.get("head_id")))
		SLOT_BODY:
			return StringName(str(_current_appearance.get("body_id")))
		SLOT_LEGS:
			return StringName(str(_current_appearance.get("legs_id")))
	return StringName()


func _set_slot_id(slot: StringName, next_id: StringName) -> void:
	match slot:
		SLOT_HEAD:
			_current_appearance.set("head_id", next_id)
		SLOT_BODY:
			_current_appearance.set("body_id", next_id)
		SLOT_LEGS:
			_current_appearance.set("legs_id", next_id)


func _to_string_name_array(value: Variant) -> Array[StringName]:
	var converted: Array[StringName] = []
	if not (value is Array):
		return converted
	var source: Array = value
	for entry in source:
		converted.append(StringName(str(entry)))
	return converted


func _reset_preview_idle_animation() -> void:
	_preview_idle_frame_index = 0
	_preview_idle_elapsed_seconds = 0.0


func _apply_preview_frame() -> void:
	var frame: int = 0
	if not PREVIEW_IDLE_FRAMES.is_empty():
		frame = PREVIEW_IDLE_FRAMES[_preview_idle_frame_index]
	for sprite in [_preview_head, _preview_body, _preview_legs, _preview_weapon_front, _preview_weapon_back]:
		if sprite == null:
			continue
		sprite.frame = frame
