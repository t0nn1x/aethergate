class_name PlayerEquipmentComponent
extends Node

## Manages the player's 5 equipment slots.
## Child node of the Player scene — added alongside PlayerVisualComponent.
## Emits equipment_changed when a slot changes.

signal equipment_changed(slot: EquipmentData.EquipmentSlot, item: EquipmentData)

@export var equipment_data: PlayerEquipmentData = PlayerEquipmentData.new()


func _ready() -> void:
	if equipment_data == null:
		equipment_data = PlayerEquipmentData.new()
	# Restore saved equipment from profile on startup
	var saved: PlayerEquipmentData = PlayerProfileService.load_equipment()
	if saved != null:
		equipment_data = saved
	# Auto-save whenever a slot changes
	equipment_changed.connect(_on_equipment_changed)


func _on_equipment_changed(_slot: EquipmentData.EquipmentSlot, _item: EquipmentData) -> void:
	PlayerProfileService.save_equipment(equipment_data)


## Equip an item. Replaces whatever is currently in its slot.
func equip(item: EquipmentData) -> void:
	if item == null:
		return
	equipment_data.set_slot(item.slot, item)
	equipment_changed.emit(item.slot, item)


## Unequip the item in a slot. Sets slot to null.
func unequip(s: EquipmentData.EquipmentSlot) -> void:
	equipment_data.set_slot(s, null)
	equipment_changed.emit(s, null)


## Get the item currently in a slot, or null.
func get_item_in_slot(s: EquipmentData.EquipmentSlot) -> EquipmentData:
	return equipment_data.get_slot(s)


## Collect all skill_grants from all non-accessory slots.
func get_all_skill_grants() -> Array[SkillData]:
	var result: Array[SkillData] = []
	for item: EquipmentData in equipment_data.get_all_equipped():
		if item.slot == EquipmentData.EquipmentSlot.ACCESSORY:
			continue
		for skill: SkillData in item.skill_grants:
			result.append(skill)
	return result


## Sum stat_bonuses across all 5 slots. Returns a zeroed CombatStats if nothing equipped.
func get_total_stat_bonuses() -> CombatStats:
	var total: CombatStats = CombatStats.new()
	total.max_hp = 0
	total.max_energy = 0
	total.attack = 0.0
	total.defense = 0.0
	for item: EquipmentData in equipment_data.get_all_equipped():
		if item.stat_bonuses == null:
			continue
		total.max_hp += item.stat_bonuses.max_hp
		total.max_energy += item.stat_bonuses.max_energy
		total.attack += item.stat_bonuses.attack
		total.defense += item.stat_bonuses.defense
	return total


## Returns the PassiveEffectData from the accessory slot, or null.
func get_passive_effect() -> PassiveEffectData:
	var acc: AccessoryData = equipment_data.accessory
	if acc == null:
		return null
	return acc.passive_effect


## Returns the weapon's item_family_id, or empty StringName if no weapon equipped.
func get_weapon_family_id() -> StringName:
	if equipment_data.weapon == null:
		return &""
	return equipment_data.weapon.item_family_id
