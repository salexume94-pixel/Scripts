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
	# Refresh the placeholder display from CombatManager so the Battle scene
	# visibly confirms which encounter is currently active.
	_update_display()


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
