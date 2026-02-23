extends InventoryPanel

@export_range(1.0, 2.5, 0.05) var macos_desktop_scale_multiplier: float = 1.85
@export_range(16.0, 256.0, 1.0) var macos_min_inventory_slot_size: float = 52.0
@export_range(24.0, 256.0, 1.0) var macos_max_inventory_slot_size: float = 168.0


func _ready() -> void:
	if not is_mobile_platform():
		min_inventory_slot_size = maxf(min_inventory_slot_size, macos_min_inventory_slot_size)
		max_inventory_slot_size = maxf(max_inventory_slot_size, macos_max_inventory_slot_size)
		inventory_icon_size = maxf(inventory_icon_size, 52.0)
		inventory_count_font_size_desktop = maxi(inventory_count_font_size_desktop, 20)
	super._ready()


func _use_windows_desktop_merged_board_background() -> bool:
	return not is_mobile_platform()


func _apply_windows_section_order() -> void:
	if _skills_section == null or _inventory_section == null:
		return
	var sections_parent: Node = _skills_section.get_parent()
	if sections_parent == null:
		return
	if _inventory_section.get_index() < _skills_section.get_index():
		return
	sections_parent.move_child(_inventory_section, 0)
	sections_parent.move_child(_skills_section, 1)


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
	var available_height: float = viewport_size.y - float(_content_margin.get_theme_constant("margin_top") + _content_margin.get_theme_constant("margin_bottom"))
	var max_board_width_by_row: float = (available_width - boards_gap) * 0.5
	var board_height: float = clampf(viewport_size.y * board_height_ratio, 300.0, 760.0)
	var board_width: float = minf(max_board_width_by_row, board_height * 0.68)
	board_width = clampf(board_width, 260.0, 720.0)

	if not is_mobile:
		var scaled_board_width: float = board_width * macos_desktop_scale_multiplier
		var scaled_board_height: float = board_height * macos_desktop_scale_multiplier
		var max_board_height_by_viewport: float = maxf(300.0, available_height)
		var width_fit_scale: float = max_board_width_by_row / maxf(scaled_board_width, 1.0)
		var height_fit_scale: float = max_board_height_by_viewport / maxf(scaled_board_height, 1.0)
		var fit_scale: float = minf(1.0, minf(width_fit_scale, height_fit_scale))
		board_width = scaled_board_width * fit_scale
		board_height = scaled_board_height * fit_scale

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
