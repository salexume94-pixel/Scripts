# World Bible

## Purpose and ownership

This document is the canonical reference for **stable facts about the setting**: geography, settlements, institutions, factions, ruins, cultures, and NPC reference information. It should describe what exists in the world and how its parts relate, not the order in which the player learns plot revelations.

Plot chronology, character arcs, the central mystery, and quest sequencing belong in `docs/story/STORY_BIBLE.md`. Runtime world state belongs to the gameplay system that owns the affected world feature; this document is design reference, not a save file or runtime database.

## Canon status

The repository contains implementation content for Tutorial Town and Northbridge Village. The current story-planning direction names Havenreach and opens with *The Stranger*. Do not assume these names are interchangeable. Their relationship and the final naming of the first settlement must be explicitly resolved before implementation changes rename or relocate existing scenes/resources.

## Settlement: Havenreach

**Status: planned setting; details not yet fully established.**

- Role in the story: the destination the protagonist is trying to reach after waking in a field and meeting Mira.
- Geography and route into town: to be defined in the first-quest specification.
- Local authority: to be defined.
- Guild presence and responsibilities: to be defined.
- Church/temple presence and responsibilities: to be defined.
- Nearby ruins and their known public history: to be defined.
- Surrounding region, settlements, roads, and hazards: to be defined.

Do not invent these details during quest implementation. Add them here after they are established in the design conversation.

## NPC reference entries

Use one entry per recurring NPC. Keep stable identity, public role, motivations, relationships, and facts true about the character here. Plot-specific secrets and the timing of revelations belong in the Story Bible.

### Mira

- Role in current opening outline: the protagonist meets Mira before reaching Havenreach.
- Stable identity, reason for being in the field, goals, affiliations, and relationship to Havenreach: to be defined.
- Knowledge boundaries: she should not explain the entire world or central mystery in the opening. The Story Bible should record what she knows, what she suspects, and what she is allowed to reveal at each stage.

## Relationship to implemented content

Current repository names such as Tutorial Town, Northbridge Village, Elder Rowan, the Church save-point NPC, and existing building/location resources describe implemented content. Their relationship to the planned Havenreach setting remains unresolved until the story and world references are reconciled. Keep existing resource IDs and scene names stable until a deliberate migration is planned and all references have been checked.


---

## Opening Areas and Havenreach: Decisions Locked (2026-10-09)

This addendum records current world-layout decisions. It supersedes the unresolved relationship statement in the earlier draft; the previous text remains as history.

### Havenreach

- Havenreach is the actual first settlement in the playable story and is separate from Tutorial Town and Northbridge Village.
- Its overworld entrance is represented by a registered WorldLocationData definition and a data-driven entry region in WorldMapWorld.
- Its detailed authority, guild, church/temple, buildings, surrounding hazards, and public history remain unspecified until deliberately designed. Do not silently copy Tutorial Town's story identity into Havenreach.

### One-time story areas

- waking_area is a dedicated scene where the Player wakes and says “Where am I?” When the Player exits the area, SceneManager returns them to the overworld.
- mira_encounter_area is a separate dedicated scene entered from the overworld. It hosts Mira's first encounter and the two-option dialogue.
- Both areas use the same world/location context and scene-transition conventions as local-world scenes, but they are story encounter areas, not settlements and not repeatable quest hubs.
- Their entrances must not create visible overworld map markers. The encounter area may have a hidden entry trigger; waking_area is entered directly by New Game rather than through a normal overworld entrance.
- Mira's “journey with me” choice adds her to the party roster and transitions directly to Havenreach. “Travel alone” leaves her off the roster and returns the Player to the overworld so the Player can reach Havenreach on foot.
- Neither choice changes MAIN_001's objective requirements or completion outcome.

### Example content retained but not in the active route

- tutorial_town and northbridge_village and their existing scenes/resources remain in the repository for examples and reference.
- They must not be selected as the New Game start or shown as playable overworld destinations in the active route.
- Preserve their files and internal example content unless a separate, explicit cleanup task is approved.
