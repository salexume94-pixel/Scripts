extends Node
## Handles player movement.
##
## This script is responsible only for movement and movement input.
## It reads the player's movement inputs, calculates the movement direction,
## applies the movement speed, and then moves the CharacterBody2D.

# Movement speed measured in pixels per second.
# This can be changed in the Godot Inspector.
@export var move_speed: float = 225.0

# Reference to the CharacterBody2D that owns this movement component.
# The actual movement is performed on this player node.
var player: CharacterBody2D

# Movement can be temporarily disabled by game UI such as the Character
# screen. Keeping this state here means the movement system remains the owner
# of whether movement input is currently allowed.
var movement_enabled: bool = true

# Named locks allow multiple systems to stop movement independently. For
# example, closing dialogue removes only the dialogue lock, not a menu lock.
var movement_locks: Dictionary = {}


func _ready() -> void:
	# The movement script is expected to be a child of the player's
	# CharacterBody2D, so get_parent() gives us the player node.
	player = get_parent() as CharacterBody2D

	# DialogueManager owns the conversation state. Connecting here lets every
	# Player instance stop while any shared NPC dialogue is open.
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_cleared.connect(_on_dialogue_cleared)

	# A Player created while dialogue is already active must also remain locked.
	if DialogueManager.is_active:
		set_movement_lock("dialogue", true)


func _physics_process(_delta: float) -> void:
	# Guard the Player reference first, then stop movement whenever either a
	# menu has disabled it or one or more gameplay systems hold a movement lock.
	if player == null:
		return
	if not movement_enabled or not movement_locks.is_empty():
		player.velocity = Vector2.ZERO
		return

	# Read the four directional movement actions and convert them
	# into a normalized Vector2 direction.
	#
	# ui_left  = move left
	# ui_right = move right
	# ui_up   = move up
	# ui_down = move down
	#
	# Input.get_vector() also prevents diagonal movement from being
	# faster than horizontal or vertical movement.
	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	# Convert the movement direction into a velocity.
	# Direction determines which way the player moves.
	# move_speed determines how fast the player moves.
	player.velocity = direction * move_speed

	# Move the CharacterBody2D using its calculated velocity.
	# move_and_slide() also handles collision-based sliding against
	# other physics bodies.
	player.move_and_slide()


func set_movement_enabled(enabled: bool) -> void:
	# Public control point for menus and other gameplay states that need to
	# temporarily prevent the Player from moving.
	movement_enabled = enabled

	if not enabled and player != null:
		# Clear existing velocity immediately so opening the menu also stops any
		# movement that was already in progress.
		player.velocity = Vector2.ZERO



func set_movement_lock(lock_name: String, locked: bool) -> void:
	# Locks are keyed by system name, so unlocking dialogue cannot accidentally
	# re-enable movement while another system still needs it disabled.
	if locked:
		movement_locks[lock_name] = true
	else:
		movement_locks.erase(lock_name)

	if player != null and (not movement_enabled or not movement_locks.is_empty()):
		player.velocity = Vector2.ZERO


func _on_dialogue_started(_speaker_name: String, _dialogue_text: String) -> void:
	# Stop immediately when the shared dialogue system opens an NPC conversation.
	set_movement_lock("dialogue", true)


func _on_dialogue_cleared() -> void:
	# Release only the dialogue lock when the conversation is dismissed.
	set_movement_lock("dialogue", false)
