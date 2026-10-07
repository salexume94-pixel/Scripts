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

Current implementation in progress:
- Versioned JSON save format stored in `user://save_01.json`.
- SaveManager registered as an autoload.
- Player scene/position and world/location context are persisted.
- Player stats, inventory, equipment, and gold are persisted through their existing runtime owners.
- QuestManager state is serialized and restored.
- Chest opened/unopened state is persisted.
- Saving is performed through the designated in-world save point NPC in the Tutorial Town Church.
- F9 loads the default save slot during development/testing.
- Main Menu Load will use the same SaveManager API.

Runtime verification is required before this task is considered complete.

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
