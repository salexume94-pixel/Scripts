# Story Bible

## Purpose and ownership

This document is the canonical reference for **what happens in the story and when**: plot chronology, character arcs, mystery/revelation pacing, main-quest structure, side-quest relationships, and narrative consequences.

The World Bible (`docs/world/WORLD_BIBLE.md`) owns stable setting facts. Quest definitions under `quests/definitions/` own implementation-ready static quest data. QuestManager owns quest lifecycle/progress. Story flags and world-state changes remain separate from quest state and must have explicit runtime owners before implementation.

## Current working opening: The Stranger

**Status: design direction; not yet implemented as a quest.**

The current working outline begins with the protagonist waking in a field, meeting Mira, and reaching Havenreach. The first playable main quest is titled **The Stranger**.

This supersedes the older opening proposal in `STORY_DIRECTION.md` for planning the next design pass, but that existing file is retained unchanged as historical/reference material. Do not combine the two openings by adding an MMO login/tutorial sequence unless the story direction is deliberately revised.

## Narrative constraints

- The protagonist should not be immediately presented as a chosen one or legendary hero.
- The Wanderer should speak minimally; silence and action should carry narrative weight.
- Mira should be observant and informed without acting as an exposition machine or knowing everything about the world.
- The opening should establish an immediate practical goal and a believable reason to travel.
- The larger mystery should remain mostly unexplained during this first quest.
- Story revelations should be paced through quests, locations, NPC interactions, and environmental discoveries rather than long explanatory dialogue.
- Main quests and side quests should coexist without making every local problem a direct part of the central mystery.

## Quest: The Stranger

**Stable quest ID:** proposed `the_stranger`  
**Category:** main story quest  
**Implementation status:** not implemented; exact objective IDs and trigger details remain to be specified.

### Current narrative sequence

1. The protagonist wakes in a field.
2. The protagonist meets Mira.
3. Mira and the protagonist travel or make their way toward Havenreach.
4. The protagonist reaches Havenreach.

The order above is the current outline, not a finalized implementation specification. The next design pass must determine which beats are player objectives, which are automatic events, where dialogue is shown, and what state must persist if the player saves partway through.

### Questions the implementation specification must settle

- What triggers the opening/waking beat, and is it replayed on load?
- Where is the field in world/location data, and how does the Player reach it in the current scene architecture?
- Is Mira a single NPC encounter or a character who moves/travels with the Player?
- What exact interaction starts the quest?
- What player action constitutes meeting Mira and reaching Havenreach?
- Does the quest complete automatically on arrival, or does a named NPC need a distinct turn-in?
- What rewards, if any, are justified by this first quest?
- Which durable narrative facts are discovered during the quest?
- Does arrival change any actual world state, such as location access or NPC availability?
- How do accepted state, partial progress, completion, rewards, story facts, and world changes survive save/load independently?

Do not add generic prerequisites, branches, failure rules, or a StoryManager until this specification identifies a real requirement.

## State separation

For every quest beat, record these separately:

- **Quest state:** accepted/active/completed/failed and objective progress, owned by QuestManager.
- **Story facts:** durable narrative discoveries or milestones, to be assigned to one authoritative story-state owner if the quest needs them.
- **World state:** physical/access changes owned by the affected world system and serialized through that owner where needed.

Quest completion may trigger a story fact or world change, but it is not a replacement for either. The Quest Log presents quest state; it must not become the authoritative owner of story/world facts.

## Main quest and side-quest policy

- Main quests advance the protagonist's central journey or the player's understanding of the core mystery.
- Side quests primarily serve local characters, places, factions, or practical needs; some may echo larger themes without being required for the main plot.
- Quest IDs and objective IDs must be stable, descriptive, unique, and suitable for saves.
- Story design documents define intent; implementation-ready QuestData resources define the concrete objective/reward data consumed by the game.
