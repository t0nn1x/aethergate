# Creature Dual-Sprite Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render creatures on the overworld using native 16×16 sprites, and in combat using the existing 32×32 sprites — eliminating the 50% scale hack.

**Architecture:** Add `overworld_sprite_sheet: Texture2D` and `OVERWORLD_FRAME_SIZE = 16` to `CreatureData`. The catalog builder derives the overworld sprite automatically by replacing `_128x32.png` with `.png` in the battle sprite path. `creature.gd._apply_visual_data()` prefers `overworld_sprite_sheet` when it exists, deriving hframes from `texture.get_width() / OVERWORLD_FRAME_SIZE`. Combat snapshot captures only `sprite_sheet`, so combat is untouched.

**Tech Stack:** Godot 4.6, GDScript, headless catalog builder, ResourceSaver/ResourceLoader

---

## File Map

| File | Change |
|------|--------|
| `src/Entities/Creatures/creature_data.gd` | Add `OVERWORLD_FRAME_SIZE` const; add `overworld_sprite_sheet: Texture2D`; change `non_boss_world_scale` default to `Vector2(1.0, 1.0)` |
| `src/Entities/Creatures/Tools/creature_catalog_builder.gd` | Derive and set `overworld_sprite_sheet` and `non_boss_world_scale` in `_apply_entry_to_data()` |
| `src/Entities/Creatures/creature.gd` | `_apply_visual_data()` uses `overworld_sprite_sheet` when set |

No combat files change. No combat snapshot changes.

---

### Task 1: Update `CreatureData` — new constant, new field, corrected scale default

**Files:**
- Modify: `src/Entities/Creatures/creature_data.gd`

- [ ] **Step 1: Add `OVERWORLD_FRAME_SIZE` constant**

In `creature_data.gd`, find:
```gdscript
## Data resource defining a creature's type, stats, sprite, and behavior.
## Create .tres instances for each creature variant (wolf, skeleton, etc.)

## The creature type categories matching the tileset.
enum CreatureType {
```
Replace with:
```gdscript
## Data resource defining a creature's type, stats, sprite, and behavior.
## Create .tres instances for each creature variant (wolf, skeleton, etc.)

## Pixel size of one frame in the overworld 16×16 sprite sheet.
const OVERWORLD_FRAME_SIZE: int = 16

## The creature type categories matching the tileset.
enum CreatureType {
```

- [ ] **Step 2: Change `non_boss_world_scale` default from 0.5 to 1.0**

In `creature_data.gd`, find:
```gdscript
@export var non_boss_world_scale: Vector2 = Vector2(0.5, 0.5)
```
Replace with:
```gdscript
@export var non_boss_world_scale: Vector2 = Vector2(1.0, 1.0)
```

- [ ] **Step 3: Add `overworld_sprite_sheet` field in the Sprite export group**

In `creature_data.gd`, find:
```gdscript
@export_group("Sprite")
@export var sprite_sheet: Texture2D
## 128x32 sheets default to 4 horizontal frames (4x 32x32).
```
Replace with:
```gdscript
@export_group("Sprite")
@export var sprite_sheet: Texture2D
## 16×16 sprite sheet used on the overworld (native pixels, no downscaling).
## Populated automatically by the catalog builder from the Name.png asset.
@export var overworld_sprite_sheet: Texture2D
## 128x32 sheets default to 4 horizontal frames (4x 32x32).
```

- [ ] **Step 4: Commit**

```bash
git add src/Entities/Creatures/creature_data.gd
git commit -m "feat(creatures): add overworld_sprite_sheet field and OVERWORLD_FRAME_SIZE to CreatureData"
```

---

### Task 2: Update catalog builder to populate `overworld_sprite_sheet`

**Files:**
- Modify: `src/Entities/Creatures/Tools/creature_catalog_builder.gd`

The builder currently ends `_apply_entry_to_data()` with a `validate_for_runtime` call. We add two lines before it: derive the overworld path from the battle path, load it, and set it on the resource. Also explicitly set `non_boss_world_scale` so all rebuilt `.tres` files carry the value regardless of the code default.

- [ ] **Step 1: Add overworld sprite and scale to `_apply_entry_to_data()`**

In `creature_catalog_builder.gd`, find:
```gdscript
	creature_data.validate_for_runtime(creature_data.creature_id)
```
Replace with:
```gdscript
	var overworld_path: String = sprite_path.replace("_128x32.png", ".png")
	creature_data.overworld_sprite_sheet = _try_load_texture(overworld_path)
	creature_data.non_boss_world_scale = Vector2(1.0, 1.0)

	creature_data.validate_for_runtime(creature_data.creature_id)
```

`_try_load_texture` returns `null` when the file doesn't exist, which is a valid no-op — `creature.gd` will fall back to `sprite_sheet` for any creature missing a 16px asset.

- [ ] **Step 2: Commit**

```bash
git add src/Entities/Creatures/Tools/creature_catalog_builder.gd
git commit -m "feat(creatures): catalog builder populates overworld_sprite_sheet from 16px asset"
```

---

### Task 3: Use `overworld_sprite_sheet` in `creature.gd`

**Files:**
- Modify: `src/Entities/Creatures/creature.gd:124-152`

- [ ] **Step 1: Replace `_apply_visual_data()` to prefer overworld sprite**

In `creature.gd`, replace the entire `_apply_visual_data` function with:

```gdscript
func _apply_visual_data(data: CreatureData) -> void:
	if _sprite == null:
		push_warning("Creature '%s': Sprite2D node is missing." % name)
		return

	var texture: Texture2D
	var hframes: int
	if data.overworld_sprite_sheet != null:
		texture = data.overworld_sprite_sheet
		hframes = maxi(1, texture.get_width() / CreatureData.OVERWORLD_FRAME_SIZE)
	else:
		texture = data.sprite_sheet
		if texture == null and not data.source_sprite_path.is_empty():
			texture = load(data.source_sprite_path) as Texture2D
		hframes = maxi(data.hframes, 1)

	if texture == null:
		push_warning(
			"Creature '%s': no sprite texture found (source='%s')."
			% [name, data.source_sprite_path]
		)
		return

	_sprite.texture = texture
	_sprite.hframes = hframes
	_sprite.vframes = maxi(data.vframes, 1)
	_sprite.frame = clampi(data.default_frame, 0, _sprite.hframes * _sprite.vframes - 1)

	if _silhouette == null:
		return

	_silhouette.texture = texture
	_silhouette.hframes = _sprite.hframes
	_silhouette.vframes = _sprite.vframes
	_silhouette.frame = _sprite.frame
	_apply_silhouette_color(data.silhouette_color)
```

- [ ] **Step 2: Commit**

```bash
git add src/Entities/Creatures/creature.gd
git commit -m "feat(creatures): overworld rendering uses native 16px sprite sheet"
```

---

### Task 4: Rebuild catalog and validate

**Files:**
- Rebuilt by tool: `src/Entities/Creatures/Resources/creature_catalog.tres` and all `Types/*/Data/*.tres`

- [ ] **Step 1: Run the headless catalog builder**

```bash
godot4 --headless --path . --scene res://src/Entities/Creatures/Tools/creature_catalog_builder_runner.tscn --quit
```

Expected last line:
```
CreatureCatalogBuilder summary: processed=<N> created=0 updated=<N> skipped=0 errors=0
```

If `errors > 0`, read the warnings above it — typically a missing `.png` file for a specific creature. Non-blocking (that creature falls back to `sprite_sheet`).

- [ ] **Step 2: Spot-check one `.tres` to confirm `overworld_sprite_sheet` was set**

```bash
grep "overworld_sprite_sheet\|AdventurousAdolescent.png" "src/Entities/Creatures/Types/Humanoids/Adventurous Adolescent/Data/humanoids_adventurous_adolescent.tres"
```

Expected: a line referencing `AdventurousAdolescent.png` (the 16px file, **not** `_128x32.png`).

- [ ] **Step 3: Run catalog validation**

```bash
godot4 --headless --path . --script res://src/Entities/Creatures/Tests/run_creature_catalog_validation.gd
```

Expected: no `ERROR:` lines in output.

- [ ] **Step 4: Run the runtime smoke test**

```bash
godot4 --headless --path . --scene res://src/Entities/Creatures/Tests/creature_runtime_smoke_test.tscn --quit-after 200
```

Expected: exits cleanly with no `ERROR:` lines.

- [ ] **Step 5: Commit rebuilt resources**

```bash
git add src/Entities/Creatures/Resources/creature_catalog.tres
git add src/Entities/Creatures/Types/
git commit -m "chore(creatures): rebuild catalog — overworld_sprite_sheet populated for all creatures"
```
