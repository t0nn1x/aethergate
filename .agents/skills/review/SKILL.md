---
name: ai-factory.review
description: Perform code review on staged changes or a pull request. Checks for bugs, security issues, performance problems, and best practices. Use when user says "review code", "check my code", "review PR", or "is this code okay".
argument-hint: [PR number or empty]
allowed-tools: Bash(git *) Bash(gh *) Read Glob Grep
---

# Code Review Assistant

Perform thorough code reviews focusing on correctness, security, performance, and maintainability.

## Behavior

### Without Arguments (Review Staged Changes)

1. Run `git diff --cached` to get staged changes
2. If nothing staged, run `git diff` for unstaged changes
3. Analyze each file's changes

### With PR Number/URL

1. Use `gh pr view <number> --json` to get PR details
2. Use `gh pr diff <number>` to get the diff
3. Review all changes in the PR

## Review Checklist

### Correctness
- [ ] Logic errors or bugs
- [ ] Edge cases handling
- [ ] Null/undefined checks
- [ ] Error handling completeness
- [ ] Type safety (if applicable)

### Security
- [ ] SQL injection vulnerabilities
- [ ] XSS vulnerabilities
- [ ] Command injection
- [ ] Sensitive data exposure
- [ ] Authentication/authorization issues
- [ ] CSRF protection
- [ ] Input validation

### Performance
- [ ] N+1 query problems
- [ ] Unnecessary re-renders (React)
- [ ] Memory leaks
- [ ] Inefficient algorithms
- [ ] Missing indexes (database)
- [ ] Large payload sizes

### Best Practices
- [ ] Code duplication
- [ ] Dead code
- [ ] Magic numbers/strings
- [ ] Proper naming conventions
- [ ] SOLID principles
- [ ] DRY principle

### Testing
- [ ] Test coverage for new code
- [ ] Edge cases tested
- [ ] Mocking appropriateness

### Godot-Specific
- [ ] NodePath resolution correctness (`self` vs `parent`)
- [ ] No strict-typing inference traps (`Variant` inference from `max/min/clamp` and similar)
- [ ] No GDScript accessor pitfalls (`field` keyword misuse, or setter self-assignment causing recursion/stack overflow)
- [ ] Dynamically-instanced UI controls are configured after entering the scene tree when logic depends on `@onready` child refs
- [ ] Resource setter logic is safe against deserialization-order effects (no coupled-field wipes like item/amount during `.tres` load)
- [ ] Layout/resize code does not reset runtime-bound UI data (icons/count labels stay intact after refresh/responsive updates)
- [ ] Overlay/panel toggles rebind required gameplay components before render so data-driven UI does not open unbound
- [ ] Drag/drop logic delegates transfer rules to inventory data/component layer (UI only dispatches payload/drop intent)
- [ ] Drag UX is coherent: source slot is visually hidden during drag and restored from data after drop/cancel
- [ ] Drag preview contains intended visuals only (for example icon/count, not full slot frame, when required by design)
- [ ] Scene/script reference integrity after moves (`.tscn` `ext_resource` paths and `.uid`)
- [ ] No stale legacy path prefixes remain after refactors (for example `res://src/UI/...` vs `res://src/Entities/Ui/...`) across scenes, scripts, and `project.godot`
- [ ] Input/navigation behavior still works (tap-to-move, hold retarget, blocked target resolution)
- [ ] If custom desktop cursors are used, hotspot alignment matches world-hit intent and cursor state does not regress after hover/click transitions
- [ ] Mouse input conversion uses consistent coordinate space (no window-space `InputEventMouse*.position` mixed with viewport/global-mouse paths in same interaction flow)
- [ ] Newly used Godot engine methods in input/camera code exist in target engine version (no non-existent API calls in runtime paths)
- [ ] New autoload channels are registered in `project.godot` and not referenced through undeclared compile-time singleton names
- [ ] Event-bus migrations preserve compatibility (legacy bridge/fallback exists while callers are being moved)
- [ ] No `get_nodes_in_group` polling in hot runtime paths where composition-root injection is expected
- [ ] Solo-first code keeps multiplayer seams (identity fields + authority checks) and does not bake in single-player-only assumptions
- [ ] Layered player sprites inside Y-sorted gameplay roots do not carry accidental fixed `z_index` overrides that break world occlusion sorting
- [ ] Supporting effects (silhouette/outline/shadow) are updated for every active visual part after sprite hierarchy changes (legs/body/head/weapon layers)
- [ ] `TextureRect` stretch/repeat settings match intent (avoid accidental tiling from `STRETCH_TILE` + expanded rects unless explicitly desired)
- [ ] Scrolling parallax layers avoid seam-prone wrap/repeat mismatches (`fract` UV wrapping with repeat disabled) and use pixel-snapped fit bounds with slight overscan where full-screen coverage is required
- [ ] Parallax/background folders either enforce same-sized layer images or use explicit canonical-size filtering before assignment
- [ ] Mobile/export resource loading does not rely only on `DirAccess` listing under `res://` (manifest or `ResourceLoader.exists()` fallback is present)
- [ ] Audio responsibilities are centralized (autoload/service) instead of duplicated per UI scene; SFX playback uses pooling/reuse patterns
- [ ] Platform-restricted lifecycle actions are handled correctly (e.g., iOS cannot programmatically quit; unsupported actions are hidden/disabled in UI and focus chain)
- [ ] Platform display startup logic matches intended UX (no unintended forced windowed mode on desktop, especially Windows fullscreen startup) and startup mode/resolution logs exist for verification
- [ ] `@tool` inspector code does not call methods on editor placeholder resources and does not eagerly load large preview texture sets in property list/get paths
- [ ] Overworld creature spawn/wander target sampling applies blocker-polygon rejection (not only zone containment), and blocker-registry wiring handles scene startup ordering safely
- [ ] Overlay UI panels reuse shared base architecture (`src/Entities/Ui/Common/Overlay/adaptive_overlay_panel.gd`) instead of duplicating safe-area + viewport-resize plumbing
- [ ] Panel/title styling is resource-driven via `src/Entities/Ui/Common/Styles` profiles and not copy-pasted style constants across scripts

## Output Format

```markdown
## Code Review Summary

**Files Reviewed:** [count]
**Risk Level:** 🟢 Low / 🟡 Medium / 🔴 High

### Critical Issues
[Must be fixed before merge]

### Suggestions
[Nice to have improvements]

### Questions
[Clarifications needed]

### Positive Notes
[Good patterns observed]
```

## Review Style

- Be constructive, not critical
- Explain the "why" behind suggestions
- Provide code examples when helpful
- Acknowledge good code
- Prioritize feedback by importance
- Ask questions instead of making assumptions

## Examples

**User:** `/review`
Review staged changes in current repository.

**User:** `/review 123`
Review PR #123 using GitHub CLI.

**User:** `/review https://github.com/org/repo/pull/123`
Review PR from URL.

## Integration

If GitHub MCP is configured, can:
- Post review comments directly to PR
- Request changes or approve
- Add labels based on review outcome
