# Migration Plan

## Purpose

Migrate systems from the old repository into the new project in a controlled, testable order. Audit the old repository before migration begins. Understand existing behavior before code is moved or replaced.

## Migration Order and Verification Gates

| Order | Component | Verification gate |
|---:|---|---|
| 1 | Project settings and input | Renderer, viewport, input actions, and project configuration verified |
| 2 | Player movement, sprites, collisions | Movement, animation, collision, and interaction range tested |
| 3 | Map loader and transitions | Tiled maps load correctly; entrances, exits, layering, and collision work |
| 4 | Interaction and dialogue | NPC interaction, dialogue progression, and movement locking work |
| 5 | Save/load and audio | Save state restores correctly; music, settings, and persistence work |
| 6 | Combat, party, inventory, progression | Combat, elemental affinities, equipment, rewards, and leveling tested |
| 7 | Quest and story systems | Quest state, prerequisites, story flags, and save/load persistence verified |
| 8 | Menus, polish, and debug tools | Menus, UI behavior, error checks, and regression tests pass |

Do not begin a later stage until the current stage has passed its verification gate, unless a documented dependency requires an exception.

## Audit the Old Repository First

Maintain a separate inventory of existing systems. Assign each system one of these statuses:

- **Verified** — Passed an actual runtime test. Record the test performed and its result.
- **Needs testing** — Code exists, but behavior has not been confirmed in runtime.
- **Broken** — A known issue exists or a test failed. Record the issue and reproduction steps when available.
- **Obsolete** — Replaced by the new architecture or no longer needed. Record the reason and any known dependencies.

A system is not **Verified** merely because its script exists, imports successfully, or parses without errors. Verification requires the relevant runtime test to pass.

Keep the inventory separate from this plan so audit findings can be updated without changing the migration sequence. Update statuses when new evidence becomes available.

## Migration Rules

### Source Control and Change Safety

- **Git is the source of truth.** Pull the current repository state before starting work and verify the active branch and working tree.
- Work on the designated branch. Do not create additional branches unless explicitly authorized.
- Never overwrite or replace a working system without first auditing it and verifying the replacement.
- Preserve existing documentation and history. Append migration and development records rather than deleting or rewriting previous entries.
- Keep changes scoped to the component being migrated. Avoid unrelated refactors during a migration step.
- Record exceptions, blockers, and dependency-driven changes.

### Migration Procedure

1. Identify the legacy component and its dependencies.
2. Review its implementation, scenes, resources, configuration, and documented behavior.
3. Assign an audit status and record known issues.
4. Determine the correct destination in the new project.
5. Migrate only the required files and update references and dependencies.
6. Run static checks and resource-reference checks where applicable.
7. Launch the project in Godot and run the relevant runtime tests.
8. Confirm the current stage's verification gate passes before proceeding.
9. Update the system inventory, architecture documentation, and migration log.
10. Commit the verified changes to Git.

If a verification gate fails, stop progression for that component. Record the failure and fix or document it before continuing. Do not treat a failed or incomplete test as a pass.

### Folder Placement Rules

- **Scripts:** Put scripts in the appropriate `player/`, `systems/`, `world/`, or `ui/` subfolder.
- **Scenes:** Put scenes in `scenes/` or in the relevant feature folder when they belong alongside a specific system.
- **Maps:** Put maps in `world/maps/overworld/`, `world/maps/towns/`, or `world/maps/dungeons/`.
- **Reusable environmental objects:** Put them in `world/objects/`, organized by type.
- **Tilesets and sprites:** Put them in the appropriate `assets/` subfolders.
- **Audio:** Put audio in `assets/audio/`, organized by purpose when needed.
- **Resources and data:** Keep them beside the system that owns them, or use a dedicated `data/` folder when multiple systems share them.
- **Documentation:** Put architecture documents, system audits, test procedures, and migration records in `docs/`.

Do not create duplicate assets or parallel implementations without a documented reason. After moving files, update affected resource paths, scene references, preload/load paths, and documentation.

### Verification and Regression Requirements

- Test behavior in the running Godot project, not just in the editor or through static inspection.
- Verify relevant interactions between systems, not only each system in isolation.
- Check the debugger for new errors and warnings during testing.
- Run resource-reference and other available repository audits when applicable.
- Confirm save/load and persistence behavior for any migrated system that stores state.
- Re-run relevant regression tests after changes to shared systems or project settings.
- Record the exact test performed, its result, and any outstanding limitations.

## Completion Standard

A migration step is complete only when:

- The component is in the correct location.
- References and dependencies resolve correctly.
- The relevant runtime verification gate passes.
- No unexplained new debugger errors are introduced.
- Required documentation and the migration log are updated.
- The verified changes are committed to Git.

**Core rule:** Migrate one component at a time. Audit first, move deliberately, test in runtime, document the evidence, and only then proceed.

> “But let all things be done decently and in order.” — 1 Corinthians 14:40 (KJV)
