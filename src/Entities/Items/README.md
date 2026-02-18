# Item Workflow

This project uses a data-driven item pipeline aligned with the `Creatures` folder pattern.

## Structure

Each item lives in its own folder under `Types/<Category>/.../<ItemName>/`:

- `Data/` - item resources (`ItemData` `.tres`)
- `Sprites/` - item-local icon/art used by that item

Example:
- `res://src/Entities/Items/Types/Consumables/Potions/Health_Potion/Data/consumable_health_potion.tres`
- `res://src/Entities/Items/Types/Consumables/Potions/Health_Potion/Sprites/health_potion_icon.png`

## Add New Item

1. Create an item folder inside `src/Entities/Items/Types/...`.
2. Add icon/art into `Sprites/`.
3. In `Data/`, create `New Resource` with type `ItemData`.
4. Fill:
   - `item_id` (stable snake_case id)
   - `display_name`
   - `description`
   - `icon` (item-local sprite)
   - `max_stack`
   - `props` (optional custom fields)
5. Save the `.tres` in `Data/`.

## Inventory Integration

- Starter inventory resource:
  - `res://src/Entities/Systems/Inventory/Resources/player_starter_inventory.tres`
- Add your new `ItemData` resource into slot `item` fields there (or via player-assigned `PlayerInventoryData`).

## Notes

- Keep item assets with the item folder (do not rely on UI asset paths for canonical item data).
- `item_data.gd` remains shared at:
  - `res://src/Entities/Items/item_data.gd`
