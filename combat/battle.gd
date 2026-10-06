extends Control
## Presents the first placeholder Battle scene for the combat foundation.
##
## This script is intentionally limited to combat presentation and the basic
## Battle-scene lifecycle. It does not calculate damage, store enemy stats, or
## decide combat actions. Those responsibilities will be added in later
## Combat Foundation steps.
##
## CombatManager owns the active combat state and handles entering/leaving the
## Battle scene.

func _ready() -> void:
	# Connect to CombatManager so the Battle UI refreshes whenever combat state
	# changes, then populate the initial screen from the active encounter.
	CombatManager.player_attack_performed.connect(_on_player_attack_performed)
	_update_display()
	_update_enemy_hp_display()
	_update_combat_controls()


func _on_player_attack_performed(attack_value: int) -> void:
	# CombatManager has already calculated and applied the attack damage.
	# The Battle UI only presents the result and updates the available controls.
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label == null:
		return
	if CombatManager.is_victory():
		action_label.text = "Enemy defeated!"
	else:
		action_label.text = "Player attacks for %d damage." % CombatManager.get_last_damage()
	_update_enemy_hp_display()
	_update_combat_controls()


func _update_enemy_hp_display() -> void:
	# Display the current enemy HP supplied by CombatManager.
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyHPLabel")
	if hp_label == null:
		return
	hp_label.text = "Enemy HP: %d / %d" % [
		CombatManager.get_enemy_hp(),
		CombatManager.get_enemy_max_hp(),
	]


func _update_combat_controls() -> void:
	# Attack remains available during combat. When the enemy reaches zero HP,
	# the encounter is resolved as Victory and the player receives a return path.
	var attack_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/AttackButton") as Button
	var run_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/RunButton") as Button
	var victory_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/VictoryButton") as Button
	var state_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/StateLabel")

	if attack_button == null or run_button == null or victory_button == null:
		return

	var victory := CombatManager.is_victory()
	attack_button.disabled = victory
	run_button.visible = not victory
	victory_button.visible = victory

	if state_label != null:
		state_label.text = "VICTORY" if victory else "Combat Foundation"


func _on_attack_pressed() -> void:
	# Ask CombatManager to perform the combat action. The Battle UI does not
	# calculate or modify combat values itself.
	CombatManager.player_attack()


func _on_run_pressed() -> void:
	# Run immediately ends the active encounter and returns the Player to the
	# scene and position recorded before entering Battle.
	CombatManager.end_combat()


func _on_victory_pressed() -> void:
	# Victory currently returns to the originating World scene. Rewards will be
	# added later by the progression and loot systems.
	CombatManager.end_combat()


func _update_display() -> void:
	# The first combat step only needs enough presentation to prove that the
	# combat state reached the Battle scene. Future steps will replace this
	# placeholder with real combat controls and combat information.
	var encounter_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EncounterLabel")
	if encounter_label == null:
		return

	var enemy_id: String = CombatManager.get_active_enemy_id()
	if enemy_id.is_empty():
		enemy_id = "Unknown"

	encounter_label.text = "Combat Encounter: %s" % enemy_id
