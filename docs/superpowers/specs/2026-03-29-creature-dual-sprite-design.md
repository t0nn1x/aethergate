# Creature Dual-Sprite Rendering

**Date:** 2026-03-29
**Branch:** feature/ui

## Summary

Creatures on the overworld should render their native 16×16 sprite sheet (`Name.png`)
instead of the 32×32 sheet (`Name_128x32.png`) scaled down 50%.
In combat, the existing 32×32 sprite is used unchanged.

## Problem

The catalog builder scans `*_128x32.png` files and sets them as the sole `sprite_sheet`.
`creature.gd` then applies `non_boss_world_scale = Vector2(0.5, 0.5)` to the whole
Creature node, making 32px sprites appear 16px on the overworld.
This anti-pattern scales the collision shape down too (effective radius 4px) and renders
artwork at half resolution instead of native pixels.

## Design

### `creature_data.gd`

Add one new exported field in the **Sprite** group:

```gdscript
@export var overworld_sprite_sheet: Texture2D
```

Change the default of `non_boss_world_scale` from `Vector2(0.5, 0.5)` to `Vector2(1.0, 1.0)`.

No new path string field is needed; the catalog builder derives the path internally.

### `creature_catalog_builder.gd`

Add constants:

```
OVERWORLD_FRAME_SIZE: int = 16
```

In `_apply_entry_to_data()`, after populating `sprite_sheet`:

1. Derive overworld path: replace `_128x32.png` suffix with `.png` in the battle sprite path.
2. Load it with `_try_load_texture()`.
3. Validate it exists and has height == 16 (skip silently if missing — future-proof).
4. Set `creature_data.overworld_sprite_sheet = <loaded texture>`.
5. Set `creature_data.non_boss_world_scale = Vector2(1.0, 1.0)`.

Creatures that have no 16px sprite leave `overworld_sprite_sheet = null` and fall back
gracefully in `creature.gd`.

### `creature.gd` — `_apply_visual_data()`

Priority:

1. If `data.overworld_sprite_sheet` is set → use it.
   - `hframes = max(1, overworld_sprite_sheet.get_width() / 16)`
   - `vframes = 1`, `frame = data.default_frame`
2. Else → existing behavior (use `sprite_sheet` / `source_sprite_path`, hframes from `data.hframes`).

No changes to `_apply_world_scale_from_data()` — it already reads `data.non_boss_world_scale`.

### Combat (unchanged)

`CombatantSnapshot.from_creature()` captures `sprite_sheet` (the 32×32 sheet) and its
existing frame dimensions. `desktop_combat_ui.gd` reads only from the snapshot.
Nothing changes in the combat rendering path.

## Scale change side-effect

`non_boss_world_scale` moves from 0.5 → 1.0.
The Creature node's effective collision radius goes from 4px → 8px (CircleShape2D radius 8.0).
This is intentional: 4px was an artifact of the scaling hack; 8px is a more reasonable
hit area for a 16×16 sprite.

## Rollout

1. Edit `creature_data.gd` (add field, change default).
2. Edit `creature_catalog_builder.gd` (derive + populate overworld sprite, set scale).
3. Edit `creature.gd` (`_apply_visual_data` override).
4. Run headless catalog rebuild — all `.tres` files updated in one pass.

No manual `.tres` edits required.
No combat code changes.
