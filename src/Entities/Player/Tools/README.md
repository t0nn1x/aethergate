# Player Tools

## Rebuild Player Cosmetic Catalog

Use this when you add/remove part sprites in:

- `src/Entities/Player/Sprites/Parts/Head`
- `src/Entities/Player/Sprites/Parts/Body`
- `src/Entities/Player/Sprites/Parts/Legs`

Runner scene:

- `res://src/Entities/Player/Tools/player_cosmetic_catalog_builder_runner.tscn`

What it does:

- scans `Head/Body/Legs` folders for `.png`
- validates expected size `128x32`
- preserves existing IDs for unchanged files
- assigns next IDs for new files (`head_3`, `body_3`, etc.)
- removes missing entries
- saves `src/Entities/Player/Resources/player_cosmetic_catalog.tres`

How to run (Editor):

1. Open `player_cosmetic_catalog_builder_runner.tscn`.
2. Run Current Scene (`F6`).
3. Check `player_cosmetic_catalog.tres` diff and commit.

How to run (CLI, if Godot is on PATH):

```bash
godot4 --headless --path . --scene res://src/Entities/Player/Tools/player_cosmetic_catalog_builder_runner.tscn
```
