extends Node
## Handles player movement and forwards movement state to the visual animation controller.
##
## Movement remains separate from rendering: this script reads arrow-key input,
## calculates velocity, and asks PlayerAnimationController to show the matching
## idle, walking, or running animation.

# Normal walking speed measured in pixels per second.
@export var move_speed: float = 225.0

# Holding Shift multiplies walking speed. Shift is the only run control.
@export var run_speed_multiplier: float = 1.6

# Reference to the CharacterBody2D that owns this movement component.
var player: CharacterBody2D

# The animation controller is responsible for directional sprite frames.
var animation_controller: Node

# Movement can be temporarily disabled by game UI such as the Character screen.
var movement_enabled: bool = true

# Named locks allow multiple systems to stop movement independently.
var movement_locks: Dictionary = {}


func _ready() -> void:
	# The movement script is expected to be a child of the Player CharacterBody2D.
	player = get_parent() as CharacterBody2D
	animation_controller = player.get_node_or_null("PlayerAnimationController")

	# DialogueManager owns conversation state. Dialogue locks movement while open.
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_cleared.connect(_on_dialogue_cleared)

	# A Player created while dialogue is already active must also remain locked.
	if DialogueManager.is_active:
		set_movement_lock("dialogue", true)


func _physics_process(_delta: float) -> void:
	# Stop both movement and movement animations during transitions, menus, or locks.
	if player == null:
		return

	if (
		SceneManager.transition_in_progress
		or not movement_enabled
		or not movement_locks.is_empty()
	):
		player.velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO, false)
		return

	# Read only the four arrow keys. WASD is intentionally not used for movement.
	# Normalizing the vector prevents diagonal movement from being faster.
	var direction := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	).normalized()

	# Shift is the only run control. Releasing it immediately restores walking speed.
	var is_running := direction != Vector2.ZERO and Input.is_key_pressed(KEY_SHIFT)
	var current_speed := move_speed
	if is_running:
		current_speed *= run_speed_multiplier

	# Update the animation from actual input state, preserving the last facing
	# direction whenever the Player stops moving.
	_update_animation(direction, is_running)

	# Convert direction into velocity and let CharacterBody2D handle collisions.
	player.velocity = direction * current_speed
	player.move_and_slide()


func _update_animation(direction: Vector2, is_running: bool) -> void:
	# Keep movement independent from sprite implementation so animation changes
	# do not alter collision, movement speed, or other Player systems.
	if animation_controller != null and animation_controller.has_method("update_motion"):
		animation_controller.update_motion(direction, is_running)


func set_movement_enabled(enabled: bool) -> void:
	# Public control point for menus and other gameplay states that disable movement.
	movement_enabled = enabled

	if not enabled and player != null:
		player.velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO, false)


func set_movement_lock(lock_name: String, locked: bool) -> void:
	# Unlocking one system cannot re-enable movement while another lock remains.
	if locked:
		movement_locks[lock_name] = true
	else:
		movement_locks.erase(lock_name)

	if player != null and (
		not movement_enabled or not movement_locks.is_empty()
	):
		player.velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO, false)


func _on_dialogue_started(_speaker_name: String, _dialogue_text: String) -> void:
	# Stop immediately when shared dialogue opens.
	set_movement_lock("dialogue", true)


func _on_dialogue_cleared() -> void:
	# Release only the dialogue lock when the conversation is dismissed.
	set_movement_lock("dialogue", false)
