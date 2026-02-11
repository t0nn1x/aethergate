# Implementation Plan: Player Pipeline Phase 1 Refactor

Branch: refactor-player-pipeline-phase1
Created: 2026-02-11

## Settings
- Testing: yes
- Logging: verbose

## Commit Plan
- Commit 1 (after tasks 1-3): `refactor: add player context and remove state lookup duplication`
- Commit 2 (after tasks 4-6): `refactor: split player move target blocking from input component`

## Tasks

### Phase 1: Player State Wiring
- [x] Task 1: Add `PlayerContext` component to centralize typed references to player runtime components and common states.
- [x] Task 2: Update `PlayerIdleState` to read dependencies from `PlayerContext` instead of repetitive `get_node_or_null` lookups.
- [x] Task 3: Update `PlayerPathMoveState` to read dependencies from `PlayerContext` and keep transition logic unchanged.

### Phase 2: Input Responsibility Split
- [x] Task 4: Add `PlayerMoveTargetBlockerComponent` responsible for nav-polygon blocker cache and world-position block checks.
- [x] Task 5: Refactor `PlayerInputComponent` to delegate blocker checks to the new component and remove local blocker cache logic.
- [x] Task 6: Wire new components in `player.tscn`, validate script references, and run lightweight regression checks.

## Logging Requirements
- Log warnings for missing critical runtime nodes (`PlayerContext` or blocker component) in debug builds.
- Keep logs behind debug checks where possible to avoid noisy release output.
- Include clear component names in warnings for quick traceability.
