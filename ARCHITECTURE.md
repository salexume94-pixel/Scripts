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

### Data Definitions

Reusable static data is stored alongside its owning system rather than in a generic top-level folder:
- `items/definitions/` for item data.
- `enemies/definitions/` for enemy, action, affinity, and behavior-profile data.
- `quests/definitions/` for quest data.
- `world/definitions/` for reusable world/location data.

Add a generic top-level data folder only if a concrete shared-ownership requirement emerges.

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
- `player/player_currency.gd` owns the Player-facing gold API.
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


## Scene Transitions and NPC Movement Lock (2026-10-09)

- `systems/scene_manager.gd` owns the shared transition overlay. It briefly fades to black, displays a short destination message, waits for the destination scene and Player placement, then fades back to gameplay.
- Transition messages are selected from the destination/source scene context so battle and town transitions do not require per-town UI copies.
- `player/player_movement.gd` owns movement permission. Named movement locks allow dialogue to stop the Player without overriding an independent menu lock.
- `systems/dialogue_manager.gd` remains the authoritative dialogue state. Each PlayerMovement component listens for dialogue start/clear signals and applies or releases its own dialogue lock.
- These changes require local Godot runtime verification after pulling from GitHub; they are not considered tested merely because the files commit successfully.


### Transition Movement Lock Follow-up (2026-10-09)

- `player/player_movement.gd` checks `SceneManager.transition_in_progress` before reading movement input.
- SceneManager sets this flag as soon as a transition request is accepted, so movement stops before the fade begins and remains disabled for the outgoing and incoming Player until the transition fully finishes.
- This shared transition state does not overwrite dialogue or menu movement locks.


## Mutually Exclusive Menu Ownership

`systems/menu_manager.gd` is the single authority for whether a player-facing menu may open. Menus request ownership before becoming visible and release only their own menu ID when closed.

Current menu IDs:
- `quest_log`: `ui/quest_log.gd`
- `inventory_character`: `ui/inventory_character_hud.gd`
- `world_map`: `ui/world_map.gd`
- `options`: `systems/options_manager.gd`

A menu shortcut must close its own menu when it is already open. It must refuse to open when another menu owns the UI. New menus must use MenuManager rather than implementing separate menu-lock logic.


### Shared Menu Movement Lock Follow-up (2026-10-09)

- `systems/menu_manager.gd` now applies a named `menu` movement lock whenever a menu successfully claims menu ownership and releases it only when that same active menu closes.
- The manager finds the active Player through the `player` group and calls `PlayerMovement.set_movement_lock()`. This keeps menu movement restrictions separate from dialogue, scene-transition, and other movement locks.
- Menus should continue using `MenuManager.try_open_menu()` and `MenuManager.close_menu()`; they must not independently toggle global movement permission for this shared menu lock.


---

## Documentation Organization and Audit Corrections (2026-10-09)

This section supplements earlier architecture notes and corrects stale path descriptions without removing historical content.

- The current repository does not contain a `data/` directory. Static definitions are kept with their owning systems, including `items/definitions/`, `enemies/definitions/`, `quests/definitions/`, and `world/definitions/`. Do not create a generic data folder unless a concrete ownership need is identified.
- The Player-facing currency implementation is `player/player_currency.gd`, not `systems/player_currency.gd`.
- `docs/README.md` defines the documentation index and ownership rules.
- `docs/world/WORLD_BIBLE.md` owns stable setting facts. `docs/story/STORY_BIBLE.md` owns plot chronology, character arcs, and revelation pacing. Existing root-level `STORY_DIRECTION.md` and `STORY_DESIGN.md` remain in place as reference material until their conflicts are deliberately reconciled.
- Quest state remains owned by QuestManager. World features own their physical/access state. Story flags require one explicit authoritative owner before implementation; do not scatter duplicate flags across NPCs or scenes.
- The first quest should be specified before expanding QuestData or DialogueManager. Add prerequisites, categories, turn-in states, failure rules, or conditional dialogue only when the actual quest design requires them.


### Player Skills Placeholder Status

`player/player_skills.gd` currently contains only `extends Node` and does not implement skill behavior. Its location under `player/` is appropriate if a Player-owned skill/ability system is designed. Until that system has a defined responsibility and implementation, do not attach the empty placeholder as an active Player component. Define actual skill data, resource costs, unlock rules, and execution ownership before building it; combat actions should remain in the combat system unless the design establishes a distinct player-skill responsibility.


---

## Story Opening Implementation Boundaries (2026-10-09)

- The first playable story route uses scenes/WakingArea.tscn, scenes/MiraEncounterArea.tscn, the overworld, and a separate Havenreach scene. Tutorial Town and Northbridge Village remain example assets and are not active route destinations.
- world/world_location_database.gd remains the catalog for stable location definitions. world/world_map_world.gd builds entry triggers from registered WorldLocationData; do not hard-code separate town-entry behavior into the map script for each location.
- systems/dialogue_manager.gd owns active dialogue and choice selection. ui/dialogue_box.gd renders the available choices; NPCs or scene-owned encounter scripts respond to stable choice IDs.
- systems/party_manager.gd owns stable party-member IDs and serializable roster state. It currently represents membership only; companion combat AI, formation, and companion-specific stats require separate design before implementation.
- systems/save_manager.gd serializes PartyManager data alongside existing quest and player snapshots. Scene and position remain restored through the existing SceneManager path.
- MAIN_001 uses the existing QuestData/QuestManager lifecycle. A dialogue route choice is not a quest branch and must not add a duplicate quest flag.
- Runtime verification must distinguish static repository checks from a local Godot run. Do not mark a new story scene, dialogue choice, transition, party roster, or save/load route as runtime-verified until it has been tested after pulling.


### One-time World Location Entrances

WorldLocationData supports optional entry blocking after a named quest objective is complete. WorldMapWorld reads this metadata while building entry triggers and consults QuestManager's existing progress. This is intended for a concrete one-time entrance such as Mira's first encounter; it does not create a new story flag or duplicate quest state. Leave the fields empty for ordinary locations.

## Runtime Debug Menu and Companion Preview

- `ui/debug_menu.gd` and `ui/DebugMenu.tscn` provide the gameplay development menu. F3 toggles it in gameplay scenes.
- `systems/game_state.gd` owns the runtime-only `overworld_encounters_enabled` setting. `systems/world_encounter_system.gd` reads the setting before processing random encounters. The toggle does not change enemy definitions, encounter probability, or combat affinities.
- `ui/debug_combat_hud.gd` remains the combat diagnostic overlay and continues to display Player Affinities. It is separate from the general Debug Menu and normal Battle HUD.
- The Character/Inventory menu presents party membership and provisional companion preview stats. Those values are informational only until a dedicated companion-stat and combat-participation system is implemented.
- Each playable world with its own map identity must register a matching `WorldMapData` resource in `world/world_map_database.gd`. In particular, the `havenreach` scene context requires a map definition whose `world_id` is exactly `havenreach`.

## Debug Menu Consolidation Correction

The active development overlay is the existing `ui/debug_combat_hud.gd` / `ui/DebugCombatHUD.tscn`, attached to gameplay scenes and toggled with F3. It retains the Player Affinities display and also exposes the runtime-only overworld encounter toggle. No separate general DebugMenu scene is used.


## Dialogue Interaction Lock

- `systems/dialogue_manager.gd` owns the internal dialogue state through `is_active`. This state is gameplay-facing and is not a visible indicator.
- While `DialogueManager.is_active` is true, `player/interaction_system.gd` reserves E for dialogue only. It must not continue to NPC, Door, Chest, or other world-interactable selection during that input.
- Single-line dialogue consumes E to dismiss the line. Choice dialogue consumes E to activate the focused option; `ui/dialogue_box.gd` owns focus and delegates the selected choice ID back to DialogueManager.
- The interaction lock is cleared by DialogueManager when dialogue ends. Avoid adding a second dialogue-active flag to the Player or individual interactables, as duplicate state can drift out of sync.

## Dialogue Interaction-Lock Verification

- The temporary scene `scenes/InteractionLockTest.tscn` was used to verify that pressing E during active dialogue dismisses dialogue without activating a nearby Chest.
- The user reported that the interaction-lock checklist passed. The temporary scene was then removed from `main`; it is not production content.
- If this behavior needs retesting later, recreate a temporary isolated test scene rather than adding test-only objects to Havenreach.


## Documentation and Runtime Ownership Correction (2026-10-10)

The documentation source of truth is indexed in `docs/README.md`:

- `ARCHITECTURE.md` defines technical ownership and system boundaries.
- `ROADMAP.md` defines priorities and planned work.
- `DEVELOPMENT_LOG.md` is the chronological implementation and verification record. Append entries; never replace earlier history.
- `docs/world/WORLD_BIBLE.md` owns stable setting facts.
- `docs/story/STORY_BIBLE.md` owns plot chronology, character arcs, and revelation order.
- `STORY_DIRECTION.md` and `STORY_DESIGN.md` remain reference material until explicitly reconciled; they are not co-equal instructions to merge contradictory openings.

Correction to the earlier Runtime Debug Menu section: the active F3 overlay is `ui/debug_combat_hud.gd` with `ui/DebugCombatHUD.tscn`, which also exposes the runtime-only overworld encounter toggle and Player Affinities diagnostic display. There is no separate active `ui/debug_menu.gd` / `ui/DebugMenu.tscn` system in the current repository tree. Treat the earlier naming as stale documentation, not a requirement to recreate a second debug menu.

The current *The Stranger* route uses `scenes/WakingArea.tscn`, `scenes/MiraEncounterArea.tscn`, and `scenes/Havenreach.tscn`. Tutorial Town and Northbridge Village files remain example/reference content and should not be deleted or reactivated as part of routine architecture cleanup.

Static repository inspection and local Godot runtime verification are separate gates. Do not describe current story scenes, dialogue choices, transitions, party persistence, or save/load behavior as runtime-verified unless the developer has tested those exact behaviors after pulling the corresponding changes.


## Moving World Characters

- `world/moving_npc.gd` owns shared autonomous-character movement, identity (`ENEMY`, `NPC`, `ALLY`), basic obstacle steering, and hostile contact-encounter requests.
- Moving actors use `CharacterBody2D` collision. Their collision masks must include world obstacles and other actors as appropriate; existing static NPCs and interactables remain separate systems.
- Enemy and civilian movement intent is identity-specific. Only Enemy identity may call `CombatManager.start_encounter()`; the existing CombatManager remains authoritative for enemy lookup and battle lifecycle.
- Ally is an identity placeholder only. Do not add party-following or combat participation until the companion combat design is approved.
- `scenes/MovingNPCTest.tscn` is isolated development content. Keep test actors and obstacles out of Havenreach and production world scenes.
- Steering probes are a lightweight initial obstacle-avoidance foundation, not full pathfinding. Protected-town exclusion and robust multi-obstacle navigation remain acceptance gates before this system is production-ready.

## Dedicated Test Scene Policy

All future isolated gameplay tests and debugging work should use `scenes/MovingNPCTest.tscn` as the shared `test_scene` / debugging area unless a test explicitly requires a separate scene for technical reasons. Keep the Player instance in this scene. The test scene owns its test-only camera, attached to the Player so the view remains centered on the Player during movement. Do not remove or replace the Player when adding new test fixtures; add temporary test actors and obstacles around it instead.


## Ally Presence and Town Encounters

Moving Allies use a non-blocking proximity sensor separate from their physical body collision. The shared `world/moving_npc.gd` actor emits `ally_player_entered` and `ally_player_exited` signals when the Player enters or leaves the Ally's detection radius. The sensor does not start dialogue, recruit the Ally, change relationship values, or start combat by itself.

Town-specific Ally appearances should be authored as deliberate story/location content. An Ally may be placed at a particular town location for a visit or story condition, then use the sensor to notify the story/interaction layer when the Player approaches. A future Ally Presence / Private Actions system should own appearance conditions and visit state; it should query existing location and quest data instead of embedding town schedules or story progression in the moving actor. This is inspired by optional party-member town interactions in *Star Ocean*, without copying its specific characters or story content.
