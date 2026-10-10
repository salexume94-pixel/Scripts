extends Node
## Handles player movement.
##
## This script is responsible only for movement and movement input.
## It reads the player's movement inputs, calculates the movement direction,
## applies the movement speed, and then moves the CharacterBody2D.

# Normal walking speed measured in pixels per second.
# This can be changed in the Godot Inspector.
@export var move_speed: float = 225.0

# Holding Shift multiplies walking speed. Shift is the only run control.
@export var run_speed_multiplier: float = 1.6

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
	# Guard the Player reference first, then stop movement whenever a transition,
	# menu, or gameplay movement lock says input must be ignored.
	if player == null:
		return

	# SceneManager sets transition_in_progress as soon as a scene change is
	# requested, before the fade begins. Checking this shared flag stops the
	# outgoing Player immediately and also keeps a newly created Player still
	# until the transition overlay has completely faded away.
	if (
		SceneManager.transition_in_progress
		or not movement_enabled
		or not movement_locks.is_empty()
	):
		player.velocity = Vector2.ZERO
		return

	# Use the four arrow keys directly so WASD is never treated as movement
	# input, even if someone later changes the project's UI input bindings.
	# Normalizing the vector prevents diagonal movement from being faster.
	var direction := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	).normalized()

	# Shift is the only run control. Releasing it immediately restores walking speed.
	var current_speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= run_speed_multiplier

	# Convert direction into velocity, then let CharacterBody2D handle movement
	# and collision sliding as before.
	player.velocity = direction * current_speed
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

	if player != null and (
		not movement_enabled or not movement_locks.is_empty()
	):
		player.velocity = Vector2.ZERO


func _on_dialogue_started(_speaker_name: String, _dialogue_text: String) -> void:
	# Stop immediately when the shared dialogue system opens an NPC conversation.
	set_movement_lock("dialogue", true)


func _on_dialogue_cleared() -> void:
	# Release only the dialogue lock when the conversation is dismissed.
	set_movement_lock("dialogue", false)
