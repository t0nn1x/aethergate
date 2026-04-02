class_name PlayerSkinDefinition
extends Resource

## Serializable preset player skin entry.

@export var skin_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var overworld_idle_texture: Texture2D
@export var battle_idle_texture: Texture2D


func is_complete() -> bool:
	return (
		skin_id != StringName()
		and not display_name.strip_edges().is_empty()
		and overworld_idle_texture != null
		and battle_idle_texture != null
	)
