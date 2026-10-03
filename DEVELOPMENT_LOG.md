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

### World Presentation and Camera Structure

Implemented the initial World presentation skeleton according to the project architecture.

The World scene now contains:

- `WorldPresentation` for world presentation responsibilities.
- `WorldContent` as the future container for terrain, scenery, and world objects.
- `Camera2D` under `WorldPresentation`.
- `Player` as a separate World child instance.

Created `world/world_presentation.gd`.

This script is responsible for following the active Player with the World camera. Camera behavior remains outside `player.gd`, preserving the one-primary-job architecture.

The camera is positioned from the Player's world coordinates, allowing the World to extend beyond the visible viewport.

The project viewport baseline is now explicitly configured as **1152x648** in `project.godot`.

No permanent background, terrain, or temporary visual placeholder was added.

### Current Camera Test State

The World presentation and camera structure has been pushed to GitHub for local Godot testing.

The implementation has not yet been verified in the local Godot runtime after this GitHub update. The next verification should run `World.tscn` and confirm:

- The World scene loads without debugger errors.
- The Player movement still works.
- The camera follows the Player.
- The visible viewport uses the 1152x648 baseline.
- No temporary background or unrelated presentation system has been introduced.

### Project Structure Cleanup

Removed the unused `systems/save_system.gd` and its generated UID file because save/load functionality is not yet being implemented.

### Current Status

The project is in the foundation stage.

The modular Player structure has been created and successfully tested.

The Player is instanced into the World and its basic movement has been verified successfully with no debugger errors.

The experimental background and oversized Player collision changes have been reverted.

The World presentation skeleton and camera have now been implemented and pushed for local verification.

### Development Rule

After every successful debug or meaningful verification, update this development log with:

- What was tested.
- What worked.
- Files or systems changed.
- Remaining issues or unfinished work.

The development log should be updated as part of the corresponding Git checkpoint so the repository history reflects verified project state.

### Next Work

- Run and verify the new World presentation/camera structure locally at the 1152x648 baseline.
- Verify Player collision behavior in the World.
- Define the appropriate permanent world visual responsibility before implementing terrain or a background.
- Replace temporary Player debug visuals with the eventual visual system when appropriate.
- Continue implementing focused Player systems without expanding `player.gd` into a large multi-purpose script.

### World Visual Foundation

Added a temporary visual foundation for the World presentation so the camera can be tested against visible content.

The Player scene now gives `PlayerSprite` a simple diamond-shaped `Polygon2D` presentation. The visual remains separate from the existing `PlayerCollision` CircleShape2D, which remains at a 16px radius.

The World scene now uses `WorldContent` as the container for a large temporary world floor. The floor is a 3000x2000 visual area, substantially larger than the 1152x648 viewport, so camera movement can be observed while the Player moves away from the starting position.

No gameplay logic was added to the World visual layer. The floor exists only as presentation content, while camera following remains owned by `world/world_presentation.gd`.

### World Runtime Debug Checklist

This checklist is now the standard verification checklist for every new World/runtime test in this project. It should be used in project chats when reporting a new test so that important checks are not left to human memory, humanity's least reliable debugging subsystem.

Run `scenes/World.tscn` with F6 and verify:

1. **Scene load**
   - World scene opens and runs.
   - No debugger errors or script errors appear.

2. **Viewport**
   - Game window/view uses the configured **1152x648** viewport baseline.
   - The visible area behaves as a camera viewport rather than defining the total World size.

3. **Player presentation**
   - Player sprite is visible immediately.
   - Player visual remains separate from Player collision.

4. **Player movement**
   - Arrow-key movement works.
   - Player moves up, down, left, and right.
   - Player stops when input is released.
   - Diagonal movement does not move faster than cardinal movement.

5. **Camera**
   - Camera starts centered on the Player.
   - Camera follows the Player while moving.
   - Camera follows in all four directions.
   - Player remains in the expected camera-centered position while the World moves around the visible viewport.

6. **World presentation**
   - World floor/content is visible.
   - World content extends beyond the 1152x648 viewport.
   - Moving the Player exposes different parts of the larger World.

7. **Collision**
   - Player collision remains independent of the visual.
   - No unexpected collision behavior occurs during movement.

8. **Runtime stability**
   - No debugger errors appear during movement.
   - No warnings or errors indicate broken node paths, missing resources, or invalid scripts.

When reporting a test result, record each item as **PASS**, **FAIL**, or **NOT TESTED**, with a short note for anything other than PASS.

### Camera Follow Verification Failure

The first local runtime test after the World visual foundation confirmed that the Player sprite is visible.

The camera did **not** follow the Player during movement.

Other checklist items were not fully tested because the project did not previously provide the complete checklist above.

The camera implementation was updated in `world/world_presentation.gd` to:

- Explicitly enable the Camera2D.
- Explicitly call `make_current()` so this Camera2D becomes the active viewport camera.
- Update camera position during `_physics_process()` so it follows the Player after physics movement.
- Continue using global coordinates because Player and WorldPresentation are sibling nodes.

### Pending Runtime Verification

After pulling the camera fix, run the full **World Runtime Debug Checklist** above.

At minimum, verify:

- Scene loads without debugger errors.
- Player remains visible.
- Player movement works in all four directions.
- Camera starts centered on Player.
- Camera follows Player in all four directions.
- Larger World content remains visible as the camera moves.
- Player collision remains separate from the visual.
- No node-path, resource, or script errors appear.


### World Hierarchy Correction

The World scene hierarchy was corrected after runtime testing exposed two presentation failures: the Player was visible but the camera was not following it, and the World floor was no longer visible.

The World scene now keeps the major responsibilities as separate siblings:

- WorldContent contains the actual World visual/content nodes.
- WorldPresentation owns presentation behavior and the Camera2D.
- Player remains a separate gameplay actor instance.

WorldFloor was moved back under WorldContent instead of being nested inside WorldPresentation. This keeps World content separate from camera/presentation control and follows the project's one-primary-job architecture.

world/world_presentation.gd was also strengthened with explicit target validation and camera-current diagnostics. The camera is enabled, made current, checked with is_current(), positioned immediately on startup, and updated after Player physics movement.

### Pending Runtime Verification

The corrected World hierarchy and camera diagnostics are now committed to GitHub but require local Godot runtime verification.

Run scenes/World.tscn with F6 and use the full World Runtime Debug Checklist above. Record each item as PASS, FAIL, or NOT TESTED. The expected focus of this test is:

- World floor is visible again.
- Player remains visible.
- Camera starts centered on Player.
- Camera follows Player in all four directions.
- Debugger shows no node-path or camera errors.
- The World floor moves through the viewport as the Player moves.
