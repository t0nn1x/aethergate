class_name AccessoryData
extends EquipmentData

## Equipment data for accessories. Grants a passive proc — no active skills.
## skill_grants must remain empty.

@export_group("Accessory")
@export var passive_effect: PassiveEffectData = null

func _init() -> void:
	slot = EquipmentSlot.ACCESSORY
