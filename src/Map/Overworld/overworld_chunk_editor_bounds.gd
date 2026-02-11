class_name OverworldChunkEditorBounds
extends RefCounted

## Editor-only bounds rendering and tile cleanup helpers for OverworldChunk.


static func queue_redraw_if_needed(owner: CanvasItem) -> void:
	if Engine.is_editor_hint():
		owner.queue_redraw()


static func draw_bounds(
	owner: CanvasItem,
	show_bounds: bool,
	chunk_size_tiles: int,
	tile_size: Vector2i,
	bounds_fill_color: Color,
	bounds_color: Color,
	bounds_line_width: float
) -> void:
	if not show_bounds or not Engine.is_editor_hint():
		return

	var size := chunk_pixel_size(chunk_size_tiles, tile_size)
	if size.x <= 0.0 or size.y <= 0.0:
		return

	if bounds_fill_color.a > 0.0:
		owner.draw_rect(Rect2(Vector2.ZERO, size), bounds_fill_color, true)
	var line_width := bounds_line_width if bounds_line_width > 0.0 else 1.0
	owner.draw_rect(Rect2(Vector2.ZERO, size), bounds_color, false, line_width)


static func enforce_tile_bounds(owner: Node, chunk_size_tiles: int) -> void:
	var max_x := max(chunk_size_tiles, 1)
	var max_y := max(chunk_size_tiles, 1)
	for child in owner.get_children():
		if child is not TileMapLayer:
			continue

		var layer := child as TileMapLayer
		for cell in layer.get_used_cells():
			if cell.x < 0 or cell.y < 0 or cell.x >= max_x or cell.y >= max_y:
				layer.erase_cell(cell)


static func chunk_pixel_size(chunk_size_tiles: int, tile_size: Vector2i) -> Vector2:
	return Vector2(
		chunk_size_tiles * tile_size.x,
		chunk_size_tiles * tile_size.y
	)
