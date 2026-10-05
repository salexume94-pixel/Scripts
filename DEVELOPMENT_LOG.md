### Chest Implementation and Runtime Verification

Implemented and runtime verified the reusable World Chest.

Created:
- `world/chest.gd`
- `world/Chest.tscn`

The Chest owns its physical presence, interaction range, open/closed state, and temporary visual state. It does not own item definitions or inventory storage.

The Chest uses the **E key** while the Player is within interaction range. A shared interaction input/UI system remains intentionally separate.

The Chest was runtime tested successfully:
- The Chest is visible.
- The Chest physically blocks the Player.
- The interaction range detects the Player.
- Pressing **E** in range opens the Chest.
- Pressing **E** outside the range does nothing.
- An opened Chest cannot be opened repeatedly.
- The Chest changes visual state when opened.
- Player movement, Building collision, Door transition, and World boundaries remain functional.
- Godot reported no script errors during the item reward test.

The Chest body collision was increased from `32x24` to `40x32` to prevent visible Player overlap.

### Building Collision

The World Building exterior collision has been corrected and runtime verified.

The previous collision layout used oversized wall rectangles that overlapped around the Building corners. This could push the Player away from the Building or prevent the Player from walking completely around it.

Updated:
- `world/building.gd`

The corrected collision layout:
- Keeps the Building's visible footprint unchanged.
- Uses clean wall geometry around the exterior.
- Prevents problematic collision overlap at the corners.
- Keeps the bottom wall split around the Door.
- Preserves the intended visual clearance between the Player and Building.
- Includes comments explaining the purpose and geometry of each collision section.

Runtime verification confirmed the Player can walk completely around the Building without the previous pushing or corner-blocking behavior.

### Item and Inventory Foundation

Implemented the first functional Item and Player Inventory foundation.

Created:
- `items/item_data.gd`
- `items/test_items.gd`

Updated:
- `player/player_inventory.gd`
- `world/chest.gd`

`ItemData` defines the shared data structure for an item, including:
- Stable item ID.
- Display name.
- Description.
- Category.
- Maximum stack size.

`TestItems` provides temporary Potion, Sword, and Gold definitions for development and testing.

`PlayerInventory` stores item quantities by item ID and supports:
- Adding items.
- Removing items.
- Checking item quantities.
- Checking whether the Player owns a requested quantity.
- Enforcing item stack limits.
- Providing a read-only inventory copy through `get_inventory()`.

The Chest now creates a test item reward and adds it to the Player's inventory when opened.

Godot initially reported parse errors because the inventory and Chest scripts depended on globally registered `class_name` types. Those dependencies were replaced with explicit script preloads so the item systems do not depend on Godot's global class-name cache being available at parse time.

### Inventory Runtime Verification

The Chest-to-inventory path has now been runtime verified.

The temporary debug inventory display was replaced by the reusable **Inventory/Character HUD**.

Created:
- `systems/game_state.gd`
- `ui/inventory_character_hud.gd`
- `ui/InventoryCharacterHUD.tscn`

Updated:
- `player/player_inventory.gd`
- `project.godot`
- `scenes/World.tscn`
- `scenes/Interior.tscn`

Removed:
- `world/debug_inventory_ui.gd`

The new HUD:
- Is a reusable CanvasLayer scene.
- Is available in both World and Building Interior.
- Opens and closes with the **I key**.
- Reads inventory through `PlayerInventory.get_inventory()`.
- Displays readable names for the current temporary test items.
- Does not own or modify inventory data.

### Inventory Runtime Persistence

`GameState` is now an autoload responsible for the runtime inventory snapshot.

The persistence path is now:

`Chest -> PlayerInventory -> GameState`

When a scene transition recreates the Player:
- The new PlayerInventory loads its inventory from GameState.
- Successful inventory additions/removals synchronize back to GameState.
- Inventory therefore has a runtime owner outside the Player scene.

This is **runtime persistence only**. It does not yet save inventory to disk. Save/load persistence will remain the responsibility of the future save system.

### Four Inventory/HUD Tasks

The four previously identified tasks have now been started:

1. **Build the real Inventory/Character screen HUD**
   - Initial reusable HUD implemented.

2. **Make the HUD available from the appropriate game UI context**
   - The same HUD scene is instantiated in both World and Interior instead of being tied only to World.

3. **Replace the temporary debug inventory display**
   - The temporary debug UI has been removed and replaced by the new HUD.

4. **Establish a persistence owner for inventory**
   - GameState now owns the runtime inventory snapshot so it survives Player recreation during scene transitions.

### Current Verification Status

The new HUD and GameState changes have **not yet been runtime tested locally** after the GitHub implementation.

The next required runtime test should verify:
- Project opens without parse errors.
- World loads normally.
- Pressing **I** opens the Character/Inventory screen.
- Inventory starts empty.
- Chest still awards `Test Potion`.
- HUD displays `Test Potion x1`.
- Entering the Building Interior keeps the inventory.
- Pressing **I** inside the Interior opens the same HUD.
- Returning to the World keeps the inventory.
- No Godot debugger errors occur.

### Current Project State

Verified before this change:
- World scene and camera.
- Player movement and collision.
- World boundaries.
- Building exterior collision.
- Building Door and Interior transition.
- Chest presence, collision, and E-key interaction.
- Item data foundation.
- Test item definitions.
- Functional Player inventory storage.
- Read-only inventory interface.
- Chest item rewards.
- Chest-to-inventory runtime verification.

Implemented but awaiting local runtime verification:
- Inventory/Character screen HUD.
- HUD availability in World and Interior.
- Replacement of temporary inventory debug UI.
- Runtime inventory persistence through GameState.

Still incomplete:
- Disk save/load persistence.
- Full character stats/equipment presentation.
- Equipment system integration.
- Shared interaction/input system.
- Item use/consumption behavior.
- Item detail/selection UI.
- Quests and other planned World systems.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Character Screen and Inventory UI Expansion

Implemented the next three Inventory/Character HUD tasks:

1. Character stats section
   - The HUD now reads Player level, HP, MP, Attack, Defense, Magic Attack, Magic Defense, and Speed directly from PlayerStats.
   - The HUD does not duplicate or own stat values.

2. Inventory slot UI
   - The previous text-only inventory list was replaced with selectable inventory slots.
   - Each owned item is represented by a button showing its readable name and quantity.
   - Inventory data remains owned by PlayerInventory.

3. Item selection and details
   - Selecting an inventory slot updates a details panel with the item's name, description, and quantity.
   - Selection is UI state only.
   - Item use, consumption, equipping, and other item behavior remain separate future systems.

Updated:
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

### Current Runtime Verification Required

The new Character/Inventory UI has not yet been runtime tested after this implementation.

Verify locally:
- Project opens without parse errors.
- World loads normally.
- Pressing I opens the expanded Character/Inventory screen.
- Character stats display the current PlayerStats values.
- Inventory starts empty.
- Chest still awards Test Potion.
- Test Potion x1 appears as a selectable inventory slot.
- Selecting the potion shows its name, description, and quantity.
- Entering the Interior preserves the inventory and HUD behavior.
- Returning to World preserves the inventory and HUD behavior.
- No Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section.


### Character HUD Movement Lock

Updated the Character/Inventory HUD so opening it disables Player movement while the screen is visible.

Updated:
- player/player_movement.gd
- ui/inventory_character_hud.gd

The movement system now exposes a small `set_movement_enabled()` control point. The HUD uses that control instead of directly manipulating CharacterBody2D movement. Existing velocity is cleared immediately when the HUD opens so the Player cannot continue sliding.

Runtime verification required:
- Open the Character/Inventory HUD with **I**.
- Confirm directional input no longer moves the Player.
- Confirm the Player stops immediately when the HUD opens.
- Close the HUD with **I** and confirm movement resumes normally.
- Confirm World/Interior transitions and inventory behavior remain unchanged.
