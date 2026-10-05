undefined

### First Chest Implementation

Started the next isolated World object: a reusable Chest.

Created:
- `world/chest.gd`
- `world/Chest.tscn`

The Chest is implemented as a World object rather than an item system. The Chest owns its physical presence, interaction range, open/closed state, and temporary visual state.

The Chest does not own item definitions or inventory behavior. Those responsibilities remain with the future `items/` and Player inventory systems.

The initial interaction test uses the **E key** while the Player is within the Chest's interaction range. A shared interaction input/UI system has intentionally not been added yet so the first Chest implementation remains isolated.

Updated:
- `scenes/World.tscn` now contains a test Chest instance at `(240, -80)`.

### Chest Runtime Verification Pending

The next local test should:
1. Pull the Chest implementation.
2. Run `scenes/World.tscn` with F6.
3. Confirm the Chest is visible.
4. Confirm the Chest physically blocks the Player.
5. Confirm approaching the Chest activates its interaction range.
6. Confirm pressing **E** while in range opens the Chest.
7. Confirm pressing **E** outside the interaction range does nothing.
8. Confirm an opened Chest cannot be opened repeatedly.
9. Confirm Player movement, Building collision, Door transition, and World boundaries remain functional.
10. Check for debugger, node-path, resource, and script errors.

The Chest interaction was runtime tested successfully: the Chest changes state when the Player is within interaction range and **E** is pressed.

A collision adjustment was also made:
- `world/Chest.tscn` increased the Chest body collision from `32x24` to `40x32` so the Player does not visibly overlap the Chest vertically.

No item reward has been added yet because the item-definition and inventory systems have not been implemented.

### Building Collision

The World Building exterior collision has now been corrected and runtime verified.

The previous collision layout used oversized wall rectangles that overlapped around the Building corners. This could push the Player away from the Building or prevent the Player from walking completely around it.

Updated:
- `world/building.gd`

The corrected collision layout:
- Keeps the Building's visible footprint unchanged.
- Uses clean wall geometry around the exterior.
- Prevents collision rectangles from creating problematic corner overlap.
- Keeps the bottom wall split around the Door.
- Preserves the intended visual clearance between the Player and Building.
- Includes comments explaining the purpose and geometry of each collision section.

Runtime verification confirmed the Player can now walk completely around the Building without the previous pushing or corner-blocking behavior.

### Current Project State

Verified systems:
- World scene and camera.
- Player movement and collision.
- World boundaries.
- Building exterior collision.
- Building Door and Interior transition.
- Chest presence, collision, and basic E-key interaction.

Still incomplete:
- Chest item rewards.
- Item definitions.
- Functional Player inventory.
- Shared interaction/input system.
- Equipment and item systems.
- Quests and other planned World systems.

### Next Project Goal

The next project goal is to build the **Item and Inventory foundation**.

Planned order:
1. Define the base item data structure in `items/`.
2. Create a small set of test items.
3. Implement functional Player inventory storage.
4. Connect Chest rewards to the Player inventory.
5. Runtime verify obtaining and storing items.
6. Keep item data, inventory behavior, and World Chest behavior separated according to the one-primary-job architecture rule.

Continue using comments in scripts to explain each script and major section.
