class_name PlayerSkinCatalog
extends Resource

## Runtime catalog of preset player skins.

@export var default_skin_id: StringName = &""
@export var skins: Array[PlayerSkinDefinition] = []

var _skins_by_id: Dictionary = {}


func rebuild_indices() -> void:
	_skins_by_id.clear()
	for skin in skins:
		if skin == null:
			continue
		var skin_id: String = String(skin.skin_id).strip_edges()
		if skin_id.is_empty():
			continue
		if _skins_by_id.has(skin_id):
			push_warning("PlayerSkinCatalog: duplicate skin_id '%s' (keeping first)." % skin_id)
			continue
		_skins_by_id[skin_id] = skin


func get_selectable_skins() -> Array[PlayerSkinDefinition]:
	rebuild_indices()
	var selectable: Array[PlayerSkinDefinition] = []
	for skin in skins:
		if skin != null and skin.is_complete():
			selectable.append(skin)
	return selectable


func get_skin(skin_id: StringName) -> PlayerSkinDefinition:
	rebuild_indices()
	var key: String = String(skin_id).strip_edges()
	if key.is_empty():
		return null
	return _skins_by_id.get(key, null) as PlayerSkinDefinition


func get_default_skin() -> PlayerSkinDefinition:
	var default_skin: PlayerSkinDefinition = get_skin(default_skin_id)
	if default_skin != null and default_skin.is_complete():
		return default_skin

	var selectable: Array[PlayerSkinDefinition] = get_selectable_skins()
	if not selectable.is_empty():
		return selectable[0]
	return null


func get_overworld_idle_texture(skin_id: StringName) -> Texture2D:
	var skin: PlayerSkinDefinition = get_skin(skin_id)
	if skin != null and skin.is_complete():
		return skin.overworld_idle_texture

	var default_skin: PlayerSkinDefinition = get_default_skin()
	if default_skin != null:
		return default_skin.overworld_idle_texture
	return null


func get_battle_idle_texture(skin_id: StringName) -> Texture2D:
	var skin: PlayerSkinDefinition = get_skin(skin_id)
	if skin != null and skin.is_complete():
		return skin.battle_idle_texture

	var default_skin: PlayerSkinDefinition = get_default_skin()
	if default_skin != null:
		return default_skin.battle_idle_texture
	return null
