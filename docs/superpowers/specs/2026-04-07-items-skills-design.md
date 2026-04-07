# Items & Skills System Design
**Date:** 2026-04-07  
**Branch:** `feature/items-skills` (to be created)  
**Status:** Approved

---

## Summary

Gear-driven skills system inspired by Albion Online (gear = skills), with WoW-style equipment slots, rarity tiers (Common / Rare / Legendary), use-based mastery scaled by player level, a blueprint crafting system, and passive accessory procs. The combat resolver is untouched — all bonuses are baked into `CombatantSnapshot` before combat starts.

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
ItemData extends Resource                        (exists)
  └─ EquipmentData extends ItemData             (new)
       ├─ WeaponData extends EquipmentData      (new)
       ├─ ArmorData extends EquipmentData       (new — Helmet / Chest / Boots)
       └─ AccessoryData extends EquipmentData   (new)

SkillData extends Resource                       (exists)
PassiveEffectData extends Resource               (new)
BlueprintData extends Resource                   (new)
LootTableData extends Resource                   (new)
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
@export var item_family_id: StringName         # e.g. &"swords" — used for mastery tracking
@export var weapon_visual_id: StringName       # for combat sprite (maps to existing prop)
```

### ArmorData adds

```gdscript
@export var armor_slot: EquipmentSlot          # HELMET / CHEST / BOOTS
```

### AccessoryData adds

```gdscript
@export var passive_effect: PassiveEffectData
# skill_grants is always empty for accessories
```

### PassiveEffectData

```gdscript
class_name PassiveEffectData extends Resource

enum PassiveEffectType {
    POISON_ON_HIT, REGEN_ENERGY, REFLECT_DAMAGE, THORNS, LIFESTEAL
}

@export var effect_type: PassiveEffectType
@export var trigger_chance: float              # 0.0–1.0
@export var value: float                       # damage / hp / energy amount
```

### BlueprintData

```gdscript
class_name BlueprintData extends Resource

@export var blueprint_id: StringName
@export var display_name: String
@export var result_item: EquipmentData         # what gets crafted
@export var required_materials: Array[Dictionary]
# [{ "item_id": &"iron_ore", "amount": 3 }, ...]
```

### LootTableData

```gdscript
class_name LootTableData extends Resource

@export var entries: Array[Dictionary]
# [{ "item": ItemData, "weight": float, "min_player_level": int }, ...]
```

### Mastery — tracked in PlayerProfileService

```
# player_profile.cfg [mastery] section
# mastery_xp = Dictionary: item_family_id (StringName) → xp (int)
# e.g. "swords" = 340

mastery_level = f(xp, player_level)
  → unlocks mastery_variants[n] on SkillData
  → higher player level required to unlock higher mastery tiers
```

---

## New Systems

### PlayerEquipmentComponent (Node — child of Player scene)

```gdscript
# src/entities/systems/equipment/player_equipment_component.gd
signal equipment_changed(slot: EquipmentData.EquipmentSlot, item: EquipmentData)

@export var equipment_data: PlayerEquipmentData  # 5-slot Resource, @tool, saved to profile

func equip(item: EquipmentData) -> void
func unequip(slot: EquipmentData.EquipmentSlot) -> void
func get_all_skill_grants() -> Array[SkillData]
func get_passive_effect() -> PassiveEffectData   # from accessory slot
func get_total_stat_bonuses() -> CombatStats     # sum across all 5 slots
```

### LootService (autoload)

```gdscript
# src/entities/systems/loot/loot_service.gd
func roll_loot(creature_data: CreatureData) -> Array[ItemData]
# reads creature_data's LootTableData, weighted random roll
# result items go to player inventory via PlayerInventoryComponent
```

### CraftingService (autoload)

```gdscript
# src/entities/systems/crafting/crafting_service.gd
func can_craft(blueprint: BlueprintData) -> bool
func craft(blueprint: BlueprintData) -> EquipmentData
# consumes materials from PlayerInventoryComponent
# adds crafted EquipmentData to inventory
```

### MasteryService (autoload)

```gdscript
# src/entities/skills/mastery_service.gd
func award_mastery_xp(item_family_id: StringName, amount: int) -> void
func get_mastery_level(item_family_id: StringName, player_level: int) -> int
func get_active_skill_variant(skill: SkillData, item_family_id: StringName, player_level: int) -> SkillData
# returns mastery_variants[n] or base skill if not yet unlocked
```

---

## Combat Snapshot Assembly

`PlayerProgressionService.build_player_snapshot()` — called before every combat, **combat resolver unchanged**.

```
1. base stats       → calculate_stats(level)                          (exists)
2. equipment stats  → PlayerEquipmentComponent.get_total_stat_bonuses()  (new)
3. skill grants     → PlayerEquipmentComponent.get_all_skill_grants()
                      → each skill resolved via MasteryService.get_active_skill_variant()
4. passive effect   → PlayerEquipmentComponent.get_passive_effect()
5. emit snapshot    → CombatantSnapshot (combat resolver untouched ✓)
```

---

## Post-Combat Flow

```
combat_won signal emitted
  → LootService.roll_loot(enemy_data)          → items to inventory
  → MasteryService.award_mastery_xp(           → saved to [mastery] in profile
        equipped_weapon.item_family_id, xp)
  → PlayerProgressionService.award_xp(xp)      (exists)
  → CombatResultPanel shows loot + mastery progress
```

---

## Crafting Flow

```
Enemy drops BlueprintData (rare) → added to player blueprint collection
  → saved to PlayerProfileService [blueprints] section

Player visits Blacksmith NPC
  → CraftingUI lists known blueprints
  → CraftingService.can_craft(blueprint) checks inventory materials
  → CraftingService.craft(blueprint) → consumes materials → adds gear to inventory
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
       ├─ data/iron_sword.tres
       └─ sprites/iron_sword_icon.png

src/entities/systems/equipment/
  ├─ player_equipment_data.gd
  └─ player_equipment_component.gd

src/entities/systems/loot/
  └─ loot_service.gd

src/entities/systems/crafting/
  └─ crafting_service.gd

src/entities/skills/
  ├─ mastery_service.gd
  └─ combat/
       ├─ slash/data/slash.tres  +  sprites/slash_icon.png
       ├─ fireball/data/fireball.tres  +  sprites/fireball_icon.png
       └─ heal/data/heal.tres  +  sprites/heal_icon.png

src/core/events/
  └─ item_events.gd     # loot_dropped, item_equipped, blueprint_found
```

## Files to Modify

```
src/core/player_progression_service.gd    # wire equipment + mastery into build_player_snapshot()
src/core/player_profile_service.gd        # add [equipment], [mastery], [blueprints] save sections
src/entities/systems/combat/combat_round_resolver.gd  # passive_effect proc evaluation
src/world/combat/combat_scene.gd          # award mastery XP + trigger loot on win
project.godot                             # register LootService, CraftingService, MasteryService
```

---

## Asset Placement Convention

Icons are co-located with data, following the existing `ItemData` auto-resolve pattern:

```
src/entities/items/catalog/<category>/<name>/sprites/<name>_icon.png
src/entities/skills/combat/<skill_name>/sprites/<skill_name>_icon.png
```

`ItemData.gd` already auto-resolves icons from `<item_folder>/sprites/` — `EquipmentData` inherits this for free. `SkillData.icon` field is already defined — just populate it.

---

## Out of Scope (This Iteration)

- Inventory / Equipment UI screens
- Blacksmith / Shop NPC scenes
- Full item catalog (seed items only — iron sword + 3 skills to validate)
- Set bonuses
- Durability / item degradation
- Auction house / player trading
