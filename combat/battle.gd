extends Control

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
const AFFINITIES = preload("res://combat/affinities.gd")
const FIRE_ACTION = preload("res://combat/definitions/fire_attack.tres")
## Presents Battle state and forwards player input to CombatManager.
##
## CombatManager owns Press Turns and combat rules. This script only presents
## their current state and handles Battle button input.

func _ready() -> void:
	CombatManager.player_attack_performed.connect(_on_player_attack_performed)
	CombatManager.player_press_turns_changed.connect(_on_press_turns_changed)
	CombatManager.enemy_turn_started.connect(_on_enemy_turn_started)
	CombatManager.enemy_attack_performed.connect(_on_enemy_attack_performed)
	_update_display()
	_update_enemy_hp_display()
	_update_press_turn_display()
	_update_combat_controls()

func _on_player_attack_performed(_attack_value: int) -> void:
	# Present the resolved damage type and affinity without moving combat rules
	# into the Battle UI.
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label == null:
		return

	var affinity_name := AFFINITIES.get_display_name(CombatManager.get_last_player_affinity())
	var damage_type_name := DAMAGE_TYPES.get_display_name(CombatManager.get_last_player_damage_type())
	var result_type := CombatManager.get_last_player_result_type()
	var damage := CombatManager.get_last_damage()
	var critical: bool = CombatManager.get_last_player_critical()

	if critical:
		action_label.text = "PLAYER: CRITICAL! Player %s attack deals %d damage (%s)." % [damage_type_name, damage, affinity_name]
	elif CombatManager.is_victory():
		action_label.text = "PLAYER: Enemy defeated! %s %s." % [damage_type_name, affinity_name]
	elif result_type == "miss":
		action_label.text = "PLAYER: %s attack misses (%s)." % [damage_type_name, affinity_name]
	elif result_type == "drain":
		action_label.text = "PLAYER: %s attack drains %d HP (%s)." % [damage_type_name, damage, affinity_name]
	elif result_type == "repel":
		action_label.text = "PLAYER: %s attack is repelled (%s)." % [damage_type_name, affinity_name]
	elif CombatManager.is_enemy_turn():
		action_label.text = "PLAYER: %s attack deals %d damage (%s). ENEMY TURN." % [damage_type_name, damage, affinity_name]
	else:
		action_label.text = "PLAYER: %s attack deals %d damage (%s)." % [damage_type_name, damage, affinity_name]

	_update_enemy_hp_display()
	_update_player_hp_display()
	_update_press_turn_display()
	_update_combat_controls()

func _on_press_turns_changed(_remaining: float) -> void:
	_update_press_turn_display()
	_update_combat_controls()

func _on_defend_pressed() -> void:
	if CombatManager.player_defend():
		var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
		if action_label != null:
			action_label.text = "PLAYER: Defend." if CombatManager.is_player_turn() else "PLAYER: Defend. ENEMY TURN."

func _on_pass_pressed() -> void:
	if CombatManager.player_pass():
		var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
		if action_label != null:
			action_label.text = "PLAYER: Pass." if CombatManager.is_player_turn() else "PLAYER: Pass. ENEMY TURN."

func _on_enemy_turn_started() -> void:
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label != null:
		action_label.text = "ENEMY TURN: %s is choosing an action..." % CombatManager.get_active_enemy_name()
	_update_combat_controls()

func _on_enemy_attack_performed(damage: int) -> void:
	# Show the enemy actor and selected action explicitly so AI testing is
	# unambiguous even when the action name alone would not identify the actor.
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label != null:
		var enemy_name := CombatManager.get_active_enemy_name()
		var action_name := CombatManager.get_last_enemy_action_name()
		var ai_debug := CombatManager.get_last_enemy_ai_debug()
		var decision_text := "\n".join(ai_debug)
		if CombatManager.is_defeat():
			action_label.text = "ENEMY: %s uses %s for %d damage. PLAYER DEFEATED.\n%s" % [enemy_name, action_name, damage, decision_text]
		else:
			action_label.text = "ENEMY: %s uses %s for %d damage. PLAYER TURN.\n%s" % [enemy_name, action_name, damage, decision_text]
	_update_player_hp_display()
	_update_press_turn_display()
	_update_combat_controls()

func _update_enemy_hp_display() -> void:
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyHPLabel")
	if hp_label == null:
		return
	hp_label.text = "Enemy HP: %d / %d" % [CombatManager.get_enemy_hp(), CombatManager.get_enemy_max_hp()]

func _update_player_hp_display() -> void:
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/PlayerHPLabel")
	if hp_label == null:
		return
	var stats: Dictionary = GameState.get_player_stats()
	var hp: int = stats.get("hp", 0)
	var max_hp: int = stats.get("max_hp", 0)
	hp_label.text = "Player HP: %d / %d" % [hp, max_hp]

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
	var attack_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/AttackButton") as Button
	var fire_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/FireButton") as Button
	var defend_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/DefendButton") as Button
	var pass_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/PassButton") as Button
	var critical_test_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/CriticalTestButton") as Button
	var miss_test_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/MissTestButton") as Button
	var run_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/RunButton") as Button
	var victory_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/VictoryButton") as Button
	var state_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/StateLabel")
	if attack_button == null or fire_button == null or defend_button == null or pass_button == null or run_button == null or victory_button == null:
		return
	if critical_test_button == null or miss_test_button == null:
		return
	var victory := CombatManager.is_victory()
	var defeat := CombatManager.is_defeat()
	var player_turn := CombatManager.is_player_turn()
	attack_button.disabled = victory or defeat or not player_turn
	fire_button.disabled = victory or defeat or not player_turn
	defend_button.disabled = victory or defeat or not player_turn
	pass_button.disabled = victory or defeat or not player_turn
	critical_test_button.disabled = victory or defeat or not player_turn
	miss_test_button.disabled = victory or defeat or not player_turn
	run_button.visible = not victory and not defeat and player_turn
	victory_button.visible = victory
	if state_label != null:
		if victory:
			state_label.text = "VICTORY"
		elif defeat:
			state_label.text = "DEFEAT"
		elif CombatManager.is_enemy_turn():
			state_label.text = "ENEMY TURN"
		else:
			state_label.text = "PLAYER TURN"

func _on_attack_pressed() -> void:
	CombatManager.player_attack()

func _on_fire_pressed() -> void:
	CombatManager.player_attack(FIRE_ACTION)

func _on_critical_test_pressed() -> void:
	CombatManager.player_critical_test()

func _on_miss_test_pressed() -> void:
	CombatManager.player_miss_test()

func _on_run_pressed() -> void:
	CombatManager.end_combat()

func _on_victory_pressed() -> void:
	CombatManager.end_combat()

func _update_display() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EncounterLabel")
	if label == null:
		return
	var enemy_id: String = CombatManager.get_active_enemy_id()
	label.text = "Combat Encounter: %s" % (enemy_id if not enemy_id.is_empty() else "Unknown")
