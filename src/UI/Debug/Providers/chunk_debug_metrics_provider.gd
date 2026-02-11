class_name ChunkDebugMetricsProvider
extends RefCounted

## Collects chunk-loading debug lines for DebugOverlay.


func collect(chunk_manager: ChunkManager) -> Array[String]:
	var lines: Array[String] = []
	if chunk_manager == null:
		return lines

	var coords: Array[Vector2i] = chunk_manager.get_loaded_chunk_coords()
	var coord_strings: Array[String] = []
	for coord in coords:
		coord_strings.append("(%d,%d)" % [coord.x, coord.y])

	if coord_strings.size() > 0:
		lines.append("Loaded: %d %s" % [coord_strings.size(), ", ".join(coord_strings)])
	else:
		lines.append("Loaded: 0")

	return lines
