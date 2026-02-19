---
name: ai-factory.commit
description: Create conventional commit messages by analyzing staged changes. Generates semantic commit messages following the Conventional Commits specification. Use when user says "commit", "save changes", or "create commit".
argument-hint: [scope or context]
allowed-tools: Bash(git *)
disable-model-invocation: true
---

# Conventional Commit Generator

Generate commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Workflow

1. **Analyze Changes**
   - Run `git status` to see staged files
   - Run `git diff --cached` to see staged changes
   - If nothing staged, show warning and suggest staging

2. **Determine Commit Type**
   - `feat`: New feature
   - `fix`: Bug fix
   - `docs`: Documentation only
   - `style`: Code style (formatting, semicolons)
   - `refactor`: Code change that neither fixes a bug nor adds a feature
   - `perf`: Performance improvement
   - `test`: Adding or modifying tests
   - `build`: Build system or dependencies
   - `ci`: CI configuration
   - `chore`: Maintenance tasks

3. **Identify Scope**
   - From file paths (e.g., `src/auth/` → `auth`)
   - From argument if provided
   - Optional - omit if changes span multiple areas

4. **Generate Message**
   - Keep subject line under 72 characters
   - Use imperative mood ("add" not "added")
   - Don't capitalize first letter after type
   - No period at end of subject

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Examples

**Simple feature:**
```
feat(auth): add password reset functionality
```

**Bug fix with body:**
```
fix(api): handle null response from payment gateway

The payment API can return null when the gateway times out.
Added null check and retry logic.

Fixes #123
```

**Breaking change:**
```
feat(api)!: change response format for user endpoint

BREAKING CHANGE: user endpoint now returns nested profile object
```

## Behavior

When invoked:

1. Check for staged changes
2. Analyze the diff content
3. Propose a commit message
4. Ask for confirmation or modifications
5. Execute `git commit` with the message

If argument provided (e.g., `/commit auth`):
- Use it as the scope
- Or as context for the commit message

## Important

- Never commit secrets or credentials
- Review large diffs carefully before committing
- Suggest splitting if changes are unrelated
- For mass move/refactor diffs, prefer grouping commits by intent (for example `refactor(ui): move directories` then `fix(ui): update stale paths`) when practical
- In asset-heavy move commits with many identical placeholders (like `.gitkeep`), verify final tree paths with `git status`/filesystem checks; rename pairings can look odd even when end-state is correct
- In Godot repos, watch for editor serialization churn (`.tscn`/`.tres` UID or property-order updates) and split/unstage unrelated noise from behavior changes
- Before final commit, run `git diff --name-only` and confirm staged asset/style/resource files match the feature scope (especially after opening scenes in editor)
- Add Co-Authored-By for pair programming if mentioned
