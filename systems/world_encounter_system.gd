extends Node
## Triggers random enemy encounters while the Player travels through the World.
##
## This system owns overworld encounter timing only. CombatManager remains
## responsible for creating and running the actual battle. An encounter uses
## the configured enemy definition, so combat remains the authoritative source
## for encounter state and enemy data.

@export var enemy_id: String = "slime"
@export_range(16.0, 512.0) var distance_between_checks: float = 64.0
@export_range(0.0, 1.0) var encounter_chance: float = 0.5

var player: Node2D = null
var last_player_position: Vector2 = Vector2.ZERO
var distance_since_check: float = 0.0
var encounter_started: bool = false

# SceneManager places the Player after the destination scene has loaded. Ignore
# the first movement sample so the spawn-position correction is never mistaken
# for travel distance that should trigger a random encounter.
var tracking_initialized: bool = false


func _ready() -> void:
	# World owns the Player, so resolve it once when the encounter system starts.
	# Do not begin distance tracking yet: SceneManager may still need to place
	# the Player at the requested town-exit or overworld-entry position.
	player = get_parent().get_node_or_null("Player") as Node2D
	tracking_initialized = false


func _process(_delta: float) -> void:
	if encounter_started or player == null:
		return

	# Seed the tracker from the Player's actual position after the scene has
	# loaded. The first frame is deliberately not eligible for an encounter roll.
	if not tracking_initialized:
		last_player_position = player.global_position
		distance_since_check = 0.0
		tracking_initialized = true
		return

	# A debug-menu toggle can suspend random encounters without changing the
	# configured enemy, probability, or distance threshold. Reset tracking while
	# disabled so re-enabling encounters never triggers an immediate stale roll.
	if not GameState.overworld_encounters_enabled:
		last_player_position = player.global_position
		distance_since_check = 0.0
		return
	if GameState.is_encounter_cooldown_active():
		# Ignore movement while the post-combat cooldown is active. This prevents
		# Run from immediately producing another encounter.
		last_player_position = player.global_position
		distance_since_check = 0.0
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
	# the World scene, then creates the authoritative battle state.
	if CombatManager.start_encounter(enemy_id):
		encounter_started = true
