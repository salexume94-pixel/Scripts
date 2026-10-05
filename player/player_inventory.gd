extends Node
## Stores the Player's item inventory.
##
## This script is responsible only for keeping track of which items the
## Player owns and how many copies of each item are currently stored.
##
## ItemData defines what an item is. The Chest will eventually decide when
## an item is awarded. This script only handles the Player's inventory data.
##
## A Dictionary is used for the initial inventory foundation. Each key is an
## item_id and each value is the quantity currently owned.

var items: Dictionary = {}


func add_item(item: ItemData, quantity: int = 1) -> bool:
	# Reject invalid item references and non-positive quantities so the
	# inventory cannot accidentally create meaningless entries.
	if item == null or quantity <= 0:
		return false

	# Read the current quantity, defaulting to zero when this is the first
	# copy of the item being added.
	var current_quantity: int = items.get(item.item_id, 0)
	var new_quantity := current_quantity + quantity

	# Prevent a stack from exceeding the limit defined by the ItemData.
	if new_quantity > item.max_stack_size:
		return false

	items[item.item_id] = new_quantity
	return true


func remove_item(item: ItemData, quantity: int = 1) -> bool:
	# An item cannot be removed unless both the item and requested quantity
	# are valid.
	if item == null or quantity <= 0:
		return false

	var current_quantity: int = items.get(item.item_id, 0)

	# Do not allow the inventory to remove more copies than the Player owns.
	if current_quantity < quantity:
		return false

	var new_quantity := current_quantity - quantity

	# Remove empty entries entirely so the inventory stays clean.
	if new_quantity == 0:
		items.erase(item.item_id)
	else:
		items[item.item_id] = new_quantity

	return true


func get_item_quantity(item: ItemData) -> int:
	# Return zero when the Player does not currently own this item.
	if item == null:
		return 0

	return items.get(item.item_id, 0)


func has_item(item: ItemData, quantity: int = 1) -> bool:
	# This provides a simple query for other systems without exposing how
	# the inventory stores its internal Dictionary.
	if item == null or quantity <= 0:
		return false

	return get_item_quantity(item) >= quantity
