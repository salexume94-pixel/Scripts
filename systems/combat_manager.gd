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

# The Battle UI listens for this signal so presentation can react to a player
# action without taking ownership of combat state or calculations.
signal player_attack_performed(attack_value: int)


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
	# Temporary controlled HP value until EnemyData becomes authoritative.
	combat_state.enemy_max_hp = 50
	combat_state.enemy_hp = combat_state.enemy_max_hp
	active_combat = combat_state

	# SceneManager owns actual scene loading, keeping transition responsibility
	# separate from combat state management.
	SceneManager.change_scene(BATTLE_SCENE, Vector2.ZERO)
	return true


func player_attack() -> bool:
	# The Player Attack action is the first real combat command. It reads the
	# Player's authoritative Attack stat and records the action in CombatState.
	# Enemy HP and damage application are intentionally deferred to the next
	# Combat Foundation steps.
	if not is_in_combat():
		return false

	if active_combat.phase != COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN:
		return false

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	var player := current_scene.get_node_or_null("Player")
	if player == null:
		# The Battle scene is intentionally Player-less, so obtain the Player's
		# attack value from the runtime snapshot maintained by PlayerStats.
		# Combat damage will use the same authoritative stat later.
		var saved_stats: Dictionary = GameState.get_player_stats()
		if saved_stats.is_empty():
			return false
		active_combat.last_player_attack = saved_stats.get("attack", 0)
	else:
		var stats := player.get_node_or_null("PlayerStats")
		if stats == null:
			return false
		active_combat.last_player_attack = stats.attack

	# For this step, the Player's Attack value is the direct damage amount. This
	# deliberately keeps the formula simple until the dedicated damage system is
	# introduced, while still exercising the complete HP update path.
	var damage := maxi(active_combat.last_player_attack, 1)
	active_combat.last_damage = damage
	active_combat.enemy_hp = maxi(active_combat.enemy_hp - damage, 0)

	# Keep the encounter on the Player turn until enemy behavior is implemented.
	active_combat.phase = COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN
	player_attack_performed.emit(active_combat.last_player_attack)
	return true


func get_enemy_hp() -> int:
	# Expose current enemy HP without allowing UI to modify combat state.
	if not is_in_combat():
		return 0
	return active_combat.enemy_hp


func get_last_damage() -> int:
	# Expose the most recent damage result for combat presentation.
	if not is_in_combat():
		return 0
	return active_combat.last_damage


func get_enemy_max_hp() -> int:
	# Expose maximum enemy HP for health presentation.
	if not is_in_combat():
		return 0
	return active_combat.enemy_max_hp


func get_last_player_attack() -> int:
	# Expose the most recent attack value to presentation without allowing the
	# Battle UI to modify combat state directly.
	if not is_in_combat():
		return 0
	return active_combat.last_player_attack


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
