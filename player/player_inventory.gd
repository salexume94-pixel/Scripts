extends Node
## Stores the Player's item inventory.
##
## This script is responsible only for keeping track of which items the
## Player owns and how many copies of each item are currently stored.
##
## ItemData defines what an item is. The Chest decides when an item is
## awarded. This script only handles the Player's inventory data.
##
## ItemData is preloaded explicitly here instead of relying on Godot's
## global class-name cache. This keeps the dependency available immediately
## after pulling the project into a fresh local editor session.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")

# Each key is an item_id and each value is the quantity currently owned.
# Other systems should use the read-only access functions below instead of
# modifying this Dictionary directly.
var items: Dictionary = {}


func add_item(item: Resource, quantity: int = 1) -> bool:
	# Reject invalid item references and non-positive quantities so the
	# inventory cannot accidentally create meaningless entries.
	if item == null or not item.get_script() == ITEM_DATA_SCRIPT or quantity <= 0:
		return false

	var item_id: String = item.get("item_id")
	var max_stack_size: int = item.get("max_stack_size")

	# Read the current quantity, defaulting to zero when this is the first
	# copy of the item being added.
	var current_quantity: int = items.get(item_id, 0)
	var new_quantity := current_quantity + quantity

	# Prevent a stack from exceeding the limit defined by the ItemData.
	if new_quantity > max_stack_size:
		return false

	items[item_id] = new_quantity
	return true


func remove_item(item: Resource, quantity: int = 1) -> bool:
	# An item cannot be removed unless both the item and requested quantity
	# are valid.
	if item == null or not item.get_script() == ITEM_DATA_SCRIPT or quantity <= 0:
		return false

	var item_id: String = item.get("item_id")
	var current_quantity: int = items.get(item_id, 0)

	# Do not allow the inventory to remove more copies than the Player owns.
	if current_quantity < quantity:
		return false

	var new_quantity := current_quantity - quantity

	# Remove empty entries entirely so the inventory stays clean.
	if new_quantity == 0:
		items.erase(item_id)
	else:
		items[item_id] = new_quantity

	return true


func get_inventory() -> Dictionary:
	# Return a copy instead of the internal Dictionary so UI and other systems
	# can inspect the inventory without being able to modify its stored state.
	#
	# This creates a simple boundary between inventory ownership and systems
	# that only need to display or inspect inventory contents.
	return items.duplicate()


func get_item_quantity(item: Resource) -> int:
	# Return zero when the Player does not currently own this item.
	if item == null or not item.get_script() == ITEM_DATA_SCRIPT:
		return 0

	var item_id: String = item.get("item_id")
	return items.get(item_id, 0)


func has_item(item: Resource, quantity: int = 1) -> bool:
	# This provides a simple query for other systems without exposing how
	# the inventory stores its internal Dictionary.
	if item == null or quantity <= 0:
		return false

	return get_item_quantity(item) >= quantity
