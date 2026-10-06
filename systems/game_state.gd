extends Node
## Owns persistent runtime game state that must survive scene changes.
##
## PlayerInventory, PlayerEquipment, and PlayerStats own their respective
## gameplay behavior. GameState owns runtime snapshots so those values survive
## when a Player node is recreated by a scene transition.
##
## This is runtime persistence only. Save-to-disk persistence will belong to the
## future save/load system rather than this script.

var inventory_items: Dictionary = {}
var equipment_items: Dictionary = {}
var player_stats: Dictionary = {}


func get_inventory() -> Dictionary:
	# Return a copy so other systems can inspect global inventory state without
	# directly modifying the data owned by GameState.
	return inventory_items.duplicate()


func set_inventory(items: Dictionary) -> void:
	# Replace the runtime inventory snapshot with a copy of the supplied data.
	inventory_items = items.duplicate()


func get_equipment() -> Dictionary:
	# Return a copy so PlayerEquipment can restore its owned equipment snapshot.
	return equipment_items.duplicate()


func set_equipment(equipment: Dictionary) -> void:
	# Store the equipment ownership snapshot. PlayerEquipment remains responsible
	# for validating equip and unequip operations.
	equipment_items = equipment.duplicate()


func get_player_stats() -> Dictionary:
	# Return a copy so a recreated PlayerStats node can restore its values
	# without directly modifying GameState's stored snapshot.
	return player_stats.duplicate()


func set_player_stats(stats: Dictionary) -> void:
	# Store the Player's current base stat snapshot. Equipment modifiers are
	# intentionally not stored here because PlayerEquipment reapplies them after
	# PlayerStats has been restored.
	player_stats = stats.duplicate()
