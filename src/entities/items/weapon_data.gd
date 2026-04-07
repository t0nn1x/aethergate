class_name WeaponData
extends EquipmentData

## Equipment data for weapons. slot is always WEAPON.
## item_family_id is used by MasteryService to track mastery per weapon type.

@export_group("Weapon")
@export var item_family_id: StringName = &"swords"
@export var weapon_visual_id: StringName = &""

func _init() -> void:
	slot = EquipmentSlot.WEAPON
