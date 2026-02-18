# Implementation Plan: Inventory MVP (Open with `I` + Editor-Configured Items)

Branch: feature/item-system-combat-inventory
Created: 2026-02-17

## Settings
- Testing: no (default from `ai-factory.feature`)
- Logging: no (default from `ai-factory.feature`)

## Scope
- Press `I` to toggle inventory visibility.
- Show a grid with items configured in the editor.
- Keep item data as reusable resources with custom properties.
- No combat, loot drops, equipment, or persistence in this feature.

## Commit Plan
- Commit 1 (after tasks 1-3): `feat(items): add item data resources and player inventory container`
- Commit 2 (after tasks 4-6): `feat(ui): add inventory grid UI and I-key toggle integration`

## Tasks

### Phase 1: Item Data and Inventory Container
- [x] Task 1: Add base item resource with shared properties.
  Files: `src/Entities/Items/item_data.gd`
  Notes: Include fields such as `item_id`, `display_name`, `description`, `icon`, `max_stack`, and generic `props` dictionary for custom values.

- [x] Task 2: Add simple inventory resource/container that stores fixed-size item slots.
  Files: `src/Entities/Systems/Inventory/player_inventory_data.gd`, `src/Entities/Systems/Inventory/inventory_slot_data.gd`, `src/Entities/Systems/Inventory/Resources/player_starter_inventory.tres`
  Notes: Expose slots in Inspector so items can be assigned directly in editor.

- [x] Task 3: Wire inventory data into player runtime via a lightweight component.
  Files: `src/Entities/Systems/Inventory/player_inventory_component.gd`, `src/Entities/Player/player.tscn`, `src/Gameplay/Player/Components/Core/player_context.gd`
  Notes: Component only provides read access for UI in this MVP.

### Phase 2: Inventory UI Grid
- [x] Task 4: Create inventory UI scene with panel + grid container + reusable slot widget.
  Files: `src/Entities/Ui/Inventory/inventory_screen.tscn`, `src/Entities/Ui/Inventory/inventory_screen.gd`, `src/Entities/Ui/Inventory/inventory_slot_widget.tscn`, `src/Entities/Ui/Inventory/inventory_slot_widget.gd`
  Notes: Each slot displays icon and stack count if amount > 1.

- [x] Task 5: Bind inventory screen to player inventory component and render editor-configured slots.
  Files: `src/Entities/Ui/Inventory/inventory_screen.gd`, `src/World/Overworld/overworld.gd`
  Notes: Add a safe null path if player or inventory component is missing.

### Phase 3: Input and Toggle Flow
- [x] Task 6: Add input action and toggle behavior for `I` key.
  Files: `src/Entities/Ui/Inventory/inventory_screen.gd`, `src/World/Overworld/overworld.tscn`
  Notes: Reused existing `inventory` input action already mapped to `I`; pressing again closes inventory.

- [x] Task 7: Emit existing UI event when inventory is opened for compatibility.
  Files: `src/Entities/Ui/Inventory/inventory_screen.gd`
  Notes: Reuse `inventory_opened` event path; no new event channels needed for MVP.

### Phase 4: Authoring Guide
- [x] Task 8: Document how to create item resources and assign them to player inventory in editor.
  Files: `src/Entities/Ui/Inventory/README.md`
  Notes: Include exact steps for creating `.tres` item assets and linking them into `player_starter_inventory.tres`.

## Acceptance Criteria
- Pressing `I` opens and closes the inventory screen.
- Inventory screen shows a grid populated from editor-assigned item resources.
- Items expose reusable properties (name, description, icon, stack, custom props).
- No runtime errors if inventory is empty or partially configured.

## Out of Scope
- Combat item usage.
- Equipment/loadout systems.
- Loot drops and world pickups.
- Drag-and-drop interactions.
- Save/load.
