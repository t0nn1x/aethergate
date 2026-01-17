Godot Project Structure Overview

Top-level folders are minimal to avoid clutter and keep the root clean.

Primary organization is by in-game functionality, not by file type.

Asset types (art, sound, data, scripts) are grouped only at the lowest folder level, inside each feature or entity.

📁 Main Folder Layout

assets/

Global assets used across the entire game

Examples: soundtrack music, fonts, credits

common/

Reusable, game-agnostic systems with no dependency on game logic

Examples:

State machine system

Resolution / interface scaler

General-purpose shaders

In-game time system

Designed to be portable between projects

config/

Stores configuration values shown in the options menu

Examples:

Audio volume

Resolution settings

Gameplay toggles

entities/ (largest folder)

Everything that can appear or be interacted with in the game world

Includes:

Player

NPCs and organisms

Items and equipment

Skills and interaction nodes

Weather systems

Crafting stations and gathering nodes

Inheritance-based structure:

Base class scripts at the top level

Subtype folders beneath

Final implementations at the lowest level

Example:

items/
  item.gd
  tools/
    tool_item.gd
    foraging/
      foraging_tool_item.gd
      axe/
      pickaxe/


ui/ (inside entities)

UI scenes that exist as nodes in the scene tree

Examples:

HUD

Crafting interface

Inventory

Field notes

Placed here because UI directly interacts with gameplay

localization/

All translated text and language files

Organized for easy long-term maintenance

stages/

All playable areas and environments

Examples:

Islands

Caves

Interiors

Ocean zones

Contains:

Tilemaps

Procedural maps

Shared tilesets reused across stages

utilities/

Background helper systems and global logic

Examples:

Game manager (save/load)

Global signal bus

Scene transition manager

Many scripts here are autoload singletons.

🔑 Core Design Rules

Organize by gameplay purpose first, not by file extension.

Keep related resources together inside the same feature folder.

Use inheritance folders for scalable RPG systems.

Avoid large numbers of root-level folders.

Treat stages as the parent world, and entities as objects living inside it.


