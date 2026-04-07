# Equipment & Combat Integration — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the gear-driven skills system core — equipment resource classes, player equipment component, mastery service, snapshot wiring, and passive proc evaluation in combat.

**Architecture:** `EquipmentData extends ItemData` carries stat bonuses + skill grants. `PlayerEquipmentComponent` (Node, child of Player scene) holds the 5-slot loadout. `PlayerProgressionService.build_player_snapshot()` bakes equipment bonuses + mastery-resolved skills into the snapshot before combat starts. `CombatRoundResolver` evaluates passive procs from `CombatantSnapshot.passive_effect`. Mastery XP is awarded post-combat via `MasteryService`.

**Tech Stack:** Godot 4.6, GDScript, `.tres` resources, headless SceneTree tests, `ConfigFile` save format.

**Spec:** `docs/superpowers/specs/2026-04-07-items-skills-design.md`

---

## Chunk 1: Equipment Data Resources

### Task 1: EquipmentData base class

**Files:**
- Create: `src/entities/items/equipment_data.gd`

- [ ] **Step 1: Create `equipment_data.gd`**

```gdscript
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
```

- [ ] **Step 2: Verify no GDScript parse errors**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | findstr /i "error\|parse\|equipment_data"
```
Expected: No errors mentioning `equipment_data.gd`.

- [ ] **Step 3: Commit**

```bash
git add src/entities/items/equipment_data.gd
git commit -m "feat: add EquipmentData base resource class"
```

---

### Task 2: WeaponData, ArmorData, AccessoryData

**Files:**
- Create: `src/entities/items/weapon_data.gd`
- Create: `src/entities/items/armor_data.gd`
- Create: `src/entities/items/accessory_data.gd`
- Create: `src/entities/items/passive_effect_data.gd`

- [ ] **Step 1: Create `passive_effect_data.gd`**

```gdscript
class_name PassiveEffectData
extends Resource

## Passive proc effect granted by an Accessory.
## Evaluated by CombatRoundResolver after each phase.

enum PassiveEffectType {
	POISON_ON_HIT,   ## Deal value damage to defender each round after hit
	REGEN_ENERGY,    ## Restore value energy at start of player turn (always triggers)
	REFLECT_DAMAGE,  ## Reflect value% of incoming damage back to attacker
	THORNS,          ## Deal value flat damage when taking a hit
	LIFESTEAL        ## Heal value% of damage dealt
}

@export var effect_type: PassiveEffectType = PassiveEffectType.POISON_ON_HIT
@export_range(0.0, 1.0) var trigger_chance: float = 0.1
@export var value: float = 5.0
```

- [ ] **Step 2: Create `weapon_data.gd`**

```gdscript
class_name WeaponData
extends EquipmentData

## Equipment data for weapons. slot is always WEAPON.
## item_family_id is used by MasteryService to track mastery per weapon type.

@export_group("Weapon")
@export var item_family_id: StringName = &"swords"
@export var weapon_visual_id: StringName = &""

func _init() -> void:
	slot = EquipmentSlot.WEAPON
```

- [ ] **Step 3: Create `armor_data.gd`**

```gdscript
class_name ArmorData
extends EquipmentData

## Equipment data for armor pieces. slot must be HELMET, CHEST, or BOOTS.

func _init() -> void:
	slot = EquipmentSlot.HELMET  # default; set correct slot in .tres
```

- [ ] **Step 4: Create `accessory_data.gd`**

```gdscript
class_name AccessoryData
extends EquipmentData

## Equipment data for accessories. Grants a passive proc — no active skills.
## skill_grants must remain empty.

@export_group("Accessory")
@export var passive_effect: PassiveEffectData = null

func _init() -> void:
	slot = EquipmentSlot.ACCESSORY
```

- [ ] **Step 5: Verify parse — no errors**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | findstr /i "error\|parse\|weapon_data\|armor_data\|accessory"
```
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add src/entities/items/passive_effect_data.gd src/entities/items/weapon_data.gd src/entities/items/armor_data.gd src/entities/items/accessory_data.gd
git commit -m "feat: add WeaponData, ArmorData, AccessoryData, PassiveEffectData resources"
```

---

### Task 3: Seed item — Iron Sword `.tres`

**Files:**
- Create: `src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword.tres`

- [ ] **Step 1: Create `iron_sword.tres`**

Create the file at `src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword.tres` with this content:

```
[gd_resource type="Resource" script_class="WeaponData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/entities/items/weapon_data.gd" id="1_weapon"]

[resource]
script = ExtResource("1_weapon")
item_id = "iron_sword"
display_name = "Iron Sword"
description = "A sturdy iron sword. Reliable but unrefined."
slot = 0
rarity = 0
required_level = 1
item_family_id = &"swords"
weapon_visual_id = &"iron_sword"
skill_grants = []
```

Note: `slot = 0` = WEAPON, `rarity = 0` = COMMON. `skill_grants` will be populated once `slash.tres` exists (Task 5).

- [ ] **Step 2: Verify resource loads**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | findstr /i "error\|iron_sword"
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add src/entities/items/catalog/weapons/swords/iron_sword/
git commit -m "feat: add iron_sword seed item"
```

---

### Task 4: PlayerEquipmentData resource

**Files:**
- Create: `src/entities/player/components/player_equipment_data.gd`

- [ ] **Step 1: Create `player_equipment_data.gd`**

```gdscript
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
```

- [ ] **Step 2: Verify parse**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | findstr /i "error\|player_equipment_data"
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add src/entities/player/components/player_equipment_data.gd
git commit -m "feat: add PlayerEquipmentData 5-slot resource"
```

---

### Task 5: Seed skills — slash, fireball, heal `.tres`

**Files:**
- Create: `src/entities/skills/combat/slash/data/slash.tres`
- Create: `src/entities/skills/combat/fireball/data/fireball.tres`
- Create: `src/entities/skills/combat/heal/data/heal.tres`

- [ ] **Step 1: Create `slash.tres`**

```
[gd_resource type="Resource" script_class="SkillData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/entities/skills/combat/skill_data.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = &"slash"
display_name = "Slash"
description = "A basic sword strike."
skill_type = 0
element = 0
energy_cost = 10
base_power = 15.0
mastery_variants = []
```

Note: `skill_type = 0` = ATTACK, `element = 0` = NONE.

- [ ] **Step 2: Create `fireball.tres`**

```
[gd_resource type="Resource" script_class="SkillData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/entities/skills/combat/skill_data.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = &"fireball"
display_name = "Fireball"
description = "Hurls a ball of fire at the enemy."
skill_type = 0
element = 1
energy_cost = 20
base_power = 25.0
mastery_variants = []
```

Note: `element = 1` = FIRE.

- [ ] **Step 3: Create `heal.tres`**

```
[gd_resource type="Resource" script_class="SkillData" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/entities/skills/combat/skill_data.gd" id="1_skill"]

[resource]
script = ExtResource("1_skill")
skill_id = &"heal"
display_name = "Heal"
description = "Restore some of your health."
skill_type = 2
element = 0
energy_cost = 15
base_power = 20.0
mastery_variants = []
```

Note: `skill_type = 2` = HEAL. Check the enum in `skill_data.gd` to confirm HEAL index:
```bash
grep -n "HEAL\|ATTACK\|DEFEND\|SkillType" C:\Users\Anton.Khrobust\projects\aethergate\src\entities\skills\combat\skill_data.gd
```

- [ ] **Step 4: Wire slash into iron_sword.tres**

Update `src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword.tres` to reference `slash.tres`:

```
[gd_resource type="Resource" script_class="WeaponData" load_steps=3 format=3]

[ext_resource type="Script" path="res://src/entities/items/weapon_data.gd" id="1_weapon"]
[ext_resource type="Resource" path="res://src/entities/skills/combat/slash/data/slash.tres" id="2_slash"]

[resource]
script = ExtResource("1_weapon")
item_id = "iron_sword"
display_name = "Iron Sword"
description = "A sturdy iron sword. Reliable but unrefined."
slot = 0
rarity = 0
required_level = 1
item_family_id = &"swords"
weapon_visual_id = &"iron_sword"
skill_grants = [ExtResource("2_slash")]
```

- [ ] **Step 5: Verify resources load cleanly**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | findstr /i "error\|slash\|fireball\|heal"
```
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add src/entities/skills/combat/slash/ src/entities/skills/combat/fireball/ src/entities/skills/combat/heal/ src/entities/items/catalog/weapons/swords/iron_sword/
git commit -m "feat: add slash, fireball, heal seed skills; wire slash into iron_sword"
```

---

## Chunk 2: PlayerEquipmentComponent + MasteryService

### Task 6: PlayerEquipmentComponent node

**Files:**
- Create: `src/entities/player/components/player_equipment_component.gd`

- [ ] **Step 1: Write the failing test first**

Create `src/entities/player/tests/player_equipment_component_test.gd`:

```gdscript
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
	var result = comp.call("get_passive_effect")
	if result != null:
		_add_failure("get_passive_effect() should return null when no accessory equipped")


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
```

Create runner `src/entities/player/tests/run_player_equipment_component_test.gd`:

```gdscript
extends SceneTree

const TEST_SCRIPT: Script = preload(
	"res://src/entities/player/tests/player_equipment_component_test.gd"
)

func _initialize() -> void:
	var test = TEST_SCRIPT.new()
	quit(0 if test.run() else 1)
```

- [ ] **Step 2: Run test — expect FAIL (component not created yet)**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_equipment_component_test.gd 2>&1
```
Expected: Error about missing `player_equipment_component.gd` preload. This confirms the test is wired.

- [ ] **Step 3: Create `player_equipment_component.gd`**

```gdscript
class_name PlayerEquipmentComponent
extends Node

## Manages the player's 5 equipment slots.
## Child node of the Player scene — added alongside PlayerVisualComponent.
## Emits equipment_changed when a slot changes.
## LootService and CraftingService receive a reference via set_inventory_component().

signal equipment_changed(slot: EquipmentData.EquipmentSlot, item: EquipmentData)

@export var equipment_data: PlayerEquipmentData = null


func _ready() -> void:
	if equipment_data == null:
		equipment_data = PlayerEquipmentData.new()


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
```

- [ ] **Step 4: Run test — expect PASS**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_equipment_component_test.gd 2>&1
```
Expected: `PlayerEquipmentComponentTest: PASS` and exit code 0.

- [ ] **Step 5: Commit**

```bash
git add src/entities/player/components/player_equipment_component.gd src/entities/player/tests/player_equipment_component_test.gd src/entities/player/tests/run_player_equipment_component_test.gd
git commit -m "feat: add PlayerEquipmentComponent with full test coverage"
```

---

### Task 7: MasteryService

**Files:**
- Create: `src/core/mastery_service.gd`

- [ ] **Step 1: Write the failing test**

Create `src/entities/player/tests/mastery_service_test.gd`:

```gdscript
class_name MasteryServiceTest
extends RefCounted

## Tests for MasteryService: XP award, level thresholds, skill variant resolution.

const MASTERY_SCRIPT: Script = preload("res://src/core/mastery_service.gd")
const PROFILE_SCRIPT: Script = preload("res://src/core/player_profile_service.gd")
const SKILL_SCRIPT: Script = preload("res://src/entities/skills/combat/skill_data.gd")

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()
	_test_mastery_level_zero_when_no_xp()
	_test_mastery_level_1_at_tier1_threshold()
	_test_mastery_level_2_at_tier2_threshold()
	_test_mastery_player_level_gates_tier()
	_test_get_active_skill_variant_base()
	_test_get_active_skill_variant_tier1()
	_test_award_mastery_xp_accumulates()
	_print_summary()
	return _failures.is_empty()


func _test_mastery_level_zero_when_no_xp() -> void:
	var svc: Node = _make_service()
	var level: int = svc.call("get_mastery_level", &"swords", 10)
	if level != 0:
		_add_failure("No XP should give mastery level 0, got %d" % level)


func _test_mastery_level_1_at_tier1_threshold() -> void:
	var svc: Node = _make_service()
	# Tier 1 threshold at player_level=1: 100 + 1*5 = 105 XP
	svc.call("_set_mastery_xp_for_test", &"swords", 105)
	var level: int = svc.call("get_mastery_level", &"swords", 1)
	if level != 1:
		_add_failure("105 XP at player level 1 should give mastery level 1, got %d" % level)


func _test_mastery_level_2_at_tier2_threshold() -> void:
	var svc: Node = _make_service()
	# Tier 2 threshold at player_level=1: 400 + 1*15 = 415 XP
	svc.call("_set_mastery_xp_for_test", &"swords", 415)
	var level: int = svc.call("get_mastery_level", &"swords", 1)
	if level != 2:
		_add_failure("415 XP at player level 1 should give mastery level 2, got %d" % level)


func _test_mastery_player_level_gates_tier() -> void:
	var svc: Node = _make_service()
	# 300 XP: tier1 threshold at pl=10 = 100 + 10*5 = 150 → should be tier 1
	# Same 300 XP: tier1 threshold at pl=40 = 100 + 40*5 = 300 → exactly tier 1
	# Same 300 XP: tier1 threshold at pl=41 = 100 + 41*5 = 305 → still tier 0
	svc.call("_set_mastery_xp_for_test", &"swords", 300)
	var level_low: int = svc.call("get_mastery_level", &"swords", 10)
	var level_high: int = svc.call("get_mastery_level", &"swords", 41)
	if level_low < 1:
		_add_failure("300 XP at player_level=10 should be at least mastery 1, got %d" % level_low)
	if level_high >= 1:
		_add_failure("300 XP at player_level=41 should be mastery 0 (gated), got %d" % level_high)


func _test_get_active_skill_variant_base() -> void:
	var svc: Node = _make_service()
	var skill: SkillData = _make_skill("slash", [])
	var result: SkillData = svc.call("get_active_skill_variant", skill, &"swords", 1)
	if result != skill:
		_add_failure("Mastery 0 should return the base skill")


func _test_get_active_skill_variant_tier1() -> void:
	var svc: Node = _make_service()
	var variant1: SkillData = _make_skill("slash_ii", [])
	var skill: SkillData = _make_skill("slash", [variant1])
	# Set XP above tier1 threshold for player_level=1
	svc.call("_set_mastery_xp_for_test", &"swords", 200)
	var result: SkillData = svc.call("get_active_skill_variant", skill, &"swords", 1)
	if result != variant1:
		_add_failure("Mastery 1 should return mastery_variants[0], got %s" % str(result))


func _test_award_mastery_xp_accumulates() -> void:
	var svc: Node = _make_service()
	svc.call("award_mastery_xp", &"swords", 50)
	svc.call("award_mastery_xp", &"swords", 50)
	var xp: int = svc.call("_get_mastery_xp_for_test", &"swords")
	if xp != 100:
		_add_failure("Two awards of 50 XP should accumulate to 100, got %d" % xp)


# --- Helpers ---

func _make_service() -> Node:
	var svc: Node = MASTERY_SCRIPT.new()
	return svc


func _make_skill(id: StringName, variants: Array) -> SkillData:
	var skill: SkillData = SKILL_SCRIPT.new()
	skill.skill_id = id
	skill.mastery_variants = variants
	return skill


func _add_failure(msg: String) -> void:
	_failures.append(msg)


func _print_summary() -> void:
	for f: String in _failures:
		printerr("[MasteryServiceTest][FAIL] %s" % f)
	if _failures.is_empty():
		print("MasteryServiceTest: PASS")
	else:
		print("MasteryServiceTest: FAIL (%d failures)" % _failures.size())
```

Create runner `src/entities/player/tests/run_mastery_service_test.gd`:

```gdscript
extends SceneTree

const TEST_SCRIPT: Script = preload(
	"res://src/entities/player/tests/mastery_service_test.gd"
)

func _initialize() -> void:
	var test = TEST_SCRIPT.new()
	quit(0 if test.run() else 1)
```

- [ ] **Step 2: Run test — expect FAIL (service not created yet)**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_mastery_service_test.gd 2>&1
```
Expected: Preload error for missing `mastery_service.gd`.

- [ ] **Step 3: Create `mastery_service.gd`**

```gdscript
class_name MasteryService
extends Node

## Tracks mastery XP per item family and resolves active skill variants.
## Saved to player_profile.cfg [mastery] section.
## Registered as autoload "MasteryService" in project.godot.

const MASTERY_SECTION: String = "mastery"
const PROFILE_SAVE_PATH: String = "user://player_profile.cfg"

## In-memory mastery XP: item_family_id → xp total (int)
var _mastery_xp: Dictionary = {}


func _ready() -> void:
	_load_mastery_data()


## Award mastery XP for using a weapon family. Caps per-fight gain at 100.
## Emits PlayerEvents.mastery_xp_gained so the CombatResultPanel can show progress.
func award_mastery_xp(item_family_id: StringName, amount: int) -> void:
	var capped: int = mini(amount, 100)
	var current: int = _mastery_xp.get(item_family_id, 0)
	_mastery_xp[item_family_id] = current + capped
	_save_mastery_data()
	PlayerEvents.mastery_xp_gained.emit(item_family_id, capped)


## Returns 0, 1, or 2 based on XP thresholds scaled by player level.
## tier_1_threshold = 100 + player_level * 5
## tier_2_threshold = 400 + player_level * 15
func get_mastery_level(item_family_id: StringName, player_level: int) -> int:
	var xp: int = _mastery_xp.get(item_family_id, 0)
	var tier2: int = 400 + player_level * 15
	var tier1: int = 100 + player_level * 5
	if xp >= tier2:
		return 2
	if xp >= tier1:
		return 1
	return 0


## Returns the appropriate SkillData variant based on mastery level.
## mastery 0 → base skill, mastery 1 → mastery_variants[0], mastery 2 → mastery_variants[1].
func get_active_skill_variant(
	skill: SkillData,
	item_family_id: StringName,
	player_level: int
) -> SkillData:
	var level: int = get_mastery_level(item_family_id, player_level)
	if level == 0 or skill.mastery_variants.is_empty():
		return skill
	if level == 1:
		return skill.mastery_variants[0] as SkillData
	# level == 2
	if skill.mastery_variants.size() >= 2:
		return skill.mastery_variants[1] as SkillData
	return skill.mastery_variants[0] as SkillData


# --- Persistence ---

func _load_mastery_data() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PROFILE_SAVE_PATH) != OK:
		return
	if not cfg.has_section(MASTERY_SECTION):
		return
	for key: String in cfg.get_section_keys(MASTERY_SECTION):
		_mastery_xp[StringName(key)] = int(cfg.get_value(MASTERY_SECTION, key, 0))


func _save_mastery_data() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROFILE_SAVE_PATH)
	for family_id: StringName in _mastery_xp:
		cfg.set_value(MASTERY_SECTION, String(family_id), _mastery_xp[family_id])
	var err: Error = cfg.save(PROFILE_SAVE_PATH)
	if err != OK and OS.is_debug_build():
		push_warning("MasteryService: failed to save mastery data (%d)" % int(err))


# --- Test helpers (not called in production) ---

func _set_mastery_xp_for_test(item_family_id: StringName, xp: int) -> void:
	_mastery_xp[item_family_id] = xp


func _get_mastery_xp_for_test(item_family_id: StringName) -> int:
	return _mastery_xp.get(item_family_id, 0)
```

- [ ] **Step 4: Run test — expect PASS**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_mastery_service_test.gd 2>&1
```
Expected: `MasteryServiceTest: PASS` and exit code 0.

- [ ] **Step 5: Add `mastery_xp_gained` signal to `player_events.gd`**

Open `src/core/events/player_events.gd` and add this signal alongside the existing ones:

```gdscript
signal mastery_xp_gained(item_family_id: StringName, amount: int)
```

- [ ] **Step 6: Register MasteryService as autoload in `project.godot`**

Open `project.godot` and add to the `[autoload]` section:
```ini
MasteryService="*res://src/core/mastery_service.gd"
```

- [ ] **Step 7: Verify project still loads**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | findstr /i "error\|mastery"
```
Expected: No errors.

- [ ] **Step 8: Commit**

```bash
git add src/core/mastery_service.gd src/core/events/player_events.gd src/entities/player/tests/mastery_service_test.gd src/entities/player/tests/run_mastery_service_test.gd project.godot
git commit -m "feat: add MasteryService with persistence, mastery_xp_gained signal, and full test coverage"
```

---

## Chunk 3: Snapshot Wiring + Combat Integration

### Task 8: Extend CombatantSnapshot with new fields

**Files:**
- Modify: `src/entities/systems/combat/data/combatant_snapshot.gd`

- [ ] **Step 1: Add `passive_effect` and `weapon_family_id` fields**

Open `src/entities/systems/combat/data/combatant_snapshot.gd` and add after `var skill_loadout: Array[SkillData] = []`:

```gdscript
## Passive proc effect from the accessory slot. Null if no accessory equipped.
var passive_effect: PassiveEffectData = null
## Item family ID of the equipped weapon. Used to award mastery XP post-combat.
## Empty StringName if no weapon equipped.
var weapon_family_id: StringName = &""
```

- [ ] **Step 2: Run existing smoke test to confirm no regressions**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200 2>&1 | findstr /i "error\|FAIL"
```
Expected: No errors, no FAIL output.

- [ ] **Step 3: Commit**

```bash
git add src/entities/systems/combat/data/combatant_snapshot.gd
git commit -m "feat: add passive_effect and weapon_family_id fields to CombatantSnapshot"
```

---

### Task 9: Wire equipment into `build_player_snapshot()`

**Files:**
- Modify: `src/core/player_progression_service.gd`

- [ ] **Step 1: Write the failing test for snapshot wiring**

Add to `src/entities/player/tests/player_progression_service_test.gd` — append these methods before `_make_test_config()`:

```gdscript
const EQUIPMENT_COMPONENT_SCRIPT: Script = preload(
	"res://src/entities/player/components/player_equipment_component.gd"
)
const WEAPON_DATA_SCRIPT: Script = preload("res://src/entities/items/weapon_data.gd")
const MASTERY_SCRIPT: Script = preload("res://src/core/mastery_service.gd")
const SKILL_DATA_SCRIPT_FOR_SNAPSHOT: Script = preload(
	"res://src/entities/skills/combat/skill_data.gd"
)

func _test_build_player_snapshot_with_equipment() -> void:
	var svc: Node = _make_progression_service_with_profile()

	# Create a minimal equipment component (node, not autoload)
	var equipment_comp: Node = EQUIPMENT_COMPONENT_SCRIPT.new()
	
	# Give it a sword with a skill
	var sword: WeaponData = WEAPON_DATA_SCRIPT.new()
	sword.item_id = "iron_sword"
	sword.slot = EquipmentData.EquipmentSlot.WEAPON
	sword.item_family_id = &"swords"
	sword.stat_bonuses = CombatStats.new()
	sword.stat_bonuses.attack = 10.0
	var skill: SkillData = SKILL_DATA_SCRIPT_FOR_SNAPSHOT.new()  # use preloaded script, not class_name
	skill.skill_id = &"slash"
	sword.skill_grants = [skill]
	equipment_comp.call("equip", sword)

	# Inject component and mastery service (use script instance, not autoload singleton)
	svc.set("_equipment_component", equipment_comp)
	svc.set("_mastery_service", MASTERY_SCRIPT.new())

	var snapshot: CombatantSnapshot = svc.call("build_player_snapshot")

	if snapshot == null:
		_add_failure("build_player_snapshot() returned null")
		return
	if snapshot.skill_loadout.size() != 1:
		_add_failure(
			"Snapshot should have 1 skill from sword, got %d" % snapshot.skill_loadout.size()
		)
	if not is_equal_approx(snapshot.base_stats.attack, 8.0 + 10.0):
		_add_failure(
			"Snapshot attack should be base(8.0) + bonus(10.0) = 18.0, got %f"
			% snapshot.base_stats.attack
		)
	if snapshot.weapon_family_id != &"swords":
		_add_failure(
			"weapon_family_id should be 'swords', got '%s'" % snapshot.weapon_family_id
		)
```

Also add `_test_build_player_snapshot_with_equipment()` to the `run()` method call list. Find the `run()` method and add it with the other test calls:

```gdscript
	_test_build_player_snapshot_with_equipment()
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_progression_service_test.gd 2>&1
```
Expected: FAIL on `_test_build_player_snapshot_with_equipment` — `_equipment_component` field doesn't exist yet.

- [ ] **Step 3: Update `player_progression_service.gd`**

Add these vars near the top (after `var _profile_service`):

```gdscript
## Injected by main.gd after Player scene is ready. Null = no equipment wired (fallback OK).
var _equipment_component: PlayerEquipmentComponent = null
## Injected reference to MasteryService autoload. Settable for tests.
var _mastery_service: Node = null
```

Add this setter (after `_ready()`):

```gdscript
## Called by main.gd after the Player scene is added to the scene tree.
func set_equipment_component(comp: PlayerEquipmentComponent) -> void:
	_equipment_component = comp


func _get_mastery_service() -> Node:
	if _mastery_service != null:
		return _mastery_service
	return MasteryService
```

Replace the `build_player_snapshot()` function with:

```gdscript
## Builds a CombatantSnapshot for the player using current level, base stats, and equipment.
## Sprite and VFX data are NOT included — callers augment the snapshot.
func build_player_snapshot() -> CombatantSnapshot:
	var level: int = int(_profile_service.call("get_player_level"))
	var snap := CombatantSnapshot.new()
	snap.combatant_id = &"player"
	snap.display_name = "Player"
	snap.level = level

	# 1. Base stats from level
	var base: CombatStats = calculate_stats(level)

	# 2. Equipment stat bonuses
	if _equipment_component != null:
		var bonus: CombatStats = _equipment_component.get_total_stat_bonuses()
		base.max_hp     += bonus.max_hp
		base.max_energy += bonus.max_energy
		base.attack     += bonus.attack
		base.defense    += bonus.defense

	snap.base_stats = base

	# 3. Skill grants resolved through mastery
	if _equipment_component != null:
		var mastery: Node = _get_mastery_service()
		var family_id: StringName = _equipment_component.get_weapon_family_id()
		for skill: SkillData in _equipment_component.get_all_skill_grants():
			var active: SkillData = mastery.call(
				"get_active_skill_variant", skill, family_id, level
			)
			snap.skill_loadout.append(active)
		# 4. Passive effect from accessory
		snap.passive_effect = _equipment_component.get_passive_effect()
		# 5. Weapon family for post-combat mastery awarding
		snap.weapon_family_id = family_id

	return snap
```

- [ ] **Step 4: Run test — expect PASS**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_progression_service_test.gd 2>&1
```
Expected: All tests PASS including the new snapshot wiring test.

- [ ] **Step 5: Commit**

```bash
git add src/core/player_progression_service.gd src/entities/player/tests/player_progression_service_test.gd
git commit -m "feat: wire equipment bonuses and mastery skills into build_player_snapshot()"
```

---

### Task 10: Passive proc evaluation in CombatRoundResolver

**Files:**
- Modify: `src/entities/systems/combat/combat_round_resolver.gd`

- [ ] **Step 1: Write the failing test**

Create `src/entities/systems/combat/tests/combat_resolver_passive_test.gd`:

```gdscript
class_name CombatResolverPassiveTest
extends RefCounted

## Tests passive proc evaluation in CombatRoundResolver.

const RESOLVER_SCRIPT: Script = preload(
	"res://src/entities/systems/combat/combat_round_resolver.gd"
)
const PASSIVE_SCRIPT: Script = preload(
	"res://src/entities/items/passive_effect_data.gd"
)

var _failures: Array[String] = []


func run() -> bool:
	_failures.clear()
	_test_no_passive_no_change()
	_test_poison_on_hit_always_triggers()
	_test_regen_energy_always_triggers()
	_test_thorns_applies_to_attacker()
	_print_summary()
	return _failures.is_empty()


func _test_no_passive_no_change() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, null)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, null)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_attacker_hp_delta != 0 or result.passive_defender_hp_delta != 0:
		_add_failure("No passive — passive deltas should be 0")


func _test_poison_on_hit_always_triggers() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var poison: PassiveEffectData = PASSIVE_SCRIPT.new()
	poison.effect_type = PassiveEffectData.PassiveEffectType.POISON_ON_HIT
	poison.trigger_chance = 1.0  # always trigger
	poison.value = 8.0
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, poison)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, null)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_defender_hp_delta != -8:
		_add_failure(
			"POISON_ON_HIT(1.0, 8.0) should deal 8 poison, got %d"
			% result.passive_defender_hp_delta
		)


func _test_regen_energy_always_triggers() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var regen: PassiveEffectData = PASSIVE_SCRIPT.new()
	regen.effect_type = PassiveEffectData.PassiveEffectType.REGEN_ENERGY
	regen.trigger_chance = 1.0
	regen.value = 10.0
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, regen)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, null)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_attacker_energy_delta != 10:
		_add_failure(
			"REGEN_ENERGY(1.0, 10.0) should grant 10 energy, got %d"
			% result.passive_attacker_energy_delta
		)


func _test_thorns_applies_to_attacker() -> void:
	var resolver: Node = RESOLVER_SCRIPT.new()
	var thorns: PassiveEffectData = PASSIVE_SCRIPT.new()
	thorns.effect_type = PassiveEffectData.PassiveEffectType.THORNS
	thorns.trigger_chance = 1.0
	thorns.value = 5.0
	# Defender has THORNS passive
	var attacker: CombatantSnapshot = _make_snapshot(10.0, 5.0, null)
	var defender: CombatantSnapshot = _make_snapshot(5.0, 3.0, thorns)
	var action: CombatAction = _make_attack_action()
	var result: CombatPhaseResult = resolver.call(
		"resolve_phase", action, attacker, defender, 50
	)
	if result.passive_attacker_hp_delta != -5:
		_add_failure(
			"THORNS(1.0, 5.0) on defender should deal 5 to attacker, got %d"
			% result.passive_attacker_hp_delta
		)


# --- Helpers ---

func _make_snapshot(attack: float, defense: float, passive: PassiveEffectData) -> CombatantSnapshot:
	var snap: CombatantSnapshot = CombatantSnapshot.new()
	snap.combatant_id = &"test"
	snap.base_stats = CombatStats.new()
	snap.base_stats.attack = attack
	snap.base_stats.defense = defense
	snap.base_stats.max_hp = 100
	snap.passive_effect = passive
	return snap


func _make_attack_action() -> CombatAction:
	var action: CombatAction = CombatAction.new()
	action.actor_id = &"test"
	action.skill_used = null
	return action


func _add_failure(msg: String) -> void:
	_failures.append(msg)


func _print_summary() -> void:
	for f: String in _failures:
		printerr("[CombatResolverPassiveTest][FAIL] %s" % f)
	if _failures.is_empty():
		print("CombatResolverPassiveTest: PASS")
	else:
		print("CombatResolverPassiveTest: FAIL (%d failures)" % _failures.size())
```

Check if a tests folder exists for combat:
```bash
ls C:\Users\Anton.Khrobust\projects\aethergate\src\entities\systems\combat\
```
If not, create `src/entities/systems/combat/tests/` and also create `run_combat_resolver_passive_test.gd`:

```gdscript
extends SceneTree

const TEST_SCRIPT: Script = preload(
	"res://src/entities/systems/combat/tests/combat_resolver_passive_test.gd"
)

func _initialize() -> void:
	var test = TEST_SCRIPT.new()
	quit(0 if test.run() else 1)
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/systems/combat/tests/run_combat_resolver_passive_test.gd 2>&1
```
Expected: FAIL — `passive_attacker_hp_delta` field doesn't exist on `CombatPhaseResult`.

- [ ] **Step 3: Add passive delta fields to `CombatPhaseResult`**

Open `src/entities/systems/combat/data/combat_phase_result.gd` and add:

```gdscript
## HP delta applied to attacker from passive procs (THORNS, LIFESTEAL, etc). Usually <= 0.
var passive_attacker_hp_delta: int = 0
## HP delta applied to defender from passive procs (POISON_ON_HIT, REFLECT, etc). Usually <= 0.
var passive_defender_hp_delta: int = 0
## Energy delta applied to attacker from passive procs (REGEN_ENERGY). Usually >= 0.
var passive_attacker_energy_delta: int = 0
```

- [ ] **Step 4: Add passive proc evaluation to `CombatRoundResolver`**

At the end of `resolve_phase()`, before `return result`, add:

```gdscript
	# Evaluate passive procs after the main phase
	_apply_passive_procs(result, attacker_snapshot, defender_snapshot)
```

Add the private method:

```gdscript
func _apply_passive_procs(
	result: CombatPhaseResult,
	attacker: CombatantSnapshot,
	defender: CombatantSnapshot
) -> void:
	# Attacker's passive (e.g. POISON_ON_HIT, REGEN_ENERGY, LIFESTEAL)
	if attacker.passive_effect != null:
		_apply_attacker_effect(result, attacker.passive_effect)
	# Defender's passive (e.g. THORNS, REFLECT_DAMAGE)
	if defender.passive_effect != null:
		_apply_defender_effect(result, defender.passive_effect)


func _apply_attacker_effect(result: CombatPhaseResult, effect: PassiveEffectData) -> void:
	if effect.effect_type == PassiveEffectData.PassiveEffectType.REGEN_ENERGY:
		result.passive_attacker_energy_delta += int(effect.value)
		return
	if randf() > effect.trigger_chance:
		return
	match effect.effect_type:
		PassiveEffectData.PassiveEffectType.POISON_ON_HIT:
			result.passive_defender_hp_delta -= int(effect.value)
		PassiveEffectData.PassiveEffectType.LIFESTEAL:
			var heal: int = int(absf(float(result.defender_hp_delta)) * effect.value)
			result.passive_attacker_hp_delta += heal


func _apply_defender_effect(result: CombatPhaseResult, effect: PassiveEffectData) -> void:
	if randf() > effect.trigger_chance:
		return
	match effect.effect_type:
		PassiveEffectData.PassiveEffectType.THORNS:
			result.passive_attacker_hp_delta -= int(effect.value)
		PassiveEffectData.PassiveEffectType.REFLECT_DAMAGE:
			var reflected: int = int(absf(float(result.defender_hp_delta)) * effect.value)
			result.passive_attacker_hp_delta -= reflected
```

- [ ] **Step 5: Run test — expect PASS**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/systems/combat/tests/run_combat_resolver_passive_test.gd 2>&1
```
Expected: `CombatResolverPassiveTest: PASS` and exit code 0.

- [ ] **Step 6: Run all existing tests to confirm no regressions**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200 2>&1 | findstr /i "error\|FAIL"
```

- [ ] **Step 7: Commit**

```bash
git add src/entities/systems/combat/ src/entities/systems/combat/tests/
git commit -m "feat: add passive proc evaluation to CombatRoundResolver with tests"
```

---

### Task 11: Mastery XP awarded post-combat in CombatScene

**Files:**
- Modify: `src/world/combat/combat_scene.gd`

- [ ] **Step 1: Add mastery XP award to `_on_combat_ended()`**

In `combat_scene.gd`, update the `_on_combat_ended()` method. Find:

```gdscript
	if _is_victory:
		_xp_awarded = _context.enemy_snapshot.xp_reward
		PlayerProgressionService.award_xp(_xp_awarded)
```

Replace with:

```gdscript
	if _is_victory:
		_xp_awarded = _context.enemy_snapshot.xp_reward
		PlayerProgressionService.award_xp(_xp_awarded)
		# Award mastery XP for the weapon family used in this combat
		var enemy_level: int = _context.enemy_snapshot.level
		var mastery_xp: int = 10 + enemy_level * 2
		var family_id: StringName = _context.player_snapshot.weapon_family_id
		if family_id != &"":
			MasteryService.award_mastery_xp(family_id, mastery_xp)
```

- [ ] **Step 2: Run smoke test to verify combat still works**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200 2>&1 | findstr /i "error\|FAIL"
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add src/world/combat/combat_scene.gd
git commit -m "feat: award mastery XP post-combat victory based on weapon family"
```

---

### Task 12: Add PlayerEquipmentComponent to Player scene

**Files:**
- Modify: `src/entities/player/player.tscn`
- Modify: `src/entities/player/player.gd`
- Modify: `src/world/main.gd` (or wherever Player is instantiated and PlayerProgressionService is referenced)

- [ ] **Step 1: Find how the Player scene is used**

```bash
grep -rn "PlayerProgressionService\|player\.tscn\|player_scene\|set_equipment" C:\Users\Anton.Khrobust\projects\aethergate\src\world\main.gd 2>nul
grep -rn "build_player_snapshot\|set_equipment_component" C:\Users\Anton.Khrobust\projects\aethergate\src\ --include="*.gd" 2>nul
```

- [ ] **Step 2: Add `PlayerEquipmentComponent` as a child node in `player.tscn`**

First, check what the next ext_resource ID should be:

```bash
grep "ext_resource" C:\Users\Anton.Khrobust\projects\aethergate\src\entities\player\player.tscn | tail -5
```

Note the highest numeric ID in the output (e.g. `id="7_visual"` → next ID is `8`). Use that number in the edits below.

Open `src/entities/player/player.tscn` and make two additions:

1. Near the top with the other `[ext_resource]` entries, add (**replace `8` with the actual next ID from grep**):
```
[ext_resource type="Script" path="res://src/entities/player/components/player_equipment_component.gd" id="8_equip"]
```

2. After the last `[node ... parent="."]` child, add:
```
[node name="PlayerEquipmentComponent" type="Node" parent="."]
script = ExtResource("8_equip")
```

Verify the `.tscn` file is still valid after editing:

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --quit 2>&1 | findstr /i "error\|player.tscn\|PlayerEquipment"
```
Expected: No errors.

- [ ] **Step 3: Add `@onready` reference in `player.gd`**

In `src/entities/player/player.gd`, add with the other `@onready` declarations:

```gdscript
@onready var equipment_component: PlayerEquipmentComponent = $PlayerEquipmentComponent
```

- [ ] **Step 4: Inject equipment component into PlayerProgressionService**

Find where the Player scene is instantiated (likely `src/world/main.gd`). After the player is added to the scene tree, inject the equipment component using the typed `@onready` reference added in Step 3 — **not** `get_node()`:

```gdscript
# After player is added to scene tree — use typed property, not get_node():
PlayerProgressionService.set_equipment_component(player.equipment_component)
```

Check `main.gd` first — find the exact location:
```bash
grep -n "player\|Player\|progression" C:\Users\Anton.Khrobust\projects\aethergate\src\world\main.gd | head -30
```

- [ ] **Step 5: Run smoke test**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200 2>&1 | findstr /i "error\|FAIL"
```
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add src/entities/player/player.tscn src/entities/player/player.gd src/world/main.gd
git commit -m "feat: add PlayerEquipmentComponent to Player scene and wire into PlayerProgressionService"
```

---

### Task 13: Equipment save/load in PlayerProfileService

**Files:**
- Modify: `src/core/player_profile_service.gd`

> Note: The spec also calls for a `[blueprints]` save section in `player_profile_service.gd`. This is deferred to Plan B (Loot + Crafting) where `BlueprintData` and `CraftingService` are implemented.

- [ ] **Step 1: Add equipment persistence constants**

At the top of `player_profile_service.gd`, add:

```gdscript
const EQUIPMENT_SECTION: String = "equipment"
const KEY_WEAPON: String = "weapon_path"
const KEY_HELMET: String = "helmet_path"
const KEY_CHEST: String = "chest_path"
const KEY_BOOTS: String = "boots_path"
const KEY_ACCESSORY: String = "accessory_path"
```

- [ ] **Step 2: Add load/save equipment methods**

Add these methods to `player_profile_service.gd`:

```gdscript
## Load equipment slot resource paths from profile and return a PlayerEquipmentData.
## Returns empty PlayerEquipmentData if no saved equipment.
func load_equipment() -> PlayerEquipmentData:
	var data: PlayerEquipmentData = PlayerEquipmentData.new()
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PROFILE_SAVE_PATH) != OK:
		return data
	data.weapon   = _load_equipment_item(cfg, KEY_WEAPON)   as WeaponData
	data.helmet   = _load_equipment_item(cfg, KEY_HELMET)   as ArmorData
	data.chest    = _load_equipment_item(cfg, KEY_CHEST)    as ArmorData
	data.boots    = _load_equipment_item(cfg, KEY_BOOTS)    as ArmorData
	data.accessory = _load_equipment_item(cfg, KEY_ACCESSORY) as AccessoryData
	return data


## Save equipment slot resource paths to profile.
func save_equipment(equipment_data: PlayerEquipmentData) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PROFILE_SAVE_PATH)
	_save_equipment_item(cfg, KEY_WEAPON,    equipment_data.weapon)
	_save_equipment_item(cfg, KEY_HELMET,    equipment_data.helmet)
	_save_equipment_item(cfg, KEY_CHEST,     equipment_data.chest)
	_save_equipment_item(cfg, KEY_BOOTS,     equipment_data.boots)
	_save_equipment_item(cfg, KEY_ACCESSORY, equipment_data.accessory)
	var err: Error = cfg.save(PROFILE_SAVE_PATH)
	if err != OK and OS.is_debug_build():
		push_warning("PlayerProfileService: failed to save equipment (%d)" % int(err))


func _load_equipment_item(cfg: ConfigFile, key: String) -> EquipmentData:
	var path: String = cfg.get_value(EQUIPMENT_SECTION, key, "")
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("PlayerProfileService: equipment path not found: %s" % path)
		return null
	return ResourceLoader.load(path) as EquipmentData


func _save_equipment_item(cfg: ConfigFile, key: String, item: EquipmentData) -> void:
	if item == null:
		cfg.set_value(EQUIPMENT_SECTION, key, "")
	else:
		cfg.set_value(EQUIPMENT_SECTION, key, item.resource_path)
```

- [ ] **Step 3: Wire save into `PlayerEquipmentComponent` — update `_ready()` and add save handler**

Update `player_equipment_component.gd`. Replace the `_ready()` function and add the save handler. **This is a single edit — both the load-on-startup and the auto-save connect go here:**

```gdscript
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
```

- [ ] **Step 4: Run all tests**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_progression_service_test.gd 2>&1
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_equipment_component_test.gd 2>&1
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_mastery_service_test.gd 2>&1
```
Expected: All PASS.

- [ ] **Step 5: Commit**

```bash
git add src/core/player_profile_service.gd src/entities/player/components/player_equipment_component.gd
git commit -m "feat: add equipment save/load to PlayerProfileService, wire auto-save on equip change"
```

---

## Final Verification

- [ ] **Run all project tests**

```bash
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/creatures/tests/run_creature_catalog_validation.gd 2>&1
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --scene res://src/entities/creatures/tests/creature_runtime_smoke_test.tscn --quit-after 200 2>&1 | findstr /i "error\|FAIL"
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_progression_service_test.gd 2>&1
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_player_equipment_component_test.gd 2>&1
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/player/tests/run_mastery_service_test.gd 2>&1
C:\Users\Anton.Khrobust\projects\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe --headless --path C:\Users\Anton.Khrobust\projects\aethergate --script res://src/entities/systems/combat/tests/run_combat_resolver_passive_test.gd 2>&1
```
Expected: All PASS, exit code 0.

- [ ] **Final commit — tag Plan A complete**

```bash
git add -A
git status --short
git commit -m "feat: equipment + combat integration plan A complete — gear-driven skills, mastery, passive procs"
```
