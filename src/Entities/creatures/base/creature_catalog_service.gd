class_name CreatureCatalogService
extends Node

## Runtime loader and accessor for the creature catalog.

const CreatureData = preload("res://src/Entities/creatures/base/creature_data.gd")

@export var catalog: Resource
@export_file("*.tres") var catalog_resource_path: String = "res://src/Entities/creatures/resources/creature_catalog.tres"


func _ready() -> void:
	ensure_catalog_loaded()


func ensure_catalog_loaded() -> bool:
	if catalog == null:
		catalog = load(catalog_resource_path)
		if catalog == null:
			push_error(
				"CreatureCatalogService: failed to load catalog at '%s'." % catalog_resource_path
			)
			return false

	catalog.call("rebuild_indices")
	return true


func get_catalog() -> Resource:
	if catalog == null:
		if not ensure_catalog_loaded():
			return null
	return catalog


func get_by_id(creature_id: String) -> CreatureData:
	var active_catalog: Resource = get_catalog()
	if active_catalog == null:
		return null
	var data: CreatureData = active_catalog.call("get_by_id", creature_id) as CreatureData
	if data == null:
		push_warning("CreatureCatalogService: missing creature_id '%s'." % creature_id)
	return data


func get_by_type(creature_type: CreatureData.CreatureType) -> Array[CreatureData]:
	var active_catalog: Resource = get_catalog()
	if active_catalog == null:
		return []
	return active_catalog.call("get_by_type", creature_type) as Array[CreatureData]


func get_by_source_category(source_category: String) -> Array[CreatureData]:
	var active_catalog: Resource = get_catalog()
	if active_catalog == null:
		return []
	return active_catalog.call("get_by_source_category", source_category) as Array[CreatureData]
