# Items & Skills System

Gear-driven skills for combat. Equipping items grants the player skills and passives. All bonuses are baked into a `CombatantSnapshot` before combat starts — the resolver is unchanged except for passive proc evaluation.

---

## Overview

```
EquipmentData (resource)
  └─ WeaponData / ArmorData / AccessoryData
       └─ skill_grants: Array[SkillData]
       └─ passive_effect: PassiveEffectData   (accessory only)

PlayerEquipmentComponent (node, child of Player)
  └─ reads PlayerEquipmentData (resource, 5 typed slots)
  └─ auto-saves to player_profile.cfg [equipment]

PlayerProgressionService.build_player_snapshot()
  └─ bakes base stats + equipment bonuses + mastery-resolved skills + passives
  └─ → CombatantSnapshot (handed to CombatRoundResolver)

MasteryService (autoload)
  └─ tracks XP per weapon family in player_profile.cfg [mastery]
  └─ returns upgraded SkillData variants at tier thresholds
```

---

## Resource Classes

### `ItemData` (base, pre-existing)

Extended by all equipment types.

### `EquipmentData extends ItemData`
`src/entities/items/equipment_data.gd`

| Field | Type | Notes |
|---|---|---|
| `slot` | `EquipmentSlot` | WEAPON, HELMET, CHEST, BOOTS, ACCESSORY |
| `rarity` | `Rarity` | COMMON, RARE, LEGENDARY |
| `required_level` | `int` | |
| `stat_bonuses` | `CombatStats` | Added to player base stats at snapshot time |
| `skill_grants` | `Array[SkillData]` | Skills added to combat loadout when equipped |

### `WeaponData extends EquipmentData`
`src/entities/items/weapon_data.gd`

| Field | Type | Notes |
|---|---|---|
| `item_family_id` | `StringName` | e.g. `&"swords"` — key for mastery tracking |
| `weapon_visual_id` | `StringName` | For future combat sprite switching |

### `ArmorData extends EquipmentData`
`src/entities/items/armor_data.gd`

For HELMET / CHEST / BOOTS slots. No extra fields beyond `EquipmentData`.

### `AccessoryData extends EquipmentData`
`src/entities/items/accessory_data.gd`

| Field | Type | Notes |
|---|---|---|
| `passive_effect` | `PassiveEffectData` | Applied every combat phase (see below) |

No active `skill_grants` — accessories grant passives only.

### `PassiveEffectData`
`src/entities/items/passive_effect_data.gd`

| Field | Type | Notes |
|---|---|---|
| `effect_type` | `PassiveEffectType` | See table below |
| `trigger_chance` | `float` | 0–1. REGEN_ENERGY always triggers (ignore this field). |
| `value` | `float` | Damage / heal / energy amount |

**`PassiveEffectType` enum:**

| Value | Trigger side | Description |
|---|---|---|
| `POISON_ON_HIT` | Attacker | Chance to poison target on hit |
| `REGEN_ENERGY` | Attacker | Always restores `value` energy after phase |
| `REFLECT_DAMAGE` | Defender | Chance to reflect `value` damage back |
| `THORNS` | Defender | Chance to deal `value` damage on being hit |
| `LIFESTEAL` | Attacker | Chance to heal attacker for `value` on hit |

### `PlayerEquipmentData`
`src/entities/player/components/player_equipment_data.gd`

`@tool` Resource holding the 5 typed slots. Used for editor inspection and save/load.

```gdscript
var weapon: WeaponData
var helmet: ArmorData
var chest:  ArmorData
var boots:  ArmorData
var accessory: AccessoryData
```

Methods: `get_slot(slot: EquipmentSlot)`, `set_slot(slot, item)`, `get_all_equipped() -> Array[EquipmentData]`

---

## Node Components

### `PlayerEquipmentComponent`
`src/entities/player/components/player_equipment_component.gd`

Node child of the Player scene. Source of truth for what the player has equipped at runtime.

**Signals:**
```gdscript
signal equipment_changed(slot: EquipmentSlot, item: EquipmentData)
```

**Key methods:**

| Method | Returns | Notes |
|---|---|---|
| `equip(item: EquipmentData)` | `void` | Equips to correct slot, emits signal, auto-saves |
| `unequip(slot: EquipmentSlot)` | `void` | Clears slot, emits signal, auto-saves |
| `get_item_in_slot(slot)` | `EquipmentData` | Null if empty |
| `get_all_skill_grants()` | `Array[SkillData]` | Flat list from all equipped items |
| `get_total_stat_bonuses()` | `CombatStats` | Summed across all equipped items |
| `get_passive_effect()` | `PassiveEffectData` | From equipped accessory, or null |
| `get_weapon_family_id()` | `StringName` | From equipped weapon, or `&""` |

Auto-saves on every equip/unequip via `PlayerProfileService.save_equipment()`.

---

## Services

### `MasteryService` (autoload)
`src/core/mastery_service.gd` — registered in `project.godot`.

Tracks mastery XP per weapon family. XP persists in `player_profile.cfg [mastery]`.

**Thresholds:**

| Tier | XP required |
|---|---|
| Tier 1 | `100 + player_level * 5` |
| Tier 2 | `400 + player_level * 15` |

**Methods:**

| Method | Notes |
|---|---|
| `award_mastery_xp(family_id: StringName, amount: int)` | Capped at 100 XP per fight. Emits `PlayerEvents.mastery_xp_gained`. |
| `get_mastery_level(family_id, player_level) -> int` | Returns 0, 1, or 2 |
| `get_active_skill_variant(skill: SkillData, family_id, player_level) -> SkillData` | Returns upgraded variant at tier 1/2, base skill at tier 0 |

---

## Snapshot Assembly Pipeline

Called by `PlayerProgressionService.build_player_snapshot()` before every combat:

```
1. base_stats  = calculate_stats(player_level)
2. base_stats += PlayerEquipmentComponent.get_total_stat_bonuses()
3. For each skill in get_all_skill_grants():
       resolved = MasteryService.get_active_skill_variant(skill, family_id, level)
       snap.skill_loadout.append(resolved)
4. snap.passive_effect   = get_passive_effect()
5. snap.weapon_family_id = get_weapon_family_id()
```

`PlayerProgressionService` receives the equipment component via `set_equipment_component(comp)`, called by `OverworldPlayerSpawner` after the player is instantiated.

**Modified `CombatantSnapshot` fields:**

| Field | Type |
|---|---|
| `passive_effect` | `PassiveEffectData` |
| `weapon_family_id` | `StringName` |

---

## Passive Proc Flow

`CombatRoundResolver._apply_passive_procs()` is called after each combat phase.

```
Attacker passives:
  REGEN_ENERGY   → always: attacker.energy += value
  POISON_ON_HIT  → if randf() < trigger_chance: defender.hp -= value
  LIFESTEAL      → if randf() < trigger_chance: attacker.hp += value

Defender passives:
  THORNS         → if randf() < trigger_chance: attacker.hp -= value
  REFLECT_DAMAGE → if randf() < trigger_chance: attacker.hp -= value
```

Deltas are stored in `CombatPhaseResult`:

| Field | Description |
|---|---|
| `passive_attacker_hp_delta` | HP change to attacker from passives |
| `passive_defender_hp_delta` | HP change to defender from passives |
| `passive_attacker_energy_delta` | Energy change to attacker from passives |

---

## Post-Combat Mastery Award

In `CombatScene`, on combat win:

```gdscript
MasteryService.award_mastery_xp(snap.weapon_family_id, 10 + enemy_level * 2)
```

XP is capped at 100 per fight regardless of enemy level.

---

## Persistence

All stored in `user://player_profile.cfg`.

**`[equipment]` section** — resource paths per slot:
```ini
[equipment]
weapon = "res://src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword.tres"
helmet = ""
chest  = ""
boots  = ""
accessory = ""
```

**`[mastery]` section** — XP per family:
```ini
[mastery]
swords = 340
axes   = 60
```

Load/save methods on `PlayerProfileService`: `load_equipment()`, `save_equipment()`.

---

## Seed Content

Three combat skills and one weapon to validate the pipeline end-to-end.

| Resource | Type | Element | Power | Energy Cost |
|---|---|---|---|---|
| `slash.tres` | ATTACK | NONE | 15 | 10 |
| `fireball.tres` | ATTACK | FIRE | 25 | 20 |
| `heal.tres` | HEAL | NONE | 20 | 15 |

**Iron Sword** (`iron_sword.tres`): COMMON WeaponData, `item_family_id = &"swords"`, grants Slash.

Paths:
```
src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword.tres
src/entities/skills/combat/slash/data/slash.tres
src/entities/skills/combat/fireball/data/fireball.tres
src/entities/skills/combat/heal/data/heal.tres
```

---

## Testing Equipment Now (No Loot UI Yet)

Equip items in code — `OverworldPlayerSpawner` is the right place, after `set_equipment_component` is called:

```gdscript
var sword: WeaponData = load(
    "res://src/entities/items/catalog/weapons/swords/iron_sword/data/iron_sword.tres"
)
player_instance.equipment_component.equip(sword)
```

Start a combat — the player snapshot will contain the Slash skill in `skill_loadout`.

---

## What Is Out of Scope (Plan B)

The economy layer is not implemented yet:

- `LootService` / `LootTableData` — item drop on kill
- `CraftingService` / `BlueprintData` — crafting recipes
- `ItemEvents` — domain events for item pickup/drop
- Equipment UI — inventory and equip screens
