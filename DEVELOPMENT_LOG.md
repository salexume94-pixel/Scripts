# Development Log

## 2026-10-02

### Project Initialization

Started a fresh Godot 4.7 project named **Scripts** using the **Compatibility** renderer and Git version control.

The project is being rebuilt from scratch with a stronger separation of responsibilities than the previous Prototype project.

### Initial Structure

Created the following top-level directories:

- `combat/`
- `data/`
- `enemies/`
- `items/`
- `player/`
- `quests/`
- `scenes/`
- `systems/`
- `ui/`
- `world/`

### Architecture

Created `ARCHITECTURE.md` to establish project organization and separation-of-responsibility rules.

Core principle:

> A script should do one primary job.

Player systems will be separated instead of placing movement, stats, skills, inventory, equipment, and other unrelated functionality into one large player script.

### Systems Created

Created `systems/game_manager.gd`.

Created the initial Player scene:

`scenes/Player.tscn`

The Player root is a `CharacterBody2D`.

Created `player/player.gd` as the Player's core script.

Created `player/player_movement.gd` for movement logic.

Created the following focused Player systems:

- `player/player_stats.gd`
- `player/player_skills.gd`
- `player/player_inventory.gd`
- `player/player_equipment.gd`
- `player/player_progression.gd`

The Player scene currently contains:

- `Player`
- `PlayerMovement`
- `PlayerStats`
- `PlayerSkills`
- `PlayerInventory`
- `PlayerEquipment`
- `PlayerProgression`
- `PlayerSprite`
- `PlayerCollision`

The Player uses a temporary `CircleShape2D` collision shape with radius 16.0 for the current foundation.

The Player core script references the focused Player systems without owning their implementation.

### Successful Debug / Verification

Ran the Player scene directly to verify the modular Player foundation.

The first test reported three empty-script errors because the newly created skills, inventory, and equipment scripts contained no code.

Fixed those scripts by giving each a valid `extends Node` declaration.

Re-ran the Player scene successfully. The empty-script errors were resolved and the Player scene loaded without those errors.

This successful debug established that the current modular Player scene and its attached system scripts are structurally valid.

### World Scene Setup

Created the initial `World` scene at `scenes/World.tscn`.

Instanced `Player.tscn` as a child of the World scene.

A temporary `ColorRect` was used during initial movement testing so the Player could be seen. This experimental visual setup was later removed rather than becoming part of the permanent architecture.

### Successful World Movement Debug

Ran `World.tscn` directly with F6.

Verified successfully:

- Player is visible in the World.
- Player moves with the arrow keys.
- Player moves in all four directions.
- Player stops when movement input is released.
- Godot's debugger reports no errors.

This confirms the current Player instancing and movement system work correctly in the World test scene.

The temporary `ColorRect` used during this test is not part of the current permanent Player scene.

### Architecture Review and World Visual Reset

Compared the local experimental World and Player changes against the current GitHub `main` branch and `ARCHITECTURE.md`.

The temporary World background experiments using `ColorRect` and `Polygon2D` were discarded because they were not yet backed by a defined world-visual responsibility.

The temporary Player collision change from the original 16px CircleShape2D to a 130x130 RectangleShape2D was also discarded.

The project is returning to the known architectural baseline before adding a permanent world visual system.

The architecture continues to require clear ownership of responsibilities rather than adding functionality to existing nodes simply because it is convenient.

### Display and World Baseline

The intended in-game viewport is **1152x648 pixels**, using a **16:9 aspect ratio**.

This resolution will be used as the baseline when designing the initial Player presentation, visible world area, and camera behavior.

The viewport size should not be treated as the total world size. The world can extend beyond the visible 1152x648 area, with the camera determining which portion of the world is visible.

Player visual size and Player collision size should remain separate concerns. Collision should represent the physical space occupied by the Player rather than simply matching an arbitrary visual size.

### Project Structure Cleanup

Removed the unused `systems/save_system.gd` and its generated UID file because save/load functionality is not yet being implemented.

### Current Status

The project is in the foundation stage.

The modular Player structure has been created and successfully tested.

The Player is instanced into the World and its basic movement has been verified successfully with no debugger errors.

The experimental background and oversized Player collision changes have been reverted.

### Development Rule

After every successful debug or meaningful verification, update this development log with:

- What was tested.
- What worked.
- Files or systems changed.
- Remaining issues or unfinished work.

The development log should be updated as part of the corresponding Git checkpoint so the repository history reflects verified project state.

### Next Work

- Verify Player collision behavior in the World.
- Define the appropriate world visual/presentation responsibility before implementing a permanent background.
- Replace temporary Player debug visuals with the eventual visual system when appropriate.
- Continue implementing focused Player systems without expanding `player.gd` into a large multi-purpose script.
