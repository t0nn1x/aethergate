# Feature: XP & Level Progression

Branch: `feature/xp-levels`
Created: 2026-04-04

## Scope

Full player levelling system: earn XP from combat victories, level up automatically, gain base stat growth and bonus points per level. HUD widget shows current level, XP bar, and compact XP fraction. Debug panel supports XP injection and direct level forcing.

## Architecture

Three layers: **config resource** (tunable curve) → **service** (logic + signals) → **UI** (reactive display).

```
Combat victory
  → PlayerProgressionService.award_xp(amount)
    → level_up.emit(new_level, CombatStats, bonus_points)   ← zero or more times
    → xp_gained.emit(amount, new_xp, xp_needed)             ← always once
      → XpIndicator._on_level_up / _on_xp_gained
        → _update_level / _update_progress
          → reads PlayerProfileService for ground truth
            → updates Label + ProgressBar in HUD
```

### Key files

| File | Role |
|---|---|
| `src/entities/player/resources/player_level_config.gd` | `PlayerLevelConfig` resource — XP curve params, base stats, growth per level, bonus points |
| `src/entities/player/resources/player_level_config.tres` | Tunable instance (edit in inspector, no code needed) |
| `src/core/player_progression_service.gd` | Autoload — owns `award_xp`, `xp_needed_for_level`, `calculate_stats`, `build_player_snapshot`; emits `xp_gained` and `level_up` |
| `src/core/player_profile_service.gd` | Autoload — persists `player_level` and `player_xp` to `user://player_profile.cfg` via `set_xp_and_level` / `get_player_level` / `get_player_xp` |
| `src/ui/common/xp_indicator/xp_indicator.tscn` | HUD widget scene — ghost pill (PanelContainer → HBoxContainer) |
| `src/ui/common/xp_indicator/xp_indicator.gd` | Widget script — connects signals, formats numbers, updates display |
| `src/ui/desktop/hud/system_hud/system_hud.tscn` | Hosts `XpIndicator` above the action slot row |
| `src/ui/mobile/hud/system_hud/system_hud_mobile.tscn` | Mobile HUD — also hosts `XpIndicator` |
| `src/ui/common/debug/debug_panel.gd` | XP & LEVEL section — XP injection buttons, level presets, custom level input |

## XP Curve

Formula: `xp_needed_for_level(n) = max(1, xp_base + xp_growth × (n - 1))`

Default config (`player_level_config.tres`):

| Parameter | Value | Effect |
|---|---|---|
| `xp_base` | 200 | XP required to level up from Lv 1 |
| `xp_growth` | 50 | Additional XP required per level |
| `max_level` | 100 | Cap — bar fills to 100%, label shows "MAX" |

Level 1 → Lv 2 costs 200 XP. Level 99 → Lv 100 costs 200 + 98×50 = 5,100 XP. Linear — consistently harder each level.

## Stat Growth

Applied automatically on every level-up. No code needed to tune — edit `player_level_config.tres`.

| Stat | Base (Lv 1) | Growth per level |
|---|---|---|
| Max HP | 80 | +5 |
| Max Energy | 100 | +2 |
| Attack | 8.0 | +0.5 |
| Defense | 4.0 | +0.25 |

Stat growth is automatic — no manual allocation. Equipment will be the primary source of build variety (to be implemented).

## HUD Widget — XpIndicator

Ghost minimal pill above the action slots. All on one horizontal row:

```
[ Lv 42 ] [████████░░░░] [ 720 / 1k ]
```

- **Level label** — `"Lv %d"`, white 60% opacity, 12 px
- **Bar** — 80×8 px minimum, white track 10% / fill 65%, no percentage text overlay
- **XP label** — compact fraction, white 35% opacity, 10 px

### Number formatting (`_format_number`)

| Range | Example output |
|---|---|
| < 1,000 | `720` |
| 1k – 9.9k | `1.2k` |
| 10k – 999k | `42k` |
| 1kk – 9.9kk | `1.2kk` |
| 10kk – 999kk | `500kk` |
| 1kkk+ | `1.5kkk` |

`kk` = million, `kkk` = billion. Values above 10 billion are rounded to the nearest kkk. **Requires 64-bit int** throughout the XP pipeline (`KKK` and `BIG_KKK` exceed 32-bit range).

At max level the XP label shows `MAX` and the bar fills to 100%.

### Signal wiring (important)

`PlayerProgressionService` and `PlayerProfileService` are GDScript **autoloads** — they must be accessed **directly by name**, not via `Engine.has_singleton()` (which only works for C++ singletons and always returns `false` for GDScript autoloads).

```gdscript
# CORRECT
PlayerProgressionService.xp_gained.connect(_on_xp_gained)

# WRONG — returns false, signals never connect, UI never updates
if Engine.has_singleton("PlayerProgressionService"):
    ...
```

### Multi-level-up behaviour

When `award_xp` crosses multiple levels at once, `level_up` fires for each level crossed before `xp_gained` fires once with the final remainder. The indicator's `_on_level_up` resets the bar to 0 (with a comment noting `xp_gained` corrects it immediately after). This causes a one-frame flicker at most; it's intentional and documented in the code.

## Debug Panel

Open with **F3** (or the floating DBG button on mobile). Under **XP & LEVEL**:

| Control | Action |
|---|---|
| `+10 / +50 / +100 / +500 XP` | Calls `PlayerProgressionService.award_xp(n)` |
| `Lv 1 / Lv 10 / Lv 25 / Lv 50 / Lv 75 / Lv 100` | Force-sets level instantly |
| Level text input + Set | Force-sets any level 1–100 |

Force-setting a level via the debug panel:
1. Writes `(xp=0, level=N)` to `PlayerProfileService`
2. Recalculates bonus points as `(N-1) × bonus_points_per_level`
3. Emits `PlayerProgressionService.level_up` and `xp_gained` so all listeners (XP indicator, stat systems) update immediately

## Extending the System

**Tune the curve** — open `src/entities/player/resources/player_level_config.tres` in the Godot inspector and adjust `xp_base`, `xp_decay`, `max_level`, or stat growth values. No code changes needed.

**Add a new XP source** — call `PlayerProgressionService.award_xp(amount)` from anywhere. The service handles level-up loops, persistence, and signal emission.

**Listen for level-ups** — connect to `PlayerProgressionService.level_up(new_level: int, new_stats: CombatStats, bonus_points_gained: int)` from any node.

**Listen for XP gains** — connect to `PlayerProgressionService.xp_gained(amount: int, new_xp: int, xp_needed: int)`.

## Tests

```bash
# Progression service logic (award_xp, xp_needed_for_level, calculate_stats)
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script res://src/entities/player/tests/run_player_progression_service_test.gd

# XP indicator number formatter (k / kk / kkk)
# Note: runs in --script mode which can't compile xp_indicator.gd when autoloads
# are unavailable; number-formatting unit tests are in run_xp_indicator_validation_test.gd
# but require the full project scene to load (use --scene instead of --script)
```
