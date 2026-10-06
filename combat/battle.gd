extends Control
## Presents Battle state and forwards player input to CombatManager.
##
## CombatManager owns Press Turns and combat rules. This script only presents
## their current state and handles Battle button input.

func _ready() -> void:
	CombatManager.player_attack_performed.connect(_on_player_attack_performed)
	CombatManager.player_press_turns_changed.connect(_on_press_turns_changed)
	CombatManager.enemy_turn_started.connect(_on_enemy_turn_started)
	_update_display()
	_update_enemy_hp_display()
	_update_press_turn_display()
	_update_combat_controls()

func _on_player_attack_performed(_attack_value: int) -> void:
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label == null:
		return
	if CombatManager.is_victory():
		action_label.text = "Enemy defeated!"
	elif CombatManager.is_enemy_turn():
		action_label.text = "Player attacks for %d damage. Enemy turn." % CombatManager.get_last_damage()
	else:
		action_label.text = "Player attacks for %d damage." % CombatManager.get_last_damage()
	_update_enemy_hp_display()
	_update_press_turn_display()
	_update_combat_controls()

func _on_press_turns_changed(_remaining: float) -> void:
	_update_press_turn_display()
	_update_combat_controls()

func _on_enemy_turn_started() -> void:
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label != null:
		action_label.text = "Player turn complete. Enemy turn."
	_update_combat_controls()

func _update_enemy_hp_display() -> void:
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyHPLabel")
	if hp_label == null:
		return
	hp_label.text = "Enemy HP: %d / %d" % [CombatManager.get_enemy_hp(), CombatManager.get_enemy_max_hp()]

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
	var run_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/RunButton") as Button
	var victory_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/VictoryButton") as Button
	var state_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/StateLabel")
	if attack_button == null or run_button == null or victory_button == null:
		return
	var victory := CombatManager.is_victory()
	var player_turn := CombatManager.is_player_turn()
	attack_button.disabled = victory or not player_turn
	run_button.visible = not victory and player_turn
	victory_button.visible = victory
	if state_label != null:
		if victory:
			state_label.text = "VICTORY"
		elif CombatManager.is_enemy_turn():
			state_label.text = "ENEMY TURN"
		else:
			state_label.text = "PLAYER TURN"

func _on_attack_pressed() -> void:
	CombatManager.player_attack()
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
