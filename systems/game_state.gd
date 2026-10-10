extends Node
## Owns persistent runtime game state that must survive scene changes.
##
## PlayerInventory, PlayerEquipment, and PlayerStats own their respective
## gameplay behavior. GameState owns runtime snapshots so those values survive
## when a Player node is recreated by a scene transition.
##
## This is runtime persistence only. Save-to-disk persistence belongs to
## SaveManager, which serializes these snapshots without taking ownership of
## the underlying gameplay rules.

var inventory_items: Dictionary = {}
var equipment_items: Dictionary = {}
var player_stats: Dictionary = {}
var gold: int = 0

## Prevents a freshly completed encounter from immediately starting another one
## after the World scene is restored. This is runtime state only.
var encounter_cooldown_until_msec: int = 0

## Development toggle for random overworld encounters. Not saved to disk.
var overworld_encounters_enabled: bool = true


func reset_runtime_state() -> void:
	# New Game must clear the runtime snapshots that normally survive scene
	# changes. This does not delete the disk save, so an existing save can still
	# be loaded later from the Main Menu.
	inventory_items.clear()
	equipment_items.clear()
	player_stats.clear()
	gold = 0
	encounter_cooldown_until_msec = 0
	overworld_encounters_enabled = true


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


func get_gold() -> int:
	# Gold is runtime Player state and survives scene transitions like inventory.
	return gold


func set_gold(amount: int) -> void:
	# Clamp currency at zero so recovery and spending can never create debt.
	gold = maxi(amount, 0)


func get_player_stats() -> Dictionary:
	# Return a copy so a recreated PlayerStats node can restore its values
	# without directly modifying GameState's stored snapshot.
	return player_stats.duplicate()


func set_player_stats(stats: Dictionary) -> void:
	# Store the Player's current base stat snapshot. Equipment modifiers are
	# intentionally not stored here because PlayerEquipment reapplies them after
	# PlayerStats has been restored.
	player_stats = stats.duplicate()


func set_encounter_cooldown(seconds: float) -> void:
	# Store the cooldown globally because the World encounter system is recreated
	# when the World scene is loaded after combat.
	encounter_cooldown_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)


func is_encounter_cooldown_active() -> bool:
	# Time-based cooldown survives World scene replacement without tying combat
	# lifecycle code to the World scene instance.
	return Time.get_ticks_msec() < encounter_cooldown_until_msec
