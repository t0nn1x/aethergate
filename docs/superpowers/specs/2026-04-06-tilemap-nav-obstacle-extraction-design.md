# Tilemap Navigation Obstacle Extraction — Design Spec

**Date:** 2026-04-06  
**Branch:** `feature/tilemap-nav-obstacle-extraction`  
**Status:** Approved for implementation

---

## Problem

Currently, placing a blocking object (tree, rock, building) in any chunk requires two manual steps:

1. Place the tile on a `TileMapLayer`
2. Manually draw a `Polygon2D` inside `NavigationRegion2D` matching the object's shape — once for the navmesh hole (pathfinding exclusion) and once for click-rejection pickup by `NavigationBlockerRegistry`

With many chunks and objects this is prohibitively tedious. The physics collision shapes are already drawn per-tile in the TileSet editor; the navigation system should reuse them automatically.

---

## Goals

- Any tile with a physics collision polygon on any layer automatically generates a navigation obstacle and click-rejection blocker at runtime when the chunk loads
- No changes to existing manual `Polygon2D` nodes in chunks — they continue to work as before
- Terrain-edge tiles (cliff edges, water borders) that should NOT block navigation can opt out via a per-tile custom data flag
- Zero extra per-tile-type work for the common case (opt-out, not opt-in)

---

## Non-Goals

- Editor-time navmesh rebaking (runtime carving via `NavigationObstacle2D` is sufficient)
- Polygon merging / union of adjacent tiles (one obstacle per tile, defer optimization if needed)
- Changes to the physics collision setup or tileset structure

---

## Architecture

Three targeted changes to existing files. No new files.

### 1. `src/world/streaming/overworld_chunk_ysort_extractor.gd`

**Widen obstacle creation condition**

Current condition:
```gdscript
if has_collision and (is_objects_layer or should_extract):
    _create_navigation_obstacle_for_cell(...)
```

New condition:
```gdscript
if has_collision and not _is_nav_obstacle_disabled(tile_set, tile_info.tile_data):
    _create_navigation_obstacle_for_cell(...)
```

`_is_nav_obstacle_disabled` returns `true` only if the TileSet has a custom data layer named `"nav_obstacle"` **and** that tile's value is explicitly `false`. All other cases (flag absent, flag = `true`) proceed.

**New helper: `_get_tile_collision_polygons`**

```gdscript
static func _get_tile_collision_polygons(tile_set: TileSet, tile_data: TileData) -> Array[PackedVector2Array]
```

Iterates all physics layers on the TileSet. For each layer, iterates collision polygons on the tile. Returns each polygon's points (tile-local space, `PackedVector2Array`). Returns empty array if none found.

**Update `_create_navigation_obstacle_for_cell`**

Replace the hardcoded bounding-box vertices with actual collision polygon shapes:

- Call `_get_tile_collision_polygons(tile_set, tile_data)` — returns one array per collision polygon
- For each polygon (≥3 points): create one `NavigationObstacle2D`:
  - `affect_navigation_mesh = true` (hard navmesh carving, no rebake needed)
  - `avoidance_enabled = true` (keep existing RVO soft avoidance)
  - `vertices` = the polygon's points (tile-local space)
  - `position` = `layer.to_global(layer.map_to_local(cell))`
  - Parented to `_navigation_obstacle_root`, appended to `owner._navigation_obstacles`
- For each polygon: also create one companion `Polygon2D`:
  - `polygon` = same points as the obstacle vertices
  - `position` = same world position as the obstacle
  - Added to group `"navigation_tile_blocker"`
  - Parented to `_navigation_obstacle_root` (auto-cleaned when chunk unloads)
  - `modulate = Color(1, 1, 1, 0)` (invisible)

**Fallback:** If `_get_tile_collision_polygons` returns empty (tile has no polygon data despite `_tile_has_collision` returning true), fall back to the existing bounding-box approach.

---

### 2. `src/world/overworld/navigation_blocker_registry.gd`

**Extend `refresh()`**

After the existing `NavigationRegion2D → Polygon2D` scan loop, add a second pass:

```gdscript
for node in get_tree().get_nodes_in_group("navigation_tile_blocker"):
    var polygon := node as Polygon2D
    if polygon and is_instance_valid(polygon) and polygon.polygon.size() >= 3:
        _blocker_polygons.append(polygon)
```

No other changes. `get_blocker_polygons()`, the signal, and all downstream consumers (`PlayerMoveTargetBlockerComponent`, policies) are unchanged.

---

### 3. `src/world/overworld/chunks/chunk.gd`

**No changes required.**

Companion `Polygon2D` nodes are children of `_navigation_obstacle_root`. The existing cleanup in `_cleanup_extracted_sprites` already calls `_navigation_obstacle_root.queue_free()`, which frees all children including the companion polygons. The group membership is also automatically removed when the node is freed.

---

## Custom Data Opt-Out

To mark a tile as NOT a navigation obstacle:

1. Open the relevant TileSet (e.g. `terrain.tres`) in the Godot editor
2. Add a custom data layer named `"nav_obstacle"` with type `bool` (one-time setup per TileSet)
3. For any terrain-edge or boundary tile that should not block navigation: set `nav_obstacle = false` in that tile's custom data

All other tiles — including those with no `"nav_obstacle"` layer defined — generate obstacles automatically.

---

## Data Flow

```
Chunk._ready()
  └─ OverworldChunkYSortExtractor.extract(chunk)
       └─ for each TileMapLayer:
            └─ for each cell with physics collision (and nav_obstacle != false):
                 ├─ NavigationObstacle2D (affect_navigation_mesh=true, avoidance_enabled=true)
                 │    └─ vertices = tile physics collision polygon
                 │    └─ position = tile world position
                 │    └─ parent: _navigation_obstacle_root
                 └─ Polygon2D (group: "navigation_tile_blocker", invisible)
                      └─ polygon = same points
                      └─ position = same world position
                      └─ parent: _navigation_obstacle_root

Overworld._on_chunks_changed()
  └─ NavigationBlockerRegistry.refresh()
       ├─ scan: Polygon2D inside NavigationRegion2D (existing)
       └─ scan: nodes in group "navigation_tile_blocker" (new)
            └─ _blocker_polygons populated

PlayerMoveTargetBlockerComponent._on_blocker_polygons_changed()
  └─ _cached_blocker_polygons refreshed
       └─ click targets inside any blocker polygon → rejected or snapped
```

---

## Chunk Unload Cleanup

```
OverworldChunk._cleanup_extracted_sprites()
  └─ _navigation_obstacle_root.queue_free()
       └─ frees NavigationObstacle2D nodes
       └─ frees companion Polygon2D nodes (group membership auto-cleared)
```

After unload, `NavigationBlockerRegistry.refresh()` is called by `_on_chunks_changed()`, which re-scans and drops any stale references.

---

## Edge Cases

| Case | Handling |
|------|----------|
| Tile has multiple collision polygons | One `NavigationObstacle2D` + one `Polygon2D` per polygon |
| Tile has no collision polygon data despite `_tile_has_collision` returning true | Fall back to bounding-box vertices |
| TileSet has no `"nav_obstacle"` custom data layer | `get_custom_data_layer_by_name` returns -1 → treat as opt-in (no skip) |
| Chunk unloads while registry refresh is in-flight | `is_instance_valid(polygon)` guard in `get_blocker_polygons()` handles stale refs |
| Manually placed `Polygon2D` in `NavigationRegion2D` | Unchanged — still picked up by existing registry scan |

---

## Files Changed

| File | Change |
|------|--------|
| `src/world/streaming/overworld_chunk_ysort_extractor.gd` | Widen obstacle condition; use real collision polygons; add companion Polygon2D; add `_get_tile_collision_polygons`; add `_is_nav_obstacle_disabled` |
| `src/world/overworld/navigation_blocker_registry.gd` | Add group scan in `refresh()` |
| `src/world/overworld/chunks/chunk.gd` | None |
| TileSet assets (`terrain.tres`, `objects.tres`) | No code changes; users may add `"nav_obstacle"` custom data layer as needed |
