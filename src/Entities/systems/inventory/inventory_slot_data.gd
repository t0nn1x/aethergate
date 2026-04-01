@tool
class_name InventorySlotData
extends Resource

var _item: Resource
var _amount: int = 0

@export var item: Resource:
	get:
		return _item
	set(value):
		_item = value
		_clamp_amount_to_item()

@export_range(0, 999, 1) var amount: int:
	get:
		return _amount
	set(value):
		_amount = maxi(0, value)
		_clamp_amount_to_item()


func is_empty() -> bool:
	return _item == null or _amount <= 0


func clear() -> void:
	_item = null
	_amount = 0


func _clamp_amount_to_item() -> void:
	if _item == null:
		# Keep amount when item is not yet assigned; resource deserialization
		# can set exported properties in non-deterministic order.
		_amount = maxi(0, _amount)
		return
	var max_stack: int = int(_item.get("max_stack"))
	_amount = mini(_amount, maxi(1, max_stack))
