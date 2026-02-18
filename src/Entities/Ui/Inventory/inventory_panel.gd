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


func _ready() -> void:
	if content_margin_path == NodePath():
		content_margin_path = NodePath("%ContentMargin")
	super._ready()
	_rebuild_inventory_slots()
	_cache_character_slots()
	_apply_textures()
	_apply_responsive_layout()
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
