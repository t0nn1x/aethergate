class_name EquipmentData
extends ItemData

## Base class for all equippable items.
## Extends ItemData — inherits item_id, display_name, description, icon auto-resolve.

enum EquipmentSlot { WEAPON, HELMET, CHEST, BOOTS, ACCESSORY }
enum Rarity { COMMON, RARE, LEGENDARY }

@export_group("Equipment")
@export var slot: EquipmentSlot = EquipmentSlot.WEAPON
@export var rarity: Rarity = Rarity.COMMON
@export var required_level: int = 1

@export_group("Stats")
@export var stat_bonuses: CombatStats = null

@export_group("Skills")
## Skills granted to the player while this item is equipped.
## Count rules: Weapon = 1/2/3 (Common/Rare/Legendary), Armor = 1/2, Accessory = 0.
@export var skill_grants: Array[SkillData] = []
