---
name: ai-factory.implement
description: Execute implementation tasks from the current plan. Works through tasks sequentially, marks completion, and preserves progress for continuation across sessions. Use when user says "implement", "start coding", "execute plan", or "continue implementation".
argument-hint: [task-id or "status"]
allowed-tools: Read Write Edit Glob Grep Bash TaskList TaskGet TaskUpdate AskUserQuestion
disable-model-invocation: true
---

# Implement - Execute Task Plan

Execute tasks from the plan, track progress, and enable session continuation.

## Workflow

### Step 0: Check Current State

**FIRST:** Determine what state we're in:

```
1. Check for uncommitted changes (git status)
2. Check for plan files (.ai-factory/PLAN.md or branch-named)
3. Check current branch
```

**If uncommitted changes exist:**
```
You have uncommitted changes. Commit them first?
- [ ] Yes, commit now (/ai-factory.commit)
- [ ] No, stash and continue
- [ ] Cancel
```

**If NO plan file exists (all tasks completed or fresh start):**

```
No active plan found.

Current branch: feature/user-auth

What would you like to do?
- [ ] Start new feature from current branch
- [ ] Return to main/master and start new feature
- [ ] Create quick task plan (no branch)
- [ ] Nothing, just checking status
```

Based on choice:
- New feature from current → `/ai-factory.feature <description>`
- Return to main → `git checkout main && git pull` → `/ai-factory.feature <description>`
- Quick task → `/ai-factory.task <description>`

**If plan file exists → continue to Step 0.1**

### Step 0.1: Load Project Context & Past Experience

**Read `.ai-factory/DESCRIPTION.md`** if it exists to understand:
- Tech stack (language, framework, database, ORM)
- Project architecture and conventions
- Non-functional requirements

**Read all patches from `.ai-factory/patches/`** if the directory exists:
- Use `Glob` to find all `*.md` files in `.ai-factory/patches/`
- Read each patch to learn from past fixes and mistakes
- Apply lessons learned: avoid patterns that caused bugs, use patterns that prevented them
- Pay attention to **Root Cause** and **Prevention** sections — they tell you what NOT to do

**Use this context when implementing:**
- Follow the specified tech stack
- Use correct import patterns and conventions
- Apply proper error handling and logging as specified
- **Avoid pitfalls documented in patches** — don't repeat past mistakes

### Step 0.1: Find Plan File

**Check for plan files in this order:**

```
1. .ai-factory/PLAN.md exists? → Use it (direct /task call)
2. No .ai-factory/PLAN.md → Check current git branch:
   git branch --show-current
   → Look for .ai-factory/features/<branch-name>.md (e.g., .ai-factory/features/feature-user-auth.md)
```

**Priority:**
1. `.ai-factory/PLAN.md` - always takes priority (from direct `/ai-factory.task`)
2. Branch-named file - if no .ai-factory/PLAN.md (from `/ai-factory.feature`)

**Read the plan file** to understand:
- Context and settings (testing, logging preferences)
- Commit checkpoints (when to commit)
- Task dependencies

### Step 1: Load Current State

```
TaskList → Get all tasks with status
```

Find:
- Next pending task (not blocked, not completed)
- Any in_progress tasks (resume these first)

### Step 2: Display Progress

```
## Implementation Progress

✅ Completed: 3/8 tasks
🔄 In Progress: Task #4 - Implement search service
⏳ Pending: 4 tasks

Current task: #4 - Implement search service
```

### Step 3: Execute Current Task

For each task:

**3.1: Fetch full details**
```
TaskGet(taskId) → Get description, files, context
```

**3.2: Mark as in_progress**
```
TaskUpdate(taskId, status: "in_progress")
```

**3.3: Implement the task**
- Read relevant files
- Make necessary changes
- Follow existing code patterns
- **NO tests unless plan includes test tasks**
- **NO reports or summaries**

**3.4: Verify implementation**
- Check code compiles/runs
- Verify functionality works
- Fix any immediate issues
- For Godot services/components, verify NodePath lookup base (`self` vs `parent`) for all dependencies
- Run a runtime smoke check for critical loops affected by the change (input -> movement, state transitions, chunk load flow)
- For new Godot autoload channels, avoid direct compile-time singleton identifiers in gameplay scripts unless guaranteed; prefer `/root/<Singleton>` lookup + compatibility fallback during migration
- If replacing group discovery with DI, verify composition-root wiring assigns dependencies before gameplay loops start
- For solo-first gameplay work, keep multiplayer seams intact (identity fields + authority checks) instead of hardcoding single-player assumptions
- For Godot UI backgrounds/parallax, verify runtime render is single-composition (no unintended row/column tiling) and that randomized folders do not mix incompatible layer dimensions
- For mobile/export targets, avoid relying solely on `DirAccess` listing for `res://` assets; ensure a manifest or `ResourceLoader.exists()` fallback is implemented
- After folder/path refactors, verify no stale path prefixes remain (scan `src` + `project.godot`) and confirm moved scene/script references load without stale UID/path lookups
- For reusable audio work, prefer a centralized autoload/service (pooled SFX + music control) over scene-local duplicated audio setup blocks
- For platform-specific lifecycle actions (like app quit), implement capability guards: hide/disable unsupported UI actions (notably iOS quit) and keep focus navigation valid after removal
- For platform display startup changes, verify window mode/size policy matches intended UX per platform (for example Windows fullscreen) and avoid windowed+usable-rect centering in fullscreen startup paths
- For Godot `@tool` inspector features, avoid method calls on placeholder script resources in editor context; read exported properties and keep inspector preview loading lazy/cached
- For overworld creature spawn/wander behavior, treat zone containment and blocker polygons as separate constraints: route sampled targets through blocker policies and keep blocker-registry resolution resilient to scene init order (deferred/lazy resolve)
- For large file-tree refactors/moves, run git index-mutating commands (`git mv`, bulk `git add`) sequentially; avoid parallel execution that can trigger `.git/index.lock` contention

**3.5: Mark as completed**
```
TaskUpdate(taskId, status: "completed")
```

**3.6: Update checkbox in plan file**

**IMMEDIATELY** after completing a task, update the checkbox in the plan file:

```markdown
# Before
- [ ] Task 1: Create user model

# After
- [x] Task 1: Create user model
```

**This is MANDATORY** — checkboxes must reflect actual progress:
- Use `Edit` tool to change `- [ ]` to `- [x]`
- Do this RIGHT AFTER each task completion
- Even if deletion will be offered later
- Plan file is the source of truth for progress

**3.7: Update .ai-factory/DESCRIPTION.md if needed**

If during implementation:
- New dependency/library was added
- Tech stack changed (e.g., added Redis, switched ORM)
- New integration added (e.g., Stripe, SendGrid)
- Architecture decision was made

→ Update `.ai-factory/DESCRIPTION.md` to reflect the change:

```markdown
## Tech Stack
- **Cache:** Redis (added for session storage)
```

This keeps .ai-factory/DESCRIPTION.md as the source of truth.

**3.8: Check for commit checkpoint**

If the plan has commit checkpoints and current task is at a checkpoint:
```
✅ Tasks 1-4 completed.

This is a commit checkpoint. Ready to commit?
Suggested message: "feat: add base models and types"

- [ ] Yes, commit now (/ai-factory.commit)
- [ ] No, continue to next task
- [ ] Skip all commit checkpoints
```

**3.9: Move to next task or pause**

### Step 4: Session Persistence

Progress is automatically saved via TaskUpdate.

**To pause:**
```
Current progress saved.

Completed: 4/8 tasks
Next task: #5 - Add pagination support

To resume later, run:
/ai-factory.implement
```

**To resume (next session):**
```
/ai-factory.implement
```
→ Automatically finds next incomplete task

### Step 5: Completion

When all tasks are done:

```
## Implementation Complete

All 8 tasks completed.

Branch: feature/product-search
Plan file: .ai-factory/features/feature-product-search.md
Files modified:
- src/services/search.ts (created)
- src/api/products/search.ts (created)
- src/types/search.ts (created)

Ready to commit? Use:
/ai-factory.commit
```

**Handle plan file after completion:**

- **If `.ai-factory/PLAN.md`** (direct /task, not from /feature):
  ```
  Would you like to delete .ai-factory/PLAN.md? (It's no longer needed)
  - [ ] Yes, delete it
  - [ ] No, keep it
  ```

- **If branch-named file** (e.g., `.ai-factory/features/feature-user-auth.md`):
  - Keep it - documents what was done
  - User can delete before merging if desired

**IMPORTANT: NO summary reports, NO analysis documents, NO wrap-up tasks.**

## Commands

### Start/Resume Implementation
```
/ai-factory.implement
```
Continues from next incomplete task.

### Start from Specific Task
```
/ai-factory.implement 5
```
Starts from task #5 (useful for skipping or re-doing).

### Check Status Only
```
/ai-factory.implement status
```
Shows progress without executing.

## Execution Rules

### DO:
- ✅ Execute one task at a time
- ✅ Mark tasks in_progress before starting
- ✅ Mark tasks completed after finishing
- ✅ Follow existing code conventions
- ✅ Create files mentioned in task description
- ✅ Handle edge cases mentioned in task
- ✅ Stop and ask if task is unclear

### DON'T:
- ❌ Write tests (unless explicitly in task list)
- ❌ Create report files
- ❌ Create summary documents
- ❌ Add tasks not in the plan
- ❌ Skip tasks without user permission
- ❌ Mark incomplete tasks as done

## Progress Display Format

```
┌─────────────────────────────────────────────┐
│ Feature: User Authentication                │
├─────────────────────────────────────────────┤
│ ✅ #1 Create user model                     │
│ ✅ #2 Add registration endpoint             │
│ ✅ #3 Add login endpoint                    │
│ 🔄 #4 Implement JWT generation    ← current │
│ ⏳ #5 Add password reset                    │
│ ⏳ #6 Add email verification                │
├─────────────────────────────────────────────┤
│ Progress: 3/6 (50%)                         │
└─────────────────────────────────────────────┘
```

## Handling Blockers

If a task cannot be completed:

```
⚠️ Blocker encountered on Task #4

Issue: [Description of the problem]

Options:
1. Skip this task and continue (mark as blocked)
2. Modify the task approach
3. Stop implementation and discuss

What would you like to do?
```

## Session Continuity

Tasks are persisted in the conversation/project state.

**Starting new session:**
```
User: /ai-factory.implement

Claude: Resuming implementation...

Found 3 completed tasks, 5 pending.
Continuing from Task #4: Implement JWT generation

[Executes task #4]
```

## Example Full Flow

```
Session 1:
  /ai-factory.feature Add user authentication
  → Creates branch: feature/user-authentication
  → Asks about tests (No), logging (Verbose)
  → /ai-factory.task creates 6 tasks
  → Saves plan to: .ai-factory/features/feature-user-authentication.md
  → /ai-factory.implement starts
  → Completes tasks #1, #2, #3
  → User ends session

Session 2:
  /ai-factory.implement
  → Detects branch: feature/user-authentication
  → Reads plan: .ai-factory/features/feature-user-authentication.md
  → Loads state: 3/6 complete
  → Continues from task #4
  → Completes tasks #4, #5, #6
  → All done, suggests /ai-factory.commit
```

## Critical Rules

1. **NEVER write tests** unless task list explicitly includes test tasks
2. **NEVER create reports** or summary documents after completion
3. **ALWAYS mark task in_progress** before starting work
4. **ALWAYS mark task completed** after finishing
5. **ALWAYS update checkbox in plan file** - `- [ ]` → `- [x]` immediately after task completion
6. **PRESERVE progress** - tasks survive session boundaries
7. **ONE task at a time** - focus on current task only

## CRITICAL: Logging Requirements

**ALWAYS add verbose logging when implementing code.** AI-generated code often has subtle bugs that are hard to debug without proper logging.

### Logging Guidelines

1. **Log function entry/exit** with parameters and return values
2. **Log state changes** - before and after mutations
3. **Log external calls** - API requests, database queries, file operations
4. **Log error context** - include relevant variables, not just error message
5. **Use structured logging** when possible (JSON format)

### Example Pattern

```typescript
function processOrder(order: Order): Result {
  console.log('[processOrder] START', { orderId: order.id, items: order.items.length });

  try {
    const validated = validateOrder(order);
    console.log('[processOrder] Validation passed', { validated });

    const result = submitToPayment(validated);
    console.log('[processOrder] Payment result', { success: result.success, transactionId: result.id });

    return result;
  } catch (error) {
    console.error('[processOrder] ERROR', { orderId: order.id, error: error.message, stack: error.stack });
    throw error;
  }
}
```

### Log Management Requirements

**Logs must be configurable and manageable:**

1. **Use log levels** - DEBUG, INFO, WARN, ERROR
2. **Environment-based control** - LOG_LEVEL env variable
3. **Easy to disable** - single flag or env var to turn off verbose logs
4. **Consider rotation** - for file-based logs, implement rotation or use existing tools

```typescript
// Good: Configurable logging
const LOG_LEVEL = process.env.LOG_LEVEL || 'debug';
const logger = createLogger({ level: LOG_LEVEL });

// Good: Can be disabled
if (process.env.DEBUG) {
  console.log('[debug]', data);
}

// Bad: Hardcoded verbose logs that can't be turned off
console.log(hugeObject); // Will pollute production logs
```

### Why This Matters

- AI-generated code may have edge cases not covered
- Logs help identify WHERE things go wrong
- Debugging without logs wastes significant time
- User can remove logs later if needed, but missing logs during development is costly
- **Production safety** - logs must be reducible to avoid performance issues and storage costs

**DO NOT skip logging to "keep code clean" - verbose logging is REQUIRED during implementation, but MUST be configurable.**
