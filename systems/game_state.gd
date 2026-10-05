extends Node
## Owns persistent runtime game state that must survive scene changes.
##
## This script is intentionally separate from PlayerInventory. PlayerInventory
## is responsible for inventory behavior, while GameState owns the runtime
## copy of that data so it survives when a Player node is recreated by a
## scene transition.
##
## This is runtime persistence only. Save-to-disk persistence will belong to
## the future save/load system rather than this script.

var inventory_items: Dictionary = {}


func get_inventory() -> Dictionary:
	# Return a copy so other systems can inspect global inventory state without
	# directly modifying the data owned by GameState.
	return inventory_items.duplicate()


func set_inventory(items: Dictionary) -> void:
	# Replace the runtime inventory snapshot with a copy of the supplied data.
	# PlayerInventory remains responsible for validating individual item
	# operations before this function is called.
	inventory_items = items.duplicate()
