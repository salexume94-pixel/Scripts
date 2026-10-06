# Scripts - Architecture

## Purpose

This project is a fresh implementation of the game systems from the previous prototype.

The goal is to keep systems organized, modular, and easy to understand.

Each script should have a clear responsibility.

---

## Core Rule

A script should do one primary job.

A system should not contain unrelated functionality simply because it is convenient.

If a script becomes responsible for multiple unrelated systems, the functionality should be separated into additional scripts.

---

## Project Structure

### combat/

Combat-related systems.

### data/

Reusable game data definitions.

### enemies/

Enemy-specific behavior.

### items/

Item-related systems.

### player/

Player-related systems such as:
- Player core
- Movement
- Stats
- Skills
- Inventory
- Equipment
- Progression

### quests/

Quest-related static data definitions and quest content catalogs.

### Quest Runtime

Quest runtime state is owned by `systems/quest_manager.gd`.

Responsibilities:
- Quest IDs and definition lookup
- Quest state transitions
- Objective progress tracking
- Completion/failure state
- Save/load serialization boundary

Quest presentation is owned by `ui/quest_log.gd` and must not become the owner of quest state.

World interactions and future gated-area systems should communicate with QuestManager rather than storing duplicate quest state.

### scenes/

Game scenes.

### systems/

Global game systems such as:
- Game manager
- Save/load manager
- Scene management
- Global state

### ui/

User interface systems.

### world/

World-related systems such as:
- World interaction
- Doors
- Chests
- Regions
- Waystones
- World objects

---

## Separation of Responsibilities

Game logic should remain separate from UI whenever practical.

Game data should remain separate from presentation.

Saving and loading should be handled by the save system rather than individual gameplay systems.

Global systems should coordinate other systems rather than replacing them.

---

## Player Architecture

The player will be divided into focused systems.

Expected systems include:
- Player core
- Player movement
- Player stats
- Player skills
- Player inventory
- Player equipment
- Player progression

These systems may communicate with each other, but each should maintain a clearly defined responsibility.

---

## Development Rule

Do not add functionality to an existing script merely because the functionality is related to the same object.

First determine which system owns the responsibility.

---

## Reference Project

The previous Prototype project may be used as a reference for existing gameplay mechanics.

Its architecture should not be copied automatically.

Existing mechanics should be redesigned and implemented according to this architecture.


## World Location Data

Named locations that may have gameplay and story significance should be represented as reusable world data rather than only as scene-node names or UI text.

`world/world_location_data.gd` defines the reusable `WorldLocationData` Resource. It provides:
- Stable location ID
- Owning world ID
- Player-facing name
- Location type
- Optional description
- Story-significance metadata

`world/world_location_database.gd` is the authoritative catalog for location definitions. Gameplay scenes may continue to carry stable IDs for their physical/runtime context, but reusable player-facing location metadata should come from the location definition rather than being duplicated in UI code.

Location definitions must remain separate from map presentation. Map coordinates and world-to-map conversion are intentionally reserved for the Map / World Map Foundation task.

World scene nodes remain responsible for physical presentation and interaction behavior. The location data resource does not perform scene transitions, track Player position, own quest state, or render UI.
