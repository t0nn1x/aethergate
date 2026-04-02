# Implementation Plan: Localization System

Branch: feature/localization
Created: 2026-02-25

## Settings
- Testing: no
- Logging: no

## Commit Plan
- **Commit 1** (after tasks 1-2): `feat(localization): add core localization service and translation assets`
- **Commit 2** (after tasks 3-5): `feat(ui): wire localized text bindings and language switcher`
- **Commit 3** (after tasks 6-7): `feat(localization): persist language preference and finalize rollout`

## Tasks

### Phase 1: Foundation
- [x] Task 1: Add a localization service autoload for locale management.
Task details: Create a central service (Godot autoload) that exposes current locale, supported locales, and a `locale_changed` signal. Implement startup locale resolution (saved preference -> OS locale -> fallback `en`).
Files: `src/core/localization_service.gd`, `project.godot`.

- [x] Task 2: Create initial translation resources and key catalog.
Task details: Add base translation files (English + first additional language) with stable keys for core UI flows (main menu, character creator, HUD, inventory, system prompts). Keep key naming grouped by domain (`ui.main.*`, `ui.creator.*`, etc.).
Files: `src/localization/*.translation` or `src/localization/*.csv`, `project.godot` (translations list).

### Phase 2: UI Wiring
- [x] Task 3: Localize main menu and startup UI text.
Task details: Replace hardcoded user-facing strings with translation keys via `tr(...)` and central apply methods. Ensure text updates when locale changes at runtime.
Files: `src/ui/Windows/Gui/MainScreen/main_screen.gd`, related main screen `.tscn` files.

- [x] Task 4: Localize character creator UI text and actions.
Task details: Move button/label text (`Start Adventure`, `Randomize`, `Cancel`, titles) to translation keys and refresh bindings on locale changes.
Files: `src/ui/Windows/CharacterCreator/character_creator_panel.gd`, `src/ui/Windows/CharacterCreator/character_creator_panel.tscn`.

- [x] Task 5: Localize shared gameplay UI panels (inventory/system HUD/overlays).
Task details: Apply the same key-based approach to reusable overlays and major HUD/panel labels so all high-visibility text follows one localization pipeline.
Files: `src/ui/**` (inventory, system HUD, overlay panel scripts/scenes as needed).

### Phase 3: UX and Persistence
- [x] Task 6: Add language selector UX and runtime switching.
Task details: Add a language switch control (main menu and/or settings panel) wired to the localization service; switching locale should update visible UI immediately without restart.
Files: main menu/settings scene + script files, `src/core/localization_service.gd`.

- [ ] Task 7: Persist language preference and finalize rollout checks.
Task details: Save chosen locale in existing profile/config service and restore it on boot. Run manual desktop/mobile QA for: startup locale, runtime switching, fallback behavior for missing keys, and no untranslated high-visibility strings in core flows.
Status: Locale persistence is implemented; manual desktop/mobile QA remains.
Files: `src/core/player_profile_service.gd` (or active config persistence service), localization service, touched UI scripts.
