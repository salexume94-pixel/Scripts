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


### Item System Foundation: Resource Definitions

Replaced the temporary in-code item catalog with actual ItemData Resource definitions.

Created:
- `items/item_database.gd`
- `items/definitions/potion.tres`
- `items/definitions/iron_sword.tres`
- `items/definitions/wooden_shield.tres`
- `items/definitions/leather_helm.tres`
- `items/definitions/leather_armor.tres`
- `items/definitions/power_ring.tres`
- `items/definitions/gold.tres`

Updated:
- `items/item_data.gd`
- `world/chest.gd`
- `scenes/World.tscn`
- `scenes/Interior.tscn`

Removed:
- `items/test_items.gd`

ItemData now has typed equipment slots:
- Weapon
- Shield
- Head
- Body
- Accessory

ItemDatabase is now the authoritative mapping from stable item IDs to shared Resource definitions. Inventory, equipment, HUD, item use, and Chest systems no longer need to construct temporary item definitions in code.

### Inventory and Equipment Expansion

Updated:
- `player/player_equipment.gd`
- `ui/inventory_character_hud.gd`
- `ui/InventoryCharacterHUD.tscn`

Equipment now supports multiple slots with one item per slot:
- Weapon
- Shield
- Head
- Body
- Accessory

PlayerEquipment validates item type, item ID, and equipment slot before accepting an item. Existing equipment must successfully return to inventory before it can be replaced. Invalid or stale saved equipment is ignored during restoration.

The Character/Inventory HUD now:
- Displays every equipment slot.
- Provides an Unequip control for each occupied slot.
- Uses ItemDatabase for item definitions.
- Shows equipment comparison values such as:
  - `Attack: 10 -> 15 (+5)`
  - `Defense: 10 -> 10 (+0)`
- Calculates replacement comparisons against the currently equipped item in that slot instead of comparing only against base stats.

GameState continues to store equipment by stable item ID, and PlayerEquipment validates and reapplies those definitions when a new Player is created during World <-> Interior transitions.

### Shared Interaction System

Created:
- `systems/interaction_system.gd`

Updated:
- `player/Player.tscn`
- `world/chest.gd`
- `world/door.gd`

The Player now owns a shared InteractionSystem with an interaction detection area.

Interaction architecture:
- Player InteractionSystem detects nearby interactable Areas.
- The nearest valid interactable is selected.
- Pressing **E** calls that object's shared `interact()` method.
- Chest owns chest/reward behavior.
- Door owns scene-transition behavior.
- SceneManager still owns actual scene loading.

Chest-specific E-key input and Door automatic body-entered scene transitions have been removed from those individual scripts.

This establishes one shared interaction path for Chest, Door, and future interactables instead of giving every world object its own input handling.

### Runtime Verification Required

The Resource/item, equipment, and interaction changes require local Godot runtime verification.

Verify:
- Project opens without parse errors.
- World loads normally.
- Potion Chest awards Potion.
- Sword Chest awards Iron Sword.
- Shield/Armor chests award their correct equipment.
- Interior chests award Head/Ring equipment.
- Inventory displays the new item names and quantities.
- Sword equips to Weapon and changes Attack correctly.
- Shield equips to Shield and changes Defense correctly.
- Head, Body, and Accessory items occupy their own slots.
- Equipping another item in an occupied slot replaces the previous item correctly.
- Invalid equipment cannot be equipped.
- HUD comparison displays current -> projected stat changes.
- Unequipping each slot returns the item to inventory and removes its modifiers.
- World -> Interior -> World preserves inventory and equipment.
- Pressing **E** near a Chest opens it.
- Pressing **E** outside interaction range does nothing.
- Pressing **E** near the Door transitions to the configured scene.
- Door no longer transitions merely by walking into it.
- No Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Item Definition Ownership Tightening

Updated:
- `player/player_inventory.gd`

PlayerInventory now accepts only item IDs registered by ItemDatabase. This prevents arbitrary temporary Resource definitions from entering the persistent inventory and keeps the item-definition authority centralized in `items/item_database.gd`.



### Interaction Target Reliability Fix

Updated:
- `systems/interaction_system.gd`
- `world/chest.gd`

Fixed a bug where pressing **E** after previously entering a Door interaction range could use a stale cached interaction target and trigger a scene transition while the Player was interacting with a Chest.

The InteractionSystem now refreshes its target list from the Player's actual overlapping interaction Areas every time **E** is pressed. This makes the current physics overlap authoritative instead of relying on an older cached Area-entered state.

Chest interaction now also uses the Player reference supplied by the shared InteractionSystem instead of searching the current scene for a Player. This keeps Chest interaction isolated from scene-transition behavior.

Runtime verification required:
- Press **E** near each Chest and confirm only the Chest opens/rewards the item.
- Move away from the building Door and press **E** near a Chest; the Door must not trigger.
- Press **E** near the Door and confirm it transitions to the Interior.
- In the Interior, press **E** near the ExitDoor and confirm it returns to the World.
- Walking into either Door without pressing **E** must not transition.


### Interaction System Targeting Rewrite

The previous Area2D-overlap interaction implementation was still allowing incorrect Door selection in runtime. Interaction targeting has therefore been simplified and made explicit.

Updated:
- `systems/interaction_system.gd`
- `world/chest.gd`
- `world/door.gd`
- `world/Chest.tscn`
- `world/Door.tscn`

The shared InteractionSystem now searches the current scene for objects in the `interactable` group and selects the nearest object within an 80-pixel interaction distance. Chest and Door register themselves with that group when they enter the scene.

The old Chest and Door Area2D interaction trigger shapes are no longer used for selecting targets. This removes physics overlap state from the E-key decision and prevents an unrelated Door from being selected while interacting with a Chest.

Chest interaction receives the actual Player reference from InteractionSystem and can only grant its configured item. Door interaction remains the only path that calls SceneManager for scene transitions.

Runtime verification required:
- E near a Chest must grant the Chest item and keep the Player in the current scene.
- E near a Chest must never call SceneManager.
- E near the World Door must enter the Interior.
- E near the Interior ExitDoor must return to World.
- E away from all interactables must do nothing.
- Walking into a Door without E must not transition.


### Door Collision and HUD Layout Fix

Updated:
- `world/Door.tscn`
- `world/door.gd`
- `ui/InventoryCharacterHUD.tscn`

Door behavior was corrected so the Player cannot physically walk through a Door without interacting with it. The Door is now a solid `StaticBody2D` with a collision shape matching the doorway. Pressing **E** while within interaction range remains the intentional scene-transition action.

The Character/Inventory HUD was also resized and centered for the project's 1152x648 viewport. The overall panel is scaled down, internal margins and spacing were reduced, and inventory/detail minimum heights were tightened so the complete HUD fits on screen without extending beyond the viewport.

Runtime verification required:
- Walking into a Door without pressing **E** must be blocked.
- Pressing **E** near the World Door must enter the Interior.
- Pressing **E** near the Interior ExitDoor must return to World.
- The complete Character/Inventory HUD must be visible within the 1152x648 viewport.
- HUD controls must remain clickable after resizing.
- No Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Sword Unequip, HUD Centering, and Door Alignment Fix

Updated:
- player/player_equipment.gd
- ui/InventoryCharacterHUD.tscn
- world/Building.tscn

Reviewed:
- scenes/Interior.tscn

Changes:
- Hardened PlayerEquipment unequip ownership handling so an already-present inventory copy of the equipped item does not block the unequip transaction. The equipment slot and stat modifiers are only cleared after inventory ownership is confirmed.
- Added a center pivot to the scaled HUD panel so its 0.82 scale is applied around the panel center instead of the default top-left pivot. This keeps the complete HUD visually centered in the 1152x648 viewport while preserving the existing layout and controls.
- Moved the World Building Door center from y=72 to y=64 so the Door is centered on the Building's visible bottom edge at y=64.
- Confirmed the Interior ExitDoor is already centered at y=160, matching the InteriorFloor's visible bottom edge at y=160, so no coordinate change was required there.

Runtime verification required:
- Obtain and equip the Iron Sword.
- Press Unequip on the Weapon row and confirm the sword returns to inventory and Attack returns to its previous value.
- Confirm the HUD remains fully visible and is visually centered.
- Confirm HUD buttons remain clickable.
- Confirm the World Door is flush with the Building edge and still blocks walking without E.
- Confirm E near the World Door still enters the Interior.
- Confirm the Interior ExitDoor remains flush with the Interior floor edge and E still returns to World.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Player Stats Runtime Persistence Fix

Fixed Player stat and HP resets caused by World <-> Interior scene transitions.

Updated:
- `systems/game_state.gd`
- `player/player_stats.gd`

Changes:
- GameState now owns a runtime PlayerStats snapshot.
- PlayerStats restores level, experience, max HP, current HP, max MP, current MP, base Attack, base Defense, Magic Attack, Magic Defense, and Speed when a new Player instance is created.
- PlayerStats synchronizes current HP/MP changes back to GameState after damage and restoration.
- Equipment-derived Attack and Defense bonuses are excluded from the saved base-stat snapshot so PlayerEquipment can safely reapply equipped-item modifiers after the new Player is created.
- The first Player instance initializes GameState from its scene defaults, while later Player instances restore the existing runtime snapshot.

Runtime verification required:
- Reduce Player HP in the World.
- Enter the Building Interior and confirm current HP is unchanged.
- Leave the Interior and return to the World and confirm current HP is still unchanged.
- Equip the Iron Sword and confirm Attack remains correct after both scene transitions.
- Confirm MP, level, experience, and other PlayerStats values are preserved when changed.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Combat and Development Roadmap

The next development phase is the game's combat foundation, followed by the enemy system, progression, save/load persistence, and broader World/quest expansion.

### 1. Combat Foundation

Build the actual combat system next.

Planned combat foundation:
- Combat encounter/state system.
- Player attack.
- Enemy HP.
- Damage calculation.
- Player defense.
- Defeat/death handling.
- Return from battle to the World.
- Combat UI.

The intended core gameplay loop is:

`Explore -> encounter enemy -> fight -> win/lose -> return to World`

### 2. Enemy Foundation

After the combat foundation is established, build the enemy system that combat uses.

Planned enemy foundation:
- `EnemyData`.
- Enemy stats.
- Enemy definitions.
- Enemy instances.
- Basic enemy behavior.
- XP/reward data.

### 3. Progression

Once combat can produce rewards, implement progression systems.

Planned progression:
- XP.
- Leveling.
- Stat growth.
- Gold.
- Loot.

### 4. Save/Load

After the runtime GameState and gameplay systems are stable, implement persistent save/load.

Planned save/load data:
- Save GameState to disk.
- Load GameState from disk.
- Player position and current scene.
- Inventory.
- Equipment.
- Player stats.
- World/chest state.

The existing GameState remains runtime persistence only until this phase. Disk persistence should be implemented as a separate save/load responsibility rather than turning GameState into a file-management system.

### 5. Quests and World Expansion

After the core combat, enemy, progression, and save systems are established, expand the World and quest structure.

Planned World expansion:
- Quest system.
- Quest log.
- NPCs.
- Gated areas.
- More buildings.
- More interactables.

### Development Priority

The current implementation priority is:

`Combat Foundation -> Enemy Foundation -> Progression -> Save/Load -> Quests and World Expansion`

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.


### Combat Foundation: Encounter and State System

Implemented Step 1 of the Combat Foundation: the runtime combat encounter/state layer.

Created:
- `combat/combat_state.gd`
- `combat/battle.gd`
- `scenes/Battle.tscn`
- `systems/combat_manager.gd`

Updated:
- `systems/scene_manager.gd`
- `project.godot`

Changes:
- Added `CombatState` as a data-only Resource representing the active encounter.
- Added `CombatManager` as an autoload responsible for starting, tracking, and ending combat encounters.
- CombatManager records the originating scene and Player position before entering Battle.
- Added a placeholder Battle scene that reads the active enemy ID from CombatManager.
- SceneManager now permits destination scenes without a Player node, which allows the separate Battle scene to exist without duplicating the Player.
- CombatManager uses SceneManager for scene loading instead of owning scene-transition implementation.

Current combat flow foundation:

`World -> CombatManager.start_encounter(enemy_id) -> Battle -> CombatManager.end_combat() -> World`

Not yet implemented:
- Player attack.
- Enemy HP and authoritative enemy stats.
- Damage calculation.
- Player defense.
- Enemy attacks.
- Victory/defeat resolution.
- Final combat UI.

Those systems remain separate steps so the combat foundation does not prematurely take ownership of Enemy or Player systems.

Continue using comments in scripts to explain each script and major section. Each script should clearly describe its primary responsibility and the purpose of its major sections.

Runtime verification required:
- Pull the latest commit.
- Confirm the project opens without parse errors.
- Confirm the Battle scene opens without errors.
- Verify a future encounter call can enter Battle and preserve the originating scene/Player position for return.
- Confirm no Godot debugger errors occur.


### Combat Foundation: Player Attack

Implemented Step 2 of the Combat Foundation: the Player Attack action.

Updated:
- `combat/combat_state.gd`
- `systems/combat_manager.gd`
- `combat/battle.gd`
- `scenes/Battle.tscn`

Changes:
- Added a Player Attack command to CombatManager.
- Player Attack reads the authoritative Player Attack stat from PlayerStats/GameState.
- CombatState records the most recent Player Attack value.
- Battle UI now provides an **Attack** button.
- Battle presentation reports the Attack value through a CombatManager signal.
- CombatManager remains responsible for combat state/action logic while Battle remains responsible for presentation.
- Enemy HP and damage application are intentionally not implemented yet. Those belong to the following Combat Foundation steps.

Current combat flow:

`Battle -> Attack button -> CombatManager.player_attack() -> CombatState.last_player_attack -> Battle UI`

Runtime verification required:
- Pull the latest commit.
- Enter the Battle scene through the existing combat flow when an encounter trigger is added.
- Confirm the Attack button is visible and clickable.
- Confirm pressing Attack displays the Player's current Attack value.
- Confirm no HP is changed yet.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section.


### Combat Foundation: Enemy HP State

Implemented Step 3 of the Combat Foundation: enemy HP state.

Updated:
- combat/combat_state.gd
- systems/combat_manager.gd
- combat/battle.gd
- scenes/Battle.tscn

Changes:
- Added enemy maximum HP and current HP to CombatState.
- New development encounters initialize a temporary enemy at 50 / 50 HP.
- CombatManager exposes current and maximum enemy HP to presentation.
- Battle UI displays enemy HP.
- Player Attack still does not reduce HP. Damage calculation and HP modification remain the next step.
- The temporary 50 HP value will be replaced by authoritative EnemyData during the Enemy Foundation.

Runtime verification required:
- Pull the latest commit.
- Confirm the project opens without parse errors.
- Confirm an active Battle displays Enemy HP: 50 / 50.
- Confirm Attack does not change enemy HP yet.
- Confirm no Godot debugger errors occur.

Continue using comments in scripts to explain each script and major section.
