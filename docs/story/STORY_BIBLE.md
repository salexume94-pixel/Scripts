# Story Bible

## Purpose and ownership

This document is the canonical reference for **what happens in the story and when**: plot chronology, character arcs, mystery/revelation pacing, main-quest structure, side-quest relationships, and narrative consequences.

The World Bible (`docs/world/WORLD_BIBLE.md`) owns stable setting facts. Quest definitions under `quests/definitions/` own implementation-ready static quest data. QuestManager owns quest lifecycle/progress. Story flags and world-state changes remain separate from quest state and must have explicit runtime owners before implementation.

## Current working opening: The Stranger

**Status: initial implementation committed; local Godot runtime verification pending.**

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
**Implementation status:** initial implementation added to GitHub; local Godot runtime verification is pending. The locked objective IDs and triggers are specified in the addendum below.

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


---

## The Stranger: Opening Specification Locked (2026-10-09)

This addendum records decisions made after the initial outline above. It supersedes open questions in the earlier draft where they conflict; the earlier text is retained as design history.

### Opening flow

1. New Game initializes MAIN_001 (the_stranger) and enters the one-time waking_area scene.
2. The Wanderer wakes, says **“Where am I?”**, and receives control after the line is dismissed.
3. Exiting waking_area returns the Player to the overworld.
4. The Player explores the overworld and enters mira_encounter_area, where Mira's first encounter occurs.
5. Mira offers two choices:
   - **Journey with Mira:** Mira is added to the party and the Player is immediately transported to Havenreach.
   - **Travel alone:** Mira does not join; the Player returns to the overworld and travels to Havenreach normally.
6. Entering Havenreach completes the final travel objective. Both choices have the same MAIN_001 completion conditions.

### MAIN_001 objectives and triggers

- Stable quest ID: the_stranger
- Category: main story quest.
- complete_waking: completed when the opening line is dismissed and control is handed to the Player.
- meet_mira: completed when the Player makes either dialogue choice after Mira's first conversation. The chosen route is not a quest branch.
- reach_havenreach: completed when Havenreach is entered. QuestManager's existing automatic completion handles MAIN_001 after all objectives are complete.
- The quest has no reward for this opening unless a later design pass specifies one.

### Narrative and one-time behavior

- The waking line is brief. Do not add a long narrated cutscene or reveal the central mystery here.
- Mira's initial dialogue should explain the immediate practical reason to go to Havenreach, while leaving the larger mystery unresolved.
- Loading a save must restore the saved scene, position, quest progress, and party roster without restarting completed beats.
- Tutorial Town and Northbridge Village remain in the repository as examples/reference scenes but are not part of the active game route. Do not delete their files or register their entrances as playable overworld destinations.

### Runtime ownership

- QuestManager owns MAIN_001 lifecycle and objective progress.
- DialogueManager owns the reusable dialogue-choice lifecycle; DialogueBox only presents options and sends the selected stable choice ID back to the manager.
- SceneManager owns scene transitions and player placement.
- PartyManager owns the party roster and its save-data boundary. Adding Mira records roster membership; it does not by itself promise companion combat AI or formation behavior.
- SaveManager coordinates PartyManager serialization alongside existing GameState and QuestManager data.
- WorldLocationData and WorldMapWorld continue to own data-driven overworld entry points. The two one-time scenes are registered as hidden locations with entry regions only where appropriate; Havenreach is the visible settlement entry.
- Do not introduce a StoryManager or duplicate the route choice in quest state. The route affects party membership and the immediate destination, not the quest's completion criteria.


### Exact opening dialogue and choice text (2026-10-09)

- Waking line, speaker Wanderer: **“Where am I?”**
- Mira's first encounter line: **“You're a long way from the main road. Havenreach is the nearest settlement. I can travel with you, or you can go on your own.”**
- Choice 1: **“Journey with Mira”**. Stable choice ID: journey_with_mira. Add Mira to the party roster, mark meet_mira complete, and transition directly to Havenreach.
- Choice 2: **“Travel to Havenreach alone”**. Stable choice ID: travel_alone. Do not add Mira to the roster, mark meet_mira complete, and return the Player to the overworld outside the encounter entry trigger.
- The choice appears only until one option is selected. The overworld entry for mira_encounter_area is then closed using the existing meet_mira objective progress, so the first encounter cannot be repeated by re-entering the area.
