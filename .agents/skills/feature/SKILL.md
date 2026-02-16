---
name: ai-factory.feature
description: Start a new feature development. Creates a git branch with a logical name based on feature description, then invokes /task to create an implementation plan. Use when user says "new feature", "start feature", "implement feature", or "add feature".
argument-hint: <feature description>
allowed-tools: Bash(git *) Read Write Skill AskUserQuestion
disable-model-invocation: true
---

# Feature - New Feature Workflow

Start a new feature by creating a branch and planning implementation.

## Workflow

### Step 0: Load Project Context

**FIRST:** Read `.ai-factory/DESCRIPTION.md` if it exists to understand:
- Tech stack (language, framework, database)
- Project architecture
- Existing conventions

This context informs branch naming, task planning, and implementation.

### Step 0.1: Ensure Git Repository

Check if git is initialized. If not, initialize it.

```bash
git rev-parse --is-inside-work-tree 2>/dev/null || git init
```

### Step 1: Parse Feature Description

From `$ARGUMENTS`, extract:
- Core functionality being added
- Key domain terms
- Type (feature, enhancement, fix, refactor)

### Step 2: Generate Branch Name

Create a descriptive branch name:

```
Format: <type>/<short-description>

Examples:
- feature/user-authentication
- feature/stripe-checkout
- feature/product-search
- fix/cart-total-calculation
- refactor/api-error-handling
```

**Rules:**
- Lowercase with hyphens
- Max 50 characters
- No special characters except hyphens
- Descriptive but concise

### Step 3: Apply Default Implementation Preferences

Do not ask setup questions about testing or logging.

Use these defaults unless the user explicitly overrides them in the request:
- Testing: `no`
- Logging: `no` (minimal/no extra feature logs)

Pass these defaults to `/ai-factory.task` and `/ai-factory.implement`.

### Step 4: Create Branch

```bash
# Ensure we're on main/master and up to date
git checkout main
git pull origin main

# Create and switch to new branch
git checkout -b <branch-name>
```

If branch already exists, ask user:
- Switch to existing branch?
- Create with different name?

### Step 5: Invoke Task Planning with Branch Context

**Plan file will be named after the branch:**

```
Branch: feature/user-authentication
Plan file: .ai-factory/features/feature-user-authentication.md (NOT .ai-factory/PLAN.md!)
```

Convert branch name to filename:
- Replace `/` with `-`
- Add `.md` extension

Call `/ai-factory.task` with explicit context:

```
/ai-factory.task $ARGUMENTS

CONTEXT FROM /ai-factory.feature:
- Plan file: .ai-factory/features/feature-user-authentication.md (use this name, NOT .ai-factory/PLAN.md)
- Testing: no (default)
- Logging: no (default)
```

**IMPORTANT:** Pass the exact plan filename to /task. This distinguishes feature-based work from direct /task calls.

Pass along:
- Full feature description
- **Exact plan file name** (based on branch, e.g., `.ai-factory/features/feature-user-authentication.md`)
- Testing preference (default: no)
- Logging preference (default: no)
- Any constraints

The plan file allows resuming work based on current git branch:
```bash
git branch --show-current  # → feature/user-authentication
# → Look for .ai-factory/features/feature-user-authentication.md
```

## Examples

**User:** `/feature Add user authentication with email/password and OAuth`

**Actions:**
1. Parse: authentication feature, email/password + OAuth
2. Generate branch: `feature/user-authentication`
3. Apply defaults (`testing: no`, `logging: no`)
4. Create branch: `git checkout -b feature/user-authentication`
5. Call: `/ai-factory.task Add user authentication with email/password and OAuth`

**User:** `/feature Fix cart not updating quantities correctly`

**Actions:**
1. Parse: bug fix, cart quantities
2. Generate branch: `fix/cart-quantity-update`
3. Apply defaults (`testing: no`, `logging: no`)
4. Create branch
5. Call `/ai-factory.task`

## Important

- Default to `testing: no` and `logging: no` without asking
- If the user explicitly requests tests or specific logging, honor that override
- Pass testing/logging preferences to downstream skills
- If git operations fail, report clearly and don't proceed
- Don't create branch if one with same purpose exists (ask first)
