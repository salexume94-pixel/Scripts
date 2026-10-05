extends CanvasLayer
## Displays the Player's current inventory for development testing.
##
## This is temporary debug UI. Its only job is to make inventory state
## visible while the item and inventory systems are being built.
##
## PlayerInventory remains responsible for storing item data. This script
## only reads that data and presents it on screen. It does not add, remove,
## or otherwise modify inventory contents.

@export var player_path: NodePath = NodePath("../Player")

@onready var inventory_label: Label = $InventoryLabel

var player: Node


func _ready() -> void:
	# Resolve the Player from the World scene so the debug display can read
	# the same inventory that the Chest rewards are modifying.
	player = get_node_or_null(player_path)

	if player == null:
		push_error(
			"DebugInventoryUI could not find Player at: %s"
			% player_path
		)
		return

	# Draw the initial inventory state immediately when the World starts.
	_update_inventory_display()


func _process(_delta: float) -> void:
	# The inventory currently has no change signal because it is still a
	# simple foundation system. Refreshing this small debug label each frame
	# keeps the display accurate without adding event infrastructure before
	# the real inventory UI is built.
	_update_inventory_display()


func _update_inventory_display() -> void:
	if player == null:
		return

	var inventory = player.get_node_or_null("PlayerInventory")

	if inventory == null:
		inventory_label.text = "Inventory: PlayerInventory not found"
		return

	if inventory.items.is_empty():
		inventory_label.text = "Inventory: Empty"
		return

	var lines: Array[String] = ["Inventory:"]

	# Inventory stores item IDs and quantities. Display both values so the
	# Chest reward can be verified without exposing internal data elsewhere.
	for item_id in inventory.items:
		lines.append("%s x%d" % [item_id, inventory.items[item_id]])

	inventory_label.text = "\n".join(lines)
