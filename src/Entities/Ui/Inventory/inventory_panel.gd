class_name InventoryPanel
extends AdaptiveOverlayPanel

signal inventory_toggled(is_open: bool)

const INVENTORY_COLUMNS: int = 5
const INVENTORY_ROWS: int = 4
const INVENTORY_SLOT_COUNT: int = INVENTORY_COLUMNS * INVENTORY_ROWS

@export var slot_texture: Texture2D = preload("res://src/Entities/Ui/Assets/Gui-Hud/Panels/Slots/F_U_SlotA2.png")
@export var circular_slot_texture: Texture2D = preload("res://src/Entities/Ui/Assets/Gui-Hud/Menu Buttons And Switch/Menu Buttons/button_slot.png")
@export var board_style_profile: UiPanelStyleProfile = preload("res://src/Entities/Ui/Common/Styles/Profiles/inventory_board_style.tres")
@export var section_style_profile: UiPanelStyleProfile = preload("res://src/Entities/Ui/Common/Styles/Profiles/inventory_section_style.tres")
@export var title_style_profile: UiTextStyleProfile = preload("res://src/Entities/Ui/Common/Styles/Profiles/inventory_title_style.tres")

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
@export_range(8, 36, 1) var inventory_count_font_size_desktop: int = 16
@export_range(8, 36, 1) var inventory_count_font_size_mobile: int = 14
@export var inventory_count_text_color: Color = Color(0.96, 0.97, 1.0, 1.0)
@export var inventory_count_outline_color: Color = Color(0.0, 0.0, 0.0, 0.95)
@export_range(0.0, 220.0, 1.0) var upward_offset_pixels: float = 78.0

@onready var _content_margin: MarginContainer = %ContentMargin
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


func _ready() -> void:
	if content_margin_path == NodePath():
		content_margin_path = NodePath("%ContentMargin")
	super._ready()
	_rebuild_inventory_slots()
	_cache_character_slots()
	_apply_textures()
	_apply_responsive_layout()
	_refresh_inventory_slots_from_data()
	set_inventory_open(false)


func toggle_inventory() -> void:
	set_inventory_open(not visible)


func set_inventory_open(is_open: bool) -> void:
	if visible == is_open:
		return
	visible = is_open
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


func _on_overlay_viewport_resized() -> void:
	_apply_responsive_layout()


func _apply_textures() -> void:
	UiStyleApplier.apply_panel_style(_inventory_background, board_style_profile)
	UiStyleApplier.apply_panel_style(_character_background, board_style_profile)
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


func _apply_title_styles_for_layout(viewport_size: Vector2) -> void:
	var is_mobile: bool = is_mobile_platform()
	var is_portrait: bool = viewport_size.y > viewport_size.x
	UiStyleApplier.apply_label_style(_skills_title, title_style_profile, is_mobile, is_portrait)
	UiStyleApplier.apply_label_style(_inventory_title, title_style_profile, is_mobile, is_portrait)
	UiStyleApplier.apply_label_style(_character_title, title_style_profile, is_mobile, is_portrait)


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
		var slot_button: TextureButton = TextureButton.new()
		slot_button.name = "InventorySlot_%02d" % (slot_index + 1)
		slot_button.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_button.size_flags_horizontal = Control.SIZE_FILL
		slot_button.size_flags_vertical = Control.SIZE_FILL
		slot_button.custom_minimum_size = Vector2(56.0, 56.0)
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

	var inner_margin: float = clampf(board_width * board_inner_margin_ratio, board_inner_margin_min, board_inner_margin_max)
	for margin_container in [_inventory_margin, _character_margin]:
		margin_container.add_theme_constant_override("margin_left", int(round(inner_margin)))
		margin_container.add_theme_constant_override("margin_top", int(round(inner_margin)))
		margin_container.add_theme_constant_override("margin_right", int(round(inner_margin)))
		margin_container.add_theme_constant_override("margin_bottom", int(round(inner_margin)))

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
