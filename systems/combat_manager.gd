extends Node
## Coordinates the runtime combat encounter and Battle-scene lifecycle.
##
## CombatManager is responsible only for combat flow and state. It remembers
## which enemy is being fought, which scene the Player should return to, and
## the Player's return position. It does not own enemy definitions, calculate
## damage, apply stats, or draw combat UI.
##
## Later combat steps will add actions such as attack and defend around this
## state foundation. The Enemy Foundation will provide the real enemy data.

const COMBAT_STATE_SCRIPT = preload("res://combat/combat_state.gd")
const BATTLE_SCENE := "res://scenes/Battle.tscn"

var active_combat: Resource = null
var return_scene_path: String = ""
var return_player_position: Vector2 = Vector2.ZERO


func is_in_combat() -> bool:
	# A non-null combat state means the game currently has an active encounter.
	return active_combat != null


func start_encounter(enemy_id: String) -> bool:
	# Reject an invalid request or a second encounter while another battle is
	# already active. This keeps combat state transitions deterministic.
	if enemy_id.is_empty() or is_in_combat():
		return false

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	var player := current_scene.get_node_or_null("Player") as Node2D
	if player == null:
		return false

	# Record where the Player should be returned after the Battle scene ends.
	# The current scene itself owns the Player, so the Player node cannot simply
	# be carried into the separate Battle scene.
	return_scene_path = current_scene.scene_file_path
	return_player_position = player.global_position

	# Create the first encounter state. Enemy HP will be supplied by the future
	# Enemy Foundation instead of being hard-coded into this combat layer.
	var combat_state: Resource = COMBAT_STATE_SCRIPT.new()
	combat_state.enemy_id = enemy_id
	active_combat = combat_state

	# SceneManager owns actual scene loading, keeping transition responsibility
	# separate from combat state management.
	SceneManager.change_scene(BATTLE_SCENE, Vector2.ZERO)
	return true


func end_combat() -> bool:
	# Do not attempt to leave Battle when there is no active encounter.
	if not is_in_combat():
		return false

	# Clear the active state only after the return destination has been stored.
	# This lets the World receive the Player at the same location from which the
	# encounter began.
	active_combat = null

	var destination := return_scene_path
	var destination_position := return_player_position

	return_scene_path = ""
	return_player_position = Vector2.ZERO

	if destination.is_empty():
		return false

	SceneManager.change_scene(destination, destination_position)
	return true


func get_active_enemy_id() -> String:
	# Expose only the small piece of encounter data that presentation currently
	# needs. The complete combat state remains owned by CombatManager.
	if not is_in_combat():
		return ""
	return active_combat.enemy_id


func get_phase() -> int:
	# Return the current combat phase for future action and UI systems.
	if not is_in_combat():
		return -1
	return active_combat.phase
