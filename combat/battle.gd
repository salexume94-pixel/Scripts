extends Control

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
const AFFINITIES = preload("res://combat/affinities.gd")
const FIRE_ACTION = preload("res://combat/definitions/fire_attack.tres")
## Presents Battle state and forwards player input to CombatManager.
##
## CombatManager owns Press Turns and combat rules. This script only presents
## their current state, reports resolved results, and handles Battle input.

var action_resolving := false

func _on_combat_log_updated() -> void:
	_update_combat_log_display()

func _on_cycle_weakness_pressed() -> void:
	if CombatManager.cycle_player_weakness():
		_update_player_weakness_display()
		_update_combat_log_display()

func _ready() -> void:
	CombatManager.player_attack_performed.connect(_on_player_attack_performed)
	CombatManager.player_press_turns_changed.connect(_on_press_turns_changed)
	CombatManager.enemy_turn_started.connect(_on_enemy_turn_started)
	CombatManager.enemy_attack_performed.connect(_on_enemy_attack_performed)
	CombatManager.combat_log_updated.connect(_on_combat_log_updated)
	_update_display()
	_update_enemy_hp_display()
	_update_player_hp_display()
	_update_press_turn_display()
	_update_combat_controls()
	_update_enemy_behavior_display()
	_update_player_weakness_display()
	_update_combat_log_display()

func _on_player_attack_performed(_attack_value: int) -> void:
	# Present the resolved damage type, affinity, and outcome without moving
	# combat rules into the Battle UI.
	action_resolving = false
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label == null:
		_update_combat_controls()
		return

	var affinity_name := AFFINITIES.get_display_name(CombatManager.get_last_player_affinity())
	var damage_type_name := DAMAGE_TYPES.get_display_name(CombatManager.get_last_player_damage_type())
	var result_type: String = CombatManager.get_last_player_result_type()
	var damage: int = CombatManager.get_last_damage()
	var critical: bool = CombatManager.get_last_player_critical()

	if CombatManager.is_victory():
		if critical:
			action_label.text = "CRITICAL! Enemy defeated. %s attack dealt %d damage." % [damage_type_name, damage]
		else:
			action_label.text = "Enemy defeated. %s attack dealt %d damage." % [damage_type_name, damage]
	elif result_type == "miss":
		action_label.text = "%s attack MISSED. No damage dealt." % damage_type_name
	elif result_type == "drain":
		action_label.text = "%s attack DRAINED %d HP from the enemy. (%s)" % [damage_type_name, damage, affinity_name]
	elif result_type == "repel":
		action_label.text = "%s attack was REPELLED. %d damage reflected to Player. (%s)" % [damage_type_name, damage, affinity_name]
	elif affinity_name == "Null":
		action_label.text = "%s attack was NULLIFIED. No damage dealt." % damage_type_name
	elif critical:
		action_label.text = "CRITICAL! %s attack dealt %d damage. (%s)" % [damage_type_name, damage, affinity_name]
	else:
		action_label.text = "%s attack dealt %d damage. (%s)" % [damage_type_name, damage, affinity_name]

	_update_enemy_hp_display()
	_update_player_hp_display()
	_update_press_turn_display()
	_update_combat_controls()
	_update_combat_log_display()

func _on_press_turns_changed(_remaining: float) -> void:
	_update_press_turn_display()
	_update_combat_controls()

func _on_defend_pressed() -> void:
	if action_resolving:
		return
	action_resolving = true
	if CombatManager.player_defend():
		var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
		if action_label != null:
			action_label.text = "Player DEFENDS. Incoming damage will be reduced on the enemy turn."
		if not CombatManager.is_enemy_turn():
			action_resolving = false
	else:
		action_resolving = false
	_update_combat_controls()

func _on_pass_pressed() -> void:
	if action_resolving:
		return
	action_resolving = true
	if CombatManager.player_pass():
		var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
		if action_label != null:
			action_label.text = "Player passes the turn."
		if not CombatManager.is_enemy_turn():
			action_resolving = false
	else:
		action_resolving = false
	_update_combat_controls()

func _on_enemy_turn_started() -> void:
	action_resolving = true
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label != null:
		action_label.text = "ENEMY TURN: resolving enemy action..."
	_update_combat_controls()

func _on_enemy_attack_performed(damage: int) -> void:
	# Show the enemy action and resolved damage after the enemy turn completes.
	action_resolving = false
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label != null:
		var action_name := CombatManager.get_last_enemy_action_name()
		if CombatManager.is_defeat():
			action_label.text = "%s deals %d damage. PLAYER DEFEATED." % [action_name, damage]
		else:
			action_label.text = "%s deals %d damage. PLAYER TURN." % [action_name, damage]
	_update_player_hp_display()
	_update_press_turn_display()
	_update_combat_controls()

func _update_player_weakness_display() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/PlayerWeaknessLabel")
	if label == null:
		return
	label.text = "Player Weakness: %s" % CombatManager.get_player_weakness_debug()

func _update_enemy_behavior_display() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyBehaviorLabel")
	if label == null:
		return
	label.text = "Enemy Behavior: %s" % CombatManager.get_enemy_behavior_profile_name()

func _update_combat_log_display() -> void:
	var scroll := get_node_or_null("CenterContainer/Panel/VBoxContainer/CombatLogScroll") as ScrollContainer
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/CombatLogScroll/CombatLogLabel")
	if scroll == null or label == null:
		return
	var entries: Array[String] = CombatManager.get_combat_log()
	label.text = "\n".join(entries)
	call_deferred("_scroll_combat_log_to_latest")

func _scroll_combat_log_to_latest() -> void:
	var scroll := get_node_or_null("CenterContainer/Panel/VBoxContainer/CombatLogScroll") as ScrollContainer
	if scroll == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _update_enemy_hp_display() -> void:
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyHPLabel")
	var hp_bar := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyHPBar") as ProgressBar
	if hp_label == null:
		return
	var hp := CombatManager.get_enemy_hp()
	var max_hp := CombatManager.get_enemy_max_hp()
	hp_label.text = "Enemy HP: %d / %d" % [hp, max_hp]
	if hp_bar != null:
		hp_bar.max_value = max_hp
		hp_bar.value = hp

func _update_player_hp_display() -> void:
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/PlayerHPLabel")
	var hp_bar := get_node_or_null("CenterContainer/Panel/VBoxContainer/PlayerHPBar") as ProgressBar
	if hp_label == null:
		return
	var stats: Dictionary = GameState.get_player_stats()
	var hp: int = stats.get("hp", 0)
	var max_hp: int = stats.get("max_hp", 0)
	hp_label.text = "Player HP: %d / %d" % [hp, max_hp]
	if hp_bar != null:
		hp_bar.max_value = max_hp
		hp_bar.value = hp

func _update_press_turn_display() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/PressTurnLabel")
	if label == null:
		return
	var remaining := CombatManager.get_player_press_turns_remaining()
	var full_turns := int(floor(remaining))
	var half_turn := is_equal_approx(remaining - float(full_turns), 0.5)
	var symbols := ""
	for i in range(full_turns):
		symbols += "● "
	if half_turn:
		symbols += "◐ "
	label.text = "Press Turns: " + symbols.strip_edges()

func _update_combat_controls() -> void:
	var attack_button := get_node_or_null("BottomActionBar/ActionVBox/AttackButton") as Button
	var fire_button := get_node_or_null("BottomActionBar/ActionVBox/FireButton") as Button
	var defend_button := get_node_or_null("BottomActionBar/ActionVBox/DefendButton") as Button
	var pass_button := get_node_or_null("BottomActionBar/ActionVBox/PassButton") as Button
	var run_button := get_node_or_null("BottomActionBar/ActionVBox/RunButton") as Button
	var victory_button := get_node_or_null("BottomActionBar/ActionVBox/VictoryButton") as Button
	var state_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/StateLabel")
	if attack_button == null or fire_button == null or defend_button == null or pass_button == null or run_button == null or victory_button == null:
		return

	var victory := CombatManager.is_victory()
	var defeat := CombatManager.is_defeat()
	var player_turn := CombatManager.is_player_turn()
	var locked := action_resolving or not player_turn

	attack_button.disabled = victory or defeat or locked
	fire_button.disabled = victory or defeat or locked
	defend_button.disabled = victory or defeat or locked
	pass_button.disabled = victory or defeat or locked
	run_button.disabled = victory or defeat or locked
	run_button.visible = not victory and not defeat and player_turn
	victory_button.visible = victory
	if state_label != null:
		if victory:
			state_label.text = "VICTORY"
		elif defeat:
			state_label.text = "DEFEAT"
		elif action_resolving and CombatManager.is_enemy_turn():
			state_label.text = "ENEMY TURN"
		else:
			state_label.text = "PLAYER TURN"

func _on_attack_pressed() -> void:
	if action_resolving:
		return
	action_resolving = true
	if not CombatManager.player_attack():
		action_resolving = false
	_update_combat_controls()

func _on_fire_pressed() -> void:
	if action_resolving:
		return
	action_resolving = true
	if not CombatManager.player_attack(FIRE_ACTION):
		action_resolving = false
	_update_combat_controls()

func _on_run_pressed() -> void:
	if action_resolving:
		return
	CombatManager.end_combat()

func _on_victory_pressed() -> void:
	CombatManager.end_combat()

func _update_display() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EncounterLabel")
	if label == null:
		return
	var enemy_id: String = CombatManager.get_active_enemy_id()
	label.text = "Combat Encounter: %s" % (enemy_id if not enemy_id.is_empty() else "Unknown")
