extends Node
## Coordinates the runtime combat encounter and Battle-scene lifecycle.
##
## CombatManager owns combat flow and state. It does not own enemy definitions
## or draw the Battle UI. Player and enemy actions are resolved here so the
## combat rules remain authoritative outside the presentation layer.

const COMBAT_STATE_SCRIPT = preload("res://combat/combat_state.gd")
const ENEMY_DATABASE = preload("res://enemies/enemy_database.gd")
const COMBAT_RULES = preload("res://combat/combat_rules.gd")
const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
const PLAYER_PHYSICAL_ACTION = preload("res://combat/definitions/physical_attack.tres")
const BATTLE_SCENE := "res://scenes/Battle.tscn"

## The current enemy action is stored separately from the enemy definition so
## CombatState can keep only the active encounter data.

var active_combat: Resource = null
var return_scene_path: String = ""
var return_player_position: Vector2 = Vector2.ZERO

signal player_attack_performed(attack_value: int)
signal player_press_turns_changed(remaining: float)
signal enemy_turn_started
signal enemy_attack_performed(damage: int)
signal player_defeated

func is_in_combat() -> bool:
	return active_combat != null

func start_encounter(enemy_id: String) -> bool:
	# Start one encounter and record the Player return location.
	if enemy_id.is_empty() or is_in_combat():
		return false

	# Resolve the requested enemy from the authoritative Resource catalog.
	# Combat should never silently create an enemy from hardcoded fallback stats.
	var enemy_data: Resource = ENEMY_DATABASE.get_enemy(enemy_id)
	if enemy_data == null:
		return false
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	var player := current_scene.get_node_or_null("Player") as Node2D
	if player == null:
		return false
	return_scene_path = current_scene.scene_file_path
	return_player_position = player.global_position

	# Copy the enemy definition into the active encounter state. The Resource is
	# the source of truth for base values; CombatState owns only this encounter's
	# mutable values such as current HP and Press Turns.
	var combat_state: Resource = COMBAT_STATE_SCRIPT.new()
	combat_state.enemy_id = enemy_data.enemy_id
	combat_state.enemy_max_hp = enemy_data.max_hp
	combat_state.enemy_hp = enemy_data.max_hp
	combat_state.player_press_turns = 4
	combat_state.player_press_turns_remaining = 4.0
	if enemy_data.actions.is_empty():
		return false
	var first_action: Resource = enemy_data.actions[0]
	combat_state.enemy_attack = first_action.power
	active_combat = combat_state
	SceneManager.change_scene(BATTLE_SCENE, Vector2.ZERO)
	return true

func player_attack(action: Resource = null) -> bool:
	# Resolve a Player action against the enemy's affinity.
	# Action data supplies the damage type and power multiplier, while this
	# coordinator applies the shared Press Turn and damage rules.
	if not is_in_combat() or active_combat.phase != COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN:
		return false
	if active_combat.player_press_turns_remaining <= 0.0:
		return false

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	var player_attack_value := 0
	var player := current_scene.get_node_or_null("Player")
	if player == null:
		var saved_stats: Dictionary = GameState.get_player_stats()
		if saved_stats.is_empty():
			return false
		player_attack_value = saved_stats.get("attack", 0)
	else:
		var stats := player.get_node_or_null("PlayerStats")
		if stats == null:
			return false
		player_attack_value = stats.attack

	var enemy_data: Resource = enemy_data_for_active_combat()
	if enemy_data == null:
		return false

	var selected_action: Resource = action if action != null else PLAYER_PHYSICAL_ACTION
	var action_power := maxi(int(round(float(player_attack_value) * selected_action.power_multiplier)), 1)
	var damage_result: Dictionary = COMBAT_RULES.resolve_damage(
		action_power,
		selected_action.damage_type,
		enemy_data
	)

	active_combat.last_player_attack = action_power
	active_combat.last_damage = damage_result.damage
	active_combat.last_player_damage_type = selected_action.damage_type
	active_combat.last_player_affinity = damage_result.affinity
	active_combat.last_player_result_type = damage_result.result_type

	match damage_result.result_type:
		"damage":
			active_combat.enemy_hp = maxi(active_combat.enemy_hp - damage_result.damage, 0)
		"drain":
			# Drain heals the target instead of damaging it.
			active_combat.enemy_hp = mini(
				active_combat.enemy_hp + damage_result.damage,
				active_combat.enemy_max_hp
			)
		"repel":
			# Repel reflects the resolved damage back to the Player.
			var stats_to_update: Dictionary = GameState.get_player_stats()
			var current_hp: int = stats_to_update.get("hp", stats_to_update.get("max_hp", 0))
			stats_to_update["hp"] = maxi(current_hp - damage_result.damage, 0)
			GameState.set_player_stats(stats_to_update)
			active_combat.last_damage = 0

	consume_player_press_turn(damage_result.turn_cost)

	if damage_result.result_type == "repel":
		var reflected_stats: Dictionary = GameState.get_player_stats()
		if reflected_stats.get("hp", 0) <= 0:
			active_combat.phase = COMBAT_STATE_SCRIPT.Phase.DEFEAT
			player_defeated.emit()
		elif active_combat.player_press_turns_remaining <= 0.0:
			active_combat.phase = COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN
			enemy_turn_started.emit()
			_resolve_enemy_turn()
		else:
			active_combat.phase = COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN
	elif active_combat.enemy_hp <= 0:
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.VICTORY
	elif active_combat.player_press_turns_remaining <= 0.0:
		# All Player actions are spent, so the enemy receives its turn.
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN
		enemy_turn_started.emit()
		_resolve_enemy_turn()
	else:
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN

	player_attack_performed.emit(active_combat.last_player_attack)
	return true

func player_defend() -> bool:
	# Defend spends one full Press Turn and reduces the next enemy turn's damage.
	if not is_in_combat() or active_combat.phase != COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN:
		return false
	if active_combat.player_press_turns_remaining <= 0.0:
		return false

	active_combat.player_defending = true
	consume_player_press_turn(1.0)
	_resolve_player_action_end("Player defends.")
	return true

func player_pass() -> bool:
	# Pass spends one full Press Turn without changing combat stats or HP.
	if not is_in_combat() or active_combat.phase != COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN:
		return false
	if active_combat.player_press_turns_remaining <= 0.0:
		return false

	consume_player_press_turn(1.0)
	_resolve_player_action_end("Player passes.")
	return true

func _resolve_player_action_end(action_text: String) -> void:
	# Centralize the shared end-of-action flow for Defend and Pass so both actions
	# obey the same Press Turn exhaustion rule as a normal Player action.
	var action_label = action_text
	if active_combat.player_press_turns_remaining <= 0.0:
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN
		enemy_turn_started.emit()
		_resolve_enemy_turn()

func get_last_player_action_text() -> String:
	# Return the most recent non-attack action text for Battle presentation.
	return "Player defends." if is_in_combat() and active_combat.player_defending else "Player passes."

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

func _resolve_enemy_turn() -> void:
	# Resolve the enemy action after the Battle UI has had a chance to
	# display the ENEMY TURN state. The timer also makes the turn readable during
	# testing instead of changing phases in the same frame.
	if not is_in_combat() or active_combat.phase != COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN:
		return
	await get_tree().create_timer(0.75).timeout
	if not is_in_combat() or active_combat.phase != COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN:
		return

	var saved_stats: Dictionary = GameState.get_player_stats()
	if saved_stats.is_empty():
		return

	var enemy_action: Resource = _select_enemy_action(enemy_data_for_active_combat())
	if enemy_action == null:
		return

	# Store the selected action in CombatState so the presentation layer can
	# report exactly what the enemy performed without owning selection logic.
	active_combat.enemy_attack = enemy_action.power
	active_combat.last_enemy_action_id = enemy_action.action_id
	active_combat.last_enemy_action_name = enemy_action.display_name

	var player_defense: int = saved_stats.get("defense", 0)
	var damage := maxi(active_combat.enemy_attack - player_defense, 1)
	if active_combat.player_defending:
		# Defend currently halves the final incoming damage, with a minimum of 1.
		damage = maxi(int(ceil(float(damage) * 0.5)), 1)
	active_combat.player_defending = false
	var current_hp: int = saved_stats.get("hp", saved_stats.get("max_hp", 0))
	var new_hp := maxi(current_hp - damage, 0)
	saved_stats["hp"] = new_hp
	GameState.set_player_stats(saved_stats)
	active_combat.last_enemy_damage = damage
	enemy_attack_performed.emit(damage)

	if new_hp <= 0:
		# Defeat is recorded now, but the actual defeat/recovery flow remains a
		# later system so this step only establishes the combat state correctly.
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.DEFEAT
		player_defeated.emit()
		return

	# The enemy's turn is complete, so restore the Player's full Press Turn set.
	active_combat.player_press_turns_remaining = float(active_combat.player_press_turns)
	active_combat.phase = COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN
	player_press_turns_changed.emit(active_combat.player_press_turns_remaining)

func enemy_data_for_active_combat() -> Resource:
	# Resolve the authoritative definition again when an enemy action is needed.
	# The database remains the single source of truth for available actions.
	if not is_in_combat():
		return null
	return ENEMY_DATABASE.get_enemy(active_combat.enemy_id)

func _select_enemy_action(enemy_data: Resource) -> Resource:
	# Choose one available action using its configured relative weight.
	# This keeps selection rules in CombatManager while action definitions remain
	# reusable Resources.
	if enemy_data == null or enemy_data.actions.is_empty():
		return null

	var total_weight := 0.0
	for action in enemy_data.actions:
		if action != null and action.selection_weight > 0.0:
			total_weight += action.selection_weight
	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	for action in enemy_data.actions:
		if action == null or action.selection_weight <= 0.0:
			continue
		roll -= action.selection_weight
		if roll < 0.0:
			return action

	return null

func get_last_enemy_action_name() -> String:
	return active_combat.last_enemy_action_name if is_in_combat() else ""

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
func get_last_enemy_damage() -> int:
	return active_combat.last_enemy_damage if is_in_combat() else 0
func get_last_player_affinity() -> int:
	return active_combat.last_player_affinity if is_in_combat() else 0
func get_last_player_damage_type() -> int:
	return active_combat.last_player_damage_type if is_in_combat() else DAMAGE_TYPES.Type.PHYSICAL
func get_last_player_result_type() -> String:
	return active_combat.last_player_result_type if is_in_combat() else ""
func is_player_turn() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN
func is_enemy_turn() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN
func is_victory() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.VICTORY
func is_defeat() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.DEFEAT

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
