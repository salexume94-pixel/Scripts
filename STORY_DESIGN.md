# Story Design

## Purpose

This document defines the story direction and narrative design for the Scripts RPG.

The goal is to establish the game's story before implementing a full dialogue/story system. Story development should remain compatible with the existing quest architecture and should grow naturally out of gameplay rather than relying on constant cutscenes.

## Core Story Direction

The intended story style draws inspiration from several RPG traditions:

- Pokémon: clear progression, memorable characters, exploration, personal journeys, and a world that can be understood through play.
- Shin Megami Tensei / Persona: deeper themes, supernatural elements, moral questions, character relationships, and a larger conflict beneath the ordinary world.
- Baldur's Gate: character-driven storytelling, meaningful choices, consequences, factions, and world reactivity.
- Dark Souls / Elden Ring: mystery, environmental storytelling, fragmented history, ancient conflicts, hidden truths, and lore that is discovered rather than constantly explained.
- NieR:Automata: philosophical themes, layered revelations, ambiguity, emotional consequences, and a story whose meaning can change as the player learns more.
- Classic Final Fantasy: strong adventure structure, memorable party/world characters, escalating stakes, and a journey that expands beyond its initial premise.
- Chrono Trigger / Chrono Cross: mystery, interconnected events, unusual world concepts, personal stories connected to larger events, and revelations that recontextualize earlier experiences.
- Breath of Fire: traditional RPG adventure structure combined with mythology, character relationships, exploration, and a larger world mystery.

The project should not attempt to copy any one of these games. Their shared strengths should instead guide the game's own identity.

## Desired Narrative Structure

The story should begin relatively grounded and understandable.

The player should have:

1. A clear immediate reason to travel.
2. A reason to care about the people and places encountered.
3. Smaller problems that can be solved through normal gameplay.
4. Hints that something larger is happening.
5. Gradual revelations that expand the meaning of earlier events.
6. A larger conflict that eventually connects the regional stories.
7. A final confrontation whose meaning is established by the journey rather than appearing suddenly at the end.

The story should therefore expand in scope as the player progresses.

A useful progression is:

Personal → Regional → World → Existential

The player should not need to understand the entire world mystery at the beginning.

## Journey / Pilgrimage Framework

A journey or pilgrimage structure is currently the preferred framework for the main story.

The player travels between regions, towns, wilderness areas, ruins, and other locations.

Each region should ideally contain:

- A local problem.
- Characters with their own motivations.
- At least one meaningful story or quest thread.
- Lore about the world.
- A connection to the larger narrative.
- Gameplay consequences when appropriate.

Not every local story needs to be directly about the main conflict.

Some stories should simply make the world feel inhabited.

## Story Revelation Philosophy

Important information should be revealed progressively.

The game should use three layers of information:

### Layer 1: What the Player Knows

Facts that are immediately understandable.

Examples:

- A town has a problem.
- Someone has disappeared.
- A road is blocked.
- A dangerous creature is attacking travelers.
- An old ruin contains something important.

### Layer 2: What the Player Suspects

Evidence that suggests a larger explanation.

Examples:

- Similar events are occurring in distant regions.
- Different characters tell contradictory versions of history.
- Ancient ruins contain related symbols.
- Someone appears to know more than they admit.
- An apparently unrelated quest contains information connected to the main mystery.

### Layer 3: What Is Actually Happening

The deeper truth behind the events.

This should be revealed gradually and, where appropriate, should cause earlier events to be understood differently.

## Story and Gameplay Relationship

Story should interact with gameplay systems rather than existing as a separate layer.

The relationship should generally be:

Story Event → Quest / World Change → Player Action → Consequence → New Story Information

Examples:

- A story event starts a quest.
- Completing a quest changes an NPC's dialogue.
- A completed quest opens a previously inaccessible area.
- Entering that area reveals information about the larger story.
- That discovery activates another quest or story milestone.

The story should therefore create reasons for the player to explore and play the game.

## Quest Integration

The Quest Log is the foundation for tracking individual player objectives.

The story should not replace the Quest Manager.

### QuestManager

Responsible for:

- Quest state.
- Quest objectives.
- Quest completion.
- Quest failure, if failure states are needed.
- Quest rewards.
- Tracking active and completed quests.

### StoryManager

When implemented, should be responsible for:

- Major story progression.
- Story chapters or acts.
- Major story flags.
- Story milestones.
- Story-driven world-state changes.
- Determining which major narrative events have occurred.

The two systems should communicate without becoming dependent on each other's internal implementation.

Conceptually:

StoryManager ↔ QuestManager

A story milestone may start or advance a quest.

A quest completion may trigger a story milestone.

Neither system should become a collection of unrelated global Boolean variables.

## Story Flags

Story flags should represent meaningful narrative facts rather than every tiny interaction.

Good examples:

- met_mentor
- discovered_ancient_ruins
- learned_world_secret
- faction_alliance_established

Poor examples:

- talked_to_npc_17_once
- opened_chest_43
- walked_into_town

Small gameplay state should remain in the systems that own it.

Story state should represent information that can meaningfully change the narrative.

## Characters

Important characters should have motivations independent of the player.

A character should not exist solely to give the player quests.

For major NPCs, story development should eventually define:

- Identity.
- Motivation.
- Goal.
- Fear or conflict.
- Relationships.
- Secrets.
- Character arc.
- Relationship to the larger story.
- Possible changes based on player actions.

Characters should be capable of having their own problems even when the player is not present.

## Worldbuilding

Worldbuilding should support the story without requiring exposition dumps.

Useful sources of information include:

- NPC dialogue.
- Quests.
- Books and written records.
- Ruins.
- Architecture.
- Items.
- Enemy behavior.
- Factions.
- Environmental details.
- Regional traditions.
- Conflicting historical accounts.

The player should be able to form theories from these pieces.

## Mystery and Foreshadowing

Major revelations should have evidence planted before they occur.

A later revelation should ideally make the player think:

"The game showed me that earlier. I just didn't understand what it meant."

Rather than:

"That came completely out of nowhere."

Foreshadowing can be subtle. Not every mystery needs an immediate explanation.

## Player Role

The player's exact role in the story has not yet been finalized.

The following possibilities remain open:

- An ordinary traveler who becomes involved in larger events.
- A person with an unusual past.
- Someone connected to an important historical event.
- A chosen or destined figure.
- A character who appears ordinary but becomes important because of their actions.

No final decision should be made until the core theme and main conflict are developed further.

## Tone

The intended tone should be capable of moving between:

- Adventure.
- Mystery.
- Humor and ordinary character moments.
- Dark or unsettling discoveries.
- Emotional character moments.
- Philosophical questions.
- Large-scale fantasy conflict.

The game should not remain relentlessly bleak.

Likewise, darker material should have enough contrast that it remains meaningful.

## Main Conflict

The central antagonist, primary threat, and ultimate conflict are not yet defined.

These should be developed after establishing:

1. The game's central theme.
2. The world rules.
3. The player's initial motivation.
4. The nature of the journey.
5. The major question or mystery driving the story.

The final antagonist should emerge from the story's themes rather than being selected simply because the game needs a final boss.

## Current Story Development Order

1. Define the game's central theme.
2. Define the world premise.
3. Define the player's starting situation and motivation.
4. Define the main mystery or question.
5. Define the major regions and their narrative purposes.
6. Create the major characters and factions.
7. Outline the main story arc.
8. Connect story beats to the Quest Log.
9. Define major story flags and milestones.
10. Implement the required story/dialogue architecture.
11. Build actual quests and gated areas around the established story.
12. Develop the final act, boss, and ending(s).

## Important Design Rule

Do not start by writing hundreds of dialogue lines.

First establish:

Theme → World → Player → Conflict → Characters → Story Arc → Quests → Dialogue

This keeps the narrative from becoming disconnected scenes that happen to contain the same protagonist.

## Current Status

Story development is currently in the conceptual design phase.

The game has a general desired narrative style and several major influences, but it does not yet have a finalized plot.

The next task is to develop the game's central theme and world premise before implementing story systems or writing detailed quests.
