class_name OverworldChunkWaterShader
extends RefCounted

## Shared water shader assignment for overworld chunks.

static var _water_material: ShaderMaterial = null


static func apply_to_chunk(chunk: OverworldChunk, base_layer_name: String = "Base") -> void:
	if _water_material == null:
		var shader := load("res://src/World/overworld/Shaders/water.gdshader") as Shader
		if shader:
			_water_material = ShaderMaterial.new()
			_water_material.shader = shader
		else:
			push_warning("OverworldChunk: water.gdshader not found")
			return

	var base_layer := chunk.get_node_or_null(base_layer_name) as TileMapLayer
	if base_layer:
		base_layer.material = _water_material
