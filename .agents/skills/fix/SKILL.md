---
name: ai-factory.fix
description: Fix a specific bug or problem in the codebase. Analyzes code to find and fix issues without creating plans. Use when user reports a bug, error, or something not working. Always suggests test coverage and adds logging.
argument-hint: <bug description or error message>
allowed-tools: Read Write Edit Glob Grep Bash AskUserQuestion
disable-model-invocation: false
---

# Fix - Quick Bug Fix Workflow

Fix a specific bug or problem by analyzing the codebase directly. No plans, no reports.

## Workflow

### Step 0: Load Project Context & Past Experience

**Read `.ai-factory/DESCRIPTION.md`** if it exists to understand:
- Tech stack (language, framework, database)
- Project architecture
- Coding conventions

**Read all patches from `.ai-factory/patches/`** if the directory exists:
- Use `Glob` to find all `*.md` files in `.ai-factory/patches/`
- Read each patch file to learn from past fixes
- Pay attention to recurring patterns, root causes, and solutions
- If the current problem resembles a past patch — apply the same approach or avoid the same mistakes
- This is your accumulated experience. Use it.

### Step 1: Understand the Problem

From `$ARGUMENTS`, identify:
- Error message or unexpected behavior
- Where it occurs (file, function, endpoint)
- Steps to reproduce (if provided)

If unclear, ask:
```
To fix this effectively, I need more context:

1. What is the expected behavior?
2. What actually happens?
3. Can you share the error message/stack trace?
4. When did this start happening?
```

### Step 2: Investigate the Codebase

**Search for the problem:**
- Find relevant files using Glob/Grep
- Read the code around the issue
- Trace the data flow
- Check for similar patterns elsewhere

**Look for:**
- The root cause (not just symptoms)
- Related code that might be affected
- Existing error handling
- Godot strict typing traps (e.g. `:= max/min/clamp` inferring `Variant` when warnings are errors)
- GDScript property accessor traps: no `field` identifier in setters/getters, and avoid self-assignment inside setters (`prop = value`) that causes infinite recursion
- GDScript constant-expression traps: typed collection constants can fail parse in strict contexts; prefer simple `const NAME := [...]` or runtime initialization
- Dynamic UI init-order traps: methods using `@onready` node refs called before node enters tree (for instanced UI controls); add child first and/or use `call_deferred`
- Resource deserialization-order traps: coupled setters (for example `item` + `amount`) that clamp/reset state before both fields are loaded can silently wipe inventory data
- UI layout-pass side effects: layout/resize helpers that also clear visibility/text can erase runtime-populated icons/counts on every refresh
- Panel dependency wiring order traps: panel opens before its inventory/component dependency is bound, producing empty UI despite valid data
- Drag-preview composition traps: preview nodes including slot backgrounds can create misleading duplicate-slot visuals when only icon/count should be dragged
- Drag lifecycle traps: source slot visuals not cleared during drag and not restored on cancel/drop cause double-visual artifacts; handle via drag start/end hooks
- Scene-vs-script override traps: scene-authored control state resources (e.g. `texture_hover`) can be overwritten by runtime `_apply_*` methods in scripts; audit runtime assignments before editing `.tscn` only
- Broken scene references after file moves (`.tscn` `ext_resource path=...`, missing `.uid` continuity)
- Stale path prefixes after folder refactors (for example `res://src/UI/...` still referenced after moving to `res://src/Entities/Ui/...`)
- Godot localization resource traps: moved locale files still referenced from old paths (`project.godot`/autoload/runtime loaders) and UTF-8 BOM in `.tres` translation files causing parser errors like `Expected '['`
- Godot cache/UID mismatch after moves (parse errors referencing deleted paths). Rebuild project cache (`.godot`) and reopen editor when source paths are already correct
- Autoload identifier parse traps (new singleton names referenced directly in scripts before `project.godot` autoload resolution)
- Runtime group-discovery in hot paths (`_process`/`_physics_process`) that should be replaced with injected dependencies
- Layered character render-order traps: fixed per-part `z_index` on Y-sorted player sprites can desync body/head/weapon from world occluder sorting
- Layered effect-sync traps: keeping a single silhouette/outline node after splitting visuals into multiple sprite parts leaves incomplete coverage
- UI background composition traps: `TextureRect.STRETCH_TILE` combined with enlarged fit rects/material repeat causing unintended multi-row tiling
- Mixed-size parallax layer sets (different source dimensions in one folder) that produce random zoom/crop framing across starts
- Parallax seam traps on desktop (especially Windows): shader `fract` wrapping + disabled texture repeat and unsnapped fit bounds can expose 1px edges; align wrap/repeat strategy and use pixel-snapped bounds with slight overscan
- Export/mobile resource discovery traps: runtime `DirAccess` listing under `res://` returning empty in packaged builds (prefer manifest or `ResourceLoader.exists()` probe fallback)
- UI/audio architecture traps: duplicating player setup/loading logic in multiple scenes instead of using a centralized autoload service with pooled players
- Platform capability traps (iOS quit): if the platform disallows lifecycle actions like programmatic app exit, do not keep a clickable UI action that can never succeed; hide/disable it and adjust focus/navigation
- Desktop startup display traps: platform display bootstrapping forcing windowed mode/usable-rect centering when the intended UX is fullscreen (especially Windows) and no startup mode logs exist to verify behavior
- Godot `@tool` placeholder traps: script-backed resources loaded in editor can be placeholders; avoid relying on method calls from tool scripts (`resource.call(...)`) and prefer exported-property reads where possible
- Inspector performance traps: avoid eager loading large preview sets inside `_get_property_list`/`_get`; lazy-load only selected preview assets and cache lightweight metadata
- Spawn/wander sampling traps: zone-randomized world positions can still land inside navigation blocker polygons; enforce blocker-policy rejection/resolution and avoid early `_ready` null wiring by resolving blocker registries deferred/lazily
- Mouse coordinate-space traps: mixing `InputEventMouse*.position` (window/screen space) with `Viewport.get_mouse_position()` / `get_global_mouse_position()` paths can introduce stable click offsets; keep one coordinate space per interaction path
- Move-target authority traps: emitting/consuming raw requested click positions instead of resolved navigation targets can desync marker position from actual arrival; keep request→resolve→emit→render on the same authoritative world point
- Hold-retarget cache traps: caching pre-resolution pointer world positions during hold can cause distance checks and marker updates to drift from applied nav targets; cache accepted target coordinates instead
- Pointer-anchor compensation traps: hardcoded desktop marker offsets can hide root coordinate issues and create persistent visual drift; default to zero offset unless explicitly calibrated
- Godot API-surface traps: avoid introducing unverified engine methods in hot input/camera paths (for example non-existent `Camera2D` conversion helpers); confirm method availability for Godot 4.x before wiring
- UI layout-coupling traps: using title/content spacing margins as inputs for panel background geometry/height calculations can unintentionally shrink or shift panels; keep decorative spacing decoupled from container-size math
- CanvasLayer ordering traps: fullscreen blur/dimmer overlays can unintentionally blur HUD controls if layer indices differ across platform variants; verify HUD/menu layers render above blur layers where intended
- Patch-edit syntax traps: accidental stray tokens/characters near function headers or first statements (e.g. leading digits) can cause parser errors that look unrelated; inspect exact offending lines and fix minimally

### Step 3: Implement the Fix

**Apply the fix with logging:**

```typescript
// ✅ REQUIRED: Add logging around the fix
console.log('[FIX] Processing user input', { userId, input });

try {
  // The actual fix
  const result = fixedLogic(input);
  console.log('[FIX] Success', { userId, result });
  return result;
} catch (error) {
  console.error('[FIX] Error in fixedLogic', {
    userId,
    input,
    error: error.message,
    stack: error.stack
  });
  throw error;
}
```

**Logging is MANDATORY because:**
- User needs to verify the fix works
- If it doesn't work, logs help debug further
- Feedback loop: user provides logs → we iterate

### Step 4: Verify the Fix

- Check the code compiles/runs
- Verify the logic is correct
- Ensure no regressions introduced
- For Godot refactors, verify that every referenced script/resource in `.tscn` still exists
- For large path moves, run a repo-wide grep for old prefixes in `src` and `project.godot` and fix all leftovers before rerunning
- If touching localization files/services, verify translation resources load from current paths, confirm `project.godot` internationalization entries, and ensure translation `.tres` files are UTF-8 without BOM
- If touching autoload-driven code, verify `project.godot` `[autoload]` entries and keep a compatibility fallback path while migrating callers
- If touching startup display settings, verify platform window mode matches intended UX (for example Windows fullscreen startup) and confirm via startup mode/resolution logs
- If touching `@tool` inspector code, verify inspector properties appear as expected and editor stays responsive (no repeated placeholder-call errors or heavy lag)
- If touching overworld creature spawning/wander, verify sampled targets are rejected when inside blocker polygons and blocker-registry wiring is valid after scene startup order settles
- If touching layered character visuals, validate all layers (legs/body/head/weapon) sort together against world occluders and verify silhouette/outline mirrors each part
- If touching dynamically-instantiated UI widgets, verify configuration runs after node-tree entry when it depends on `@onready` children (for example `add_child` before configure or deferred configure)
- If touching UI title/padding spacing, verify any dependent panel/background height calculations still use base paddings (not spacing offsets added only for visual alignment)
- If touching click-to-move flow, verify pointer marker and player arrival align to the resolved/accepted target (not raw click input) and confirm any visual anchor offset is zero/intentional

### Step 5: Suggest Test Coverage

**ALWAYS suggest covering this case with a test:**

```
## Fix Applied ✅

The issue was: [brief explanation]
Fixed by: [what was changed]

### Logging Added
The fix includes logging with prefix `[FIX]`.
Please test and share any logs if issues persist.

### Recommended: Add a Test

This bug should be covered by a test to prevent regression:

\`\`\`typescript
describe('functionName', () => {
  it('should handle [the edge case that caused the bug]', () => {
    // Arrange
    const input = /* the problematic input */;

    // Act
    const result = functionName(input);

    // Assert
    expect(result).toBe(/* expected */);
  });
});
\`\`\`

Would you like me to create this test?
- [ ] Yes, create the test
- [ ] No, skip for now
```

## Logging Requirements

**All fixes MUST include logging:**

1. **Log prefix**: Use `[FIX]` or `[FIX:<issue-id>]` for easy filtering
2. **Log inputs**: What data was being processed
3. **Log success**: Confirm the fix worked
4. **Log errors**: Full context if something fails
5. **Configurable**: Use LOG_LEVEL if available

```typescript
// Pattern for fixes
const LOG_FIX = process.env.LOG_LEVEL === 'debug' || process.env.DEBUG_FIX;

function fixedFunction(input) {
  if (LOG_FIX) console.log('[FIX] Input:', input);

  // ... fix logic ...

  if (LOG_FIX) console.log('[FIX] Output:', result);
  return result;
}
```

## Examples

### Example 1: Null Reference Error

**User:** `/fix TypeError: Cannot read property 'name' of undefined in UserProfile`

**Actions:**
1. Search for UserProfile component/function
2. Find where `.name` is accessed
3. Add null check with logging
4. Suggest test for null user case

### Example 2: API Returns Wrong Data

**User:** `/fix /api/orders returns empty array for authenticated users`

**Actions:**
1. Find orders API endpoint
2. Trace the query logic
3. Find the bug (e.g., wrong filter)
4. Fix with logging
5. Suggest integration test

### Example 3: Form Validation Not Working

**User:** `/fix email validation accepts invalid emails`

**Actions:**
1. Find email validation logic
2. Check regex or validation library usage
3. Fix the validation
4. Add logging for validation failures
5. Suggest unit test with edge cases

## Important Rules

1. **NO plans** - This is a direct fix, not planned work
2. **NO reports** - Don't create summary documents
3. **ALWAYS log** - Every fix must have logging for feedback
4. **ALWAYS suggest tests** - Help prevent regressions
5. **Root cause** - Fix the actual problem, not symptoms
6. **Minimal changes** - Don't refactor unrelated code
7. **One fix at a time** - Don't scope creep

## After Fixing

```
## Fix Applied ✅

**Issue:** [what was broken]
**Cause:** [why it was broken]
**Fix:** [what was changed]

**Files modified:**
- path/to/file.ts (line X)

**Logging added:** Yes, prefix `[FIX]`
**Test suggested:** Yes

Please test the fix and share logs if any issues.

To add the suggested test:
- [ ] Yes, create test
- [ ] No, skip
```

### Step 6: Create Self-Improvement Patch

**ALWAYS create a patch after every fix.** This builds a knowledge base for future fixes.

**Create the patch:**

1. Create directory if it doesn't exist:
   ```bash
   mkdir -p .ai-factory/patches
   ```

2. Create a patch file with the current timestamp as filename.
   **Format:** `YYYY-MM-DD-HH.mm.md` (e.g., `2026-02-07-14.30.md`)

3. Use this template:

```markdown
# [Brief title describing the fix]

**Date:** YYYY-MM-DD HH:mm
**Files:** list of modified files
**Severity:** low | medium | high | critical

## Problem

What was broken. How it manifested (error message, wrong behavior).
Be specific — include the actual error or symptom.

## Root Cause

WHY the problem occurred. This is the most valuable part.
Not "what was wrong" but "why it was wrong":
- Logic error? Why was the logic incorrect?
- Missing check? Why was it missing?
- Wrong assumption? What was assumed?
- Race condition? What sequence caused it?

## Solution

How the fix was implemented. Key code changes and reasoning.
Include the approach, not just "changed line X".

## Prevention

How to prevent this class of problems in the future:
- What pattern/practice should be followed?
- What should be checked during code review?
- What test would catch this?

## Tags

Space-separated tags for categorization, e.g.:
`#null-check` `#async` `#validation` `#typescript` `#api` `#database`
```

**Example patch:**

```markdown
# Null reference in UserProfile when user has no avatar

**Date:** 2026-02-07 14:30
**Files:** src/components/UserProfile.tsx
**Severity:** medium

## Problem

TypeError: Cannot read property 'url' of undefined when rendering
UserProfile for users without an uploaded avatar.

## Root Cause

The `user.avatar` field is optional in the database schema but the
component accessed `user.avatar.url` without a null check. This was
introduced in commit abc123 when avatar display was added — the
developer tested only with users that had avatars.

## Solution

Added optional chaining: `user.avatar?.url` with a fallback to a
default avatar URL. Also added a null check in the Avatar sub-component.

## Prevention

- Always check if database fields marked as `nullable` / `optional`
  are handled with null checks in the UI layer
- Add test cases for "empty state" — user with minimal data
- Consider a lint rule for accessing nested optional properties

## Tags

`#null-check` `#react` `#optional-field` `#typescript`
```

**This is NOT optional.** Every fix generates a patch. The patch is your learning.

---

**DO NOT:**
- ❌ Create PLAN.md or any plan files
- ❌ Generate reports or summaries (patches are NOT reports — they are learning artifacts)
- ❌ Refactor unrelated code
- ❌ Add features while fixing
- ❌ Skip logging
- ❌ Skip test suggestion
- ❌ Skip patch creation
