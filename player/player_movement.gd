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


func _ready() -> void:
	# The movement script is expected to be a child of the player's
	# CharacterBody2D, so get_parent() gives us the player node.
	player = get_parent() as CharacterBody2D


func _physics_process(_delta: float) -> void:
	# Stop here if movement has been disabled by another gameplay system, such
	# as a full-screen Character/Inventory menu.
	if not movement_enabled:
		player.velocity = Vector2.ZERO
		return

	# Stop here if the player reference could not be found.
	# This prevents errors when trying to move a nonexistent player.
	if player == null:
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
