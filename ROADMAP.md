# Scripts - Development Roadmap

## Purpose

This roadmap tracks the planned development order for the Scripts Godot RPG project.

The roadmap is intentionally separate from the development log:

- ROADMAP.md defines what should be worked on next.
- DEVELOPMENT_LOG.md records what has actually been implemented, corrected, and runtime-verified.
- ARCHITECTURE.md defines where systems and responsibilities belong.

The roadmap should be updated when the development order changes. Completed work should not be treated as an upcoming task simply because an older roadmap entry still exists.

---

## Current Development Order

### 1. Equipment Comparison / Details - COMPLETE

Equipment comparison and item details are implemented and locally runtime-verified.

Includes:
- Equipment slot information
- Equipment stat bonuses
- Current equipped item comparison
- Projected Attack/Defense values
- Equip/Unequip behavior remaining connected to the authoritative equipment system

---

### 2. Map / World Map Foundation - COMPLETE, RUNTIME VERIFIED

The project currently has a playable world, but it does not yet have a proper player-facing map system.

The map foundation is now implemented as a reusable data/runtime/presentation stack. `WorldLocationData` provides stable location identity and logical map coordinates, `WorldMapData` defines each world's map metadata and coordinate conversion, `MapManager` tracks the Player's current map position, and the reusable World Map overlay displays Tutorial Town and its registered locations.

Before adding map labels, establish the map foundation:

- Define what the player-facing map represents. *(implemented: reusable world map overlay)*
- Establish the world/map coordinate relationship. *(implemented: WorldMapData world-bounds to logical-map conversion)*
- Define map locations and points of interest in reusable data. *(implemented: WorldLocationData map coordinates; Tutorial Town locations registered)*
- Create the basic map UI. *(implemented: reusable WorldMap overlay opened with M)*
- Display the player's current position. *(implemented: MapManager runtime position tracking)*
- Support the current world and future regions without hard-coding presentation into gameplay systems. *(implemented: world map database + reusable presentation)*
- Keep map data, world state, and map presentation separated according to ARCHITECTURE.md.

The initial map should be deliberately simple. The goal is a reusable foundation, not a fully featured MMO map on the first pass.

Current world-layer extension:
- Playable World Map scene added as the larger world layer outside Tutorial Town.
- Tutorial Town can transition to the World Map and back.
- World Map uses its own WorldContext and WorldMapData definition so MapManager can distinguish the two layers.
- M remains the player-facing map overlay and now reads the active world layer.

---

### 3. Save / Load System - COMPLETE, RUNTIME VERIFIED

Establish a working disk-persistence layer before adding more World Map content or presentation polish.

Current implementation:
- Versioned JSON save format stored in `user://save_01.json`.
- SaveManager registered as an autoload.
- Player scene/position and world/location context are persisted.
- Player stats, inventory, equipment, and gold are persisted through their existing runtime owners.
- QuestManager state is serialized and restored.
- Chest opened/unopened state is persisted.
- Saving is performed through the designated in-world save point NPC in the Tutorial Town Church.
- F9 loads the default save slot during development/testing.
- Main Menu Load will use the same SaveManager API.

Runtime verification has passed for the current SaveManager foundation, including quest-state persistence, as confirmed by the developer. This task is complete for the behavior currently implemented; newly added quest-specific behavior still requires its own runtime tests.

---

### 4. Map Labels - IN PROGRESS

After the map foundation exists, add readable labels for:

- Towns
- Regions
- Important locations
- Other points of interest as the world expands

Labels should be driven by map/world data rather than scattered UI-specific strings.

Current implementation in progress:
- Data-driven map label visibility and positioning added to WorldLocationData.
- Region definitions added for the current World Map.
- Region names are rendered as area labels instead of point markers.
- Town and point-of-interest label sizing is determined by location type.

Runtime verification is still required before marking this task complete.

---

### 5. Combat Polish - COMPLETE

The planned Combat Polish work has been implemented and runtime verified.

Completed:
- Player and enemy combat actions
- Elemental affinity presentation and resolution
- Speed-based accuracy and critical resolution
- Defend and Pass
- Enemy behavior profiles
- Combat feedback and turn-state presentation
- Victory/defeat handling
- Run and Return to World
- Overworld encounter integration
- Combat Debug HUD and diagnostic presentation

Combat remains subject to ongoing balance and presentation refinement as new content is added, but the current roadmap-level Combat Polish task is complete.

---

### 6. Balance - ONGOING WORLD-BUILDING CONSTRAINT

Balance is an ongoing constraint during world building, not something that must wait until the end.

A broader final balance pass remains planned after sufficient world, enemy, equipment, quest, and progression content exists.

Continue evaluating:
- Enemy difficulty
- Player damage and survivability
- Encounter frequency
- Enemy action weights
- Elemental affinity impact
- Press Turn costs
- XP, gold, and loot
- Equipment progression
- Regional difficulty

A broader balance pass should happen after enough world, enemy, equipment, quest, and progression content exists to make meaningful comparisons.

---

### 7. Quest Log - FOUNDATION IMPLEMENTED, RUNTIME VERIFIED

The Quest Log foundation has been implemented.

Current foundation includes:
- Quest definitions
- Stable quest IDs
- Quest states
- Objectives and progress
- Completion/failure handling
- QuestManager runtime ownership
- Quest Log UI
- Save/load serialization boundary

The runtime verification pass is complete. The foundation is now verified and is being used by actual quest content.

---

### 8. Core Progression - COMPLETE, RUNTIME VERIFIED

Establish the systems that determine how the Player actually advances.

Current implementation:
- XP and level progression
- Level-up stat growth
- Gold/currency
- Character progression rules
- Equipment progression through authoritative equipment/item data
- Item acquisition and shared reward application
- Player defeat and recovery

Runtime verification is complete for the current implementation. XP, level progression, stat growth, gold, rewards, equipment-derived stat preservation, and defeat/recovery behavior have been verified.

Planned progression rules must remain centralized so combat, quests, shops, loot, and future content do not implement competing XP, level, currency, or reward logic.

---

### 9. Quests / Gated Areas - FOUNDATION READY, CONTENT PAUSED

The Quest Log and reusable quest/NPC integration are established, but actual story quest production is intentionally paused while the remaining core systems are identified and implemented.

The Northbridge NPC, quest giver, building, and quest tracking work was an integration test, not final story content.

Planned later work includes:
- Tutorial and early-game quests
- Required-item objectives
- Defeated-enemy objectives
- Exploration objectives
- Locked doors and areas
- Quest-based area unlocking
- Story progression through gameplay
- Subtle anomalies that support the game's underlying mystery

Quest state must remain authoritative in QuestManager. Gated-area systems should query quest state rather than maintaining duplicate quest progression.

---

### 10. Ending / Boss

After the core world, progression, quest, and gated-area structure is established:

- Design the final progression path.
- Implement the final area.
- Implement the final boss encounter.
- Build the ending sequence.
- Connect the ending to the game's established story and mystery.

---

## World-Building Rule

World building should use the existing systems rather than bypassing them.

When creating new regions, enemies, equipment, quests, or locations:

1. Follow ARCHITECTURE.md.
2. Reuse existing systems where they are appropriate.
3. Keep balance considerations active during content creation.
4. Add reusable data definitions instead of hard-coding content into UI or unrelated gameplay scripts.
5. Runtime-test each meaningful system before treating it as complete.

---

## Story Direction

The intended progression is:

> "I'm playing an MMO."
>
> "Something about this game is strange."
>
> "This world isn't behaving like a normal MMO."
>
> "There is something underneath this world."
>
> "What exactly is this world?"
>
> "What should I do now that I know the truth?"

The protagonist begins as an ordinary beginner rather than an obvious chosen one. The story should emerge gradually through normal gameplay, quests, locations, NPCs, and increasingly difficult-to-ignore anomalies.

Core framework:

- Quest = What am I doing now?
- Story = Why does it matter?
- Mystery = What is happening?
- Choice = What should I do about it?

---

## Development Workflow

For each roadmap item:

1. Inspect the current repository and architecture before changing code.
2. Implement the smallest coherent system that establishes the required foundation.
3. Add comments explaining each script and major section.
4. Commit changes to GitHub.
5. Pull the changes locally with git pull origin main.
6. Run the Godot runtime verification checklist.
7. Only mark the work locally verified after the runtime test actually passes.
8. Append the verified result to DEVELOPMENT_LOG.md without replacing previous entries.


---

## Documentation Addendum: Current Quest + Story Design Focus (2026-10-09)

The next major content-design focus is the main story and quest structure. This is a planning decision, not a claim that the story quests have been implemented.

### Planning sequence

1. Establish the World Bible and Story Bible, keeping world reference material distinct from plot and quest planning.
2. Define Havenreach and its surrounding region, including the local authority, Adventurer's Guild, church, shops, important NPCs, nearby routes, and ruins.
3. Refine the main-story quest list from the current story skeleton. Preserve the restrained dialogue of the Wanderer and Mira's role as a companion with her own life, not an exposition source.
4. Define quest prerequisites, objective/completion rules, missability, failure behavior, rewards, story consequences, and world-state changes.
5. Define an authoritative owner and persistence plan for story flags before implementing any flags in code.
6. Derive side quests and gameplay requirements from the established world and main story.
7. Audit each planned content feature against ARCHITECTURE.md before repository implementation.
8. Implement in small increments, then have the developer pull `origin main` and perform runtime verification in Godot. Append results to DEVELOPMENT_LOG.md; never replace prior log entries.

### Current story skeleton (design only)

- **The Stranger:** the protagonist wakes in a field, meets Mira, and reaches Havenreach.
- **The Missing Caravan:** a normal guild job leads to the first unexplained discovery: a corpse without visible wounds. The player glimpses the Wanderer, who disappears.
- **Life in Havenreach:** ordinary RPG activities, local jobs, ruins, reputation, and Mira's personal story allow the world and relationships to develop before the mystery escalates.
- **The Wanderer's appearances:** rare, brief encounters; he offers little or no explanation.
- **The Ruined Watchtower:** murals resemble the Wanderer. The player and Mira lose to the boss; the Wanderer intervenes, and the official record later conflicts with Mira's memory.
- **Investigation:** the player finds contradictory historical and religious accounts without receiving a definitive explanation.
- **Mira's injury:** a personal relationship beat, not a lore lecture.
- **The Black Coin:** an unexplained object is recognized by the Wanderer much later.
- **Beyond the Road:** the Wanderer leads the player and Mira to an ancient structure of doors. The Wanderer refuses to enter the player's door. This is the current arc endpoint, not a finalized game ending.

Names, locations, IDs, timings, and mechanics in this outline remain subject to story/world design. The existing repository's Northbridge quest is an integration test and should not be mistaken for the final Havenreach story questline.

### Quest-content readiness checklist

Before adding each quest to the repository, define:
- Stable unique quest ID and display name.
- Quest type (main, side, or repeatable activity).
- Giver/start trigger and location.
- Prerequisites and unlock conditions.
- Ordered or parallel objectives with stable objective IDs.
- Completion and failure conditions, including whether failure is possible.
- Reward definitions using existing reward/item/progression systems.
- Story facts and world changes produced by the quest, with explicit authoritative owners.
- Whether the quest can be missed, repeated, or revisited.
- Save/load behavior for quest progress and related persistent world objects.
- Runtime verification steps and results.


---

## Quest and Narrative Preparation Gate (2026-10-09)

This addendum records the next development gate without removing or rewriting earlier roadmap entries.

### Completed preparation

- Repository tree inventory completed for all 63 GDScript files, 30 scenes, and 61 Resource definitions.
- Static checks of scene/resource external references and explicit GDScript `preload()`/`load()` paths found no missing targets in the reviewed tree.
- Structural findings are recorded in `docs/REPOSITORY_AUDIT.md`.
- Documentation ownership is established in `docs/README.md`, with separate World Bible and Story Bible documents. Existing root story documents remain in place.

### Quest/NPC capabilities to add when the approved quest design requires them

- **Distinct quest turn-in:** support quests whose objectives can be complete while the quest remains awaiting delivery/reporting to a designated NPC or location. Do not auto-complete these quests as soon as objective counts reach their targets.
- **Conditional dialogue:** let NPC dialogue select the appropriate response from explicit conditions such as quest state/objective progress and approved story/world facts. Keep dialogue presentation in DialogueManager/UI, quest state in QuestManager, and world-state ownership in the affected world system.
- **Prerequisites and unlock conditions:** add only the condition types required by the approved quest design; do not build a generic branching narrative engine in advance.

### Remaining design gate before quest implementation

1. Reconcile the older MMO-login/tutorial-town opening in `STORY_DIRECTION.md` with the current *The Stranger* opening: waking in a field, meeting Mira, and reaching Havenreach. Do not merge the two openings by assumption.
2. Establish Havenreach's stable facts in `docs/world/WORLD_BIBLE.md`: local authority, guild, church/temple, NPC roles, nearby ruins, and surrounding region. Keep plot chronology and revelation timing in `docs/story/STORY_BIBLE.md`.
3. Specify *The Stranger* against the existing QuestManager, NPC interaction, DialogueManager, RewardManager, Quest Log, and SaveManager interfaces. Lock stable quest/objective IDs, prerequisites, trigger rules, dialogue transitions, completion/turn-in behavior, rewards, story facts, world changes, and persistence requirements.
4. Extend QuestData or dialogue/NPC behavior only for capabilities the approved first-quest specification proves necessary. Do not create a StoryManager until its responsibilities, authoritative data, and interface are explicitly defined.
5. Implement the quest end to end, then locally verify acceptance, objective progress, dialogue, completion, rewards-once behavior, Quest Log updates, and save/restart/load for active and completed states.

### Verification boundary

The repository audit is static. It does not establish that Godot parsed/imported the project or that any new quest behavior has passed runtime verification. After local testing, append the actual results to `DEVELOPMENT_LOG.md`; never replace or shorten existing log history.


---

## MAIN_001 Implementation Started (2026-10-09)

The opening decisions are now implemented in the repository as an initial playable content pass rather than planning-only content.

- New Game now initializes MAIN_001 and enters WakingArea.
- WakingArea, MiraEncounterArea, and Havenreach have separate scenes and stable location context.
- The Stranger is registered through the existing QuestData/QuestDatabase system.
- DialogueManager and DialogueBox support reusable choice buttons; Mira's two choices use stable choice IDs.
- WorldLocationData and WorldMapWorld define the hidden Mira entry and visible Havenreach entry. The Mira entry closes after the existing meet_mira objective completes.
- PartyManager records companion roster membership and SaveManager serializes/restores it.
- Havenreach includes a church interior and Churchkeeper save point so both choice routes can be saved after reaching the settlement.
- Tutorial Town and Northbridge Village remain in the repository, but their overworld entry regions and visible markers are disabled.

Status: repository implementation committed; local Godot runtime verification is still required. This implementation does not establish companion combat AI or full Havenreach town content.


## Repository Audit and Documentation Ownership Refresh (2026-10-10)

The current repository inventory is 67 GDScript files, 35 scenes, and 70 `.tres` resources. The historical audit in `docs/REPOSITORY_AUDIT.md` was originally run against an earlier tree of 63 scripts, 30 scenes, and 61 resources. Its no-missing-reference result is scoped to that earlier tree; a full static reference pass against the current inventory remains an explicit audit task.

Documentation ownership is settled:

- `ARCHITECTURE.md`: technical ownership and system boundaries.
- `ROADMAP.md`: current development priorities.
- `DEVELOPMENT_LOG.md`: append-only history of implementation, static checks, and developer-reported runtime verification.
- `docs/REPOSITORY_AUDIT.md`: structural inventory, concrete findings, and audit verification boundaries.
- `docs/world/WORLD_BIBLE.md`: stable world facts.
- `docs/story/STORY_BIBLE.md`: plot chronology, characters, and revelations.
- Root `STORY_DIRECTION.md` and `STORY_DESIGN.md`: retained reference documents pending deliberate reconciliation.

Current story implementation work is present in the repository, but local Godot runtime verification remains pending as recorded in the Story Bible and development log. Do not treat the repository audit as evidence that the new opening has passed runtime testing. The next audit completion gate is a current-tree static reference check, followed by local Godot import/parser and story-route testing.


## Moving NPC Foundation (in progress)

Implementation order:

1. Inspect Player movement, collision layers, world boundaries, interaction targets, and CombatManager encounter interfaces.
2. Add shared `world/moving_npc.gd` with Enemy, NPC, and Ally identity values.
3. Add isolated `scenes/MovingNPCTest.tscn`.
4. Verify civilian wandering and Player avoidance; improve steering until it reliably handles buildings, doors, chests, and boundaries.
5. Verify Enemy pursuit and contact-triggered encounters, including protected-town exclusion.
6. Confirm existing combat, Player movement, and world interactions remain intact.
7. Append actual implementation and runtime results to `DEVELOPMENT_LOG.md`; do not rewrite earlier history.
8. Pull `main` and run the dedicated Godot checklist locally.

Current status: initial code and test scene are on `feature/moving-npc-foundation`. Static review only. Do not merge to `main` or call this runtime-verified until the test scene has been run and the protected-town/pathfinding gaps are closed.
