extends CanvasLayer
## Displays the Player's Character and Inventory screen.
##
## This script presents Player information and requests gameplay actions from
## the appropriate systems. It does not own stats, inventory, item definitions,
## or equipment.

@onready var screen: Control = $Screen
@onready var level_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/LevelLabel
@onready var hp_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/HPLabel
@onready var mp_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MPLabel
@onready var attack_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/AttackLabel
@onready var defense_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/DefenseLabel
@onready var magic_attack_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MagicAttackLabel
@onready var magic_defense_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MagicDefenseLabel
@onready var speed_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/SpeedLabel
@onready var equipment_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/EquipmentLabel
@onready var test_damage_button: Button = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/DebugPanel/DebugMargin/DebugVBox/TestDamageButton
@onready var unequip_button: Button = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/UnequipButton
@onready var inventory_grid: GridContainer = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/InventoryGrid
@onready var item_name_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemName
@onready var item_description_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemDescription
@onready var item_quantity_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemQuantity
@onready var item_action_button: Button = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemActionButton

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")
const TEST_ITEMS_SCRIPT = preload("res://items/test_items.gd")
const ITEM_USE_SYSTEM = preload("res://systems/item_use_system.gd")
const DEBUG_SYSTEM = preload("res://systems/debug_system.gd")

var selected_item_id: String = ""


func _ready() -> void:
	# Start closed so the world remains active until the Player opens the HUD.
	screen.visible = false
	unequip_button.pressed.connect(_on_unequip_button_pressed)
	test_damage_button.pressed.connect(_on_test_damage_button_pressed)
	test_damage_button.visible = OS.is_debug_build()
	item_action_button.pressed.connect(_on_item_action_button_pressed)
	_set_player_movement_enabled(true)
	_refresh_screen()


func _unhandled_input(event: InputEvent) -> void:
	# I toggles the Character/Inventory screen.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			screen.visible = not screen.visible
			_set_player_movement_enabled(not screen.visible)

			if screen.visible:
				_refresh_screen()



func _refresh_screen() -> void:
	# Locate the active Player in the current gameplay scene.
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		_show_missing_player()
		return

	_refresh_character_stats(player)
	_refresh_equipment(player)
	_refresh_inventory(player)


func _refresh_character_stats(player: Node) -> void:
	# PlayerStats is the authoritative source for resulting character values.
	var stats: Node = player.get_node_or_null("PlayerStats")
	if stats == null:
		return

	level_label.text = "Level: %d" % stats.get("level")
	hp_label.text = "HP: %d / %d" % [stats.get("hp"), stats.get("max_hp")]
	mp_label.text = "MP: %d / %d" % [stats.get("mp"), stats.get("max_mp")]
	attack_label.text = "Attack: %d" % stats.get("attack")
	defense_label.text = "Defense: %d" % stats.get("defense")
	magic_attack_label.text = "Magic Attack: %d" % stats.get("magic_attack")
	magic_defense_label.text = "Magic Defense: %d" % stats.get("magic_defense")
	speed_label.text = "Speed: %d" % stats.get("speed")


func _refresh_equipment(player: Node) -> void:
	# PlayerEquipment owns equipped item IDs. The HUD only formats their names.
	var equipment = player.get_node_or_null("PlayerEquipment")
	if equipment == null:
		equipment_label.text = "Weapon: --"
		unequip_button.visible = false
		return

	var equipped: Dictionary = equipment.get_equipped_items()
	if equipped.has("weapon"):
		var definitions: Dictionary = TEST_ITEMS_SCRIPT.create_test_items()
		var item_id: String = equipped["weapon"]
		var display_name := item_id
		if definitions.has(item_id):
			display_name = definitions[item_id].get("display_name")
		equipment_label.text = "Weapon: %s" % display_name
		unequip_button.visible = true
	else:
		equipment_label.text = "Weapon: None"
		unequip_button.visible = false


func _refresh_inventory(player: Node) -> void:
	# PlayerInventory owns quantities. The HUD only creates visual controls.
	var inventory = player.get_node_or_null("PlayerInventory")
	if inventory == null:
		_clear_inventory_ui()
		_clear_item_details()
		return

	var inventory_items: Dictionary = inventory.get_inventory()
	var item_definitions: Dictionary = TEST_ITEMS_SCRIPT.create_test_items()

	if not inventory_items.has(selected_item_id):
		selected_item_id = ""

	_clear_inventory_slots()

	if inventory_items.is_empty():
		_add_empty_inventory_slot()
		_clear_item_details()
		return

	for item_id in inventory_items:
		_create_inventory_slot(item_id, inventory_items[item_id], item_definitions)

	if selected_item_id != "":
		_show_item_details(selected_item_id, inventory_items, item_definitions)
	else:
		_clear_item_details()


func _create_inventory_slot(item_id: String, quantity: int, item_definitions: Dictionary) -> void:
	# Each inventory entry becomes a selectable button.
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(110, 64)
	slot.text = _get_item_display_name(item_id, item_definitions) + "\nx%d" % quantity
	slot.tooltip_text = "Select " + _get_item_display_name(item_id, item_definitions)
	slot.pressed.connect(_on_inventory_slot_pressed.bind(item_id))
	inventory_grid.add_child(slot)


func _add_empty_inventory_slot() -> void:
	# Show an explicit empty state when no items are owned.
	var slot := Label.new()
	slot.custom_minimum_size = Vector2(110, 64)
	slot.text = "Inventory is empty."
	slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_grid.add_child(slot)


func _on_inventory_slot_pressed(item_id: String) -> void:
	# Selection is UI state only. Gameplay actions use the separate action button.
	selected_item_id = item_id
	_refresh_screen()


func _show_item_details(item_id: String, inventory_items: Dictionary, item_definitions: Dictionary) -> void:
	# Display item data and expose the action appropriate to its item type.
	if not inventory_items.has(item_id):
		_clear_item_details()
		return

	var item: Resource = item_definitions.get(item_id)
	if item == null:
		item_name_label.text = item_id
		item_description_label.text = "No item definition available."
		item_quantity_label.text = "Quantity: %d" % inventory_items[item_id]
		item_action_button.visible = false
		return

	item_name_label.text = item.get("display_name")
	item_description_label.text = item.get("description")
	item_quantity_label.text = "Quantity: %d" % inventory_items[item_id]

	match item.get("item_type"):
		ITEM_DATA_SCRIPT.ItemType.CONSUMABLE:
			item_action_button.text = "Use"
			item_action_button.visible = true
		ITEM_DATA_SCRIPT.ItemType.EQUIPMENT:
			item_action_button.text = "Equip"
			item_action_button.visible = true
		_:
			item_action_button.visible = false


func _on_item_action_button_pressed() -> void:
	# The HUD requests an action but does not implement its gameplay effect.
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null or selected_item_id == "":
		return

	var definitions: Dictionary = TEST_ITEMS_SCRIPT.create_test_items()
	var item: Resource = definitions.get(selected_item_id)
	if item == null:
		return

	match item.get("item_type"):
		ITEM_DATA_SCRIPT.ItemType.CONSUMABLE:
			ITEM_USE_SYSTEM.use_item(player, item)
		ITEM_DATA_SCRIPT.ItemType.EQUIPMENT:
			var equipment = player.get_node_or_null("PlayerEquipment")
			if equipment != null:
				equipment.equip_item(item)

	_refresh_screen()


func _on_test_damage_button_pressed() -> void:
	# The HUD only requests the debug action. DebugSystem owns the test behavior
	# so normal Character/Inventory presentation remains separate from testing.
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	DEBUG_SYSTEM.test_damage(player, 25)
	_refresh_screen()


func _on_unequip_button_pressed() -> void:
	# PlayerEquipment owns unequipping. The HUD only requests it.
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	var equipment = player.get_node_or_null("PlayerEquipment")
	if equipment != null:
		equipment.unequip_slot("weapon")

	_refresh_screen()


func _get_item_display_name(item_id: String, item_definitions: Dictionary) -> String:
	# Unknown IDs fall back to their stable identifier.
	if item_definitions.has(item_id):
		return item_definitions[item_id].get("display_name")
	return item_id


func _clear_inventory_slots() -> void:
	# Remove only temporary visual controls. Inventory data is untouched.
	for child in inventory_grid.get_children():
		child.queue_free()


func _clear_item_details() -> void:
	# Reset the detail panel when nothing is selected.
	item_name_label.text = "Select an item"
	item_description_label.text = "Choose an inventory slot to view its details."
	item_quantity_label.text = ""
	item_action_button.visible = false


func _show_missing_player() -> void:
	# Keep the HUD readable if a gameplay scene ever lacks a Player.
	level_label.text = "Player not found."
	hp_label.text = ""
	mp_label.text = ""
	attack_label.text = ""
	defense_label.text = ""
	magic_attack_label.text = ""
	magic_defense_label.text = ""
	speed_label.text = ""
	equipment_label.text = "Weapon: --"
	unequip_button.visible = false
	_clear_inventory_ui()
	_clear_item_details()


func _clear_inventory_ui() -> void:
	# Clear only visual inventory controls.
	_clear_inventory_slots()


func _set_player_movement_enabled(enabled: bool) -> void:
	# Disable only Player movement rather than pausing the entire SceneTree.
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	var movement = player.get_node_or_null("PlayerMovement")
	if movement == null:
		return

	movement.set_movement_enabled(enabled)
