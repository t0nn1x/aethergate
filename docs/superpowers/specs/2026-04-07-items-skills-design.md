# Items & Skills System Design
**Date:** 2026-04-07  
**Branch:** `feature/items-skills`  
**Status:** Approved

---

## Summary

Gear-driven skills system inspired by Albion Online (gear = skills), with WoW-style equipment slots, rarity tiers (Common / Rare / Legendary), use-based mastery scaled by player level, a blueprint crafting system, and passive accessory procs. The combat resolver reads `passive_effect` from `CombatantSnapshot` — all bonuses are baked into the snapshot before combat starts, keeping the resolver boundary clean.

---

## Design Decisions

| Question | Decision |
|---|---|
| How do players get skills? | Gear-driven — equipping an item grants its skills |
| Tier system | 3 rarities: Common / Rare / Legendary |
| Skill progression | Use-based mastery per item family, scaled by player level |
| Equipment slots | 5: Weapon, Helmet, Chest, Boots, Accessory |
| Active skills in combat | 4 (all Common) to 8 (all Rare/Legendary mix) |
| Armor skill grants | 1 (Common) / 2 (Rare) — no 3rd slot on armor |
| Weapon skill grants | 1 (Common) / 2 (Rare) / 3 (Legendary) |
| Accessory | Passive proc only — no active skill |
| Loot sources | Enemy drops + shops + crafting (full economy) |
| Crafting | Blueprint system — blueprints drop from enemies, require materials to craft |
| Asset placement | Co-located with data: `<entity_folder>/sprites/<name>_icon.png` |

---

## Data Model

### Resource Hierarchy

```
ItemData extends Resource                        (exists — icon auto-resolved from sprites/ folder)
  └─ EquipmentData extends ItemData             (new)
       ├─ WeaponData extends EquipmentData      (new)
       ├─ ArmorData extends EquipmentData       (new — Helmet / Chest / Boots)
       └─ AccessoryData extends EquipmentData   (new)

SkillData extends Resource                       (exists — has icon, mastery_variants fields)
PassiveEffectData extends Resource               (new)
BlueprintData extends Resource                   (new)
LootTableData extends Resource                   (new)
PlayerEquipmentData extends Resource             (new — 5-slot save resource, @tool)
```

### EquipmentData fields

```gdscript
class_name EquipmentData extends ItemData

enum EquipmentSlot { WEAPON, HELMET, CHEST, BOOTS, ACCESSORY }
enum Rarity { COMMON, RARE, LEGENDARY }

@export var slot: EquipmentSlot
@export var rarity: Rarity
@export var required_level: int = 1
@export var stat_bonuses: CombatStats          # flat bonuses, baked into snapshot
@export var skill_grants: Array[SkillData]     # 1 / 2 / 3 depending on slot + rarity
```

### WeaponData adds

```gdscript
class_name WeaponData extends EquipmentData

@export var item_family_id: StringName         # e.g. &"swords" — used for mastery tracking
@export var weapon_visual_id: StringName       # for combat sprite (maps to existing prop)
# slot is always WEAPON — validated in _validate()
```

### ArmorData

```gdscript
class_name ArmorData extends EquipmentData

# slot must be HELMET, CHEST, or BOOTS — validated in _validate()
# No additional fields — slot field on EquipmentData is sufficient
```

### AccessoryData adds

```gdscript
class_name AccessoryData extends EquipmentData

@export var passive_effect: PassiveEffectData
# slot is always ACCESSORY — validated in _validate()
# skill_grants must always be empty — validated in _validate()
```

### PassiveEffectData

```gdscript
class_name PassiveEffectData extends Resource

enum PassiveEffectType {
    POISON_ON_HIT,    # deal poison damage after hit
    REGEN_ENERGY,     # restore energy each round
    REFLECT_DAMAGE,   # reflect % of incoming damage
    THORNS,           # deal flat damage when hit
    LIFESTEAL         # heal % of damage dealt
}

@export var effect_type: PassiveEffectType
@export var trigger_chance: float              # 0.0–1.0 (REGEN_ENERGY always triggers)
@export var value: float                       # damage / hp / energy amount
```

### PlayerEquipmentData

```gdscript
class_name PlayerEquipmentData extends Resource

@tool

@export var weapon: WeaponData
@export var helmet: ArmorData
@export var chest: ArmorData
@export var boots: ArmorData
@export var accessory: AccessoryData

# Saved to player_profile.cfg [equipment] section as item_ids
# e.g. weapon = "iron_sword", helmet = "", etc.
```

### BlueprintData

```gdscript
class_name BlueprintData extends Resource

@export var blueprint_id: StringName
@export var display_name: String
@export var result_item: EquipmentData               # what gets crafted
@export var required_materials: Array[Dictionary]
# [{ "item": ItemData (resource ref), "amount": int }, ...]
# Uses resource refs (same as LootTableData) — no ID lookup step needed
```

### LootTableData

```gdscript
class_name LootTableData extends Resource

@export var entries: Array[Dictionary]
# [{ "item": ItemData, "weight": float, "min_player_level": int }, ...]
# weight is relative — e.g. common=100, rare=20, legendary=3
```

### Mastery — tracked in PlayerProfileService

```
# Saved in player_profile.cfg [mastery] section
# mastery_xp: Dictionary — item_family_id (StringName) → xp (int)
# e.g. { "swords": 340, "fire_staves": 80 }

Mastery tiers: 3 levels (0 = base skill, 1 = variant I, 2 = variant II)

mastery_level(family_id, player_level):
  xp = mastery_xp.get(family_id, 0)
  tier_1_threshold = 100  + player_level * 5   → unlocks mastery_variants[0]
  tier_2_threshold = 400  + player_level * 15  → unlocks mastery_variants[1]
  returns 0, 1, or 2

Mastery XP gained per combat win = 10 + (enemy_level * 2)
  → capped at 100 per fight to prevent grinding trivial enemies

SkillData.mastery_variants: Array[SkillData]  (already exists)
  → mastery_variants[0] = Slash II (stronger, different animation)
  → mastery_variants[1] = Slash III (AoE, hits both rounds)
```

---

## New Systems

### PlayerEquipmentComponent (Node — child of Player scene)

```gdscript
# src/entities/systems/equipment/player_equipment_component.gd
class_name PlayerEquipmentComponent extends Node

signal equipment_changed(slot: EquipmentData.EquipmentSlot, item: EquipmentData)

@export var equipment_data: PlayerEquipmentData  # @tool resource, saved to profile

func equip(item: EquipmentData) -> void          # replaces slot, emits equipment_changed
func unequip(slot: EquipmentData.EquipmentSlot) -> void
func get_item_in_slot(slot: EquipmentData.EquipmentSlot) -> EquipmentData
func get_all_skill_grants() -> Array[SkillData]  # all 4 gear slots combined
func get_passive_effect() -> PassiveEffectData   # from accessory slot (null if empty)
func get_total_stat_bonuses() -> CombatStats     # summed across all 5 slots
```

### LootService (autoload)

```gdscript
# src/core/loot_service.gd
class_name LootService extends Node

func roll_loot(creature_data: CreatureData) -> Array[ItemData]
# weighted random roll from creature_data.loot_table (LootTableData)
# filters by min_player_level vs current player level
# emits ItemEvents.loot_dropped(items) — caller adds to inventory
```

### CraftingService (autoload)

```gdscript
# src/core/crafting_service.gd
class_name CraftingService extends Node

func can_craft(blueprint: BlueprintData) -> bool
# checks PlayerInventoryComponent has required material amounts

func craft(blueprint: BlueprintData) -> EquipmentData
# pre: can_craft() is true
# consumes materials from inventory, returns crafted EquipmentData
# caller adds result to inventory
```

### MasteryService (autoload)

```gdscript
# src/core/mastery_service.gd
class_name MasteryService extends Node

func award_mastery_xp(item_family_id: StringName, amount: int) -> void
# adds xp to profile [mastery] section, emits PlayerEvents.mastery_xp_gained

func get_mastery_level(item_family_id: StringName, player_level: int) -> int
# returns 0, 1, or 2 based on xp thresholds + player_level

func get_active_skill_variant(skill: SkillData, item_family_id: StringName, player_level: int) -> SkillData
# mastery_level=0 → returns skill itself
# mastery_level=1 → returns skill.mastery_variants[0] (if exists, else skill)
# mastery_level=2 → returns skill.mastery_variants[1] (if exists, else [0])
```

---

## CombatantSnapshot — new field

```gdscript
# Added to CombatantSnapshot (src/entities/systems/combat/data/combatant_snapshot.gd)
var passive_effect: PassiveEffectData = null   # null if no accessory equipped
```

The resolver evaluates `passive_effect` at the end of each phase — this is the only change to the combat system.

---

## Combat Snapshot Assembly

`PlayerProgressionService.build_player_snapshot()` — called before every combat.

```
1. base stats       → calculate_stats(level)                               (exists)
2. equipment stats  → PlayerEquipmentComponent.get_total_stat_bonuses()    (new)
                      → added to base CombatStats
3. skill grants     → PlayerEquipmentComponent.get_all_skill_grants()      (new)
                      → each SkillData resolved via MasteryService.get_active_skill_variant()
                      → stored as skill_loadout on snapshot
4. passive effect   → PlayerEquipmentComponent.get_passive_effect()        (new)
                      → stored as passive_effect on snapshot
5. snapshot ready   → CombatantSnapshot with baked stats + skills + passive
```

`CombatRoundResolver` change: after each phase result, check `attacker.passive_effect` and `defender.passive_effect` against `randf()` and apply `value` to the appropriate HP/energy delta. No structural change to the resolver's phase flow.

---

## Post-Combat Flow

```
CombatEvents.combat_won emitted (enemy_data: CreatureData)
  → LootService.roll_loot(enemy_data)
      → ItemEvents.loot_dropped(items) emitted
      → PlayerInventoryComponent.add_item() for each drop
  → MasteryService.award_mastery_xp(
        player_snapshot.weapon_family_id,    # new field on CombatantSnapshot
        10 + enemy_data.level * 2)           # capped at 100
  → PlayerProgressionService.award_xp(enemy_data.xp_reward)   (exists)
  → CombatResultPanel shows loot drops + mastery progress bar
```

---

## Crafting Flow

```
Enemy drops BlueprintData (rare, from loot table)
  → stored as resource paths in PlayerProfileService [blueprints] section
  #  e.g. "res://src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword_blueprint.tres"
  #  loaded at runtime via ResourceLoader.load(path) → BlueprintData (no separate catalog needed)
  → ItemEvents.blueprint_found(blueprint) emitted

Player visits Blacksmith NPC (future scope — NPC/UI not in this iteration)
  → CraftingService.can_craft(blueprint) checks inventory
  → CraftingService.craft(blueprint)
      → removes required_materials from inventory
      → returns EquipmentData instance
      → caller adds to PlayerInventoryComponent
```

---

## Existing Files Referenced (confirmed)

### PlayerInventoryComponent — `src/entities/systems/inventory/player_inventory_component.gd`
- `signal inventory_changed()`
- `func add_item(item: Resource, amount: int = 1) -> int`
- `func remove_item_by_id(item_id: String, amount: int = 1) -> int`
- `func get_item_count(item_id: String) -> int`

**Access pattern:** `LootService` and `CraftingService` receive a reference to `PlayerInventoryComponent` via a setter call after the Player scene is ready — consistent with the project's `@onready` pattern. `PlayerProgressionService` (which already references the Player) will inject the reference at startup. No `get_node()` in hot paths.

### ItemData — `src/entities/items/item_data.gd`
- Auto-resolves icon from `<item_folder>/Sprites/<name>_icon.png` via `_resolve_icon_from_item_folder()`
- `EquipmentData extends ItemData` inherits this for free

### CombatStats — `src/entities/systems/combat/data/combat_stats.gd`
Fields: `max_hp: int`, `max_energy: int`, `attack: float`, `defense: float`

### CombatantSnapshot — `src/entities/systems/combat/data/combatant_snapshot.gd`
Existing fields: `combatant_id`, `display_name`, `level`, `base_stats: CombatStats`, `skill_loadout: Array[SkillData]`, sprite/VFX fields  
**New field to add:** `var passive_effect: PassiveEffectData = null`  
**New field to add:** `var weapon_family_id: StringName = &""` — used by `combat_scene.gd` to award mastery XP post-combat

### SkillData — `src/entities/skills/combat/skill_data.gd`
Fields: `skill_id: StringName`, `display_name`, `description`, `skill_type: SkillType`, `element: Element`, `energy_cost: int`, `base_power: float`, `icon: Texture2D`, `mastery_variants: Array[Resource]`, VFX fields

---

## ItemEvents — new event hub

```gdscript
# src/core/events/item_events.gd
class_name ItemEvents extends Node

signal loot_dropped(items: Array[ItemData])
signal blueprint_found(blueprint: BlueprintData)
# Note: item_equipped/unequipped are NOT on ItemEvents
# Use PlayerEquipmentComponent.equipment_changed for equipment slot changes (local, node-level)
# Cross-system equipment reactions (e.g. HUD updates) should connect to that signal directly
```

---

## Files to Create

```
src/entities/items/
  ├─ equipment_data.gd
  ├─ weapon_data.gd
  ├─ armor_data.gd
  ├─ accessory_data.gd
  ├─ passive_effect_data.gd
  ├─ blueprint_data.gd
  ├─ loot_table_data.gd
  └─ catalog/weapons/swords/iron_sword/
       ├─ data/iron_sword.tres          # WeaponData, rarity=COMMON, slot=WEAPON
       └─ sprites/iron_sword_icon.png   # placeholder icon

src/entities/systems/equipment/
  ├─ player_equipment_data.gd
  └─ player_equipment_component.gd

src/core/
  ├─ loot_service.gd
  ├─ crafting_service.gd
  └─ mastery_service.gd

src/core/events/
  └─ item_events.gd

src/entities/skills/combat/
  ├─ slash/
  │    ├─ data/slash.tres               # SkillData, element=NONE, type=ATTACK
  │    └─ sprites/slash_icon.png
  ├─ fireball/
  │    ├─ data/fireball.tres            # SkillData, element=FIRE, type=ATTACK
  │    └─ sprites/fireball_icon.png
  └─ heal/
       ├─ data/heal.tres                # SkillData, element=NONE, type=HEAL
       └─ sprites/heal_icon.png
```

## Files to Modify

```
src/entities/systems/combat/data/combatant_snapshot.gd
  → add: var passive_effect: PassiveEffectData = null

src/core/player_progression_service.gd
  → build_player_snapshot(): wire equipment bonuses + mastery skill variants

src/core/player_profile_service.gd
  → add save/load for [equipment], [mastery], [blueprints] sections

src/entities/systems/combat/combat_round_resolver.gd
  → after each phase: evaluate passive_effect proc (trigger_chance + value)

src/world/combat/combat_scene.gd
  → on combat win: call LootService + MasteryService

project.godot
  → register LootService, CraftingService, MasteryService, ItemEvents as autoloads
```

---

## Asset Placement Convention

Icons are co-located with their data resource, following `ItemData`'s existing auto-resolve behavior (confirmed in `item_data.gd` — icon resolved from `<item_folder>/sprites/`):

```
# Equipment
src/entities/items/catalog/<category>/<name>/sprites/<name>_icon.png

# Skills
src/entities/skills/<type>/<skill_name>/sprites/<skill_name>_icon.png
```

`EquipmentData extends ItemData` — inherits icon auto-resolve for free.  
`SkillData.icon` field already exists — set it to the png path in the `.tres` file.

---

## Out of Scope (This Iteration)

- Inventory / Equipment UI screens (separate design session)
- Blacksmith / Shop NPC scenes
- Full item catalog (seed: 1 weapon + 3 skills only, to validate pipeline)
- Set bonuses
- Durability / item degradation
- Auction house / player trading
- Shop / merchant system
