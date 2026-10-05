extends CanvasLayer
## Displays the Player's Inventory/Character screen.
##
## This script is responsible only for presenting inventory information and
## handling the screen's open/closed state. It does not own inventory data.
##
## The same reusable HUD can be placed in both World and Interior scenes so
## the interface remains available after scene transitions instead of being
## tied to one particular World scene.
##
## Pressing I toggles the screen while the game is running.

@onready var screen: Control = $Screen
@onready var inventory_label: Label = $Screen/Panel/Margin/VBox/InventoryLabel

const TEST_ITEMS_SCRIPT = preload("res://items/test_items.gd")


func _ready() -> void:
	# Start with the character screen closed so the game world remains visible.
	screen.visible = false
	_refresh_inventory_display()


func _unhandled_input(event: InputEvent) -> void:
	# Toggle the screen when the Player presses I. Key input is handled here
	# because this script owns the HUD's open/closed state.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			screen.visible = not screen.visible

			if screen.visible:
				_refresh_inventory_display()


func _process(_delta: float) -> void:
	# Refresh only while the screen is visible. This keeps the temporary
	# foundation responsive without doing unnecessary UI work while hidden.
	if screen.visible:
		_refresh_inventory_display()


func _refresh_inventory_display() -> void:
	# Find the active Player in whichever gameplay scene currently owns this
	# HUD. Both World and Interior use the same Player scene structure.
	var player := get_tree().current_scene.get_node_or_null("Player")

	if player == null:
		inventory_label.text = "Player not found."
		return

	var inventory = player.get_node_or_null("PlayerInventory")

	if inventory == null:
		inventory_label.text = "PlayerInventory not found."
		return

	var inventory_items: Dictionary = inventory.get_inventory()

	if inventory_items.is_empty():
		inventory_label.text = "Inventory is empty."
		return

	# Build a lookup of the temporary test item definitions so the HUD can
	# display readable item names while the real item database is unfinished.
	var item_definitions: Dictionary = TEST_ITEMS_SCRIPT.create_test_items()
	var lines: Array[String] = []

	for item_id in inventory_items:
		var display_name: String = item_id

		if item_definitions.has(item_id):
			display_name = item_definitions[item_id].get("display_name")

		lines.append("%s x%d" % [display_name, inventory_items[item_id]])

	inventory_label.text = "\n".join(lines)
