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



## Save / Load System

Disk persistence is owned by `systems/save_manager.gd`.

Responsibilities:
- Build a versioned save document from authoritative runtime systems.
- Write and read the default JSON save slot at `user://save_01.json`.
- Restore the saved gameplay scene and Player position.
- Preserve World/Location transition context needed by reusable interior exits.
- Coordinate serialization for GameState and QuestManager.
- Coordinate persistence for scene-owned persistent objects such as Chests.

SaveManager does not become the owner of gameplay data. Player stats, inventory, equipment, currency, quests, and world objects remain responsible for their own state and expose serialization boundaries where needed.

The initial save format is intentionally human-readable JSON and includes a save version so future format changes can be migrated or rejected explicitly rather than silently loading incompatible data.

The default runtime shortcuts are F5 for Save and F9 for Load. Save/Load should remain a reusable system so a future save menu or multiple save slots can use the same underlying API without moving persistence logic into UI scripts.


---

## Documentation Addendum: Quest / Story Planning (2026-10-09)

This addendum supplements the architecture above; it does not replace earlier rules.

### Documentation responsibilities

- `ARCHITECTURE.md` defines system ownership, folder responsibilities, and boundaries between systems.
- `ROADMAP.md` records the current development order and planned work. Update status statements when new verified information supersedes older planning notes, but retain prior history in the development log.
- `DEVELOPMENT_LOG.md` is append-only for development history. Add new dated entries; do not rewrite or remove earlier entries to make the log shorter.
- Story/world design documents should describe narrative intent and content planning. They must not become alternate sources of runtime quest state or duplicate the authoritative gameplay systems.

### Quest and story content boundaries

- `quests/quest_data.gd` defines reusable static quest data.
- `quests/definitions/` stores individual serialized quest definitions.
- `quests/quest_database.gd` is the catalog used to look up registered definitions.
- `systems/quest_manager.gd` owns runtime quest state, objective progress, and quest transitions. Other systems should call its public API rather than maintaining parallel quest-state dictionaries.
- `ui/quest_log.gd` displays quest information and must not own quest progression.
- `systems/save_manager.gd` coordinates serialization; each authoritative runtime owner remains responsible for providing and restoring its own data.
- NPC dialogue, interactables, combat outcomes, and gated areas may trigger quest progress through the existing quest API. They should not implement separate quest managers.

### Quest state versus story flags versus world state

Keep these concepts distinct in design and implementation:

- **Quest state** records the lifecycle of a particular quest (for example, not started, active, completed, or failed) and its objective progress. QuestManager is authoritative for this layer.
- **Story flags** record durable narrative facts or discoveries (for example, whether the player witnessed a specific event). The project must assign these flags to one explicit authoritative runtime owner before implementation; do not scatter duplicate copies across NPCs, scenes, and UI.
- **World state** records changes to the playable world (for example, whether a road or building entrance is accessible). Store and restore it through the system responsible for that world feature, with save/load integration where persistence is required.

A quest may affect story flags or world state, but the three layers are not interchangeable. A completed quest must not be used as a substitute for every narrative fact or physical world change.

### Content authoring and implementation gate

The revised story outline is design material, not implemented game content. Quest IDs, prerequisites, objectives, rewards, failure rules, story flags, NPC schedules/dialogue, gated areas, and save/load behavior must be reviewed against the existing architecture before implementation. Do not claim a planned story event is implemented or runtime-verified until it has been added to the repository and tested locally in Godot.

No new quest/story subsystem should be created merely to accommodate narrative content. Extend the current architecture only when a clearly owned missing responsibility has been identified and documented.


## Audio Assets and Options (2026-10-09)

### Asset folder ownership

- `assets/audio/music/` stores background music tracks. The folder's README documents the expected track names and upload workflow.
- Keep music separate from future sound effects and voice recordings, which should receive their own subfolders under `assets/audio/` if/when those assets are introduced.
- Binary audio assets are project resources, not scripts or reusable data definitions. Scenes and systems reference them through stable `res://assets/audio/music/` paths.

### Audio playback

- `systems/audio_manager.gd` is the single owner of background music playback and scene-based track selection.
- It selects battle music while `scenes/Battle.tscn` is active, selects a location-specific track when a matching location-ID MP3 exists, and otherwise falls back to Tutorial Town or overworld music.
- It stops music on the Main Menu. A single persistent AudioStreamPlayer prevents overlapping background tracks across scene changes.
- Missing music assets are tolerated during development. The expected MP3s can be uploaded after the code and folder structure are committed.
- Future scenes should use stable location IDs and a corresponding `assets/audio/music/<location_id>.mp3` filename to opt into unique location music.

### Options and preferences

- `systems/options_manager.gd` owns persistent user preferences, the brightness overlay, master-bus volume, and the globally accessible Options overlay.
- `ui/options_menu.gd` and `ui/OptionsMenu.tscn` own only the options interface and user input.
- Brightness and master volume are saved to `user://settings.cfg`; these are local user settings and must not be stored in the game's save slot.
- The Options menu is accessible from the Main Menu and with Escape during gameplay. Back or Escape closes it.
- `OptionsManager` and `AudioManager` are registered as autoloads in `project.godot` so preferences and music survive scene replacement.


### Options Access and Audio Diagnostics Follow-up

- During gameplay, OptionsManager provides a visible `Options (Esc)` button in addition to the Escape shortcut. The Main Menu retains its own Options button.
- AudioManager checks scene and playback state periodically as a fallback, and logs the detected scene, selected track, and missing-file warnings to aid runtime diagnosis.
- These additions do not establish runtime verification; verify locally in Godot before treating audio or Options as complete.


### Shared Town Music Default (2026-10-09)

- `systems/audio_manager.gd` uses `overworld.mp3` for the world-map world.
- All town/local-world scenes use `tutorial_town.mp3` by default, not only Tutorial Town.
- A location can override the shared default by providing `assets/audio/music/<location_id>.mp3` for its stable location ID.
- Battle scenes continue to use `battle.mp3`, and the Main Menu continues to stop background music.
