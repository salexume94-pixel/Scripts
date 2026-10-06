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
const PLAYER_CRITICAL_TEST_ACTION = preload("res://combat/definitions/critical_test.tres")
const PLAYER_MISS_TEST_ACTION = preload("res://combat/definitions/miss_test.tres")
const DEFAULT_ENEMY_BEHAVIOR = preload("res://enemies/definitions/behavior_balanced.tres")
const ENCOUNTER_BEHAVIOR_PROFILES: Array[Resource] = [
	preload("res://enemies/definitions/behavior_balanced.tres"),
	preload("res://enemies/definitions/behavior_aggressive.tres"),
	preload("res://enemies/definitions/behavior_weakness_hunter.tres"),
	preload("res://enemies/definitions/behavior_defensive.tres"),
]
const AFFINITIES = preload("res://combat/affinities.gd")
const ENEMY_BEHAVIOR_PROFILE = preload("res://enemies/enemy_behavior_profile.gd")
const BATTLE_SCENE := "res://scenes/Battle.tscn"

## The current enemy action is stored separately from the enemy definition so
## CombatState can keep only the active encounter data.

var active_combat: Resource = null
## Debug trace of the most recent enemy action-selection decision.
var last_enemy_ai_debug: Array[String] = []
var combat_log: Array[String] = []
signal combat_log_updated

## Debug-only actions use the same resolution path as normal Player actions.
## They exist only to make accuracy and critical behavior deterministic to test.
var return_scene_path: String = ""
var return_player_position: Vector2 = Vector2.ZERO

signal player_attack_performed(attack_value: int)
signal player_press_turns_changed(remaining: float)
signal enemy_turn_started
signal enemy_attack_performed(damage: int)
signal player_defeated


func _append_combat_log(message: String) -> void:
	# Keep combat history owned by CombatManager so Battle only presents it.
	combat_log.append(message)
	combat_log_updated.emit()

func _get_player_affinity(damage_type: int) -> int:
	# Resolve the Player's reaction to an enemy damage type from the encounter
	# snapshot captured before the World scene is replaced.
	if not is_in_combat():
		return AFFINITIES.Type.NORMAL
	for affinity_data in active_combat.player_affinities:
		if affinity_data == null:
			continue
		if affinity_data.damage_type == damage_type:
			return affinity_data.affinity
	return AFFINITIES.Type.NORMAL

func is_in_combat() -> bool:
	return active_combat != null

func is_victory() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.VICTORY

func is_defeat() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.DEFEAT

func is_player_turn() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN

func is_enemy_turn() -> bool:
	return is_in_combat() and active_combat.phase == COMBAT_STATE_SCRIPT.Phase.ENEMY_TURN

func get_active_enemy_id() -> String:
	return active_combat.enemy_id if is_in_combat() else ""

func get_enemy_hp() -> int:
	return active_combat.enemy_hp if is_in_combat() else 0

func get_enemy_max_hp() -> int:
	return active_combat.enemy_max_hp if is_in_combat() else 0

func get_player_press_turns_remaining() -> float:
	return active_combat.player_press_turns_remaining if is_in_combat() else 0.0

func get_combat_log() -> Array[String]:
	return combat_log.duplicate()

func add_combat_log(message: String) -> void:
	if message.is_empty():
		return
	_append_combat_log(message)

func get_last_enemy_action_name() -> String:
	return active_combat.last_enemy_action_name if is_in_combat() else ""

func get_enemy_behavior_profile_name() -> String:
	# Expose the selected encounter profile to Battle without exposing CombatState.
	return active_combat.enemy_behavior_profile.profile_id if is_in_combat() and active_combat.enemy_behavior_profile != null else "unknown"

func get_last_player_damage_type() -> int:
	# Expose the resolved Player damage type so Battle can present the action
	# without reaching into CombatState directly.
	return active_combat.last_player_damage_type if is_in_combat() else DAMAGE_TYPES.Type.PHYSICAL

func get_player_weakness_debug() -> String:
	if not is_in_combat():
		return "Unknown"
	for affinity_data in active_combat.player_affinities:
		if affinity_data == null:
			continue
		if affinity_data.affinity == AFFINITIES.Type.WEAK:
			return DAMAGE_TYPES.get_display_name(affinity_data.damage_type)
	return "None"

func cycle_player_weakness() -> bool:
	if not is_in_combat() or active_combat.player_affinities.is_empty():
		return false
	var weakness_index := -1
	for i in range(active_combat.player_affinities.size()):
		var affinity_data: Resource = active_combat.player_affinities[i]
		if affinity_data != null and affinity_data.affinity == AFFINITIES.Type.WEAK:
			weakness_index = i
			break
	if weakness_index < 0:
		return false
	var next_index: int = (weakness_index + 1) % active_combat.player_affinities.size()
	for i in range(active_combat.player_affinities.size()):
		var affinity_data: Resource = active_combat.player_affinities[i]
		if affinity_data == null:
			continue
		affinity_data.affinity = AFFINITIES.Type.WEAK if i == next_index else AFFINITIES.Type.NORMAL
	return true

func end_combat() -> void:
	if not is_in_combat():
		return
	var destination := return_scene_path
	var destination_position := return_player_position
	active_combat = null
	combat_log.clear()
	last_enemy_ai_debug.clear()
	if not destination.is_empty():
		SceneManager.change_scene(destination, destination_position)

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
	combat_state.player_press_turns = 2
	combat_state.player_press_turns_remaining = 2.0
	if enemy_data.actions.is_empty():
		return false

	# Capture the Player's configured affinities before replacing the World scene.
	# Enemy AI uses this encounter snapshot so selection does not depend on the
	# Battle presentation scene or a recreated Player node.
	var player_stats_node := player.get_node_or_null("PlayerStats")
	if player_stats_node != null:
		combat_state.player_affinities = player_stats_node.get("affinities").duplicate(true)

	# Choose the AI profile for this encounter. Enemy definitions may provide
	# a fixed profile for controlled encounters and debug tests. Normal enemies
	# without a fixed profile receive one of the shared profiles at random when
	# the battle begins, so the same enemy can behave differently between battles.
	var selected_behavior: Resource = enemy_data.behavior_profile
	if selected_behavior == null:
		selected_behavior = ENCOUNTER_BEHAVIOR_PROFILES[randi() % ENCOUNTER_BEHAVIOR_PROFILES.size()]
	combat_state.enemy_behavior_profile = selected_behavior

	var first_action: Resource = enemy_data.actions[0]
	combat_state.enemy_attack = first_action.power
	active_combat = combat_state
	combat_log.clear()
	_append_combat_log("COMBAT: %s entered battle." % enemy_data.display_name)
	_append_combat_log("ENEMY AI: %s profile selected." % selected_behavior.profile_id)
	_append_combat_log("PLAYER TURN: 2 Press Turns available.")
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
		enemy_data,
		selected_action.accuracy,
		selected_action.critical_chance,
		selected_action.critical_multiplier
	)

	active_combat.last_player_attack = action_power
	active_combat.last_damage = damage_result.damage
	active_combat.last_player_damage_type = selected_action.damage_type
	active_combat.last_player_affinity = damage_result.affinity
	active_combat.last_player_result_type = damage_result.result_type
	active_combat.last_player_critical = damage_result.critical

	match damage_result.result_type:
		"damage":
			active_combat.enemy_hp = maxi(active_combat.enemy_hp - damage_result.damage, 0)
		"drain":
			# Drain heals the target instead of damaging it.
			active_combat.enemy_hp = mini(
				active_combat.enemy_hp + damage_result.damage,
				active_combat.enemy_max_hp
			)
		"miss":
			# A miss consumes its Press Turn but does not change either HP pool.
			pass
		"repel":
			# Repel reflects the resolved damage back to the Player.
			var stats_to_update: Dictionary = GameState.get_player_stats()
			var current_hp: int = stats_to_update.get("hp", stats_to_update.get("max_hp", 0))
			stats_to_update["hp"] = maxi(current_hp - damage_result.damage, 0)
			GameState.set_player_stats(stats_to_update)
			active_combat.last_damage = 0

	consume_player_press_turn(damage_result.turn_cost)
	_append_combat_log("PLAYER: %s deals %d damage (%s)." % [selected_action.display_name, damage_result.damage, AFFINITIES.get_display_name(damage_result.affinity)])

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

func player_critical_test() -> bool:
	# Start a deterministic guaranteed-critical action for runtime testing.
	return player_attack(PLAYER_CRITICAL_TEST_ACTION)

func player_miss_test() -> bool:
	# Start a deterministic guaranteed-miss action for runtime testing.
	return player_attack(PLAYER_MISS_TEST_ACTION)

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
		# An enemy with no usable actions must never leave combat stuck in Enemy
		# Turn. Record the edge case and safely return control to the Player.
		_append_combat_log("ENEMY: No valid action available. Enemy Turn skipped.")
		active_combat.player_press_turns_remaining = float(active_combat.player_press_turns)
		active_combat.phase = COMBAT_STATE_SCRIPT.Phase.PLAYER_TURN
		player_press_turns_changed.emit(active_combat.player_press_turns_remaining)
		return

	# Store the selected action in CombatState so the presentation layer can
	# report exactly what the enemy performed without owning selection logic.
	active_combat.enemy_attack = enemy_action.power
	active_combat.last_enemy_action_id = enemy_action.action_id
	active_combat.last_enemy_action_name = enemy_action.display_name

	var player_defense: int = saved_stats.get("defense", 0)
	var base_damage := maxi(active_combat.enemy_attack - player_defense, 1)
	if active_combat.player_defending:
		# Defend currently halves the final incoming damage, with a minimum of 1.
		base_damage = maxi(int(ceil(float(base_damage) * 0.5)), 1)
	active_combat.player_defending = false

	var damage_result: Dictionary = COMBAT_RULES.resolve_damage_against_affinities(
		base_damage,
		enemy_action.damage_type,
		active_combat.player_affinities,
		enemy_action.accuracy,
		enemy_action.critical_chance,
		enemy_action.critical_multiplier
	)
	var damage: int = damage_result.damage
	active_combat.last_enemy_damage_type = enemy_action.damage_type
	active_combat.last_enemy_affinity = damage_result.affinity
	active_combat.last_enemy_result_type = damage_result.result_type
	var current_hp: int = saved_stats.get("hp", saved_stats.get("max_hp", 0))
	var new_hp := current_hp
	match damage_result.result_type:
		"damage":
			new_hp = maxi(current_hp - damage, 0)
		"drain":
			new_hp = mini(current_hp + damage, saved_stats.get("max_hp", current_hp))
		"repel":
			new_hp = maxi(current_hp - damage, 0)
		"miss", "nullify":
			pass
	saved_stats["hp"] = new_hp
	GameState.set_player_stats(saved_stats)
	active_combat.last_enemy_damage = damage
	_append_combat_log("ENEMY: %s deals %d damage (%s)." % [active_combat.last_enemy_action_name, damage, AFFINITIES.get_display_name(damage_result.affinity)])
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

func _get_active_enemy_behavior(enemy_data: Resource) -> Resource:
	# Return the profile selected for this specific encounter. The profile lives
	# in CombatState so AI decisions remain tied to the battle instance rather
	# than changing the source EnemyData Resource.
	if is_in_combat() and active_combat.enemy_behavior_profile != null:
		return active_combat.enemy_behavior_profile
	if enemy_data != null and enemy_data.behavior_profile != null:
		return enemy_data.behavior_profile
	return DEFAULT_ENEMY_BEHAVIOR

func _select_enemy_action(enemy_data: Resource) -> Resource:
	# Select from the enemy's available actions using both configured weights and
	# the enemy's behavior profile. Weakness hunters explicitly reserve a
	# configurable share of their decisions for actions targeting the Player's
	# known weakness instead of merely making those actions more likely.
	if enemy_data == null or enemy_data.actions.is_empty():
		return null

	var behavior: Resource = _get_active_enemy_behavior(enemy_data)

	var total_weight := 0.0
	var weighted_actions: Array[Dictionary] = []
	var max_power := 1
	var target_weakness_actions := false
	last_enemy_ai_debug.clear()

	for action in enemy_data.actions:
		if action != null:
			max_power = maxi(max_power, action.power)

	if behavior.strategy == ENEMY_BEHAVIOR_PROFILE.Strategy.WEAKNESS_HUNTER or behavior.strategy == ENEMY_BEHAVIOR_PROFILE.Strategy.AGGRESSIVE:
		# Weakness Hunter and Aggressive enemies both decide whether to target
		# the Player's known weakness before selecting a specific action.
		# Aggressive behavior then adds its stronger-action preference below.
		# The probability remains configurable through the shared behavior profile.
		target_weakness_actions = randf() < behavior.weakness_selection_chance

	for action in enemy_data.actions:
		if action == null or action.selection_weight <= 0.0:
			continue

		var weight: float = action.selection_weight
		var player_affinity := _get_player_affinity(action.damage_type)

		match behavior.strategy:
			ENEMY_BEHAVIOR_PROFILE.Strategy.AGGRESSIVE:
				# Aggressive enemies use the same weakness-targeting pool as
				# Weakness Hunters, then favor stronger actions inside that pool.
				# This makes Aggressive a more forceful version of weakness hunting
				# instead of a completely separate targeting strategy.
				var aggressive_power_ratio: float = clampf(float(action.power) / float(max_power), 0.0, 1.0)
				weight *= pow(aggressive_power_ratio, behavior.power_bias_strength)
				var is_aggressive_weakness_action := player_affinity == AFFINITIES.Type.WEAK
				if is_aggressive_weakness_action != target_weakness_actions:
					weight = 0.0
				elif is_aggressive_weakness_action:
					weight *= action.weakness_weight_multiplier * behavior.weakness_priority
			ENEMY_BEHAVIOR_PROFILE.Strategy.DEFENSIVE:
				# Defensive behavior currently has no dedicated defend/guard action,
				# so it uses action power as the available proxy: lower-power attacks
				# are treated as safer choices. This keeps the profile framework
				# functional until true defensive enemy actions are introduced.
				var defensive_power_ratio: float = clampf(float(action.power) / float(max_power), 0.0, 1.0)
				var defensive_preference: float = 1.0 - defensive_power_ratio
				weight *= pow(defensive_preference, behavior.power_bias_strength)
			ENEMY_BEHAVIOR_PROFILE.Strategy.WEAKNESS_HUNTER:
				# First choose whether this turn belongs to the weakness or
				# non-weakness pool. Then preserve configured weights inside that pool.
				var is_weakness_action := player_affinity == AFFINITIES.Type.WEAK
				if is_weakness_action != target_weakness_actions:
					weight = 0.0
				elif is_weakness_action:
					weight *= action.weakness_weight_multiplier * behavior.weakness_priority

		if player_affinity != AFFINITIES.Type.NORMAL and player_affinity != AFFINITIES.Type.WEAK:
			weight *= behavior.unfavorable_affinity_multiplier

		# Discourage repeating the exact same action while preserving the profile's
		# affinity and strategy preferences.
		if active_combat.last_enemy_action_id == action.action_id:
			weight *= behavior.repeat_action_multiplier

		if weight > 0.0:
			weight = maxf(weight, behavior.minimum_selection_weight)

		var affinity_name := AFFINITIES.get_display_name(player_affinity)
		if weight > 0.0:
			weighted_actions.append({"action": action, "weight": weight})
			total_weight += weight
			last_enemy_ai_debug.append("AI: %s -> %s | weight %.2f" % [action.display_name, affinity_name, weight])
		else:
			last_enemy_ai_debug.append("AI: %s -> %s | REJECTED (weight 0)" % [action.display_name, affinity_name])

	# If the requested pool is empty, fall back to the other pool rather than
	# skipping the enemy turn. This is important for enemies with no elemental
	# weakness action or no valid non-weakness action.
	if total_weight <= 0.0 and (behavior.strategy == ENEMY_BEHAVIOR_PROFILE.Strategy.WEAKNESS_HUNTER or behavior.strategy == ENEMY_BEHAVIOR_PROFILE.Strategy.AGGRESSIVE):
		target_weakness_actions = not target_weakness_actions
		return _select_enemy_action_from_pool(enemy_data, behavior, target_weakness_actions)

	if total_weight <= 0.0:
		# Edge-case safety: if profile rules eliminate every weighted action,
		# choose the first usable action rather than leaving the encounter stalled.
		for action in enemy_data.actions:
			if action != null and action.selection_weight > 0.0:
				last_enemy_ai_debug.append("AI FALLBACK: %s" % action.display_name)
				return action
		return null

	var roll := randf() * total_weight
	for entry in weighted_actions:
		roll -= entry.weight
		if roll < 0.0:
			last_enemy_ai_debug.append("AI SELECTED: %s" % entry.action.display_name)
			return entry.action

	last_enemy_ai_debug.append("AI SELECTED: %s" % weighted_actions.back().action.display_name)
	return weighted_actions.back().action


func _select_enemy_action_from_pool(enemy_data: Resource, behavior: Resource, target_weakness_actions: bool) -> Resource:
	# Fallback selector used only when the requested weakness/non-weakness pool
	# contains no valid actions.
	var weighted_actions: Array[Dictionary] = []
	var total_weight := 0.0

	for action in enemy_data.actions:
		if action == null or action.selection_weight <= 0.0:
			continue
		var player_affinity := _get_player_affinity(action.damage_type)
		var is_weakness_action := player_affinity == AFFINITIES.Type.WEAK
		if is_weakness_action != target_weakness_actions:
			continue
		var weight: float = action.selection_weight
		if is_weakness_action:
			weight *= action.weakness_weight_multiplier * behavior.weakness_priority
		if active_combat.last_enemy_action_id == action.action_id:
			weight *= behavior.repeat_action_multiplier
		if weight > 0.0:
			weighted_actions.append({"action": action, "weight": weight})
			total_weight += weight

	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	for entry in weighted_actions:
		roll -= entry.weight
		if roll < 0.0:
			last_enemy_ai_debug.append("AI SELECTED: %s" % entry.action.display_name)
			return entry.action
	return weighted_actions.back().action