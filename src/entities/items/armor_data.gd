class_name ArmorData
extends EquipmentData

## Equipment data for armor pieces. slot must be HELMET, CHEST, or BOOTS.

func _init() -> void:
	slot = EquipmentSlot.HELMET  # default; set correct slot in .tres
