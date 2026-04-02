# Localization System

This project uses a `LocalizationService` autoload for runtime locale switching.

## Files

- Service: `res://src/localization/localization_service.gd`
- Translations:
  - `res://src/localization/translations/ui_en.tres`
  - `res://src/localization/translations/ui_uk.tres`
- Project config:
  - `project.godot` -> `[autoload]` includes `LocalizationService`
  - `project.godot` -> `[internationalization]` includes translation resources

## How UI should read text

Use the localization service API from UI scripts:

```gdscript
@export var localization_service_path: NodePath = ^"/root/LocalizationService"
var _localization_service: Node

func _translate_key(key: StringName) -> String:
	if _localization_service and _localization_service.has_method("translate_key"):
		return String(_localization_service.call("translate_key", key))
	return String(key)
```

Then assign labels/buttons from keys like:

```gdscript
my_label.text = _translate_key(&"ui.main.title")
```

## How language switching works

1. Main menu language button calls:
   - `LocalizationService.set_locale(next_locale, true)`
2. Service emits:
   - `locale_changed(locale)`
3. UI panels listening to `locale_changed` refresh visible text.

## Add or update keys

1. Add key/value to both:
   - `ui_en.tres`
   - `ui_uk.tres`
2. Keep the same key names in every locale file.
3. Use keys in scripts (do not hardcode user-facing text).

Example key pattern:

- `ui.main.play`
- `ui.creator.head`
- `ui.inventory.skills`

## Add a new locale

1. Create a new file in `translations`, for example:
   - `ui_de.tres`
2. Set `locale = "de"` inside that file.
3. Add it to `project.godot`:
   - `[internationalization] locale/translations=...`
4. Add locale code to service export:
   - `supported_locales` in `localization_service.gd`
5. Add localized language-name keys in all locale files:
   - `ui.common.language_name_de`

## Important gotcha

Godot text resources must be saved as UTF-8 **without BOM**.
If BOM is present, Godot can fail to parse `.tres` with errors like:
"Parse Error: Expected '['."
