# Repository Structural Audit

**Audit date:** 2026-10-09  
**Repository:** `salexume94-pixel/Scripts`  
**Branch:** `main`  
**Reviewed commit:** `eb77e709ba205f9cb184fbd39e199f981ee3de45`

## Executive summary

The repository's broad folder structure is sound and the current quest foundation should be extended rather than replaced. Static reference checks found no missing targets among scene external-resource declarations, Resource external-resource declarations, or explicit GDScript `preload()`/`load()` paths checked against the repository tree. This is not a Godot editor import, parser, or runtime test.

The main concrete findings are:

1. The initial audit found that `ARCHITECTURE.md` described a nonexistent `data/` folder and used the wrong currency path. A follow-up corrected the documentation to describe system-owned definition folders and `player/player_currency.gd`.
2. `player/player_skills.gd` is a one-line `extends Node` placeholder and owns no skill behavior. A follow-up detached it from `player/Player.tscn`; the file remains in `player/` as a future option because that is the correct ownership area for a Player-owned skill system.
3. Four test-named enemy definitions (`slime_ai_test.tres`, `slime_ai_balanced_test.tres`, `slime_ai_aggressive_test.tres`, `slime_ai_defensive_test.tres`) were registered by the normal `enemies/enemy_database.gd`. A follow-up correction removes them from normal lookup and `get_all_enemies()` while preserving the `.tres` files for future dedicated debug testing.
4. The active quest implementation is a basic one-objective quest. NPC interaction can start it and advance an objective, and QuestManager auto-completes as soon as all objectives are complete. It does not yet support general prerequisites, conditional/branching dialogue, distinct turn-in, or quest-triggered story/world state changes.
5. `STORY_DIRECTION.md` describes an MMO login/tutorial-town opening. The newer working outline, *The Stranger*, starts with the protagonist waking in a field, meeting Mira, and reaching Havenreach. These openings conflict and need an explicit source-of-truth decision before implementation.
6. The architecture distinguishes quest state, story flags, and world state, but there is not yet an implemented, authoritative story-flag owner. Do not use QuestManager as a substitute for that missing responsibility or create a StoryManager without a defined interface.
7. Quest save/load persistence has been confirmed working by the developer. This supersedes the earlier audit's claim that the existing quest-specific save/load behavior remained unverified. Future story-quest-specific behaviors still need testing when implemented.

## Scope and method

The audit enumerated the repository tree and reviewed all tracked source/resource paths at the reviewed commit. Counts below exclude generated editor cache files and binary assets.

| File type | Count | Review |
|---|---:|---|
| GDScript `.gd` | 63 | Inventory, role classification, explicit resource loads, and quest/system review |
| Godot scenes `.tscn` | 30 | External resource/script attachments and referenced paths |
| Godot resources `.tres` | 61 | External script/resource paths and owning system |
| Markdown `.md` | 6 | Architecture, roadmap, story docs, development log, audio README |
| UID sidecars `.uid` | 10 | Present for a subset of scripts; not every script has one |
| Audio `.mp3` | 3 | Battle, overworld, and tutorial-town music assets |

The repository is configured as a Godot 4.7 GL Compatibility project with `ui/MainMenu.tscn` as the main scene and a 1152×648 viewport baseline.

### Reference-check result

- All external resource/script paths inspected in the 30 scenes point to files present in the repository tree.
- All external resource/script paths inspected in the 61 `.tres` files point to files present in the repository tree.
- Explicit `preload()` and `load()` paths inspected across the 63 GDScript files point to files present in the repository tree.
- No missing `res://` target was identified by these static checks.

**Limit:** this does not prove that Godot can parse every script, deserialize every Resource, resolve every UID, or execute every scene. Godot editor import, project parse, and runtime verification still require the local project.

## Folder and responsibility inventory

### `combat/` — 5 scripts, 2 resources

- `combat/affinities.gd` — shared target-affinity types and display labels.
- `combat/combat_rules.gd` — reusable combat calculations and outcome rules.
- `combat/combat_state.gd` — data for one encounter's current state.
- `combat/damage_types.gd` — shared damage categories and display labels.
- `combat/player_action_data.gd` — static definitions for player combat actions.
- Resources: `combat/definitions/fire_attack.tres`, `combat/definitions/physical_attack.tres`.

### `enemies/` — 6 scripts, 26 resources

- `enemies/enemy_action_data.gd` — static enemy action definitions.
- `enemies/enemy_affinity_data.gd` — one enemy's response to a damage type.
- `enemies/enemy_behavior_profile.gd` — action-selection preference data.
- `enemies/enemy_data.gd` — base definition for an enemy type.
- `enemies/enemy_database.gd` — stable enemy-ID catalog.
- `enemies/enemy_elemental_action_database.gd` — shared elemental enemy-action catalog.
- Resources: `behavior_aggressive.tres`, `behavior_balanced.tres`, `behavior_defensive.tres`, `slime.tres`, `slime_ai_test.tres`, `slime_ai_balanced_test.tres`, `slime_ai_aggressive_test.tres`, `slime_ai_defensive_test.tres`, `slime_air_attack.tres`, `slime_attack.tres`, `slime_dark_attack.tres`, `slime_defend.tres`, `slime_drain.tres`, `slime_earth_attack.tres`, `slime_fire_attack.tres`, `slime_fire_drain.tres`, `slime_fire_null.tres`, `slime_fire_repel.tres`, `slime_fire_resist.tres`, `slime_fire_weak.tres`, `slime_heavy_attack.tres`, `slime_light_attack.tres`, `slime_null.tres`, `slime_repel.tres`, `slime_resist.tres`, `slime_water_attack.tres`, all under `enemies/definitions/`.

### `items/` — 2 scripts, 7 resources

- `items/item_data.gd` — reusable item definition and behavior metadata.
- `items/item_database.gd` — stable item-ID catalog.
- Resources under `items/definitions/`: `gold.tres`, `iron_sword.tres`, `leather_armor.tres`, `leather_helm.tres`, `potion.tres`, `power_ring.tres`, `wooden_shield.tres`.

### `player/` — 10 scripts, 1 scene, 1 resource

- `player/player.gd` — Player root coordination.
- `player/player_movement.gd` — movement and movement locks.
- `player/player_stats.gd` — resulting combat/stat values.
- `player/player_skills.gd` — currently an empty placeholder; no skill implementation.
- `player/player_inventory.gd` — item quantities and inventory operations.
- `player/player_equipment.gd` — equipment slots, ownership, and derived equipment changes.
- `player/player_progression.gd` — XP, levels, and stat growth.
- `player/player_currency.gd` — Player-facing gold operations.
- `player/player_affinity_data.gd` — Player damage-affinity data.
- `player/interaction_system.gd` — selection and interaction with world interactables.
- Scene: `player/Player.tscn`.
- Resource: `player/definitions/player_fire_weak.tres`.

### `quests/` — 2 scripts, 1 resource

- `quests/quest_data.gd` — static quest-definition schema.
- `quests/quest_database.gd` — authoritative quest-definition catalog.
- Resource: `quests/definitions/northbridge_introduction.tres`.

### `systems/` — 15 scripts

- `systems/audio_manager.gd` — scene/location-aware background music.
- `systems/combat_manager.gd` — active encounter flow and coordination.
- `systems/debug_system.gd` — shared debug functionality.
- `systems/dialogue_manager.gd` — current dialogue line and active/cleared signals.
- `systems/game_manager.gd` — high-level game lifecycle coordination.
- `systems/game_state.gd` — runtime snapshots that survive scene replacement.
- `systems/item_use_system.gd` — item-use rules.
- `systems/map_manager.gd` — active map position and coordinate conversion.
- `systems/menu_manager.gd` — exclusive menu ownership and shared menu movement lock.
- `systems/options_manager.gd` — persistent preferences and options overlay coordination.
- `systems/quest_manager.gd` — authoritative quest lifecycle and objective progress.
- `systems/reward_manager.gd` — centralized XP, gold, and item rewards.
- `systems/save_manager.gd` — versioned disk save/load and serialization coordination.
- `systems/scene_manager.gd` — scene transitions and Player placement.
- `systems/world_encounter_system.gd` — overworld encounter initiation.

### `ui/` — 8 scripts, 7 scenes

Scripts:
- `ui/battle.gd` — combat presentation and forwarding player actions.
- `ui/debug_combat_hud.gd` — combat diagnostics presentation.
- `ui/dialogue_box.gd` — dialogue display driven by DialogueManager.
- `ui/inventory_character_hud.gd` — inventory/equipment/character interface.
- `ui/main_menu.gd` — New Game, Load, and Quit presentation/input.
- `ui/options_menu.gd` — options interface/input.
- `ui/quest_log.gd` — quest presentation, reading QuestManager state.
- `ui/world_map.gd` — map presentation, reading world/location definitions.

Scenes:
- `ui/DebugCombatHUD.tscn`
- `ui/DialogueBox.tscn`
- `ui/InventoryCharacterHUD.tscn`
- `ui/MainMenu.tscn`
- `ui/OptionsMenu.tscn`
- `ui/QuestLog.tscn`
- `ui/WorldMap.tscn`

### `world/` — 15 scripts, 4 reusable scenes, 24 resources

Scripts:
- `world/building.gd` — building footprint, collision, location identity, and door configuration.
- `world/chest.gd` — chest interaction/reward and opened state.
- `world/door.gd` — doorway interaction and transition requests.
- `world/interior.gd` — reusable interior scene behavior.
- `world/interior_presentation.gd` — reusable interior visuals.
- `world/npc.gd` — reusable NPC interaction, simple dialogue, quest start/progress hooks, optional save point.
- `world/world_boundaries.gd` — physical world bounds.
- `world/world_context.gd` — stable identity for the current world/location context.
- `world/world_exit_boundary.gd` — location exit triggers and transition targets.
- `world/world_location_data.gd` — reusable named-location metadata.
- `world/world_location_database.gd` — location-definition catalog.
- `world/world_map_data.gd` — world/map coordinate metadata.
- `world/world_map_database.gd` — map-definition catalog.
- `world/world_map_world.gd` — World Map world behavior.
- `world/world_presentation.gd` — shared world visuals/camera presentation.

Scenes: `world/Building.tscn`, `world/Chest.tscn`, `world/Door.tscn`, `world/NPC.tscn`.

Resources under `world/definitions/`: `church.tres`, `inn.tres`, `northbridge_east_house.tres`, `northbridge_north_house.tres`, `northbridge_southeast_house.tres`, `northbridge_village.tres`, `northbridge_village_map.tres`, `northbridge_village_world_map.tres`, `northbridge_west_house.tres`, `residence_01.tres`, `residence_02.tres`, `residence_03.tres`, `residence_04.tres`, `residence_05.tres`, `residence_06.tres`, `shop.tres`, `tutorial_town.tres`, `tutorial_town_map.tres`, `tutorial_town_world_map.tres`, `world_map.tres`, `world_map_east_region.tres`, `world_map_north_region.tres`, `world_map_south_region.tres`, `world_map_west_region.tres`.

### `scenes/` — 5 top-level scenes plus 13 interior scenes

Top-level:
- `scenes/Battle.tscn`
- `scenes/Interior.tscn`
- `scenes/NorthbridgeVillage.tscn`
- `scenes/World.tscn`
- `scenes/WorldMapWorld.tscn`

Interiors under `scenes/interiors/`:
- `NorthbridgeEastHouse.tscn`
- `NorthbridgeNorthHouse.tscn`
- `NorthbridgeSoutheastHouse.tscn`
- `NorthbridgeWestHouse.tscn`
- `TutorialTownChurch.tscn`
- `TutorialTownInn.tscn`
- `TutorialTownResidence01.tscn`
- `TutorialTownResidence02.tscn`
- `TutorialTownResidence03.tscn`
- `TutorialTownResidence04.tscn`
- `TutorialTownResidence05.tscn`
- `TutorialTownResidence06.tscn`
- `TutorialTownShop.tscn`

## Concrete findings and recommendations

### A-01 — Architecture folder/reference drift

**Files:** `ARCHITECTURE.md`, `player/player_currency.gd`, repository tree.

- The architecture lists `data/` as a project folder, but no such folder exists.
- It says `systems/player_currency.gd` owns the Player-facing gold API, but the actual script is `player/player_currency.gd`.
- **Recommendation:** update the architecture reference additively after this audit. Do not create an empty `data/` directory merely to match stale documentation; static data currently has clear owning folders such as `items/definitions/`, `enemies/definitions/`, `quests/definitions/`, and `world/definitions/`.

### A-02 — Empty PlayerSkills placeholder

**File:** `player/player_skills.gd`

The file contains only `extends Node` and is attached to `Player.tscn`. It currently has no signals, state, methods, or skill data. This is not a broken resource reference, but it is a component with no responsibility yet.

**Recommendation:** leave it as an explicitly planned placeholder or remove it from the Player scene when the skill system is formally scoped. Do not invent a second skill architecture as part of the quest work.

### A-03 — Test enemy definitions enter the production catalog

**Files:** `enemies/enemy_database.gd`, four `slime_ai_*_test.tres` resources.

The four test-named enemy definitions are preloaded and returned by the same catalog as normal enemy definitions. That may be intentional for debug testing, but the distinction is not enforced by the catalog.

**Recommendation:** decide whether these are debug-only fixtures or supported enemy variants. If debug-only, isolate them from the normal catalog without deleting their data until references and debug workflows have been checked.

### A-04 — Quest definition and interaction capabilities are intentionally minimal

**Files:** `quests/quest_data.gd`, `quests/quest_database.gd`, `quests/definitions/northbridge_introduction.tres`, `systems/quest_manager.gd`, `world/npc.gd`, `systems/dialogue_manager.gd`, `ui/quest_log.gd`.

The current quest schema covers stable ID, title, description, objective definitions, rewards, and repeatability. QuestManager owns lifecycle/progress and automatically completes a quest once every objective is satisfied. NPC fields support starting a quest and advancing a configured objective; DialogueManager stores one active line. There is no generic conditional dialogue/choice sequence or separate turn-in stage.

**Recommendation:** do not expand the schema speculatively. Specify *The Stranger* first, then add only the fields and interaction transitions it actually needs. For a first quest, prefer a small explicit NPC interaction state over a generalized dialogue engine.

### A-05 — Quest state, story flags, and world state do not yet have three implemented owners

QuestManager is the implemented authority for quest state. World-specific systems own their own physical/world features. The architecture explicitly says a story-flag owner must be chosen before flags are implemented; no dedicated authoritative story-flag runtime is present.

**Recommendation:** preserve the distinction. Define the exact story facts and world changes required by *The Stranger* before deciding whether a small story-flag resource/store is needed. Do not make quest completion itself the storage location for discoveries or location access.

### A-06 — Narrative opening conflict

**Files:** `STORY_DIRECTION.md`, `STORY_DESIGN.md`, current *The Stranger* outline.

`STORY_DIRECTION.md` describes the protagonist logging into an MMO for the first time and beginning in a tutorial town. The current working *The Stranger* outline begins with waking in a field, meeting Mira, and reaching Havenreach. The existing implementation still contains Tutorial Town and Northbridge Village content.

**Recommendation:** retain both existing documents unchanged as references. Treat the newer *The Stranger* outline as the working opening direction for the next design pass, but explicitly document the conflict and mark older MMO-login/town-opening details as unresolved/legacy rather than silently mixing the two openings.

### A-07 — Quest persistence needs quest-specific runtime verification

QuestManager exposes serialization methods, and SaveManager includes quest data in the versioned save document. This establishes an implementation path, not proof that all quest states restore correctly.

**Recommendation:** once *The Stranger* is implemented, verify NOT_STARTED → ACTIVE, partial objective progress, COMPLETED, rewards-once behavior, save/restart/load, and Quest Log refresh. Do not claim this test is complete before local Godot runtime testing.

### A-08 — Story and world documentation is not yet separated by ownership

The two existing root story documents mix broad narrative direction, story-system proposals, character principles, and future worldbuilding. There is no canonical World Bible or Story Bible.

**Recommendation:** introduce the structured documents under `docs/world/` and `docs/story/` without moving, deleting, or overwriting the existing root files. The new World Bible owns stable setting facts; the new Story Bible owns plot chronology, character arcs, revelations, and quest-to-plot relationships.

## Documentation organization decision

Keep these existing root files in place:

- `ARCHITECTURE.md` — system/folder ownership and technical boundaries.
- `ROADMAP.md` — current development priorities and completion status.
- `DEVELOPMENT_LOG.md` — append-only chronological implementation and verification history.
- `STORY_DIRECTION.md` — existing high-level premise/influence document; retain as legacy reference until reconciled.
- `STORY_DESIGN.md` — existing narrative design principles and proposed story/quest integration; retain as legacy reference until reconciled.

Add new canonical content under:

- `docs/README.md` — documentation map and ownership rules.
- `docs/world/WORLD_BIBLE.md` — stable world facts, geography, institutions, locations, NPC reference facts, and regional relationships.
- `docs/story/STORY_BIBLE.md` — plot chronology, character arcs, mystery/revelation sequencing, main/side-quest relationships, and story-state requirements.

No existing file is moved, deleted, or overwritten by this organization plan. The development log is not modified in this audit because no runtime implementation or local runtime test was performed.

## Recommended next work

1. Resolve the opening-direction conflict in the Story Bible without deleting the older source material.
2. Establish Havenreach's stable world facts in the World Bible; keep plot revelations and quest order in the Story Bible.
3. Specify *The Stranger* against the existing QuestManager, NPC, DialogueManager, RewardManager, Quest Log, and SaveManager interfaces.
4. Implement only the missing capabilities the specification proves necessary.
5. Pull and run the project locally in Godot; append the actual runtime results to `DEVELOPMENT_LOG.md` after testing.


## Follow-up Corrections (2026-10-09)

- `ARCHITECTURE.md` now documents data definitions in their owning folders instead of describing a nonexistent top-level `data/` folder, and the Player currency path is corrected to `player/player_currency.gd`.
- `player/player_skills.gd` is a placeholder created ahead of actual skill behavior. Its folder is appropriate for a future Player-owned skill system, but the empty component has been detached from `player/Player.tscn`; the script and UID files are retained.
- The four test-named Slime AI Resource files are retained but excluded from normal EnemyDatabase lookup and enumeration. A dedicated debug catalog can be introduced if later test workflows need those profiles.
- The developer confirmed that current quest-specific save/load behavior works. The previous pending-verification finding was stale and has been corrected. This confirmation does not claim that future, not-yet-implemented story quest behavior has been tested.
- Remaining quest-system gaps are distinct turn-ins and conditional dialogue; these are now explicit roadmap items to be designed against the first approved quest rather than implemented speculatively.
