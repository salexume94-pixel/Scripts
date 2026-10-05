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


### Item Behavior, Use, and Equipment Foundation

Implemented the first functional item behavior layer while preserving the one-primary-job architecture.

Updated:
- items/item_data.gd
- items/test_items.gd
- player/player_stats.gd
- player/player_equipment.gd
- systems/game_state.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

Created:
- systems/item_use_system.gd

ItemData now defines behavior data for consumables, equipment, currency, materials, and a future key-item category. It also carries consumable HP/MP restoration values and equipment slot/stat bonus data.

Test item behavior:
- Test Potion restores 25 HP and consumes exactly one item when it has an effect.
- Test Sword is weapon equipment with +5 Attack.
- Test Gold is a currency item and is not treated as a consumable.

Ownership responsibilities remain separated:
- ItemData = item definition and behavior data.
- PlayerInventory = item quantities.
- PlayerEquipment = equipped item ownership and equipment changes.
- PlayerStats = resulting HP/MP and combat stat values.
- ItemUseSystem = applies consumable effects.
- InventoryCharacterHUD = displays state and requests actions.

Equipment is transferred from inventory to PlayerEquipment while equipped and returned to inventory when unequipped. GameState keeps the equipped-item snapshot through scene transitions, and a newly created Player reapplies stored equipment modifiers to PlayerStats.

The HUD now provides Use for consumables, Equip for equipment, current weapon display, weapon unequip, and immediate stat refresh after actions.

### Runtime Verification Required: Item Behavior

Run locally after pulling the latest commits:
- Project opens without parse errors.
- Open the Character/Inventory HUD.
- Reduce Player HP before using Test Potion.
- Select Test Potion and press Use.
- Confirm HP increases by 25, one potion is removed, and an empty stack disappears.
- Attempt to use a potion at full HP and confirm it is not consumed.
- Obtain Test Sword, select it, and press Equip.
- Confirm the sword leaves inventory, Weapon displays Test Sword, and Attack increases from 10 to 15.
- Press Unequip Weapon and confirm the sword returns to inventory and Attack returns to 10.
- Transition World -> Interior -> World and confirm equipped state and resulting stats persist.
- Confirm no Godot debugger errors occur.


### Test Item Access and HUD Interaction Fix

Updated the temporary item test path so the item systems can actually be exercised in runtime.

Updated:
- world/chest.gd
- world/Chest.tscn
- scenes/World.tscn
- scenes/Interior.tscn
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

Changes:
- Chest rewards are now selected by exported item ID instead of every chest always giving Test Potion.
- World now contains separate Test Potion and Test Sword chests.
- Interior now also contains separate Test Potion and Test Sword chests.
- The Character/Inventory HUD no longer rebuilds its inventory Buttons every frame. The previous per-frame rebuild could destroy a Button while it was being clicked, making the UI effectively non-interactive.
- The HUD Screen now accepts mouse input while its background remains mouse-transparent, allowing child Buttons to receive clicks.
- The HUD still locks Player movement while open.

Runtime verification required:
- Pull the commit and open the project.
- Open the HUD with I and click an inventory item.
- Confirm the item details and Use/Equip button respond to mouse clicks.
- Obtain Test Potion from a Potion Chest.
- Obtain Test Sword from a Sword Chest.
- Equip and unequip the sword and verify Attack changes 10 -> 15 -> 10.
- Verify the potion can be selected and its Use button is clickable.
- Verify the same test item access exists in World and Interior.
- Confirm no Godot debugger errors.


### Item Testing Control

Added a temporary development control to the Character HUD so the Test Potion can be verified before the full combat system exists.

Updated:
- player/player_stats.gd
- ui/inventory_character_hud.gd
- ui/InventoryCharacterHUD.tscn

The HUD now has a **Test Damage (-25 HP)** button that calls PlayerStats.take_damage(). This is explicitly a development test control and is not intended to become the final combat UI.

This allows the item loop to be tested now:
1. Obtain Test Potion from a Potion Chest.
2. Open the Character/Inventory HUD.
3. Press Test Damage (-25 HP).
4. Select Test Potion.
5. Press Use.
6. Confirm HP increases by 25 and one potion is consumed.


### Item Behavior Runtime Verification

The item behavior loop has now been runtime verified locally.

Verified:
- Test Potion can be picked up from a Potion Chest.
- Test Potion quantities stack correctly from `x1` to `x2`.
- Test Sword can be picked up when the inventory does not already contain one.
- A second Test Sword cannot be picked up when the existing sword has reached its `max_stack_size` of 1.
- Test Sword can be equipped from the Character/Inventory HUD.
- Test Sword can be unequipped and returned to the inventory.
- Equipment changes therefore correctly move the item between PlayerInventory and PlayerEquipment.

The verified item path is now:

`Chest -> ItemData -> PlayerInventory -> HUD -> PlayerEquipment -> PlayerStats`

### Debug System Separation

The temporary Test Damage control has been moved into the project's debug architecture.

Created:
- `systems/debug_system.gd`

Updated:
- `ui/inventory_character_hud.gd`
- `ui/InventoryCharacterHUD.tscn`

Architecture:
- `DebugSystem` owns development-only test actions.
- `InventoryCharacterHUD` presents the debug control and requests the action.
- `PlayerStats` remains responsible for applying the resulting damage.
- The Test Damage control is now grouped under a dedicated **DEBUG** section in the Character HUD.
- The debug control is only visible in Godot debug builds.

This keeps development/testing behavior out of the normal Character HUD logic while preserving the ability to damage the Player for potion testing.

Runtime verification required after this change:
- Pull the latest commits.
- Open the Character HUD in a debug build.
- Confirm the **DEBUG** section contains Test Damage.
- Press Test Damage and confirm HP decreases by 25.
- Use Test Potion and confirm HP is restored by 25 and one potion is consumed.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.
