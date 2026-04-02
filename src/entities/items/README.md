# Item Workflow

This project uses a data-driven item pipeline aligned with the `creatures` folder pattern.

## Structure

Each item lives in its own folder under `catalog/<Category>/.../<ItemName>/`:

- `data/` - item resources (`ItemData` `.tres`)
- `sprites/` - item-local icon/art used by that item

Example:
- `res://src/entities/items/catalog/consumables/potions/health_potion/data/consumable_health_potion.tres`
- `res://src/entities/items/catalog/consumables/potions/health_potion/sprites/health_potion_icon.png`

## Add New Item

1. Create an item folder inside `src/entities/items/catalog/...`.
2. Add icon/art into `sprites/`.
3. In `data/`, create `New Resource` with type `ItemData`.
4. Fill:
   - `item_id` (stable snake_case id)
   - `display_name`
   - `description`
   - `icon` (item-local sprite)
   - `max_stack`
   - `props` (optional custom fields)
5. Save the `.tres` in `data/`.

## Inventory Integration

- Starter inventory resource:
  - `res://src/entities/systems/inventory/resources/player_starter_inventory.tres`
- Add your new `ItemData` resource into slot `item` fields there (or via player-assigned `PlayerInventoryData`).

## Notes

- Keep item assets with the item folder (do not rely on UI asset paths for canonical item data).
- `item_data.gd` remains shared at:
  - `res://src/entities/items/item_data.gd`
