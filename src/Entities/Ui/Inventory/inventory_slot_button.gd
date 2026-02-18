extends TextureButton

var _slot_index: int = -1
var _inventory_panel: Node


func configure(inventory_panel: Node, slot_index: int) -> void:
	_inventory_panel = inventory_panel
	_slot_index = slot_index


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _inventory_panel == null:
		return null
	if not _inventory_panel.has_method("build_slot_drag_data"):
		return null

	var drag_data: Variant = _inventory_panel.call("build_slot_drag_data", _slot_index)
	if drag_data == null:
		return null

	if _inventory_panel.has_method("begin_slot_drag_visual"):
		_inventory_panel.call("begin_slot_drag_visual", _slot_index)

	if _inventory_panel.has_method("create_slot_drag_preview"):
		var preview: Control = _inventory_panel.call("create_slot_drag_preview", drag_data) as Control
		if preview:
			set_drag_preview(preview)
	return drag_data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if _inventory_panel == null:
		return false
	if not _inventory_panel.has_method("can_drop_slot_drag_data"):
		return false
	return bool(_inventory_panel.call("can_drop_slot_drag_data", _slot_index, data))


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _inventory_panel == null:
		return
	if not _inventory_panel.has_method("drop_slot_drag_data"):
		return
	_inventory_panel.call("drop_slot_drag_data", _slot_index, data)


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return
	if _inventory_panel == null:
		return
	if not _inventory_panel.has_method("end_slot_drag_visual"):
		return
	_inventory_panel.call("end_slot_drag_visual", _slot_index)
