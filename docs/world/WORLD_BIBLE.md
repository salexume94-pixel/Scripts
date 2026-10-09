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
