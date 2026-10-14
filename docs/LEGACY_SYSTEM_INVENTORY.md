# Legacy System Inventory

**Purpose:** Record the state of systems in the legacy `salexume94-pixel/Scripts` repository before any systems are copied into the new project.

**Legacy repository:** https://github.com/salexume94-pixel/Scripts  
**Branch reviewed:** `main`  
**Related structural audit:** [`docs/REPOSITORY_AUDIT.md`](REPOSITORY_AUDIT.md)  
**Migration sequence:** [`docs/MIGRATION_PLAN.md`](MIGRATION_PLAN.md)

> This is a migration-planning inventory, not a claim that every listed system has been freshly tested against the current commit. Statuses distinguish previously reported runtime tests from code review and unresolved questions. Re-test systems in the current legacy build before migrating them.

## Status Definitions

- **Verified** — Passed an actual runtime test. The evidence and scope should be recorded; re-test against the current commit before migration.
- **Needs testing** — Code or resources exist, but the required behavior has not been confirmed for the current migration baseline.
- **Broken** — A known failure or unresolved defect is recorded. Do not migrate as production-ready until the issue is reproduced and resolved or explicitly accepted.
- **Obsolete** — Replaced, intentionally removed from normal use, or no longer needed in the new architecture. Keep only if a documented dependency or testing purpose requires it.

## System Inventory

| System / component | Status | Evidence and known limitations | Migration guidance |
|---|---|---|---|
| Project settings, renderer, viewport, input actions | Needs testing | `project.godot` sets Godot 4.7 / GL Compatibility and 1152×648 window overrides. Runtime configuration and input map have not been re-verified as a single migration gate in this inventory. | Verify project settings and every required input action first. Preserve the new project's settings unless intentionally adopting a legacy value. |
| Main menu (New Game / Load / Quit) | Verified | Previously reported runtime testing passed. | Re-test all three actions in the current commit and verify scene transitions. |
| Options menu and settings persistence | Verified | Previously reported runtime testing passed; brightness/audio settings were reported to persist independently of save/load. | Re-test settings persistence, audio volume, brightness, and exit behavior. |
| Player movement and animation | Needs testing | Player scripts and scenes exist; migration-baseline runtime behavior has not been freshly recorded here. | Test movement, animation states, boundaries, collision, and interaction range. |
| Player sprites and collision | Needs testing | Player and collision resources exist. Exact current sprite dimensions, collision shape, and animation coverage need confirmation against the intended new art. | Treat art and collision as separate checks; do not assume old sprite sizing fits new assets. |
| Map loader and Tiled integration | Needs testing | Tiled maps and a custom loader exist. Previous work required collision/layering fixes. Static resource checks alone do not prove maps render or collide correctly. | Test each representative map, tile layers, object layers, walkable surfaces, solid objects, and player draw order. |
| Map transitions, doors, entrances, exits | Verified | Previously reported tests passed for town entry/exit and an interior entrance/exit; current exit alignment and every map route must still be checked. | Re-test each transition against the destination map and spawn coordinates. |
| Havenreach map registration and world state | Broken / re-test required | A previous runtime report identified a missing MapManager entry for `world_id: havenreach`. The current status after subsequent edits is not confirmed by this inventory. | Resolve or reproduce the issue before migration. Confirm Havenreach loads through normal travel and saved state. |
| NPC and world interactions | Verified | The dedicated moving-NPC test area reportedly passed NPC avoidance, collision, detection, and town entry/exit tests. | Re-run the dedicated test scene and then test real NPCs, doors, chests, and map boundaries. |
| Dialogue and movement locking | Verified | Previously reported runtime testing passed for dialogue preventing player movement and preventing menu overlap. | Re-test dialogue progression, cancel/close behavior, and movement unlock on every exit path. |
| Save/load manager and progression persistence | Verified | Developer-reported runtime tests passed for save/load through the church NPC; equipped item persistence was also reported passing. | Re-test fresh save, overwrite, load, invalid/missing save behavior, and scene restoration. |
| Audio and music transitions | Verified | Previously reported testing passed for battle, overworld, and tutorial-town music tracks; fades were reported working. | Re-test scene-specific music, fades, volume settings, and missing-audio fallback. |
| Combat core and Press Turn flow | Verified | Previously reported tests covered two player Press Turns, turn consumption, and combat logging. | Re-test turn counts, turn order, victory, defeat, escape, and return to world. |
| Elemental affinities and hit/critical rules | Verified | Previously reported tests covered Physical/Fire/Water/Earth/Air/Light/Dark affinities and weak/resist/null/drain/repel handling; critical and miss rules were also tested. | Re-test each affinity outcome and ensure enemy definitions use intended values. |
| Enemy AI profiles | Needs testing | Balanced, Aggressive, and Defensive profiles exist. Test-named slime resources were removed from normal enemy lookup but retained for dedicated debug use, according to the structural audit. | Verify normal enemy catalog excludes test definitions and run repeatable AI behavior tests. |
| Party management | Needs testing | PartyManager is registered as an autoload. Current runtime coverage for party membership, active slots, and transitions needs a recorded test. | Test add/remove, party limits, save/load, combat handoff, and Mira joining behavior. |
| Inventory and equipment | Verified | Previously reported equipment persistence test passed. Full inventory edge cases have not been recorded here. | Re-test acquire/use/equip/unequip, slot restrictions, stat recalculation, and save/load. |
| XP, gold, rewards, and leveling | Verified | Previously reported runtime tests passed for XP/gold rewards, level-up, and stat increases. | Re-test reward application once per encounter, level thresholds, overflow, and persistence. |
| Quest definitions, database, and runtime state | Needs testing | Structural audit confirms QuestData, QuestDatabase, QuestManager, objective tracking, state transitions, and a Quest Log exist. Audit describes the implementation as a basic one-objective foundation with automatic completion when all objectives finish. | Preserve the existing system as the starting point, then test against current code. Do not assume advanced quest features exist. |
| Quest save/load serialization | Verified | The structural audit records developer confirmation that quest save/load persistence works. Future story-specific quest behaviors remain unverified. | Re-test persistence in the current commit and through the actual disk SaveManager flow. |
| Quest prerequisites, distinct turn-in, branching conditions | Needs testing | Structural audit identifies these as unsupported or incomplete in the current quest foundation. | Add only the fields and behavior required by designed quests; test each prerequisite and turn-in path. |
| Story flags and world/story consequences | Broken / incomplete | Architecture distinguishes quest state, story flags, and world state, but the audit found no authoritative implemented story-flag owner. | Define ownership and API before implementation. Do not use QuestManager as a substitute or create a StoryManager without a defined interface. |
| Opening story and Mira encounter | Broken / design conflict | `STORY_DIRECTION.md` describes an MMO login/tutorial-town opening, while the newer working direction, *The Stranger*, starts with the protagonist waking in a field, meeting Mira, and reaching Havenreach. These conflict. | Treat *The Stranger* / Havenreach direction as the intended design only after the project owner confirms it as the source of truth. Verify Mira choice, party addition, and destination behavior. |
| Menus, HUD, and Quest Log | Needs testing | Main/options menu behavior has been reported passing; Quest Log is present in World and Interior scenes according to the development log. Full UI regression coverage is not documented here. | Test focus, toggles, visibility across scenes, dialogue overlap, and controller/keyboard behavior as applicable. |
| Debugging area / moving enemy, NPC, and ally tests | Verified | Previously reported runtime checklist passed enemy contact/battle, run protection, enemy pause after escape, enemy removal on defeat, NPC avoidance, ally detection, collision, and town boundaries. | Preserve as a regression test environment; rerun after movement, collision, or AI changes. |
| `player/player_skills.gd` placeholder | Obsolete (placeholder only) | Structural audit says this is a one-line `extends Node` placeholder with no skill behavior and was detached from `player/Player.tscn`. The file was retained as a future option. | Do not migrate as a functioning skill system. Reuse the path only if a real Player-owned skill implementation is designed. |
| Test-only slime AI resource definitions | Obsolete from normal lookup | Structural audit records that test-named slime resources were removed from normal enemy lookup while the resource files remain for future debug testing. | Do not register these as production enemies; retain only for dedicated tests if still useful. |
| Documentation and architecture | Needs testing | `ARCHITECTURE.md`, `STORY_DIRECTION.md`, `DEVELOPMENT_LOG.md`, and `docs/REPOSITORY_AUDIT.md` exist. The audit corrected earlier architecture inaccuracies, but story direction still conflicts. | Review documentation against the current code and approved new design. Preserve history; append updates rather than rewriting prior records. |

## Audit Findings to Resolve Before Migration

1. **Confirm the actual migration baseline.** Pull `main`, record the commit SHA, run the project in Godot, and repeat the tests for every system marked Verified.
2. **Resolve Havenreach map registration.** Reproduce or close the previously reported missing-map error and verify normal travel.
3. **Choose the authoritative opening.** Resolve the conflict between the older tutorial-town opening and *The Stranger* / Havenreach.
4. **Define story-flag ownership.** Keep quest state, story flags, and world state separate; document interfaces before adding code.
5. **Scope quest features from actual content needs.** Prerequisites, branching, turn-in, failure/missability, and world consequences should be implemented only with clear requirements and tests.
6. **Do not treat static audits as runtime passes.** Resource-reference checks are useful, but do not prove import, parser, gameplay, rendering, or persistence behavior.
7. **Keep test assets out of production catalogs.** Dedicated debug definitions must not appear as ordinary game content unless intentionally promoted.

## Required Record for Each New Audit Result

Append or update a row with:

- **System and component**
- **Status**
- **Commit SHA tested**
- **Test procedure**
- **Observed result**
- **Known issues / limitations**
- **Migration decision and dependencies**

Update this inventory when new evidence changes a status. Preserve previous audit history in the development or migration log.

> “But let all things be done decently and in order.” — 1 Corinthians 14:40 (KJV)
