class_name PlayerEquipmentComponentTest
extends RefCounted

## Tests for PlayerEquipmentComponent: equip, unequip, skill grants, stat totals.

const COMPONENT_SCRIPT: Script = preload(
	"res://src/entities/player/components/player_equipment_component.gd"
)
const EQUIPMENT_DATA_SCRIPT: Script = preload(
	"res://src/entities/items/equipment_data.gd"
)
const WEAPON_DATA_SCRIPT: Script = preload(
	"res://src/entities/items/weapon_data.gd"
)
const SKILL_DATA_SCRIPT: Script = preload(
	"res://src/entities/skills/combat/skill_data.gd"
)
const PASSIVE_EFFECT_SCRIPT: Script = preload(
	"res://src/entities/items/passive_effect_data.gd"
)
const ACCESSORY_DATA_SCRIPT: Script = preload(
	"res://src/entities/items/accessory_data.gd"
)

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()
	_test_equip_and_get_slot()
	_test_unequip_clears_slot()
	_test_get_all_skill_grants_empty()
	_test_get_all_skill_grants_with_weapon()
	_test_get_total_stat_bonuses_empty()
	_test_get_total_stat_bonuses_summed()
	_test_get_passive_effect_null_when_no_accessory()
	_test_get_weapon_family_id()
	_test_accessory_skill_grants_excluded()
	_print_summary()
	return _failures.is_empty()


func _test_equip_and_get_slot() -> void:
	var comp: Node = _make_component()
	var sword: WeaponData = _make_sword()
	comp.call("equip", sword)
	var result: EquipmentData = comp.call("get_item_in_slot", EquipmentData.EquipmentSlot.WEAPON)
	if result != sword:
		_add_failure("equip() then get_item_in_slot(WEAPON) should return the sword")


func _test_unequip_clears_slot() -> void:
	var comp: Node = _make_component()
	var sword: WeaponData = _make_sword()
	comp.call("equip", sword)
	comp.call("unequip", EquipmentData.EquipmentSlot.WEAPON)
	var result: EquipmentData = comp.call("get_item_in_slot", EquipmentData.EquipmentSlot.WEAPON)
	if result != null:
		_add_failure("unequip(WEAPON) should clear the slot to null")


func _test_get_all_skill_grants_empty() -> void:
	var comp: Node = _make_component()
	var skills: Array = comp.call("get_all_skill_grants")
	if skills.size() != 0:
		_add_failure("Empty loadout should return 0 skills, got %d" % skills.size())


func _test_get_all_skill_grants_with_weapon() -> void:
	var comp: Node = _make_component()
	var sword: WeaponData = _make_sword()
	var skill: SkillData = SKILL_DATA_SCRIPT.new()
	skill.skill_id = &"slash"
	skill.base_power = 15.0
	sword.skill_grants = [skill]
	comp.call("equip", sword)
	var skills: Array = comp.call("get_all_skill_grants")
	if skills.size() != 1:
		_add_failure("Sword with 1 skill grant should return 1 skill, got %d" % skills.size())


func _test_get_total_stat_bonuses_empty() -> void:
	var comp: Node = _make_component()
	var stats: CombatStats = comp.call("get_total_stat_bonuses")
	if stats == null:
		_add_failure("get_total_stat_bonuses() should never return null")
		return
	if stats.attack != 0.0 or stats.defense != 0.0 or stats.max_hp != 0 or stats.max_energy != 0:
		_add_failure("Empty loadout stats should be all zeroes")


func _test_get_total_stat_bonuses_summed() -> void:
	var comp: Node = _make_component()
	var sword: WeaponData = _make_sword()
	sword.stat_bonuses = CombatStats.new()
	sword.stat_bonuses.attack = 5.0
	sword.stat_bonuses.max_hp = 10
	comp.call("equip", sword)
	var stats: CombatStats = comp.call("get_total_stat_bonuses")
	if not is_equal_approx(stats.attack, 5.0):
		_add_failure("Expected total attack 5.0 from sword bonus, got %f" % stats.attack)
	if stats.max_hp != 10:
		_add_failure("Expected total max_hp 10 from sword bonus, got %d" % stats.max_hp)


func _test_get_passive_effect_null_when_no_accessory() -> void:
	var comp: Node = _make_component()
	var result: PassiveEffectData = comp.call("get_passive_effect")
	if result != null:
		_add_failure("get_passive_effect() should return null when no accessory equipped")


func _test_get_weapon_family_id() -> void:
	# Empty case: no weapon equipped
	var comp: Node = _make_component()
	var empty_family: StringName = comp.call("get_weapon_family_id")
	if empty_family != &"":
		_add_failure("No weapon: get_weapon_family_id() should return &\"\", got '%s'" % empty_family)

	# Populated case: sword equipped
	var sword: WeaponData = _make_sword()
	comp.call("equip", sword)
	var family: StringName = comp.call("get_weapon_family_id")
	if family != &"swords":
		_add_failure("With sword: get_weapon_family_id() should return &\"swords\", got '%s'" % family)


func _test_accessory_skill_grants_excluded() -> void:
	var comp: Node = _make_component()
	var acc: AccessoryData = ACCESSORY_DATA_SCRIPT.new()
	acc.slot = EquipmentData.EquipmentSlot.ACCESSORY
	# Give the accessory a skill grant (shouldn't happen in real game, but we test exclusion)
	var skill: SkillData = SKILL_DATA_SCRIPT.new()
	skill.skill_id = &"passive_test"
	acc.skill_grants = [skill]
	comp.call("equip", acc)
	var skills: Array = comp.call("get_all_skill_grants")
	if skills.size() != 0:
		_add_failure("Accessory skill grants should be excluded from get_all_skill_grants(), got %d skills" % skills.size())


# --- Helpers ---

func _make_component() -> Node:
	var comp: Node = COMPONENT_SCRIPT.new()
	return comp


func _make_sword() -> WeaponData:
	var sword: WeaponData = WEAPON_DATA_SCRIPT.new()
	sword.item_id = "iron_sword"
	sword.slot = EquipmentData.EquipmentSlot.WEAPON
	sword.item_family_id = &"swords"
	return sword


func _add_failure(msg: String) -> void:
	_failures.append(msg)


func _print_summary() -> void:
	for f: String in _failures:
		printerr("[PlayerEquipmentComponentTest][FAIL] %s" % f)
	if _failures.is_empty():
		print("PlayerEquipmentComponentTest: PASS")
	else:
		print("PlayerEquipmentComponentTest: FAIL (%d failures)" % _failures.size())
