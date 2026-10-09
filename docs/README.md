# Documentation Index

This folder contains canonical structured world and story references. Existing root-level documents remain in place; nothing has been moved or deleted.

## Technical and development documents

- `../ARCHITECTURE.md` — code ownership, folder responsibilities, and system boundaries.
- `../ROADMAP.md` — current priorities and planned implementation order.
- `../DEVELOPMENT_LOG.md` — chronological implementation and verification record. **Append new entries; do not replace earlier history.**
- `REPOSITORY_AUDIT.md` — structural audit and concrete findings for the reviewed repository commit.

## World and story documents

- `world/WORLD_BIBLE.md` — stable setting facts: geography, settlements, institutions, factions, NPC reference facts, and regional relationships.
- `story/STORY_BIBLE.md` — plot chronology, character arcs, revelations, and relationships between story beats and quests.
- Root `STORY_DIRECTION.md` and `STORY_DESIGN.md` remain reference material until their overlap and contradictions are reconciled. They are not silently replaced by the new documents.

## Source-of-truth rules

1. Technical behavior and ownership are defined by code and `ARCHITECTURE.md`.
2. `ROADMAP.md` defines planned work; it does not prove a feature exists or has passed runtime verification.
3. `DEVELOPMENT_LOG.md` records what was actually changed and tested. Add entries; do not rewrite history.
4. The World Bible owns stable world facts. The Story Bible owns plot progression and narrative interpretation.
5. Quest definitions own static quest content; QuestManager owns runtime quest state; world systems own physical/world state. Story flags must have one explicit authoritative owner before implementation.
6. When references conflict, record the conflict and its status. Do not silently blend incompatible versions of the setting or opening.
