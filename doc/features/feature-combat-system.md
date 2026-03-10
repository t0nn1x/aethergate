# Feature: Turn-Based Combat System

Branch: `feature/combat-system`
Created: 2026-03-09

## Scope

1v1 turn-based combat loop: tap creature on overworld, see preview card, enter full-screen combat scene with simultaneous round resolution, return to overworld on win/loss.

## Architecture

Self-contained bounded context split across two directories:

- `src/Entities/Systems/Combat/` — pure logic (resolver, context, flow controller, AI)
- `src/World/Combat/` — scene entry point
- `src/Ui/` — platform-split combat UI (Windows first, Mobile later)

### Data flow

```
Overworld tap → CreatureEvents.creature_fight_requested
  → CombatPreviewPanel (info card overlay)
    → [FIGHT] → store snapshots on CombatEvents → GameManager.COMBAT
      → main.gd loads combat_scene.tscn
        → CombatScene reads pending snapshots → CombatFlowController.start_combat()
          → Round loop: player action (20s timer) + AI action → CombatRoundResolver.resolve()
            → CombatContext.apply_result() → UI refresh
              → combat_ended → delay → return to main.tscn
```

### Key files

| File | Role |
|---|---|
| `Data/combat_stats.gd` | Shared stat block (HP, energy, attack, defense) |
| `Data/combat_action.gd` | Per-round action (actor + skill) |
| `Data/combatant_snapshot.gd` | Immutable snapshot at combat start |
| `Data/combat_round_result.gd` | Pure output of resolver (deltas, winner) |
| `combat_context.gd` | Mutable live state (HP, energy, round) |
| `combat_round_resolver.gd` | Stateless damage math |
| `combat_flow_controller.gd` | Round loop, 20s timer, AI submission |
| `Ai/combat_ai_strategy.gd` | Base class for creature AI |
| `Ai/weighted_random_strategy.gd` | Default: random affordable skill |
| `combat_events.gd` | Autoload: round_resolved, combat_ended, pending snapshots |

### Overworld integration

- `overworld.gd` listens to `creature_fight_requested`, shows `CombatPreviewPanel`
- On confirm: stores snapshots on `CombatEvents`, transitions to COMBAT state
- `main.gd` listens to `game_state_changed` and loads `combat_scene.tscn`
- On combat end: awards 50 XP if player wins, loads `main.tscn` (fresh overworld)

### XP/Level persistence

`PlayerProfileService` extended with `add_xp()`, level-up logic, and ConfigFile persistence under `[combat]` section.

## Testing

```bash
godot4 --headless --path . --script res://src/Entities/Systems/Combat/Tests/run_combat_tests.gd
```

11 headless tests covering: auto-attack damage, defense reduction, combat end conditions, winner detection, simultaneous kills, heal skills.

## Status

- All scripts complete (Tasks 1-16)
- Scenes built for Windows (combat_preview_panel.tscn, combat_scene.tscn, windows_combat_ui.tscn)
- Mobile combat UI scripted but scene not yet built
- Post-combat overworld resume reloads from scratch (no state persistence yet)

## Future work

- Mobile combat UI scene (`mobile_combat_ui.tscn`)
- Skill .tres data resources for Fireball/Slash/Heal
- Player gear-based skill loadout
- Post-combat overworld state preservation (avoid full reload)
- Status effects system
- Combat animations and visual polish
