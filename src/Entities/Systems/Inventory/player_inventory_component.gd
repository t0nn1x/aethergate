class_name PlayerInventoryComponent
extends Node

@export var inventory_data: Resource

signal inventory_data_assigned(data: Resource)
signal inventory_changed()


func _ready() -> void:
	if inventory_data == null:
		push_warning("PlayerInventoryComponent: inventory_data is not assigned.")
		return
	inventory_data_assigned.emit(inventory_data)


func get_inventory_data() -> Resource:
	return inventory_data


func get_slots() -> Array:
	if inventory_data == null:
		return []
	if inventory_data.has_method("get_slots"):
		return inventory_data.call("get_slots")
	return []


func get_slot_count() -> int:
	if inventory_data == null:
		return 0
	if inventory_data.has_method("get"):
		return int(inventory_data.get("slot_count"))
	return 0


func add_item(item: Resource, amount: int = 1) -> int:
	if inventory_data == null:
		return amount
	if inventory_data.has_method("add_item"):
		var leftover: int = int(inventory_data.call("add_item", item, amount))
		if leftover < amount:
			inventory_changed.emit()
		return leftover
	return amount


func remove_item_by_id(item_id: String, amount: int = 1) -> int:
	if inventory_data == null:
		return 0
	if inventory_data.has_method("remove_item_by_id"):
		var removed: int = int(inventory_data.call("remove_item_by_id", item_id, amount))
		if removed > 0:
			inventory_changed.emit()
		return removed
	return 0


func get_item_count(item_id: String) -> int:
	if inventory_data == null:
		return 0
	if inventory_data.has_method("get_item_count"):
		return int(inventory_data.call("get_item_count", item_id))
	return 0


func notify_inventory_changed() -> void:
	inventory_changed.emit()
