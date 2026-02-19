class_name InventoryPanelMobile
extends InventoryPanel

@export_range(0.55, 0.98, 0.01) var inventory_board_width_ratio: float = 0.94
@export_range(0.45, 0.95, 0.01) var inventory_board_height_ratio: float = 0.74
@export_range(0.0, 260.0, 1.0) var inventory_upward_offset_pixels: float = 132.0
@export_range(24.0, 200.0, 1.0) var mobile_min_slot_size: float = 62.0
@export_range(32.0, 240.0, 1.0) var mobile_max_slot_size: float = 136.0


func _ready() -> void:
	upward_offset_pixels = inventory_upward_offset_pixels
	min_inventory_slot_size = maxf(min_inventory_slot_size, mobile_min_slot_size)
	max_inventory_slot_size = maxf(max_inventory_slot_size, mobile_max_slot_size)
	inventory_icon_size = maxf(inventory_icon_size, 44.0)
	inventory_count_font_size_mobile = maxi(inventory_count_font_size_mobile, 18)
	super._ready()


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_overlay_viewport_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	_set_mobile_inventory_only_mode()

	var edge_margin: float = clampf(minf(viewport_size.x, viewport_size.y) * 0.02, 10.0, 26.0)
	apply_overlay_margins(edge_margin, 0.0, 0.0, 0.0, inventory_upward_offset_pixels)

	_boards_row.add_theme_constant_override("separation", 0)
	_overlay_vbox.add_theme_constant_override("separation", 8)
	_boards_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var available_width: float = viewport_size.x - float(
		_content_margin.get_theme_constant("margin_left") + _content_margin.get_theme_constant("margin_right")
	)
	var available_height: float = viewport_size.y - float(
		_content_margin.get_theme_constant("margin_top") + _content_margin.get_theme_constant("margin_bottom")
	)
	available_width = maxf(available_width, 320.0)
	available_height = maxf(available_height, 360.0)

	var board_width_ratio: float = inventory_board_width_ratio
	var board_height_ratio: float = inventory_board_height_ratio
	if viewport_size.x > viewport_size.y:
		board_width_ratio = clampf(board_width_ratio * 0.82, 0.55, 0.95)
		board_height_ratio = clampf(board_height_ratio * 0.90, 0.45, 0.90)

	var board_width: float = clampf(available_width * board_width_ratio, 320.0, available_width)
	var board_height: float = clampf(available_height * board_height_ratio, 300.0, available_height)
	_inventory_board.custom_minimum_size = Vector2(board_width, board_height)
	_character_board.custom_minimum_size = Vector2.ZERO

	var is_portrait: bool = viewport_size.y > viewport_size.x
	_apply_title_styles_for_layout(viewport_size)
	var title_size: int = UiStyleApplier.resolve_font_size(title_style_profile, true, is_portrait)

	var inner_margin: float = clampf(board_width * 0.08, 20.0, 44.0)
	_inventory_margin.add_theme_constant_override("margin_left", int(round(inner_margin)))
	_inventory_margin.add_theme_constant_override("margin_top", int(round(inner_margin)))
	_inventory_margin.add_theme_constant_override("margin_right", int(round(inner_margin)))
	_inventory_margin.add_theme_constant_override("margin_bottom", int(round(inner_margin)))

	var inventory_section_height: float = board_height - inner_margin * 2.0
	_inventory_section.custom_minimum_size = Vector2(0.0, floor(maxf(120.0, inventory_section_height)))
	_inventory_section.size_flags_vertical = Control.SIZE_EXPAND_FILL

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
	inventory_area_height -= float(title_size + 16)

	var inv_separation: float = clampf(slot_spacing + 4.0, 8.0, 24.0)
	_inventory_grid.add_theme_constant_override("h_separation", int(round(inv_separation)))
	_inventory_grid.add_theme_constant_override("v_separation", int(round(inv_separation)))
	var inv_slot_width: float = (inventory_area_width - inv_separation * float(INVENTORY_COLUMNS - 1)) / float(INVENTORY_COLUMNS)
	var inv_slot_height: float = (inventory_area_height - inv_separation * float(INVENTORY_ROWS - 1)) / float(INVENTORY_ROWS)
	var inventory_slot_size: float = minf(inv_slot_width, inv_slot_height)
	inventory_slot_size = clampf(inventory_slot_size, mobile_min_slot_size, mobile_max_slot_size)
	inventory_slot_size = floor(inventory_slot_size)
	for slot_button in _inventory_slots:
		slot_button.custom_minimum_size = Vector2(inventory_slot_size, inventory_slot_size)
		_apply_inventory_slot_visual_layout(slot_button, inventory_slot_size)


func _set_mobile_inventory_only_mode() -> void:
	_skills_section.visible = false
	_character_board.visible = false
	_inventory_section.visible = true
	_inventory_board.visible = true
	_skills_section.custom_minimum_size = Vector2.ZERO
