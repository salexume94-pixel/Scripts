extends Node
## Triggers random enemy encounters while the Player travels through the World.
##
## This system owns overworld encounter timing only. CombatManager remains
## responsible for creating and running the actual battle. An encounter uses
## the requested enemy definition, allowing CombatManager to select that
## enemy's behavior profile when the battle starts.

@export var enemy_id: String = "slime"
@export_range(16.0, 512.0) var distance_between_checks: float = 64.0
@export_range(0.0, 1.0) var encounter_chance: float = 0.5

var player: Node2D = null
var last_player_position: Vector2 = Vector2.ZERO
var distance_since_check: float = 0.0
var encounter_started: bool = false


func _ready() -> void:
	# World owns the Player, so resolve it once when the encounter system starts.
	player = get_parent().get_node_or_null("Player") as Node2D
	if player != null:
		last_player_position = player.global_position


func _process(_delta: float) -> void:
	if encounter_started or player == null:
		return
	if CombatManager.is_in_combat():
		return

	var current_position := player.global_position
	var movement_distance: float = last_player_position.distance_to(current_position)
	last_player_position = current_position

	if movement_distance <= 0.0:
		return

	distance_since_check += movement_distance
	if distance_since_check < distance_between_checks:
		return

	# Consume the distance threshold even when no encounter occurs so the
	# Player gets another independent encounter roll after traveling farther.
	distance_since_check = 0.0

	if randf() > encounter_chance:
		return

	# CombatManager captures the Player's current position before replacing
	# the World scene, then selects the encounter's AI behavior profile.
	if CombatManager.start_encounter(enemy_id):
		encounter_started = true
