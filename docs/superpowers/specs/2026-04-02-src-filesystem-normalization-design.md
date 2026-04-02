# Src Filesystem Normalization Design

Date: 2026-04-02
Status: Drafted for review

## Goal

Normalize the filesystem layout under `src/` so every directory and file basename uses lowercase `snake_case`, while preserving runtime behavior and updating all adjacent path references that depend on `src/`.

This pass is intentionally filesystem-only. It does not rename script symbols, `class_name` declarations, node names, or public APIs unless a path repair absolutely requires it.

## Scope

In scope:

- every directory under `src/`
- every file basename under `src/`
- path references to renamed `src` content in:
  - `project.godot`
  - `.gd`, `.tscn`, `.tres`, `.import`, and other serialized/runtime-owned files
  - docs that point at runtime paths
  - generated catalogs and builder outputs that embed `res://src/...` paths

Out of scope:

- repo-root directories outside `src/` unless they must be edited only as reference holders
- symbol/type/class renames
- behavioral refactors unrelated to keeping renamed paths valid
- asset-library naming outside `src/`, including repo-root `Assets/`

## Naming Rules

Filesystem convention for this pass:

- every path segment under `src/` becomes lowercase `snake_case`
- top-level domains follow the same rule:
  - `src/Common` -> `src/common`
  - `src/Core` -> `src/core`
  - `src/Config` -> `src/config`
  - `src/Localization` -> `src/localization`
  - `src/Ui` -> `src/ui`
  - `src/World` -> `src/world`
  - `src/Entities` -> `src/entities`
  - `src/Utils` -> `src/utils`
- runtime-owned subfolders under `src/` also normalize:
  - `Assets` -> `assets`
  - `Tilesets` -> `tilesets`
  - `Translations` -> `translations`
  - `Tools` -> `tools`
  - `Resources` -> `resources`
  - `Tests` -> `tests`
  - `Components` -> `components`
- project-owned content category folders also normalize when they are structural rather than vendor boundaries:
  - `Cities` -> `cities`
  - `Clouds` -> `clouds`
  - `Mountains` -> `mountains`
  - `Objects` -> `objects`
  - `Terrains` -> `terrains`
- file basenames under `src/` follow the same lowercase `snake_case` rule

Exception rule:

- imported/vendor pack names can keep original casing only if the folder is a clear external boundary and not part of the repo's structural taxonomy

## Recommended Approach

Use a conservative layered rollout rather than one global rename sweep.

### Option A: Layered normalization

Recommended.

- rename top-level `src` domains first
- rename second-level structural folders next
- rename file basenames last within each normalized area
- update path references and verify after every pass

Pros:

- failures stay attributable
- diffs remain reviewable
- easier to separate newly introduced path errors from pre-existing project debt

Cons:

- takes more passes and more verification time

### Option B: Per-domain normalization

- normalize one top-level domain at a time end-to-end
- for example: `src/ui/**`, then `src/world/**`, then `src/entities/**`

Pros:

- fewer passes than full layering
- still somewhat bounded

Cons:

- larger diffs per pass
- more room for reference misses inside Godot scenes/resources

### Option C: Full-tree sweep

Not recommended.

- rename the entire `src/` tree in one pass and then repair references globally

Pros:

- fastest in raw elapsed rename time

Cons:

- hardest to review
- highest risk on Windows and in serialized Godot resources
- failures become difficult to localize

## Chosen Design

Use layered normalization with explicit verification gates.

Execution order:

1. top-level `src` domain directories
2. second-level structural folders within each domain
3. deeper project-owned category folders
4. file basenames inside already-normalized directories
5. docs/reference cleanup for each completed pass, not only at the end

This gives the safest path to a globally normalized `src/` tree without mixing path moves with API refactors.

## Rename Mechanics

Because the repo is on Windows, every case-only rename must use a temporary intermediate path.

Example:

```powershell
Rename-Item src\\Ui src\\__ui_tmp
Rename-Item src\\__ui_tmp src\\ui
```

The same temporary-hop rule applies to nested directories and file basenames where casing alone changes.

## Reference Update Policy

After each filesystem pass, update all dependent path references immediately.

Reference holders to update include:

- `project.godot`
- script preloads and `load()` paths
- scene/resource `ext_resource` and `sub_resource` paths
- generated catalogs and builders
- README and feature/spec docs that point at runtime paths

No pass is considered complete if the filesystem is renamed but serialized references still point at the old path set.

## Verification Strategy

Every pass ends with fresh verification evidence.

Required checks per pass:

- stale-path audit for the renamed area
- `git diff --check`
- headless main scene load
- targeted headless checks for the affected domain when available
- explicit comparison against known baseline debt

Baseline handling:

- pre-existing parser/import/UID noise remains tracked as existing project debt
- only newly introduced path-related failures count as regressions for this refactor

## Success Criteria

The refactor is successful when:

- every directory and file basename under `src/` follows lowercase `snake_case`
- all runtime and serialized references to renamed `src` paths are updated
- no stale old-path references remain for completed passes
- verification shows no newly introduced path-related failures
- repo-root `Assets/` remains untouched unless a later dedicated decision changes that rule

## Risks

- Godot `.tscn` and `.tres` resources are brittle under mass path renames
- Windows case-only renames can silently collapse without temporary names
- generated resources may reintroduce old paths if builders are not updated before regeneration
- broad mixed-case file renames may surface hidden assumptions in tools or docs that were not previously exercised

## Non-Goals

- converting symbol names to `snake_case`
- changing scene node names for style reasons
- flattening architecture or moving domains outside the agreed naming normalization
- normalizing repo-root asset libraries in the same pass

## Follow-Up

If this filesystem pass lands cleanly, a later optional design can evaluate whether symbol-level normalization is worth doing. That should be a separate project because it carries behavior risk rather than mostly mechanical path risk.
