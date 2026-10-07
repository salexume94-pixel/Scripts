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

### Core Progression Runtime

Player progression is split by responsibility:

- `player/player_stats.gd` owns the resulting Player numerical values.
- `player/player_progression.gd` owns XP thresholds, level-up rules, and stat growth.
- `systems/player_currency.gd` owns the Player-facing gold API.
- `systems/reward_manager.gd` coordinates XP, gold, and item rewards from combat, quests, and future gameplay systems.
- `systems/game_state.gd` stores the runtime snapshots required to preserve progression and currency across scene transitions.

Combat and quest systems should provide reward definitions or reward amounts, then route application through RewardManager rather than implementing competing progression logic.

### Equipment Progression

Equipment progression is data-driven through `ItemData` definitions and `PlayerEquipment`.

- Item definitions own equipment slot and stat bonuses.
- PlayerEquipment owns equipment ownership and slot rules.
- PlayerStats owns the resulting Attack/Defense values.
- RewardManager can award equipment by stable item ID.
- Future shops and loot systems should use the same ItemDatabase and inventory/equipment ownership rules.

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

World scene nodes remain responsible for physical presentation and interaction behavior. Buildings now reference their `WorldLocationData` resource directly, and `world/building.gd` passes that resource's stable world/location IDs to the Door at runtime. This makes existing Tutorial Town buildings part of the shared location-data foundation without moving transition logic into the data resource. The location data resource itself does not perform scene transitions, track Player position, own quest state, or render UI.


## World Map Foundation

The world map system is separated into three responsibilities:

- `world/world_map_data.gd` defines reusable metadata for a world's map, including its stable world ID, physical world bounds, and logical map bounds.
- `world/world_map_database.gd` is the authoritative catalog of world map definitions.
- `systems/map_manager.gd` owns the runtime Player map position and converts gameplay world coordinates into logical map coordinates.
- `ui/world_map.gd` and `ui/WorldMap.tscn` own map presentation only.

`WorldLocationData` now also contains a logical `map_position` and `map_visible` flag. Location definitions therefore remain the source of truth for named map markers, while the map UI only reads and presents that data.

The Tutorial Town map currently represents the existing world bounds of -1000..1000 horizontally and -1500..1500 vertically with a reusable 400x600 logical map space. This relationship is defined by `tutorial_town_map.tres`, not by the UI.

The map system is designed so future worlds can register their own `WorldMapData` and location definitions without changing the map presentation code. The current World scene includes the reusable map overlay, opened with M.

### Map Labels

Map labels are driven by WorldLocationData rather than hard-coded UI strings.

- map_visible controls whether a location participates in map presentation.
- map_label_visible controls whether its name is rendered.
- map_label_offset allows a location definition to adjust label placement without adding UI-specific exceptions.
- Region definitions use LocationType.REGION and are presented as centered area labels rather than point markers.
- ui/world_map.gd owns only the visual rendering rules and reads the location metadata.
- Adding a new town, region, landmark, or dungeon should therefore require a location definition and database registration, not a new map-UI branch.

