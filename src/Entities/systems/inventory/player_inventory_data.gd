@tool
class_name PlayerInventoryData
extends Resource

const INVENTORY_SLOT_DATA_SCRIPT := preload("res://src/Entities/systems/inventory/inventory_slot_data.gd")
const FIXED_SLOT_COUNT: int = 20

var _slot_count: int = FIXED_SLOT_COUNT
var _slots: Array[Resource] = []

@export_range(FIXED_SLOT_COUNT, FIXED_SLOT_COUNT, 1) var slot_count: int:
	get:
		return FIXED_SLOT_COUNT
	set(_value):
		_slot_count = FIXED_SLOT_COUNT
		_ensure_slot_count()

@export var slots: Array[Resource]:
	get:
		return _slots
	set(value):
		_slots = value
		_ensure_slot_count()


func _init() -> void:
	_slot_count = FIXED_SLOT_COUNT
	_ensure_slot_count()


func _ensure_slot_count() -> void:
	while _slots.size() < _slot_count:
		_slots.append(INVENTORY_SLOT_DATA_SCRIPT.new())
	if _slots.size() > _slot_count:
		_slots.resize(_slot_count)

	for slot_index in range(_slots.size()):
		if _slots[slot_index] == null:
			_slots[slot_index] = INVENTORY_SLOT_DATA_SCRIPT.new()


func get_slot(slot_index: int) -> Resource:
	_ensure_slot_count()
	if slot_index < 0 or slot_index >= _slots.size():
		return null
	return _slots[slot_index]


func get_slots() -> Array:
	_ensure_slot_count()
	return _slots


func get_total_pages(slots_per_page: int) -> int:
	var page_size: int = maxi(1, slots_per_page)
	return maxi(1, int(ceil(float(_slot_count) / float(page_size))))


func set_slot(slot_index: int, item: Resource, amount: int) -> bool:
	var slot: Resource = get_slot(slot_index)
	if slot == null:
		return false
	slot.set("item", item)
	slot.set("amount", amount)
	return true


func swap_slots(source_slot_index: int, target_slot_index: int) -> bool:
	_ensure_slot_count()
	if source_slot_index < 0 or source_slot_index >= _slots.size():
		return false
	if target_slot_index < 0 or target_slot_index >= _slots.size():
		return false
	if source_slot_index == target_slot_index:
		return false

	var source_slot: Resource = _slots[source_slot_index]
	var target_slot: Resource = _slots[target_slot_index]
	if source_slot == null or target_slot == null:
		return false
	if _is_slot_empty(source_slot):
		return false

	var source_item: Resource = _get_slot_item(source_slot)
	var source_amount: int = _get_slot_amount(source_slot)
	var target_item: Resource = _get_slot_item(target_slot)
	var target_amount: int = _get_slot_amount(target_slot)

	if target_item == null or target_amount <= 0:
		target_slot.set("item", source_item)
		target_slot.set("amount", source_amount)
		source_slot.set("amount", 0)
		source_slot.set("item", null)
		return true

	var source_item_id: String = _resolve_item_id(source_item)
	var target_item_id: String = _resolve_item_id(target_item)
	if source_item_id == target_item_id:
		var target_max_stack: int = maxi(1, int(target_item.get("max_stack")))
		var free_space: int = maxi(0, target_max_stack - target_amount)
		if free_space > 0:
			var to_transfer: int = mini(source_amount, free_space)
			target_slot.set("amount", target_amount + to_transfer)
			var remaining_source: int = source_amount - to_transfer
			source_slot.set("amount", remaining_source)
			if remaining_source <= 0:
				source_slot.set("item", null)
			return true

	source_slot.set("item", target_item)
	source_slot.set("amount", target_amount)
	target_slot.set("item", source_item)
	target_slot.set("amount", source_amount)
	return true


func add_item(item: Resource, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return maxi(amount, 0)

	var remaining: int = amount
	var target_item_id: String = _resolve_item_id(item)
	var max_stack: int = maxi(1, int(item.get("max_stack")))

	# Fill existing stacks first.
	if max_stack > 1:
		for slot in _slots:
			var slot_item: Resource = _get_slot_item(slot)
			if slot_item == null:
				continue
			if _resolve_item_id(slot_item) != target_item_id:
				continue

			var current_amount: int = _get_slot_amount(slot)
			var free_space: int = max_stack - current_amount
			if free_space <= 0:
				continue

			var to_add: int = mini(remaining, free_space)
			slot.set("amount", current_amount + to_add)
			remaining -= to_add
			if remaining <= 0:
				return 0

	# Then fill empty slots.
	for slot in _slots:
		if not _is_slot_empty(slot):
			continue

		var to_place: int = mini(max_stack, remaining)
		slot.set("item", item)
		slot.set("amount", to_place)
		remaining -= to_place
		if remaining <= 0:
			return 0

	return remaining


func remove_item_by_id(item_id: String, amount: int = 1) -> int:
	var normalized_id: String = item_id.strip_edges().to_lower()
	if normalized_id.is_empty() or amount <= 0:
		return 0

	var remaining: int = amount
	for slot in _slots:
		if remaining <= 0:
			break

		var slot_item: Resource = _get_slot_item(slot)
		if slot_item == null:
			continue
		if _resolve_item_id(slot_item) != normalized_id:
			continue

		var current_amount: int = _get_slot_amount(slot)
		var to_remove: int = mini(current_amount, remaining)
		slot.set("amount", current_amount - to_remove)
		remaining -= to_remove

		if int(slot.get("amount")) <= 0:
			slot.set("item", null)

	return amount - remaining


func get_item_count(item_id: String) -> int:
	var normalized_id: String = item_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return 0

	var total: int = 0
	for slot in _slots:
		var slot_item: Resource = _get_slot_item(slot)
		if slot_item == null:
			continue
		if _resolve_item_id(slot_item) != normalized_id:
			continue
		total += _get_slot_amount(slot)
	return total


func _resolve_item_id(item: Resource) -> String:
	if item == null:
		return ""
	var raw_id: String = str(item.get("item_id"))
	return raw_id.strip_edges().to_lower()


func _is_slot_empty(slot: Resource) -> bool:
	if slot == null:
		return true
	if slot.has_method("is_empty"):
		return bool(slot.call("is_empty"))
	return _get_slot_item(slot) == null or _get_slot_amount(slot) <= 0


func _get_slot_item(slot: Resource) -> Resource:
	if slot == null:
		return null
	return slot.get("item")


func _get_slot_amount(slot: Resource) -> int:
	if slot == null:
		return 0
	return maxi(0, int(slot.get("amount")))
