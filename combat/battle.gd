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
	CombatManager.combat_log_updated.connect(_update_combat_log)
	_update_display()
	_update_enemy_ai_profile_display()
	_update_enemy_hp_display()
	_update_press_turn_display()
	_update_combat_controls()
	_update_combat_log()
	_update_player_affinities()

func _on_player_attack_performed(_attack_value: int) -> void:
	# Keep the action label concise. The combat log contains the resolved damage,
	# affinity, and special result details.
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label == null:
		return
	var damage_type_name := DAMAGE_TYPES.get_display_name(CombatManager.get_last_player_damage_type())
	action_label.text = "PLAYER ACTION: %s" % damage_type_name
	_update_enemy_hp_display()
	_update_player_hp_display()
	_update_press_turn_display()
	_update_combat_controls()
func _on_press_turns_changed(_remaining: float) -> void:
	_update_press_turn_display()
	_update_combat_controls()

func _on_defend_pressed() -> void:
	if CombatManager.player_defend():
		CombatManager.add_combat_log("PLAYER: Defend.")
		var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
		if action_label != null:
			action_label.text = "PLAYER ACTION: Defend."

func _on_pass_pressed() -> void:
	if CombatManager.player_pass():
		CombatManager.add_combat_log("PLAYER: Pass.")
		var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
		if action_label != null:
			action_label.text = "PLAYER ACTION: Pass."

func _on_enemy_turn_started() -> void:
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label != null:
		action_label.text = "ENEMY TURN"
	_update_combat_controls()

func _on_enemy_attack_performed(_damage: int) -> void:
	# Keep the action label focused on the AI decision. The combat log records
	# the enemy action and resolved damage separately.
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label != null:
		action_label.text = "AI SELECTED: %s" % CombatManager.get_last_enemy_action_name()
	_update_player_hp_display()
	_update_press_turn_display()
	_update_combat_controls()
func _update_enemy_ai_profile_display() -> void:
	# Present the profile chosen for this specific encounter so runtime testing
	# does not depend on reading the debug console.
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyAIProfileLabel")
	if label == null:
		return
	label.text = "Enemy AI Profile: %s" % CombatManager.get_enemy_behavior_profile_name().capitalize()

func _update_enemy_hp_display() -> void:
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyHPLabel")
	if hp_label == null:
		return
	hp_label.text = "ENEMY HP: %d / %d" % [CombatManager.get_enemy_hp(), CombatManager.get_enemy_max_hp()]

func _update_player_hp_display() -> void:
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/PlayerHPLabel")
	if hp_label == null:
		return
	var stats: Dictionary = GameState.get_player_stats()
	var hp: int = stats.get("hp", 0)
	var max_hp: int = stats.get("max_hp", 0)
	hp_label.text = "PLAYER HP: %d / %d" % [hp, max_hp]

func _update_player_affinities() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/PlayerAffinityLabel")
	if label == null:
		return
	label.text = "Player Weakness: %s" % CombatManager.get_player_weakness_debug()

func _update_combat_log() -> void:
	var log := get_node_or_null("CenterContainer/Panel/VBoxContainer/CombatLog")
	if log == null:
		return
	log.text = "\n".join(CombatManager.get_combat_log())
	log.scroll_to_line(maxi(log.get_line_count() - 1, 0))

func _update_press_turn_display() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/PressTurnLabel")
	if label == null:
		return
	var remaining: float = CombatManager.get_player_press_turns_remaining()
	var full_turns := int(floor(remaining))
	var half_turn := is_equal_approx(remaining - float(full_turns), 0.5)
	var symbols := ""
	for i in range(full_turns):
		symbols += "● "
	if half_turn:
		symbols += "◐ "
	label.text = "Press Turns: " + symbols.strip_edges()

func _update_combat_controls() -> void:
	var attack_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionButtons/AttackButton") as Button
	var fire_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionButtons/FireButton") as Button
	var defend_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionButtons/DefendButton") as Button
	var pass_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionButtons/PassButton") as Button
	var critical_test_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionButtons/CriticalTestButton") as Button
	var miss_test_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionButtons/MissTestButton") as Button
	var run_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionButtons/RunButton") as Button
	var cycle_weakness_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/WeaknessControls/CycleWeaknessButton") as Button
	var victory_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/VictoryButton") as Button
	var state_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/StateLabel")
	if attack_button == null or fire_button == null or defend_button == null or pass_button == null or run_button == null or cycle_weakness_button == null or victory_button == null:
		return
	if critical_test_button == null or miss_test_button == null:
		return
	var victory: bool = CombatManager.is_victory()
	var defeat: bool = CombatManager.is_defeat()
	var player_turn: bool = CombatManager.is_player_turn()
	attack_button.disabled = victory or defeat or not player_turn
	fire_button.disabled = victory or defeat or not player_turn
	defend_button.disabled = victory or defeat or not player_turn
	pass_button.disabled = victory or defeat or not player_turn
	critical_test_button.disabled = victory or defeat or not player_turn
	miss_test_button.disabled = victory or defeat or not player_turn
	run_button.visible = not victory and not defeat and player_turn
	cycle_weakness_button.disabled = victory or defeat or not player_turn
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

func _on_cycle_weakness_pressed() -> void:
	if CombatManager.cycle_player_weakness():
		_update_player_affinities()

func _on_victory_pressed() -> void:
	CombatManager.end_combat()

func _update_display() -> void:
	var label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EncounterLabel")
	if label == null:
		return
	var enemy_id: String = CombatManager.get_active_enemy_id()
	label.text = "Combat Encounter: %s" % (enemy_id if not enemy_id.is_empty() else "Unknown")
