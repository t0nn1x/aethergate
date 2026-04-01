class_name InventoryPanel
extends AdaptiveOverlayPanel

signal inventory_toggled(is_open: bool)

const INVENTORY_COLUMNS: int = 5
const INVENTORY_ROWS: int = 4
const INVENTORY_SLOT_COUNT: int = INVENTORY_COLUMNS * INVENTORY_ROWS
const INVENTORY_SLOT_BUTTON_SCRIPT := preload("res://src/Ui/desktop/inventory/inventory_slot_button.gd")
const DRAG_DATA_TYPE_KEY: StringName = &"drag_type"
const DRAG_DATA_SOURCE_SLOT_KEY: StringName = &"source_slot_index"
const DRAG_DATA_SOURCE_PANEL_KEY: StringName = &"source_panel_id"
const DRAG_DATA_ICON_KEY: StringName = &"icon"
const DRAG_DATA_AMOUNT_KEY: StringName = &"amount"
const DRAG_DATA_TYPE_SLOT: StringName = &"inventory_slot"

@export var slot_texture: Texture2D = preload("res://src/Ui/Assets/UI-v1/Panels/Slots/F_U_SlotA2.png")
@export var circular_slot_texture: Texture2D = preload("res://src/Ui/Assets/UI-v1/Menu Buttons And Switch/Menu Buttons/button_slot.png")
@export var title_plate_texture: Texture2D = preload("res://src/Ui/Assets/UI-v1/Panels/Titles/F_UI_Title B.png")
@export var board_style_profile: UiPanelStyleProfile = preload("res://src/Ui/common/styles/profiles/inventory_board_style.tres")
@export var section_style_profile: UiPanelStyleProfile = preload("res://src/Ui/common/styles/profiles/inventory_section_style.tres")
@export var title_style_profile: UiTextStyleProfile = preload("res://src/Ui/common/styles/profiles/inventory_title_style.tres")
@export var localization_service_path: NodePath = ^"/root/LocalizationService"
@export var skills_title_text_key: StringName = &"ui.inventory.skills"
@export var inventory_title_text_key: StringName = &"ui.inventory.inventory"
@export var character_title_text_key: StringName = &"ui.inventory.character"

@export_range(0.50, 0.95, 0.01) var desktop_boards_height_ratio: float = 0.80
@export_range(0.48, 0.95, 0.01) var mobile_boards_height_ratio: float = 0.76
@export_range(0.15, 0.50, 0.01) var board_gap_ratio: float = 0.018
@export_range(0.06, 0.28, 0.01) var board_inner_margin_ratio: float = 0.10
@export_range(0.0, 40.0, 1.0) var board_inner_margin_min: float = 16.0
@export_range(0.0, 80.0, 1.0) var board_inner_margin_max: float = 32.0
@export_range(0.20, 0.80, 0.01) var inventory_section_height_ratio: float = 0.50
@export_range(0.0, 32.0, 1.0) var slot_spacing: float = 8.0
@export_range(16.0, 128.0, 1.0) var min_inventory_slot_size: float = 28.0
@export_range(24.0, 160.0, 1.0) var max_inventory_slot_size: float = 88.0
@export_range(8.0, 64.0, 1.0) var inventory_icon_size: float = 32.0
@export_range(0.35, 1.0, 0.01) var inventory_icon_fill_ratio: float = 0.66
@export_range(0.50, 1.00, 0.01) var drag_preview_icon_scale: float = 0.88
@export_range(8, 36, 1) var inventory_count_font_size_desktop: int = 16
@export_range(8, 36, 1) var inventory_count_font_size_mobile: int = 14
@export_range(0.0, 40.0, 1.0) var inventory_character_title_top_spacing: float = 10.0
@export var inventory_count_text_color: Color = Color(0.96, 0.97, 1.0, 1.0)
@export var inventory_count_outline_color: Color = Color(0.0, 0.0, 0.0, 0.95)
@export_range(0.0, 220.0, 1.0) var upward_offset_pixels: float = 78.0

@onready var _content_margin: MarginContainer = %ContentMargin
@onready var _root_control: Control = $Root
@onready var _overlay_vbox: VBoxContainer = %OverlayVBox
@onready var _boards_row: HBoxContainer = %BoardsRow
@onready var _inventory_board: Control = %InventoryBoard
@onready var _inventory_background: Panel = %InventoryBackground
@onready var _skills_section: Panel = %SkillsSection
@onready var _inventory_section: Panel = %InventorySection
@onready var _skills_title: Label = %SkillsTitle
@onready var _inventory_title: Label = %InventoryTitle
@onready var _inventory_grid: GridContainer = %InventoryGrid
@onready var _inventory_section_margin: MarginContainer = %InventorySectionMargin
@onready var _inventory_margin: MarginContainer = %InventoryMargin
@onready var _character_board: Control = %CharacterBoard
@onready var _character_background: Panel = %CharacterBackground
@onready var _character_title: Label = %CharacterTitle
@onready var _character_margin: MarginContainer = %CharacterMargin
@onready var _character_slots_root: VBoxContainer = %CharacterSlots

var _inventory_slots: Array[TextureButton] = []
var _character_slots: Dictionary = {}
var _inventory_component: Node
var _active_drag_source_slot_index: int = -1
var _touch_drag_source_slot_index: int = -1
var _touch_drag_payload: Dictionary = {}
var _touch_drag_preview: Control
var _merged_boards_background: Panel
var _localization_service: Node


func _ready() -> void:
	if content_margin_path == NodePath():
		content_margin_path = NodePath("%ContentMargin")
	super._ready()
	_rebuild_inventory_slots()
	_cache_character_slots()
	_apply_windows_section_order()
	_ensure_windows_merged_board_background()
	_apply_textures()
	_setup_localization()
	_apply_responsive_layout()
	_refresh_inventory_slots_from_data()
	set_inventory_open(false)


func toggle_inventory() -> void:
	set_inventory_open(not visible)


func set_inventory_open(is_open: bool) -> void:
	if visible == is_open:
		return
	if not is_open:
		_finish_touch_slot_drag(Vector2.ZERO, false)
	visible = is_open
	_sync_windows_merged_board_background()
	inventory_toggled.emit(visible)
	if visible:
		_apply_responsive_layout()
		_refresh_inventory_slots_from_data()


func set_inventory_component(component: Node) -> void:
	var next_component: Node = component
	if _inventory_component == next_component:
		_refresh_inventory_slots_from_data()
		return

	_disconnect_inventory_component_signals()
	_inventory_component = next_component
	_connect_inventory_component_signals()
	_refresh_inventory_slots_from_data()


func build_slot_drag_data(slot_index: int) -> Variant:
	if _inventory_component == null:
		return null

	var slot_data: Resource = _get_inventory_slot_data(slot_index)
	if not _slot_has_item(slot_data):
		return null

	var item: Resource = slot_data.get("item") as Resource
	var amount: int = maxi(0, int(slot_data.get("amount")))
	var icon: Texture2D = _resolve_item_icon(item)
	return {
		DRAG_DATA_TYPE_KEY: DRAG_DATA_TYPE_SLOT,
		DRAG_DATA_SOURCE_SLOT_KEY: slot_index,
		DRAG_DATA_SOURCE_PANEL_KEY: get_instance_id(),
		DRAG_DATA_ICON_KEY: icon,
		DRAG_DATA_AMOUNT_KEY: amount
	}


func create_slot_drag_preview(data: Variant) -> Control:
	if not _is_valid_drag_payload(data):
		return null

	var payload: Dictionary = data
	var preview_size: float = clampf(inventory_icon_size * drag_preview_icon_scale, 12.0, 64.0)

	var preview_root: Control = Control.new()
	preview_root.custom_minimum_size = Vector2(preview_size, preview_size)
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon: Texture2D = payload.get(DRAG_DATA_ICON_KEY, null) as Texture2D
	if icon != null:
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.texture = icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var icon_side: float = clampf(preview_size, 12.0, 64.0)
		var icon_size: Vector2 = Vector2(icon_side, icon_side)
		icon_rect.custom_minimum_size = icon_size
		icon_rect.size = icon_size
		icon_rect.position = Vector2.ZERO
		preview_root.add_child(icon_rect)

	var amount: int = int(payload.get(DRAG_DATA_AMOUNT_KEY, 0))
	if amount > 1:
		var count_label: Label = Label.new()
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.text = "x%d" % amount
		count_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		count_label.offset_left = 2.0
		count_label.offset_top = 2.0
		count_label.offset_right = -2.0
		count_label.offset_bottom = -2.0
		count_label.add_theme_color_override("font_color", inventory_count_text_color)
		count_label.add_theme_color_override("font_outline_color", inventory_count_outline_color)
		count_label.add_theme_constant_override("outline_size", 1)
		count_label.add_theme_font_size_override(
			"font_size",
			inventory_count_font_size_mobile if is_mobile_platform() else inventory_count_font_size_desktop
		)
		if title_style_profile and title_style_profile.font:
			count_label.add_theme_font_override("font", title_style_profile.font)
		preview_root.add_child(count_label)

	return preview_root


func can_drop_slot_drag_data(target_slot_index: int, data: Variant) -> bool:
	if not _is_valid_drag_payload(data):
		return false
	if target_slot_index < 0 or target_slot_index >= INVENTORY_SLOT_COUNT:
		return false
	if _inventory_component == null:
		return false

	var payload: Dictionary = data
	var source_slot_index: int = int(payload.get(DRAG_DATA_SOURCE_SLOT_KEY, -1))
	if source_slot_index < 0 or source_slot_index >= INVENTORY_SLOT_COUNT:
		return false
	if source_slot_index == target_slot_index:
		return false
	if not _slot_has_item(_get_inventory_slot_data(source_slot_index)):
		return false
	return true


func drop_slot_drag_data(target_slot_index: int, data: Variant) -> void:
	if not can_drop_slot_drag_data(target_slot_index, data):
		return

	var payload: Dictionary = data
	var source_slot_index: int = int(payload.get(DRAG_DATA_SOURCE_SLOT_KEY, -1))
	if source_slot_index < 0:
		return
	_swap_inventory_slots(source_slot_index, target_slot_index)


func begin_touch_slot_drag(slot_index: int, screen_position: Vector2) -> bool:
	var drag_data: Variant = build_slot_drag_data(slot_index)
	if drag_data == null:
		return false

	_finish_touch_slot_drag(Vector2.ZERO, false)
	begin_slot_drag_visual(slot_index)
	_touch_drag_source_slot_index = slot_index
	_touch_drag_payload = drag_data
	_touch_drag_preview = create_slot_drag_preview(drag_data)
	if _touch_drag_preview:
		_touch_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root_control.add_child(_touch_drag_preview)
		_update_touch_drag_preview_position(screen_position)
	return true


func update_touch_slot_drag(screen_position: Vector2) -> void:
	_update_touch_drag_preview_position(screen_position)


func finish_touch_slot_drag(screen_position: Vector2) -> void:
	_finish_touch_slot_drag(screen_position, true)


func begin_slot_drag_visual(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _inventory_slots.size():
		return
	_active_drag_source_slot_index = slot_index
	_set_inventory_slot_visual(_inventory_slots[slot_index], null, 0)


func end_slot_drag_visual(slot_index: int) -> void:
	if _active_drag_source_slot_index < 0:
		return
	if slot_index != _active_drag_source_slot_index:
		return
	_active_drag_source_slot_index = -1
	_refresh_inventory_slots_from_data()


func get_inventory_slot_index_at_position(screen_position: Vector2) -> int:
	for slot_index in range(_inventory_slots.size()):
		var slot_button: TextureButton = _inventory_slots[slot_index]
		if slot_button == null:
			continue
		if not slot_button.is_visible_in_tree():
			continue
		if slot_button.get_global_rect().has_point(screen_position):
			return slot_index
	return -1


func _on_overlay_viewport_resized() -> void:
	_apply_responsive_layout()


func _apply_textures() -> void:
	var use_windows_merged_background: bool = _use_windows_desktop_merged_board_background()
	if use_windows_merged_background:
		_ensure_windows_merged_board_background()
		if _merged_boards_background:
			UiStyleApplier.apply_panel_style(_merged_boards_background, board_style_profile)
		UiStyleApplier.apply_panel_style(_character_background, section_style_profile)
	else:
		UiStyleApplier.apply_panel_style(_inventory_background, board_style_profile)
		UiStyleApplier.apply_panel_style(_character_background, board_style_profile)
	_sync_windows_merged_board_background_visibility()

	UiStyleApplier.apply_panel_style(_skills_section, section_style_profile)
	UiStyleApplier.apply_panel_style(_inventory_section, section_style_profile)
	_apply_title_styles_for_layout(get_overlay_viewport_size())

	for slot_button in _inventory_slots:
		_apply_slot_texture(slot_button, slot_texture)

	for slot_name in _character_slots.keys():
		var slot_button: TextureButton = _character_slots[slot_name] as TextureButton
		if slot_button == null:
			continue
		var texture_to_apply: Texture2D = circular_slot_texture if slot_name == "HeadSlot" else slot_texture
		_apply_slot_texture(slot_button, texture_to_apply)


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
	if _skills_title:
		_skills_title.text = _translate_key(skills_title_text_key)
	if _inventory_title:
		_inventory_title.text = _translate_key(inventory_title_text_key)
	if _character_title:
		_character_title.text = _translate_key(character_title_text_key)


func _apply_title_styles_for_layout(viewport_size: Vector2) -> void:
	var is_mobile: bool = is_mobile_platform()
	var is_portrait: bool = viewport_size.y > viewport_size.x
	UiStyleApplier.apply_label_style(_skills_title, title_style_profile, is_mobile, is_portrait)
	UiStyleApplier.apply_label_style(_inventory_title, title_style_profile, is_mobile, is_portrait)
	UiStyleApplier.apply_label_style(_character_title, title_style_profile, is_mobile, is_portrait)
	_apply_title_plate_style(_skills_title)
	_apply_title_plate_style(_inventory_title)
	_apply_title_plate_style(_character_title)


func _apply_title_plate_style(title_label: Label) -> void:
	if title_label == null:
		return
	if title_plate_texture == null:
		return

	var title_plate_style: StyleBoxTexture = StyleBoxTexture.new()
	title_plate_style.texture = title_plate_texture
	title_plate_style.texture_margin_left = 24.0
	title_plate_style.texture_margin_top = 6.0
	title_plate_style.texture_margin_right = 24.0
	title_plate_style.texture_margin_bottom = 6.0
	title_plate_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	title_plate_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	title_plate_style.content_margin_left = 18.0
	title_plate_style.content_margin_top = 2.0
	title_plate_style.content_margin_right = 18.0
	title_plate_style.content_margin_bottom = 2.0
	title_label.add_theme_stylebox_override("normal", title_plate_style)
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _apply_slot_texture(button: TextureButton, texture: Texture2D) -> void:
	if button == null:
		return
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_disabled = texture
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.focus_mode = Control.FOCUS_NONE


func _rebuild_inventory_slots() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()

	_inventory_slots.clear()
	_inventory_grid.columns = INVENTORY_COLUMNS
	_inventory_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for slot_index in range(INVENTORY_SLOT_COUNT):
		var slot_button: TextureButton = INVENTORY_SLOT_BUTTON_SCRIPT.new() as TextureButton
		slot_button.name = "InventorySlot_%02d" % (slot_index + 1)
		slot_button.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_button.size_flags_horizontal = Control.SIZE_FILL
		slot_button.size_flags_vertical = Control.SIZE_FILL
		slot_button.custom_minimum_size = Vector2(56.0, 56.0)
		if slot_button.has_method("configure"):
			slot_button.call("configure", self, slot_index)
		_inventory_grid.add_child(slot_button)
		_ensure_slot_visual_nodes(slot_button)
		_inventory_slots.append(slot_button)


func _cache_character_slots() -> void:
	_character_slots.clear()
	var expected_nodes: Array[String] = [
		"HeadSlot",
		"LeftShoulderSlot",
		"RightShoulderSlot",
		"LeftHandSlot",
		"RightHandSlot",
		"TorsoSlot",
		"LegsSlot",
		"LeftBootSlot",
		"RightBootSlot",
		"RingLeftSlot",
		"RingRightSlot",
		"RelicSlot"
	]
	for node_name in expected_nodes:
		var slot_node: TextureButton = _character_slots_root.find_child(node_name, true, false) as TextureButton
		if slot_node:
			_character_slots[node_name] = slot_node


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_overlay_viewport_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var edge_margin: float = clampf(minf(viewport_size.x, viewport_size.y) * 0.018, 6.0, 20.0)
	apply_overlay_margins(edge_margin, 0.0, 0.0, 0.0, upward_offset_pixels)

	var boards_gap: float = clampf(viewport_size.x * board_gap_ratio, 12.0, 36.0)
	if _use_windows_desktop_merged_board_background():
		boards_gap = maxf(0.0, boards_gap * 0.05)
	_boards_row.add_theme_constant_override("separation", int(round(boards_gap)))
	_overlay_vbox.add_theme_constant_override("separation", int(round(clampf(boards_gap * 0.9, 10.0, 28.0))))

	var is_mobile: bool = is_mobile_platform()
	var is_portrait: bool = viewport_size.y > viewport_size.x
	var board_height_ratio: float = mobile_boards_height_ratio if is_mobile else desktop_boards_height_ratio
	if is_portrait:
		board_height_ratio *= 0.88

	var available_width: float = viewport_size.x - float(_content_margin.get_theme_constant("margin_left") + _content_margin.get_theme_constant("margin_right"))
	var max_board_width_by_row: float = (available_width - boards_gap) * 0.5
	var board_height: float = clampf(viewport_size.y * board_height_ratio, 300.0, 760.0)
	var board_width: float = minf(max_board_width_by_row, board_height * 0.68)
	board_width = clampf(board_width, 260.0, 720.0)

	_inventory_board.custom_minimum_size = Vector2(board_width, board_height)
	_character_board.custom_minimum_size = Vector2(board_width, board_height)

	_apply_title_styles_for_layout(viewport_size)
	var title_size: int = UiStyleApplier.resolve_font_size(title_style_profile, is_mobile, is_portrait)
	var title_top_spacing: int = int(round(inventory_character_title_top_spacing))
	var inventory_section_top_margin: int = 12 + title_top_spacing
	if _use_windows_desktop_merged_board_background():
		inventory_section_top_margin = title_top_spacing
	_inventory_section_margin.add_theme_constant_override("margin_top", inventory_section_top_margin)

	var inner_margin: float = clampf(board_width * board_inner_margin_ratio, board_inner_margin_min, board_inner_margin_max)
	var rounded_inner_margin: int = int(round(inner_margin))
	_inventory_margin.add_theme_constant_override("margin_left", rounded_inner_margin)
	_inventory_margin.add_theme_constant_override("margin_top", rounded_inner_margin)
	_inventory_margin.add_theme_constant_override("margin_right", rounded_inner_margin)
	_inventory_margin.add_theme_constant_override("margin_bottom", rounded_inner_margin)
	_character_margin.add_theme_constant_override("margin_left", rounded_inner_margin)
	_character_margin.add_theme_constant_override("margin_top", rounded_inner_margin + title_top_spacing)
	_character_margin.add_theme_constant_override("margin_right", rounded_inner_margin)
	_character_margin.add_theme_constant_override("margin_bottom", rounded_inner_margin)

	var left_content_height: float = board_height - inner_margin * 2.0
	var sections_gap: float = clampf(board_width * 0.02, 8.0, 18.0)
	var usable_sections_height: float = maxf(0.0, left_content_height - sections_gap)
	var inventory_section_height: float = usable_sections_height * clampf(inventory_section_height_ratio, 0.2, 0.8)
	var skills_section_height: float = usable_sections_height - inventory_section_height
	_skills_section.custom_minimum_size = Vector2(0.0, floor(skills_section_height))
	_inventory_section.custom_minimum_size = Vector2(0.0, floor(inventory_section_height))

	var inventory_area_width: float = board_width - inner_margin * 2.0
	inventory_area_width -= float(
		_inventory_section_margin.get_theme_constant("margin_left")
		+ _inventory_section_margin.get_theme_constant("margin_right")
	)
	var inventory_area_height: float = inventory_section_height
	inventory_area_height -= float(
		_inventory_section_margin.get_theme_constant("margin_top")
		+ _inventory_section_margin.get_theme_constant("margin_bottom")
	)
	inventory_area_height -= float(title_size + 18)

	var inv_separation: float = clampf(slot_spacing, 4.0, 18.0)
	_inventory_grid.add_theme_constant_override("h_separation", int(round(inv_separation)))
	_inventory_grid.add_theme_constant_override("v_separation", int(round(inv_separation)))
	var inv_slot_width: float = (inventory_area_width - inv_separation * float(INVENTORY_COLUMNS - 1)) / float(INVENTORY_COLUMNS)
	var inv_slot_height: float = (inventory_area_height - inv_separation * float(INVENTORY_ROWS - 1)) / float(INVENTORY_ROWS)
	var inventory_slot_size: float = minf(inv_slot_width, inv_slot_height)
	var min_touch_size: float = 44.0 if is_mobile else 36.0
	inventory_slot_size = clampf(inventory_slot_size, maxf(min_inventory_slot_size, min_touch_size), max_inventory_slot_size)
	inventory_slot_size = floor(inventory_slot_size)
	for slot_button in _inventory_slots:
		slot_button.custom_minimum_size = Vector2(inventory_slot_size, inventory_slot_size)
		_apply_inventory_slot_visual_layout(slot_button, inventory_slot_size)

	_apply_character_slot_sizes(inventory_slot_size)
	_sync_windows_merged_board_background()
	call_deferred("_sync_windows_desktop_merged_layout")


func _use_windows_desktop_merged_board_background() -> bool:
	return OS.has_feature("windows") and not is_mobile_platform()


func _ensure_windows_merged_board_background() -> void:
	if not _use_windows_desktop_merged_board_background():
		return
	if _merged_boards_background != null and is_instance_valid(_merged_boards_background):
		return
	if _root_control == null or _content_margin == null:
		return

	var merged_background: Panel = Panel.new()
	merged_background.name = "MergedBoardsBackground"
	merged_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	merged_background.visible = false

	_root_control.add_child(merged_background)
	_root_control.move_child(merged_background, _content_margin.get_index())
	_merged_boards_background = merged_background


func _sync_windows_merged_board_background() -> void:
	_sync_windows_merged_board_background_visibility()
	_sync_windows_merged_board_background_rect()


func _sync_windows_desktop_merged_layout() -> void:
	_apply_windows_character_background_layout()
	_sync_windows_merged_board_background_rect()


func _apply_windows_section_order() -> void:
	if not OS.has_feature("windows"):
		return
	if _skills_section == null or _inventory_section == null:
		return
	var sections_parent: Node = _skills_section.get_parent()
	if sections_parent == null:
		return
	if _inventory_section.get_index() < _skills_section.get_index():
		return
	sections_parent.move_child(_inventory_section, 0)
	sections_parent.move_child(_skills_section, 1)


func _sync_windows_merged_board_background_visibility() -> void:
	var use_windows_merged_background: bool = _use_windows_desktop_merged_board_background()
	_inventory_background.visible = not use_windows_merged_background
	_character_background.visible = true
	if _merged_boards_background == null or not is_instance_valid(_merged_boards_background):
		return
	_merged_boards_background.visible = use_windows_merged_background and visible


func _sync_windows_merged_board_background_rect() -> void:
	if not _use_windows_desktop_merged_board_background():
		return
	if _merged_boards_background == null or not is_instance_valid(_merged_boards_background):
		return
	if _root_control == null or _inventory_board == null or _character_board == null:
		return

	var left_rect: Rect2 = _inventory_board.get_global_rect()
	var right_rect: Rect2 = _character_board.get_global_rect()
	var merged_rect: Rect2 = left_rect.merge(right_rect)
	if merged_rect.size.x <= 0.0 or merged_rect.size.y <= 0.0:
		return
	var root_rect: Rect2 = _root_control.get_global_rect()
	_merged_boards_background.position = (merged_rect.position - root_rect.position).round()
	_merged_boards_background.size = merged_rect.size.round()


func _apply_windows_character_background_layout() -> void:
	if _character_background == null or _character_board == null:
		return
	if not _use_windows_desktop_merged_board_background():
		_reset_character_background_full_rect()
		return
	if not visible:
		return

	var board_rect: Rect2 = _character_board.get_global_rect()
	if board_rect.size.x <= 0.0 or board_rect.size.y <= 0.0:
		return
	var title_rect: Rect2 = _character_title.get_global_rect()
	var slots_rect: Rect2 = _resolve_character_slots_global_rect()
	var has_character_content_rect: bool = (
		title_rect.size.x > 0.0
		and title_rect.size.y > 0.0
		and slots_rect.size.x > 0.0
		and slots_rect.size.y > 0.0
	)
	var content_rect: Rect2 = title_rect.merge(slots_rect) if has_character_content_rect else Rect2(Vector2.ZERO, Vector2.ZERO)

	var padding_bottom: float = clampf(float(_inventory_section_margin.get_theme_constant("margin_bottom")), 8.0, 24.0)
	var board_padding_left: float = clampf(float(_character_margin.get_theme_constant("margin_left")), 8.0, 40.0)
	var board_padding_top: float = clampf(float(_character_margin.get_theme_constant("margin_top")), 8.0, 40.0)
	var board_padding_right: float = clampf(float(_character_margin.get_theme_constant("margin_right")), 8.0, 40.0)
	var board_padding_bottom: float = clampf(float(_character_margin.get_theme_constant("margin_bottom")), 8.0, 40.0)
	var section_padding_left: float = clampf(float(_inventory_section_margin.get_theme_constant("margin_left")), 8.0, 24.0)
	var title_top_spacing: float = maxf(0.0, float(int(round(inventory_character_title_top_spacing))))
	var panel_padding_top: float = board_padding_top
	if _use_windows_desktop_merged_board_background():
		panel_padding_top = clampf(board_padding_top - title_top_spacing, 8.0, 40.0)

	var panel_left: float = maxf(0.0, minf(board_padding_left, section_padding_left) * 0.05)
	var panel_top: float = panel_padding_top
	var panel_right: float = board_rect.size.x - board_padding_right
	var left_sections_rect: Rect2 = _resolve_left_sections_global_rect()
	var target_height: float = left_sections_rect.size.y
	if target_height <= 0.0 and has_character_content_rect:
		var content_bottom_local: float = (content_rect.position.y - board_rect.position.y) + content_rect.size.y
		var panel_bottom_target: float = content_bottom_local + padding_bottom
		target_height = maxf(160.0, panel_bottom_target - panel_top)

	var max_panel_height: float = maxf(160.0, board_rect.size.y - panel_padding_top - board_padding_bottom)
	var panel_height: float = clampf(target_height, 160.0, max_panel_height)

	var desired_size: Vector2 = Vector2(
		maxf(160.0, panel_right - panel_left),
		panel_height
	).round()
	var local_position: Vector2 = Vector2(panel_left, panel_top).round()

	_character_background.anchor_left = 0.0
	_character_background.anchor_top = 0.0
	_character_background.anchor_right = 0.0
	_character_background.anchor_bottom = 0.0
	_character_background.offset_left = 0.0
	_character_background.offset_top = 0.0
	_character_background.offset_right = 0.0
	_character_background.offset_bottom = 0.0
	_character_background.position = local_position
	_character_background.size = desired_size


func _resolve_left_sections_global_rect() -> Rect2:
	if _skills_section == null and _inventory_section == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var skills_rect: Rect2 = _skills_section.get_global_rect() if _skills_section != null else Rect2(Vector2.ZERO, Vector2.ZERO)
	var inventory_rect: Rect2 = _inventory_section.get_global_rect() if _inventory_section != null else Rect2(Vector2.ZERO, Vector2.ZERO)
	var has_skills: bool = skills_rect.size.x > 0.0 and skills_rect.size.y > 0.0
	var has_inventory: bool = inventory_rect.size.x > 0.0 and inventory_rect.size.y > 0.0

	if has_skills and has_inventory:
		return skills_rect.merge(inventory_rect)
	if has_skills:
		return skills_rect
	if has_inventory:
		return inventory_rect
	return Rect2(Vector2.ZERO, Vector2.ZERO)


func _resolve_character_slots_global_rect() -> Rect2:
	var has_rect: bool = false
	var merged_rect: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)

	for slot_name in _character_slots.keys():
		var slot_button: TextureButton = _character_slots[slot_name] as TextureButton
		if slot_button == null:
			continue
		if not slot_button.is_visible_in_tree():
			continue
		var slot_rect: Rect2 = slot_button.get_global_rect()
		if slot_rect.size.x <= 0.0 or slot_rect.size.y <= 0.0:
			continue
		if not has_rect:
			merged_rect = slot_rect
			has_rect = true
		else:
			merged_rect = merged_rect.merge(slot_rect)

	if has_rect:
		return merged_rect
	return Rect2(Vector2.ZERO, Vector2.ZERO)


func _reset_character_background_full_rect() -> void:
	if _character_background == null:
		return
	_character_background.anchor_left = 0.0
	_character_background.anchor_top = 0.0
	_character_background.anchor_right = 1.0
	_character_background.anchor_bottom = 1.0
	_character_background.offset_left = 0.0
	_character_background.offset_top = 0.0
	_character_background.offset_right = 0.0
	_character_background.offset_bottom = 0.0


func _apply_character_slot_sizes(base_slot_size: float) -> void:
	var s: float = base_slot_size
	var sizes: Dictionary = {
		"HeadSlot": Vector2(s * 1.4, s * 1.4),
		"LeftShoulderSlot": Vector2(s * 0.9, s * 1.5),
		"RightShoulderSlot": Vector2(s * 0.9, s * 1.5),
		"LeftHandSlot": Vector2(s * 1.35, s * 0.72),
		"RightHandSlot": Vector2(s * 1.35, s * 0.72),
		"TorsoSlot": Vector2(s * 1.15, s * 2.05),
		"LegsSlot": Vector2(s * 1.0, s * 2.05),
		"LeftBootSlot": Vector2(s * 0.8, s * 1.5),
		"RightBootSlot": Vector2(s * 0.8, s * 1.5),
		"RingLeftSlot": Vector2(s * 0.62, s * 1.35),
		"RingRightSlot": Vector2(s * 0.62, s * 1.35),
		"RelicSlot": Vector2(s * 1.05, s * 1.55)
	}

	for slot_name in _character_slots.keys():
		var slot_button: TextureButton = _character_slots[slot_name] as TextureButton
		if slot_button == null:
			continue
		if not sizes.has(slot_name):
			continue
		slot_button.custom_minimum_size = (sizes[slot_name] as Vector2).round()


func _connect_inventory_component_signals() -> void:
	if _inventory_component == null:
		return

	var changed_callback: Callable = Callable(self, "_on_inventory_component_changed")
	if _inventory_component.has_signal("inventory_changed") and not _inventory_component.is_connected("inventory_changed", changed_callback):
		_inventory_component.connect("inventory_changed", changed_callback)

	var assigned_callback: Callable = Callable(self, "_on_inventory_component_changed")
	if _inventory_component.has_signal("inventory_data_assigned") and not _inventory_component.is_connected("inventory_data_assigned", assigned_callback):
		_inventory_component.connect("inventory_data_assigned", assigned_callback)


func _disconnect_inventory_component_signals() -> void:
	if _inventory_component == null:
		return

	var changed_callback: Callable = Callable(self, "_on_inventory_component_changed")
	if _inventory_component.has_signal("inventory_changed") and _inventory_component.is_connected("inventory_changed", changed_callback):
		_inventory_component.disconnect("inventory_changed", changed_callback)

	var assigned_callback: Callable = Callable(self, "_on_inventory_component_changed")
	if _inventory_component.has_signal("inventory_data_assigned") and _inventory_component.is_connected("inventory_data_assigned", assigned_callback):
		_inventory_component.disconnect("inventory_data_assigned", assigned_callback)


func _on_inventory_component_changed(_data: Variant = null) -> void:
	_refresh_inventory_slots_from_data()


func _refresh_inventory_slots_from_data() -> void:
	_clear_touch_drag_preview()
	_touch_drag_source_slot_index = -1
	_touch_drag_payload.clear()
	_active_drag_source_slot_index = -1
	var resolved_item_count: int = 0
	var resolved_icon_count: int = 0
	for slot_button in _inventory_slots:
		_set_inventory_slot_visual(slot_button, null, 0)

	if _inventory_component == null or not _inventory_component.has_method("get_slots"):
		if OS.is_debug_build():
			print("[InventoryPanel] no inventory component bound.")
		return

	var slots: Array = _inventory_component.call("get_slots")
	var max_slots: int = mini(slots.size(), _inventory_slots.size())
	for slot_index in range(max_slots):
		var slot_data: Resource = slots[slot_index] as Resource
		if slot_data == null:
			continue

		var slot_empty: bool = true
		if slot_data.has_method("is_empty"):
			slot_empty = bool(slot_data.call("is_empty"))
		else:
			var fallback_item: Resource = slot_data.get("item") as Resource
			slot_empty = fallback_item == null or int(slot_data.get("amount")) <= 0
		if slot_empty:
			continue

		var item: Resource = slot_data.get("item") as Resource
		var amount: int = maxi(0, int(slot_data.get("amount")))
		var icon: Texture2D = _resolve_item_icon(item)
		if item != null:
			resolved_item_count += 1
		if icon != null:
			resolved_icon_count += 1
		_set_inventory_slot_visual(_inventory_slots[slot_index], icon, amount)

	if OS.is_debug_build():
		print(
			"[InventoryPanel] resolved slots: %d items, %d icons (from %d slots)"
			% [resolved_item_count, resolved_icon_count, max_slots]
		)


func _finish_touch_slot_drag(screen_position: Vector2, perform_drop: bool) -> void:
	if _touch_drag_source_slot_index < 0:
		return

	var source_slot_index: int = _touch_drag_source_slot_index
	var payload: Dictionary = _touch_drag_payload.duplicate()

	_touch_drag_source_slot_index = -1
	_touch_drag_payload.clear()
	_clear_touch_drag_preview()

	var did_drop: bool = false
	if perform_drop:
		var target_slot_index: int = get_inventory_slot_index_at_position(screen_position)
		if target_slot_index >= 0 and can_drop_slot_drag_data(target_slot_index, payload):
			drop_slot_drag_data(target_slot_index, payload)
			did_drop = true

	if not did_drop:
		end_slot_drag_visual(source_slot_index)


func _clear_touch_drag_preview() -> void:
	if _touch_drag_preview == null:
		return
	if is_instance_valid(_touch_drag_preview):
		_touch_drag_preview.queue_free()
	_touch_drag_preview = null


func _update_touch_drag_preview_position(screen_position: Vector2) -> void:
	if _touch_drag_preview == null:
		return
	var preview_size: Vector2 = _touch_drag_preview.custom_minimum_size
	if preview_size.x <= 0.0 or preview_size.y <= 0.0:
		preview_size = _touch_drag_preview.size
	_touch_drag_preview.position = (screen_position - preview_size * 0.5).round()


func _swap_inventory_slots(source_slot_index: int, target_slot_index: int) -> void:
	if _inventory_component == null:
		return

	var did_swap: bool = false
	if _inventory_component.has_method("swap_slots"):
		did_swap = bool(_inventory_component.call("swap_slots", source_slot_index, target_slot_index))
	else:
		var inventory_data: Resource = null
		if _inventory_component.has_method("get_inventory_data"):
			inventory_data = _inventory_component.call("get_inventory_data") as Resource
		if inventory_data != null and inventory_data.has_method("swap_slots"):
			did_swap = bool(inventory_data.call("swap_slots", source_slot_index, target_slot_index))
			if did_swap and _inventory_component.has_method("notify_inventory_changed"):
				_inventory_component.call("notify_inventory_changed")

	if did_swap:
		_refresh_inventory_slots_from_data()


func _get_inventory_slot_data(slot_index: int) -> Resource:
	if _inventory_component == null:
		return null
	if not _inventory_component.has_method("get_slots"):
		return null
	var slots: Array = _inventory_component.call("get_slots")
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index] as Resource


func _slot_has_item(slot_data: Resource) -> bool:
	if slot_data == null:
		return false
	var slot_empty: bool = true
	if slot_data.has_method("is_empty"):
		slot_empty = bool(slot_data.call("is_empty"))
	else:
		var item: Resource = slot_data.get("item") as Resource
		var amount: int = int(slot_data.get("amount"))
		slot_empty = item == null or amount <= 0
	return not slot_empty


func _is_valid_drag_payload(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var payload: Dictionary = data
	var payload_type: String = str(payload.get(DRAG_DATA_TYPE_KEY, ""))
	if payload_type != String(DRAG_DATA_TYPE_SLOT):
		return false
	return int(payload.get(DRAG_DATA_SOURCE_PANEL_KEY, -1)) == get_instance_id()


func _resolve_item_icon(item: Resource) -> Texture2D:
	if item == null:
		return null

	var icon: Texture2D = null
	if item.has_method("get_icon_texture"):
		icon = item.call("get_icon_texture") as Texture2D
	if icon == null:
		icon = item.get("icon") as Texture2D
	if icon == null and not item.resource_path.is_empty():
		var loaded_item: Resource = load(item.resource_path)
		if loaded_item:
			if loaded_item.has_method("get_icon_texture"):
				icon = loaded_item.call("get_icon_texture") as Texture2D
			if icon == null:
				icon = loaded_item.get("icon") as Texture2D
	return icon


func _ensure_slot_visual_nodes(slot_button: TextureButton) -> void:
	if slot_button == null:
		return

	var icon_node: TextureRect = slot_button.get_node_or_null("ItemIcon") as TextureRect
	var icon_node_created: bool = false
	if icon_node == null:
		icon_node = TextureRect.new()
		icon_node.name = "ItemIcon"
		icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_node.z_index = 1
		slot_button.add_child(icon_node)
		icon_node_created = true

	var count_label: Label = slot_button.get_node_or_null("CountLabel") as Label
	var count_label_created: bool = false
	if count_label == null:
		count_label = Label.new()
		count_label.name = "CountLabel"
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.z_index = 2
		slot_button.add_child(count_label)
		count_label_created = true

	count_label.add_theme_color_override("font_color", inventory_count_text_color)
	count_label.add_theme_color_override("font_outline_color", inventory_count_outline_color)
	count_label.add_theme_constant_override("outline_size", 1)
	if title_style_profile and title_style_profile.font:
		count_label.add_theme_font_override("font", title_style_profile.font)

	if icon_node_created:
		icon_node.visible = false
	if count_label_created:
		count_label.text = ""


func _apply_inventory_slot_visual_layout(slot_button: TextureButton, slot_size: float) -> void:
	if slot_button == null:
		return
	_ensure_slot_visual_nodes(slot_button)

	var icon_node: TextureRect = slot_button.get_node_or_null("ItemIcon") as TextureRect
	var count_label: Label = slot_button.get_node_or_null("CountLabel") as Label
	if icon_node == null or count_label == null:
		return

	var max_icon_by_slot: float = floor(slot_size * inventory_icon_fill_ratio)
	var icon_side: float = minf(inventory_icon_size, max_icon_by_slot)
	icon_side = clampf(icon_side, 10.0, maxf(10.0, slot_size - 6.0))
	var icon_size_vec: Vector2 = Vector2(icon_side, icon_side)

	icon_node.custom_minimum_size = icon_size_vec
	icon_node.size = icon_size_vec
	icon_node.position = (Vector2(slot_size, slot_size) - icon_size_vec) * 0.5

	count_label.anchor_left = 0.0
	count_label.anchor_top = 0.0
	count_label.anchor_right = 1.0
	count_label.anchor_bottom = 1.0
	count_label.offset_left = 2.0
	count_label.offset_top = 2.0
	count_label.offset_right = -2.0
	count_label.offset_bottom = -2.0
	count_label.add_theme_font_size_override(
		"font_size",
		inventory_count_font_size_mobile if is_mobile_platform() else inventory_count_font_size_desktop
	)


func _set_inventory_slot_visual(slot_button: TextureButton, icon: Texture2D, amount: int) -> void:
	if slot_button == null:
		return
	_ensure_slot_visual_nodes(slot_button)

	var icon_node: TextureRect = slot_button.get_node_or_null("ItemIcon") as TextureRect
	var count_label: Label = slot_button.get_node_or_null("CountLabel") as Label
	if icon_node == null or count_label == null:
		return

	icon_node.texture = icon
	icon_node.visible = icon != null
	count_label.text = "" if icon == null or amount <= 0 else "x%d" % amount
