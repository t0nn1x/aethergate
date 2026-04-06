# XP & Levels System — Design Spec
_Date: 2026-04-03_

## Overview

Implement a 100-level player progression system with inverted geometric XP curve (slow start, faster at high levels), per-stat auto-growth, and a bonus point pool for manual stat allocation. XP is awarded from combat victories only; the architecture is extensible for future sources (fishing, gathering).

---

## Goals

- 100 levels with meaningful early progression and satisfying high-level acceleration
- Each level improves all four combat stats automatically (at configurable growth rates)
- Each level also grants bonus points the player can manually allocate to stats
- XP reward per enemy is defined on the creature (fixed, tier-based)
- Level-up shown in the post-combat result panel

## Non-Goals (deferred)

- Bonus point allocation UI (data model ready, screen deferred)
- Weapon damage derived from stats
- Skill unlock by level
- XP from non-combat sources

---

## XP Curve

**Inverted geometric decay:** each successive level requires _less_ XP than the previous.

```
xp_for_level(n) = int(xp_base * xp_decay ^ (n - 1))
```

- `xp_base` — XP needed for level 1→2 (hardest, e.g. 1000)
- `xp_decay` — decay factor, 0 < decay < 1 (e.g. 0.97)

Early levels demand real effort; by the 70s–80s each level-up feels like a reward for commitment. All parameters live in `PlayerLevelConfig` and are tunable without code changes.

---

## New Files

### `src/entities/player/resources/player_level_config.gd` + `.tres`

`Resource` holding all tunable progression parameters:

```gdscript
@export var xp_base: int = 1000
@export var xp_decay: float = 0.97
@export var max_level: int = 100

# Base stats at level 1
@export var base_max_hp: int = 80
@export var base_max_energy: int = 100
@export var base_attack: float = 8.0
@export var base_defense: float = 4.0

# Auto-growth added per level-up
@export var hp_growth: float = 12.0
@export var energy_growth: float = 3.0
@export var attack_growth: float = 1.5
@export var defense_growth: float = 0.8

# Bonus point pool
@export var bonus_points_per_level: int = 2
```

### `src/core/player_progression_service.gd`

Autoload registered in `project.godot`. Owns all progression logic; delegates raw persistence to `PlayerProfileService`.

**Signals:**
```gdscript
signal xp_gained(amount: int, new_xp: int, xp_needed: int)
signal level_up(new_level: int, new_stats: CombatStats, bonus_points_gained: int)
```

**Public API:**
```gdscript
func award_xp(amount: int) -> void
func xp_needed_for_level(level: int) -> int
func xp_progress() -> float                        # 0.0–1.0 for XP bar
func calculate_stats(level: int, allocations: Dictionary) -> CombatStats
func get_bonus_points_available() -> int
func allocate_bonus_point(stat_key: StringName) -> bool
func build_player_snapshot() -> CombatantSnapshot
```

`award_xp()` detects level-ups, accumulates bonus points into the profile, and emits `level_up` for each level crossed. `calculate_stats()` is pure/deterministic: `base + (level-1) * growth + bonus_allocations`.

---

## Modified Files

### `src/entities/creatures/base/creature_data.gd`

Add:
```gdscript
@export var xp_reward: int = 50
```

### `src/entities/systems/combat/data/combatant_snapshot.gd`

Add:
```gdscript
var xp_reward: int = 0
```

Update `from_creature()` to copy `creature_data.xp_reward`.

### `src/core/player_profile_service.gd`

- `add_xp()` becomes a dumb persistence method (no level-up logic — that moves to `PlayerProgressionService`)
- Add getters/setters and persistence keys for `bonus_points_available` and `bonus_allocations: Dictionary`

### `src/world/combat/combat_scene.gd`

- On victory: call `PlayerProgressionService.award_xp(enemy_snapshot.xp_reward)`
- Listen for `PlayerProgressionService.level_up` between combat end and result panel; store `leveled_up` + `new_level`
- Pass those to `result_panel.show_result()`

### `src/ui/common/combat_result_panel/combat_result_panel.gd` + `.tscn`

- `show_result()` gains `leveled_up: bool` and `new_level: int` parameters
- Add a hidden `LevelUpLabel` node shown when `leveled_up == true`: `"⬆ Level {n}!"`

### Overworld creature selection (wherever `pending_player_snapshot` is set)

Replace manual player snapshot construction with:
```gdscript
CombatEvents.pending_player_snapshot = PlayerProgressionService.build_player_snapshot()
```

### `project.godot`

Register `PlayerProgressionService` as autoload.

---

## Data Flow

```
[Combat Victory]
    → CombatScene detects win
    → PlayerProgressionService.award_xp(enemy_snapshot.xp_reward)
        → PlayerProfileService persists new xp/level
        → emits level_up if threshold crossed
    → CombatScene captures level_up event
    → (1.4s delay)
    → CombatResultPanel.show_result(true, name, xp, leveled_up, new_level)

[Enter Combat]
    → PlayerProgressionService.build_player_snapshot()
        → reads level + allocations from PlayerProfileService
        → calls calculate_stats(level, allocations)
        → returns CombatantSnapshot with correct stats
```

---

## Testing

- Unit test `xp_needed_for_level()` — verify decay at levels 1, 50, 99
- Unit test `calculate_stats()` — verify base + growth + allocation math
- Unit test `award_xp()` — verify single and multi-level-up in one award
- Extend player profile migration test to cover new persistence keys
