# Feature: Combat Attack VFX

Branch: `feature/combat-system`
Created: 2026-03-16

## Scope

Data-driven sprite-sheet VFX system for combat attacks. Each attack plays an animation centered over the target combatant's sprite. The HP bar updates at a configurable "impact frame" mid-animation rather than immediately, giving a satisfying split-timing feel.

## Architecture

### Key files

| File | Role |
|---|---|
| `src/entities/Systems/Combat/Data/combat_vfx_config.gd` | Value object — 5 fields describing one VFX effect |
| `src/ui/common/combat/combat_vfx_player.gd` | Control node — drives frame animation via Timer, emits `impact_hit` / `finished` |
| `src/entities/Skills/Combat/skill_data.gd` | `@export_group("VFX")` fields for skill-specific VFX |
| `src/entities/Systems/Combat/Data/combatant_snapshot.gd` | `default_attack_vfx_pool` + fallback single-config fields for auto-attacks |
| `src/ui/Windows/Combat/windows_combat_ui.gd` | Wires VFX players, defers HP bar / log update to `impact_hit` |
| `src/world/overworld/overworld.gd` | Populates player snapshot's VFX pool in `_build_player_snapshot()` |

### VFX config fields

```gdscript
var texture: Texture2D   # sprite sheet
var hframes: int          # number of horizontal frames
var fps: float            # playback speed
var impact_frame: int     # frame index when HP bar updates (0-based)
var scale: float          # size multiplier relative to the sprite container
var target: VfxTarget     # DEFENDER (default) or ATTACKER (self-buff)
```

### Timing model

```
play() called
  → frame 0 shown immediately
  → if impact_frame == 0: impact_hit emitted now
  → Timer ticks at 1/fps intervals, advancing frames
  → at impact_frame: impact_hit emitted → HP bar drops + log entry written
  → at last frame: finished emitted, node hides
  → if combat_ended == true: VFX still plays; result panel appears on top (layer 55)
```

### Priority order in `_build_vfx_config()`

1. Skill has `vfx_texture` set → use skill VFX
2. Snapshot has non-empty `default_attack_vfx_pool` → pick randomly
3. Snapshot has single `default_attack_vfx_texture` set → use that
4. None → `impact_hit` fires immediately (graceful no-op, no animation)

### Adding a new auto-attack VFX (player)

Append a path to the array in `overworld.gd → _build_player_snapshot()`:

```gdscript
for vfx_path: String in [
    "res://src/entities/Systems/Combat/Assets/VFX/Hit Horizontal White.png",
    "res://src/entities/Systems/Combat/Assets/VFX/Hit Vertical White.png",
    # add new paths here
]:
```

### Adding VFX to a skill

Set the six `vfx_*` fields on the `SkillData` resource in the Godot editor. For self-buffs, set `vfx_target` to `ATTACKER` so the VFX plays over the caster instead of the enemy.

## Assets

VFX sprite sheets live in `src/entities/Systems/Combat/Assets/VFX/`. All are 5-frame horizontal strips (single row).

| File | Used for |
|---|---|
| `Hit Horizontal White.png` | Player auto-attack pool |
| `Hit Vertical White.png` | Player auto-attack pool |

## Known Gaps / Future Work

- Enemy creatures do not have VFX yet — `from_creature()` in `CombatantSnapshot` does not populate `default_attack_vfx_pool`. Planned: add VFX fields to `CreatureData` and propagate via catalog builder.
- Mobile UI (`MobileCombatUi`) has no sprite containers — VFX is desktop-only for now.
- VFX fills the full sprite TextureRect bounds regardless of the sprite's rendered area. Noticeable only for sprites with significant letterboxing.
