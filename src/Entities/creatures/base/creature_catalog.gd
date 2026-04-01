class_name CreatureCatalog
extends Resource

## Catalog of all creature definitions available at runtime.

const CreatureData = preload("res://src/Entities/creatures/base/creature_data.gd")

@export var creatures: Array[CreatureData] = []

var _indices_ready: bool = false
var _index_by_id: Dictionary = {}
var _index_by_type: Dictionary = {}
var _index_by_source_category: Dictionary = {}


func rebuild_indices() -> void:
	_index_by_id.clear()
	_index_by_type.clear()
	_index_by_source_category.clear()
	_indices_ready = true

	for creature_data in creatures:
		if creature_data == null:
			continue

		var creature_id: String = creature_data.get_effective_creature_id()
		if _index_by_id.has(creature_id):
			push_warning(
				"CreatureCatalog: duplicate creature_id '%s' (keeping first)." % creature_id
			)
		else:
			_index_by_id[creature_id] = creature_data

		var type_key: int = int(creature_data.creature_type)
		if not _index_by_type.has(type_key):
			_index_by_type[type_key] = []
		(_index_by_type[type_key] as Array).append(creature_data)

		var source_category_key: String = creature_data.source_category.strip_edges().to_lower()
		if source_category_key.is_empty():
			source_category_key = String(CreatureData.CreatureType.keys()[creature_data.creature_type]).to_lower()
		if not _index_by_source_category.has(source_category_key):
			_index_by_source_category[source_category_key] = []
		(_index_by_source_category[source_category_key] as Array).append(creature_data)


func get_by_id(creature_id: String) -> CreatureData:
	_ensure_indices()
	var key: String = creature_id.strip_edges().to_lower()
	if key.is_empty():
		return null
	return _index_by_id.get(key, null) as CreatureData


func get_by_type(creature_type: CreatureData.CreatureType) -> Array[CreatureData]:
	_ensure_indices()
	if not _index_by_type.has(int(creature_type)):
		return _empty_creature_data_array()
	return _typed_duplicate(_index_by_type[int(creature_type)] as Array)


func get_by_source_category(source_category: String) -> Array[CreatureData]:
	_ensure_indices()
	var key: String = source_category.strip_edges().to_lower()
	if key.is_empty():
		return _empty_creature_data_array()
	if not _index_by_source_category.has(key):
		return _empty_creature_data_array()
	return _typed_duplicate(_index_by_source_category[key] as Array)


func get_all() -> Array[CreatureData]:
	return _typed_duplicate(creatures)


func _ensure_indices() -> void:
	if _indices_ready:
		return
	rebuild_indices()


func _typed_duplicate(values: Array) -> Array[CreatureData]:
	var typed: Array[CreatureData] = []
	for value in values:
		var creature_data: CreatureData = value as CreatureData
		if creature_data:
			typed.append(creature_data)
	return typed


func _empty_creature_data_array() -> Array[CreatureData]:
	var empty: Array[CreatureData] = []
	return empty
