# XP Indicator Redesign — Design Spec
Date: 2026-04-04

## Problem

The XP indicator widget exists in the HUD but never updates after the initial render. The root cause is that `xp_indicator.gd` guards every access to `PlayerProgressionService` and `PlayerProfileService` behind `Engine.has_singleton()`, which only returns `true` for C++ engine singletons — not GDScript autoloads. So signals are never connected and the display always shows defaults ("Level 1", "0 / 1").

## Design

### Layout
Horizontal compact — all content on a single row:
```
Lv 42  ████████░░░  720 / 1k
```

### Visual style
Ghost / minimal — semi-transparent dark pill, no colored border:
- Background: `rgba(10, 10, 12, 0.82)`, corner radius 6
- Level text: white at 60% opacity, 12 px
- Bar: 5 px tall, track at 10% white, fill at 65% white
- XP fraction text: white at 35% opacity, 10 px

### Spacing
`margin_bottom` on the `XpIndicator` node in `system_hud.tscn` increased from `12` to `20` to give a clear visual gap above the action slot row.

### Number formatting
Smart suffix compaction, applied to both current XP and XP-needed:

| Range              | Format example |
|--------------------|----------------|
| < 1,000            | `720`          |
| 1,000 – 9,999      | `1.2k`         |
| 10,000 – 999,999   | `42k`          |
| 1,000,000 – ...    | `1.2kk`        |
| 1,000,000,000+     | `1.2kkk`       |

One decimal shown only when it adds precision (e.g. `1.2k` but `10k` not `10.0k`).

At max level: bar fills to 100%, XP text shows `MAX`.

### Signal wiring fix
Remove all `Engine.has_singleton()` guards. Access `PlayerProgressionService` and `PlayerProfileService` directly (they are GDScript autoloads, globally accessible by name, always present at runtime). Connect `xp_gained` and `level_up` signals in `_ready()` unconditionally.

## Files to change

| File | Change |
|------|--------|
| `src/ui/common/xp_indicator/xp_indicator.gd` | Full rewrite — fix singleton guards, horizontal layout logic, new number formatter |
| `src/ui/common/xp_indicator/xp_indicator.tscn` | Rebuild scene to match horizontal layout (HBoxContainer replacing VBoxContainer) |
| `src/ui/desktop/hud/system_hud.tscn` | Bump `XpIndicator` margin_bottom from 12 → 20 |

## Out of scope
- Mobile HUD variant (separate scene, separate task)
- Level-up animation / XP gain animation
- Clicking the indicator to open a stats panel
