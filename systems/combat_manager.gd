extends Node
## Coordinates the runtime combat encounter and Battle-scene lifecycle.
##
## CombatManager owns combat flow and state. It does not own enemy definitions
## or draw the Battle UI. Player actions consume Press Turns here so the combat
## resource remains authoritative outside the presentation layer.

const COMBAT_STATE_SCRIPT = preload("res://combat/combat_state.gd")
const BATTLE_SCENE := "res://scenes/Battle.tscn"

var active_combat: Resource = null
var return_scene_path: String = ""
var return_player_position: Vector2 = Vector2.ZERO

signal player_attack_performed(attack_value: int)
signal player_press_turns_changed(remaining: float)
signal enemy_turn_started

func is_in_combat() -> bool:
	return active_combat != null

func start_encounter(enemy_id: String) -> bool:
	# Start one encounter and record the Player return location.
	if enemy_id.is_empty() or is_in_combat():
		return false
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	var player := current_scene.get_node_or_null("Player") as Node2D
	if player == null:
		return false
	return_scene_path = current_scene.scene_file_path
	return_player_position = player.global_position

	# Temporary enemy values remain until EnemyData becomes authoritative.
	var combat_state: Resource = COMBAT_STATE_SCRIPT.new()
	combat_state.enemy_id = enemy_id
	combat_state.enemy_max_hp = 50
	combat_state.enemy_hp = 50
	combat_state.player_press_turns = 4
	combat_state.player_press_turns_remaining = 4.0
	active_combat = combat_state
	SceneManager.change_scene(BATTLE_SCENE, Vector2.ZERO)
	return true

func player_attack() -> bool:
	# A normal Attack consumes one full Press Turn.
	if not is_in_combat() or active_combat.phase != COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN:
		return false
	if active_combat.player_press_turns_remaining <= 0.0:
		return false

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	var player := current_scene.get_node_or_null("Player")
	if player == null:
		var saved_stats: Dictionary = GameState.get_player_stats()
		if saved_stats.is_empty():
			return false
		active_combat.last_player_attack = saved_stats.get("attack", 0)
	else:
		var stats := player.get_node_or_null("PlayerStats")
		if stats == null:
			return false
		active_combat.last_player_attack = stats.attack

	var damage := maxi(active_combat.last_player_attack, 1)
	active_combat.last_damage = damage
	active_combat.enemy_hp = maxi(active_combat.enemy_hp - damage, 0)
	consume_player_press_turn(1.0)

	if active_combat.enemy_hp <= 0:
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.VICTORY
	elif active_combat.player_press_turns_remaining <= 0.0:
		# Enemy behavior is not implemented yet, so this only establishes the
		# phase transition that the future enemy turn will occupy.
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN
		enemy_turn_started.emit()
	else:
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN

	player_attack_performed.emit(active_combat.last_player_attack)
	return true

func consume_player_press_turn(amount: float) -> void:
	# Keep the resource between zero and its configured maximum.
	if not is_in_combat():
		return
	active_combat.player_press_turns_remaining = clampf(
		active_combat.player_press_turns_remaining - amount,
		0.0,
		float(active_combat.player_press_turns)
	)
	player_press_turns_changed.emit(active_combat.player_press_turns_remaining)

func end_enemy_turn() -> bool:
	# Temporary enemy-turn transition. The real enemy action will replace this.
	if not is_in_combat() or active_combat.phase != COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN:
		return false
	active_combat.player_press_turns_remaining = float(active_combat.player_press_turns)
	active_combat.phase = COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN
	player_press_turns_changed.emit(active_combat.player_press_turns_remaining)
	return true

func get_enemy_hp() -> int:
	return active_combat.enemy_hp if is_in_combat() else 0
func get_last_damage() -> int:
	return active_combat.last_damage if is_in_combat() else 0
func get_enemy_max_hp() -> int:
	return active_combat.enemy_max_hp if is_in_combat() else 0
func get_last_player_attack() -> int:
	return active_combat.last_player_attack if is_in_combat() else 0
func get_player_press_turns() -> int:
	return active_combat.player_press_turns if is_in_combat() else 0
func get_player_press_turns_remaining() -> float:
	return active_combat.player_press_turns_remaining if is_in_combat() else 0.0
func is_player_turn() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN
func is_enemy_turn() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN

func end_combat() -> bool:
	if not is_in_combat():
		return false
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
	return active_combat.enemy_id if is_in_combat() else ""
func get_phase() -> int:
	return active_combat.phase if is_in_combat() else -1
func is_victory() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.VICTORY
