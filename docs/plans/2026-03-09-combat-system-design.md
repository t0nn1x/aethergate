# Combat System Design

**Date:** 2026-03-09
**Status:** Approved

## Summary

Tactical turn-based combat with gear-defined roles (Albion-inspired) and simultaneous round resolution. Mobile-first, MMO-ready architecture. Built as a self-contained bounded context that slots into the existing GameManager state machine without disrupting the overworld.

---

## Design Decisions

| Decision | Choice | Notes |
|---|---|---|
| Initiation | Tap creature → preview card → full-screen combat scene | Preview card lets player assess risk before committing |
| Participants | 1v1 now, data model group-ready | CombatantSnapshot array, not hardcoded pairs |
| Resolution | Simultaneous with action timer | Both submit → server resolves → result emitted |
| Skills | Hybrid: base skills + gear-granted skills | Base attack/dodge always available; gear adds depth |
| Progression | Levels + Gear + Gear Mastery (3 axes) | See Progression section |
| Loss | Soft loss now (respawn, resource penalty) | Zone-based risk designed in, implemented later |
| Scene location | `src/World/Combat/` entry, `src/Entities/Systems/Combat/` logic | Mirrors Overworld pattern |

---

## Architecture

### Flow

```
OVERWORLD
  └─ Player taps creature
       └─ OverworldCreatureSelectionController
            └─ CreatureEvents.combat_preview_requested(creature_data)
                 └─ CombatPreviewPanel (AdaptiveOverlayPanel, overworld overlay)
                      ├─ [FIGHT] → GameManager.change_state(COMBAT)
                      │             → loads src/World/Combat/combat_scene.tscn
                      └─ [X]     → dismiss, overworld resumes

COMBAT SCENE
  ├─ CombatFlowController   owns round loop + action timer
  ├─ CombatRoundResolver    pure stateless node: actions in → result out
  ├─ CombatContext          live state (HP, energy, round number)
  └─ CombatUi               skill bar, HP bars, round log, countdown

  Round loop:
    1. Timer starts (20s)
    2. Player submits CombatAction (skill tap) — auto base attack on timeout
    3. Enemy AI submits CombatAction (instant)
    4. CombatRoundResolver.resolve(context, p_action, e_action) → CombatRoundResult
    5. CombatFlowController applies deltas to CombatContext
    6. CombatEvents.round_resolved(result)
    7. UI animates result
    8. Repeat or → CombatEvents.combat_ended(winner, loot, xp)
         └─ GameManager.change_state(OVERWORLD)
```

### Scene Structure

```
src/World/Combat/
  ├─ combat_scene.tscn        ← entry point loaded by GameManager
  └─ combat_scene.gd          ← wires CombatFlowController + UiManager

src/Entities/Systems/Combat/
  ├─ Data/
  │    ├─ combat_stats.gd
  │    ├─ combatant_snapshot.gd
  │    ├─ combat_action.gd
  │    └─ combat_round_result.gd
  ├─ Ai/
  │    ├─ combat_ai_strategy.gd         ← base Resource (swappable per creature)
  │    └─ weighted_random_strategy.gd   ← default
  ├─ combat_context.gd
  ├─ combat_round_resolver.gd
  └─ combat_flow_controller.gd

src/Entities/Skills/Combat/
  ├─ skill_data.gd                      ← base Resource (already scaffolded)
  ├─ Fireball/
  ├─ Slash/
  └─ Heal/

src/Core/Events/
  └─ combat_events.gd                   ← new autoload

src/Ui/Common/CombatPreviewPanel/
  ├─ combat_preview_panel.tscn
  └─ combat_preview_panel.gd

src/Ui/Windows/Combat/                  ← desktop UI layout
src/Ui/Mobile/Combat/                   ← mobile UI layout
```

---

## Data Model

```gdscript
# CombatStats — shared stat block
var max_hp: int
var max_energy: int
var attack: float
var defense: float
var speed: float       # reserved for future initiative systems

# CombatantSnapshot — immutable, taken at combat start
var display_name: String
var portrait: Texture2D
var level: int
var base_stats: CombatStats
var gear_slots: Array[GearData]
var skill_loadout: Array[SkillData]   # resolved: base skills + gear skills

# GearData — extends ItemData
var gear_slot: GearSlot               # WEAPON, OFFHAND, HELM, CHEST, BOOTS, ACCESSORY
var stat_bonuses: CombatStats
var granted_skill: SkillData
var mastery_level: int                # 0–10

# SkillData
var skill_id: StringName
var display_name: String
var energy_cost: int
var base_power: float
var element: Element                  # FIRE, WATER, EARTH, ARCANE, NONE
var skill_type: SkillType             # ATTACK, DEFEND, HEAL, BUFF, DEBUFF
var mastery_variants: Array[SkillVariantData]

# CombatAction — created each round
var actor_id: StringName
var skill_used: SkillData

# CombatRoundResult — output of resolver, pure data
var round_number: int
var player_action: CombatAction
var enemy_action: CombatAction
var hp_delta_player: int
var hp_delta_enemy: int
var status_effects_applied: Array[StatusEffect]
var combat_ended: bool
```

---

## Progression System

Three independent axes:

### Levels (character-wide)
- XP earned from combat → level up → raises base CombatStats (HP, energy, attack, defense)
- Stored in `PlayerProfileService` (persisted to `user://player_profile.cfg`)

### Gear (role / identity)
- 6 equipment slots: WEAPON, OFFHAND, HELM, CHEST, BOOTS, ACCESSORY
- Each slot contributes stat bonuses + one skill to the skill bar
- Swapping gear changes role instantly — no respec cost
- Implemented in `src/Entities/Systems/Equipment/` (already scaffolded)

### Gear Mastery (depth / specialization)
- Each GearData tracks `mastery_level` (0–10) per player
- Mastery XP earned only when that piece is equipped during combat
- Unlock tiers at 3 / 6 / 10 — stronger `SkillVariantData` for that piece
  - Example: Iron Sword mastery 3 → "Heavy Slash", mastery 6 → "Cleave", mastery 10 → "Execution"
- Stored in `GearMasteryRegistry` resource, persisted alongside equipment
- Switching weapons resets mastery progress on that weapon

---

## Combat Preview Panel

Pre-fight info card shown before entering combat. Extends `AdaptiveOverlayPanel`.

Shows:
- Target name, level, creature type / element
- Rough power comparison ("Stronger / Even / Weaker")
- Gear slot hints (icons only, not full stats)

Buttons: **[FIGHT]** and **[X / Flee]**

---

## Mobile UI Layout (portrait 1080×1920)

```
┌─────────────────────┐
│   Enemy portrait    │  ← top 35%: enemy panel, name, level, HP bar
│   [HP ████░░░░]     │
├─────────────────────┤
│   Round log         │  ← middle 25%: scrolling combat feed
├─────────────────────┤
│   [HP ████████]     │  ← bottom 40%: player HP/energy + skill bar + timer
│   [EN ████░░░░]     │
│  [⚔][🔥][🛡][💊]   │
│     [ 18s ◷ ]       │
└─────────────────────┘
```

---

## Integration with Existing Systems

| Existing system | Change |
|---|---|
| `GameManager` | No change — COMBAT state and transitions already exist |
| `CreatureEvents` | Add: `combat_preview_requested`, `combat_requested` |
| `PlayerProfileService` | Add: `player_level`, `player_xp`, `gear_mastery` dict |
| `OverworldCreatureSelectionController` | Extend: tap emits `combat_preview_requested` |
| `CreatureData` | Extend: add `base_combat_stats`, `ai_strategy`, `skill_loadout` |
| `src/Entities/Systems/Equipment/` | Implement: resolve `skill_loadout` from equipped gear |
| `src/Entities/Skills/Combat/` | Add: `skill_data.gd` base resource + per-skill `.tres` files |

---

## Future / Out of Scope for MVP

- Zone-based risk tiers (safe / yellow / red zones) — designed in, not implemented
- Group combat (party vs. mob) — data model supports it, not wired up
- PvP — simultaneous resolution model is network-ready, transport not built yet
- Status effect system — field reserved in `CombatRoundResult`, not implemented
- Enemy AI beyond weighted random
