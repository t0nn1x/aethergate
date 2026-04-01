# Player Tools

## Rebuild Player Cosmetic Catalog

Use this when you add/remove player skin presets in:

- `src/Entities/player/assets/<skin_id>/32x32/normal_body_idle.png`

Runner scene:

- `res://src/Entities/player/tools/player_cosmetic_catalog_builder_runner.tscn`

What it does:

- scans each `assets/<skin_id>/32x32/normal_body_idle.png`
- validates expected size `128x32`
- preserves existing IDs for unchanged files
- assigns next IDs for new skin presets (`head_3`, `body_3`, `legs_3`, etc.)
- removes missing entries
- saves `src/Entities/player/resources/player_cosmetic_catalog.tres` as a legacy slot-compatibility catalog

How to run (Editor):

1. Open `player_cosmetic_catalog_builder_runner.tscn`.
2. Run Current Scene (`F6`).
3. Check `player_cosmetic_catalog.tres` diff and commit.

How to run (CLI, if Godot is on PATH):

```bash
godot4 --headless --path . --scene res://src/Entities/player/tools/player_cosmetic_catalog_builder_runner.tscn
```
