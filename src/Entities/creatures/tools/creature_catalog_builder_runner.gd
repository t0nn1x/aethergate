extends Node

func _ready() -> void:
	var builder_script: Script = load("res://src/Entities/creatures/tools/creature_catalog_builder.gd")
	if builder_script == null:
		push_error("CreatureCatalogBuilderRunner: failed to load builder script.")
		get_tree().quit()
		return
	var builder: RefCounted = builder_script.new()
	var summary: Dictionary = builder.build_catalog()
	print("CreatureCatalogBuilder runner completed: %s" % summary)
	get_tree().quit()
