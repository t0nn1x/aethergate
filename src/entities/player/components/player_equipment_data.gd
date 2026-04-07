@tool  # Must be the FIRST line of the file — before class_name
class_name PlayerEquipmentData
extends Resource

## Holds the player's 5 equipment slots.
## Saved to player_profile.cfg [equipment] section as item resource paths.
## @tool allows inspection in the Godot editor.

@export var weapon: WeaponData = null
@export var helmet: ArmorData = null
@export var chest: ArmorData = null
@export var boots: ArmorData = null
@export var accessory: AccessoryData = null


## Returns all equipped items as an array, filtering out empty slots.
func get_all_equipped() -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	for item: EquipmentData in [weapon, helmet, chest, boots, accessory]:
		if item != null:
			result.append(item)
	return result


## Returns the item in a given slot, or null if empty.
func get_slot(s: EquipmentData.EquipmentSlot) -> EquipmentData:
	match s:
		EquipmentData.EquipmentSlot.WEAPON:    return weapon
		EquipmentData.EquipmentSlot.HELMET:    return helmet
		EquipmentData.EquipmentSlot.CHEST:     return chest
		EquipmentData.EquipmentSlot.BOOTS:     return boots
		EquipmentData.EquipmentSlot.ACCESSORY: return accessory
	return null


## Sets a slot directly by slot enum. Validates slot type matches item.
func set_slot(s: EquipmentData.EquipmentSlot, item: EquipmentData) -> void:
	match s:
		EquipmentData.EquipmentSlot.WEAPON:
			weapon = item as WeaponData
		# Each armor branch only touches its own slot — the `else` clauses keep other slots
		# unchanged. This is intentional: set_slot(CHEST, x) must not affect helmet or boots.
		EquipmentData.EquipmentSlot.HELMET:
			helmet = item as ArmorData
		EquipmentData.EquipmentSlot.CHEST:
			chest  = item as ArmorData
		EquipmentData.EquipmentSlot.BOOTS:
			boots  = item as ArmorData
		EquipmentData.EquipmentSlot.ACCESSORY:
			accessory = item as AccessoryData
