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
	# Refresh the display when the Battle scene opens and listen for combat
	# actions so the UI can show the result of the Player Attack command.
	CombatManager.player_attack_performed.connect(_on_player_attack_performed)
	_update_display()
	_update_enemy_hp_display()


func _on_player_attack_performed(attack_value: int) -> void:
	# The first combat step records the Player's attack value but does not yet
	# apply damage. Enemy HP and damage calculation are separate later steps.
	var action_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/ActionLabel")
	if action_label == null:
		return
	action_label.text = "Player attacks for %d damage." % CombatManager.get_last_damage()
	_update_enemy_hp_display()


func _update_enemy_hp_display() -> void:
	# Display the current enemy HP supplied by CombatManager.
	var hp_label := get_node_or_null("CenterContainer/Panel/VBoxContainer/EnemyHPLabel")
	if hp_label == null:
		return
	hp_label.text = "Enemy HP: %d / %d" % [
		CombatManager.get_enemy_hp(),
		CombatManager.get_enemy_max_hp(),
	]


func _on_attack_pressed() -> void:
	# Ask CombatManager to perform the combat action. The Battle UI does not
	# calculate or modify combat values itself.
	CombatManager.player_attack()


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
