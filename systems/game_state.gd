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

## Moving-enemy lifecycle state survives the Battle scene replacing the world.
var defeated_moving_enemy_ids: Dictionary = {}
var escaped_enemy_id: String = ""
var escaped_enemy_position: Vector2 = Vector2.ZERO
var escape_invulnerable_until_msec: int = 0
var paused_enemy_id: String = ""
var paused_enemy_until_msec: int = 0

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
	defeated_moving_enemy_ids.clear()
	escaped_enemy_id = ""
	escaped_enemy_position = Vector2.ZERO
	escape_invulnerable_until_msec = 0
	paused_enemy_id = ""
	paused_enemy_until_msec = 0
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


func mark_moving_enemy_defeated(actor_id: String) -> void:
	# Remember a defeated world actor so it stays gone when Battle reloads its scene.
	if not actor_id.is_empty():
		defeated_moving_enemy_ids[actor_id] = true


func is_moving_enemy_defeated(actor_id: String) -> bool:
	# A stable actor ID, rather than the temporary Node instance ID, survives scene reloads.
	return not actor_id.is_empty() and defeated_moving_enemy_ids.has(actor_id)


func set_escape_return_state(actor_id: String, enemy_position: Vector2, invulnerability_seconds: float) -> void:
	# Keep the fleeing enemy's exact battle-start position and grant brief contact protection.
	escaped_enemy_id = actor_id
	escaped_enemy_position = enemy_position
	escape_invulnerable_until_msec = Time.get_ticks_msec() + int(invulnerability_seconds * 1000.0)


func consume_escaped_enemy_return(actor_id: String) -> Dictionary:
	# The reloaded enemy restores its saved position, then receives a fresh one-second pause.
	if actor_id.is_empty() or actor_id != escaped_enemy_id:
		return {}
	var result := {
		"position": escaped_enemy_position,
		"pause_until_msec": Time.get_ticks_msec() + 1000
	}
	paused_enemy_id = actor_id
	paused_enemy_until_msec = result["pause_until_msec"]
	escaped_enemy_id = ""
	return result


func is_enemy_recovery_paused(actor_id: String) -> bool:
	# Only the enemy the Player escaped from pauses; unrelated actors keep their own AI.
	return actor_id == paused_enemy_id and Time.get_ticks_msec() < paused_enemy_until_msec


func is_escape_invulnerable() -> bool:
	# Moving enemies use this to ignore contact encounters during the escape window.
	return Time.get_ticks_msec() < escape_invulnerable_until_msec
