# Implementation Plan: Creature Wander Navigation Compliance

Branch: feature/creature-wander-nav-respect
Created: 2026-02-15

## Settings
- Testing: yes
- Logging: verbose

## Scope
- Make ambient wandering creatures respect the active navigation map.
- Ensure creature wander targets avoid navigation blocker `Polygon2D` regions using the same blocker policies used by player move requests.
- Keep safe fallbacks when navigation dependencies are missing so creatures do not hard-fail outside overworld.

## Commit Plan
- Commit 1 (after tasks 1-3): `feat(creatures): route ambient wander through nav + blocker policies`
- Commit 2 (after tasks 4-6): `test(creatures): cover wander nav wiring and update docs`

## Tasks

### Phase 1: Runtime Integration
- [x] Task 1: Add blocker-policy component wiring to creature runtime scene and ensure spawned creatures can resolve blocker polygons from overworld registry.
  Files: `src/entities/creatures/base/creature.tscn`, `src/world/overworld/overworld_creature_spawner.gd`
  Logging (verbose): log once per spawned creature when blocker registry wiring succeeds/fails in debug builds (`[CreatureSpawner]` prefix).

- [x] Task 2: Refactor `CreatureWanderComponent` to use `CreatureNavigationComponent` for path-following movement and use blocker target resolution before setting wander targets.
  Files: `src/entities/creatures/components/wander/creature_wander_component.gd`
  Logging (verbose): add debug-level traces for target pick attempts/rejections (blocked target, nav rejection reason, fallback path) and warnings for missing dependencies.

- [x] Task 3: Preserve robust fallback behavior when nav/blocker dependencies are unavailable (direct movement fallback + existing timers) while still honoring spawn-radius enforcement.
  Files: `src/entities/creatures/components/wander/creature_wander_component.gd`
  Logging (verbose): emit one-time fallback mode notices and per-failure retry reasons in debug builds.

### Phase 2: Validation and Docs
- [x] Task 4: Extend creature runtime smoke validation to assert the blocker component is present and wired on runtime creature instances.
  Files: `src/entities/creatures/tests/creature_runtime_smoke_test.gd`
  Logging (verbose): keep existing fail-first test output and add explicit failure message for missing blocker component.

- [x] Task 5: Run headless validation for spawn-zone helpers and creature runtime smoke to verify no regressions after wander-nav integration.
  Files: none (command validation only)
  Logging (verbose): capture pass/fail summaries and surface any new warnings tied to wander/nav integration.

- [x] Task 6: Update creature workflow docs with wander-navigation behavior notes (nav-region compliance, blocker polygon avoidance, dependency expectations).
  Files: `src/entities/creatures/README.md`
  Logging (verbose): not applicable (documentation task).

## Acceptance Criteria
- Wandering creatures use nav path directions (instead of straight-line through blockers) whenever navigation is available.
- Wander target candidates are resolved through blocker policies and do not intentionally target blocked polygons.
- Spawned creatures in overworld receive blocker-registry wiring consistently.
- Headless validation scripts continue to pass.
