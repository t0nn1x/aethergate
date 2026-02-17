# Inventory MVP Authoring Guide

This inventory system is editor-driven.

## Files

- Item resource script: `res://src/Entities/Items/item_data.gd`
- Inventory container resource: `res://src/Entities/Systems/Inventory/player_inventory_data.gd`
- Slot resource: `res://src/Entities/Systems/Inventory/inventory_slot_data.gd`
- Starter inventory sample: `res://src/Entities/Systems/Inventory/Resources/player_starter_inventory.tres`
- Inventory UI scene: `res://src/Entities/Ui/Inventory/inventory_screen.tscn`

## Create a New Item

1. In FileSystem, create/select an item folder under `src/Entities/Items/Types/.../<ItemName>/`.
2. Keep item-local structure:
   - `Data/` for `.tres`
   - `Sprites/` for icons/art used by the item
3. Right-click `Data/` and create `New Resource` with type `ItemData`.
4. Set fields:
   - `item_id` (stable id)
   - `display_name`
   - `description`
   - `icon`
   - `max_stack`
   - `props` (optional custom dictionary: damage, heal_amount, rarity, etc.)
5. Save as `.tres`.

## Add Items to Player Inventory in Editor

1. Open `res://src/Entities/Player/player.tscn`.
2. Select node `PlayerInventoryComponent`.
3. Open assigned `inventory_data` resource (`player_starter_inventory.tres`) or assign a new `PlayerInventoryData`.
4. In the `slots` array:
   - Set `item` to your `ItemData` resource.
   - Set `amount`.
5. Keep `slot_count` at the size you want (default 20).

## Runtime Usage

- Press `I` (input action: `inventory`) to toggle the inventory book UI.
- Page selector at the bottom switches inventory pages.
- Clicking a slot shows item details and custom `props` on the right page.

## Add / Remove Items at Runtime (Code)

Get the component from player:

```gdscript
var inventory: Node = player.get_node_or_null("PlayerInventoryComponent")
```

Add item:

```gdscript
var item: Resource = load("res://src/Entities/Items/Types/Consumables/Potions/Health_Potion/Data/consumable_health_potion.tres")
var leftover: int = inventory.add_item(item, 7) # leftover > 0 means inventory is full
```

Remove item by id:

```gdscript
var removed: int = inventory.remove_item_by_id("consumable_health_potion", 3)
```

Get amount by id:

```gdscript
var count: int = inventory.get_item_count("consumable_health_potion")
```

If you change slots directly in code/resource while inventory is open, call:

```gdscript
inventory.notify_inventory_changed()
```

## Notes

- Empty slots are valid and safe.
- If `PlayerInventoryComponent` has no `inventory_data`, inventory opens but displays empty slots.
- The UI uses `res://src/Entities/Ui/Assets/Gui-Hud/Inventory Book` textures for open/close flip animation and chapter selectors.
