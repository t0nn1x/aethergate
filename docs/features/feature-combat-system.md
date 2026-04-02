# Feature: Turn-Based Combat System

Branch: `feature/combat-system`
Created: 2026-03-09

## Scope

1v1 turn-based combat loop: tap creature on overworld, see preview card, enter full-screen combat scene with sequential phase resolution (player phase, then enemy phase), return to overworld on win/loss.

## Architecture

Self-contained bounded context split across two directories:

- `src/entities/Systems/Combat/` — pure logic (resolver, context, flow controller, AI)
- `src/world/combat/` — scene entry point
- `src/ui/` — platform-split combat UI (Windows first, Mobile later)

### Data flow

```
Overworld tap → CreatureEvents.creature_fight_requested
  → CombatPreviewPanel (info card overlay)
    → [FIGHT] → store snapshots on CombatEvents → GameManager.COMBAT
      → main.gd loads combat_scene.tscn
        → CombatScene reads pending snapshots → CombatFlowController.start_combat()
          → Turn loop: player phase (20s timer) → CombatRoundResolver.resolve_phase()
            → CombatContext.apply_phase_result() → player-phase UI refresh
              → enemy phase (~1s pause) → resolve_phase() → enemy-phase UI refresh
                → round_completed or combat_ended → delay → return to main.tscn
```

### Key files

| File | Role |
|---|---|
| `Data/combat_stats.gd` | Shared stat block (HP, energy, attack, defense) |
| `Data/combat_action.gd` | Per-round action (actor + skill) |
| `Data/combatant_snapshot.gd` | Immutable snapshot at combat start |
| `Data/combat_phase_result.gd` | Pure output of a single phase (attacker/defender, deltas, end flag) |
| `Data/combat_round_result.gd` | Aggregated output for full turn (player_phase + enemy_phase + winner) |
| `combat_context.gd` | Mutable live state (HP, energy, round) with per-phase application |
| `combat_round_resolver.gd` | Stateless per-phase resolution (`resolve_phase`) |
| `combat_flow_controller.gd` | Phase state machine, timers, and phase/round event emission |
| `Ai/combat_ai_strategy.gd` | Base class for creature AI (accepts optional player_phase_result) |
| `Ai/weighted_random_strategy.gd` | Default: random affordable skill (reactive hook reserved) |
| `combat_events.gd` | Autoload: player_phase_resolved, enemy_phase_resolved, round_completed, combat_ended |

### Overworld integration

- `overworld.gd` listens to `creature_fight_requested`, shows `CombatPreviewPanel`
- On confirm: stores snapshots on `CombatEvents`, transitions to COMBAT state
- `main.gd` listens to `game_state_changed` and loads `combat_scene.tscn`
- On combat end: awards 50 XP if player wins, loads `main.tscn` (fresh overworld)

### XP/Level persistence

`PlayerProfileService` extended with `add_xp()`, level-up logic, and ConfigFile persistence under `[combat]` section.

## Testing

```bash
godot4 --headless --path . --script res://src/entities/systems/combat/tests/run_combat_tests.gd
```

11 headless tests covering: auto-attack damage, defense reduction, combat end conditions, winner detection, simultaneous kills, heal skills.

## Status

- Combat flow migrated to sequential phase state machine
- Resolver and tests migrated to per-phase model
- Windows + Mobile combat UIs updated for per-phase updates and turn counter
- Post-combat overworld resume reloads from scratch (no state persistence yet)

## Future work

- Mobile combat UI scene (`mobile_combat_ui.tscn`)
- Skill .tres data resources for Fireball/Slash/Heal
- Player gear-based skill loadout
- Post-combat overworld state preservation (avoid full reload)
- Status effects system
- Combat animations and visual polish
