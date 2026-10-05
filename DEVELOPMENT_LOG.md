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
- `scenes/World.tscn` now contains a test Chest instance at `(160, -80)`.

The Chest implementation is **NOT YET RUNTIME VERIFIED**.

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

No item reward has been added yet because the item-definition and inventory systems have not been implemented.

### Next Work

- Runtime verify the first Chest implementation.
- Fix any Chest collision or interaction issues found during testing.
- Keep Chest behavior separate from item data and Player inventory.
- Add a proper interaction/input system only when its responsibility is clearly defined.
- Continue using comments in scripts to explain each script and major section.

### Building Collision Issue

Current World Building collision has been improved so the Player no longer visibly overlaps the Building in the previously reported areas.

A runtime issue remains **NOT YET FIXED**: when walking around the exterior of the Building, especially near the upper border/corners, the Player can be pushed away from the Building or become blocked from walking completely around it.

This is a known collision-geometry issue. The Building should eventually allow the Player to walk around its entire exterior without snagging, while preserving the visible clearance between the Player and Building.

Do not consider the Building collision fully runtime verified until this issue is resolved and retested.
