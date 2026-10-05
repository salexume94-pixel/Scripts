extends CanvasLayer
## Displays the Player's Character and Inventory screen.
##
## This script is responsible only for presenting Player information and
## handling the screen's open/closed state. It does not own stats, inventory,
## or item definitions.
##
## The screen is divided into two purposes:
## - Character information reads values from PlayerStats.
## - Inventory controls display the PlayerInventory contents and selection.
##
## The same reusable HUD is placed in World and Interior so the interface
## remains available after scene transitions.
##
## Pressing I toggles the screen while the game is running.

@onready var screen: Control = $Screen
@onready var level_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/LevelLabel
@onready var hp_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/HPLabel
@onready var mp_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MPLabel
@onready var attack_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/AttackLabel
@onready var defense_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/DefenseLabel
@onready var magic_attack_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MagicAttackLabel
@onready var magic_defense_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MagicDefenseLabel
@onready var speed_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/SpeedLabel
@onready var inventory_grid: GridContainer = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/InventoryGrid
@onready var item_name_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemName
@onready var item_description_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemDescription
@onready var item_quantity_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemQuantity

const TEST_ITEMS_SCRIPT = preload("res://items/test_items.gd")

# The selected item ID belongs to the UI only. Inventory ownership remains
# inside PlayerInventory and is never changed by this value.
var selected_item_id: String = ""


func _ready() -> void:
	# Start closed so the game world remains visible.
	screen.visible = false
	_refresh_screen()


func _unhandled_input(event: InputEvent) -> void:
	# I toggles the character screen because this HUD owns its visibility.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			screen.visible = not screen.visible

			if screen.visible:
				_refresh_screen()


func _process(_delta: float) -> void:
	# Refresh while visible so changes made by other systems are reflected
	# immediately without requiring the screen to be reopened.
	if screen.visible:
		_refresh_screen()


func _refresh_screen() -> void:
	# Locate the active Player in the current gameplay scene. Both World and
	# Interior use the same Player scene structure.
	var player := get_tree().current_scene.get_node_or_null("Player")

	if player == null:
		_show_missing_player()
		return

	_refresh_character_stats(player)
	_refresh_inventory(player)


func _refresh_character_stats(player: Node) -> void:
	# PlayerStats is the authoritative source for character values. The HUD
	# only reads these values and formats them for presentation.
	var stats: Node = player.get_node_or_null("PlayerStats")

	if stats == null:
		level_label.text = "Level: --"
		hp_label.text = "HP: --"
		mp_label.text = "MP: --"
		attack_label.text = "Attack: --"
		defense_label.text = "Defense: --"
		magic_attack_label.text = "Magic Attack: --"
		magic_defense_label.text = "Magic Defense: --"
		speed_label.text = "Speed: --"
		return

	level_label.text = "Level: %d" % stats.get("level")
	hp_label.text = "HP: %d / %d" % [stats.get("hp"), stats.get("max_hp")]
	mp_label.text = "MP: %d / %d" % [stats.get("mp"), stats.get("max_mp")]
	attack_label.text = "Attack: %d" % stats.get("attack")
	defense_label.text = "Defense: %d" % stats.get("defense")
	magic_attack_label.text = "Magic Attack: %d" % stats.get("magic_attack")
	magic_defense_label.text = "Magic Defense: %d" % stats.get("magic_defense")
	speed_label.text = "Speed: %d" % stats.get("speed")


func _refresh_inventory(player: Node) -> void:
	# PlayerInventory owns the item quantities. The HUD rebuilds only its
	# visual slots from that read-only inventory snapshot.
	var inventory = player.get_node_or_null("PlayerInventory")

	if inventory == null:
		_clear_inventory_ui()
		item_name_label.text = "Inventory unavailable"
		item_description_label.text = ""
		item_quantity_label.text = ""
		return

	var inventory_items: Dictionary = inventory.get_inventory()
	var item_definitions: Dictionary = TEST_ITEMS_SCRIPT.create_test_items()

	# If an item disappeared since the last refresh, clear the stale selection.
	if not inventory_items.has(selected_item_id):
		selected_item_id = ""

	_clear_inventory_slots()

	if inventory_items.is_empty():
		_add_empty_inventory_slot()
		_clear_item_details()
		return

	for item_id in inventory_items:
		_create_inventory_slot(item_id, inventory_items[item_id], item_definitions)

	# Keep the selected item's details visible after the grid is rebuilt.
	if selected_item_id != "":
		_show_item_details(selected_item_id, inventory_items, item_definitions)
	else:
		_clear_item_details()


func _create_inventory_slot(item_id: String, quantity: int, item_definitions: Dictionary) -> void:
	# Each inventory entry becomes a button so the Player can select an item.
	# The button is presentation only and does not modify inventory data.
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(110, 64)
	slot.text = _get_item_display_name(item_id, item_definitions) + "\nx%d" % quantity
	slot.tooltip_text = "Select " + _get_item_display_name(item_id, item_definitions)
	slot.pressed.connect(_on_inventory_slot_pressed.bind(item_id))
	inventory_grid.add_child(slot)


func _add_empty_inventory_slot() -> void:
	# Show an explicit empty state instead of leaving a blank inventory area.
	var slot := Label.new()
	slot.custom_minimum_size = Vector2(110, 64)
	slot.text = "Inventory is empty."
	slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_grid.add_child(slot)


func _on_inventory_slot_pressed(item_id: String) -> void:
	# Selection changes only which item the details panel displays.
	# Item use, equipping, and consumption remain separate future systems.
	selected_item_id = item_id

	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	var inventory = player.get_node_or_null("PlayerInventory")
	if inventory == null:
		return

	var inventory_items: Dictionary = inventory.get_inventory()
	var item_definitions: Dictionary = TEST_ITEMS_SCRIPT.create_test_items()
	_show_item_details(item_id, inventory_items, item_definitions)


func _show_item_details(item_id: String, inventory_items: Dictionary, item_definitions: Dictionary) -> void:
	# Translate the selected item ID into readable data for the details panel.
	if not inventory_items.has(item_id):
		_clear_item_details()
		return

	var display_name := _get_item_display_name(item_id, item_definitions)
	var description := "No description available."

	if item_definitions.has(item_id):
		description = item_definitions[item_id].get("description")

	item_name_label.text = display_name
	item_description_label.text = description
	item_quantity_label.text = "Quantity: %d" % inventory_items[item_id]


func _get_item_display_name(item_id: String, item_definitions: Dictionary) -> String:
	# Test item definitions currently provide readable names. Unknown IDs fall
	# back to the stable item ID so the UI remains usable as the catalog grows.
	if item_definitions.has(item_id):
		return item_definitions[item_id].get("display_name")

	return item_id


func _clear_inventory_slots() -> void:
	# Remove only the temporary slot controls created by the previous refresh.
	# Inventory data itself is never touched here.
	for child in inventory_grid.get_children():
		child.queue_free()


func _clear_item_details() -> void:
	# Reset the detail panel when nothing is selected.
	item_name_label.text = "Select an item"
	item_description_label.text = "Choose an inventory slot to view its details."
	item_quantity_label.text = ""


func _show_missing_player() -> void:
	# Keep the HUD readable if a gameplay scene is ever opened without Player.
	level_label.text = "Player not found."
	hp_label.text = ""
	mp_label.text = ""
	attack_label.text = ""
	defense_label.text = ""
	magic_attack_label.text = ""
	magic_defense_label.text = ""
	speed_label.text = ""
	_clear_inventory_ui()
	_clear_item_details()


func _clear_inventory_ui() -> void:
	# Clear the visual inventory without changing the actual inventory owner.
	_clear_inventory_slots()
