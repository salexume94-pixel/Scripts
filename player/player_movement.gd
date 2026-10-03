extends Node
## Handles player movement.
##
## This script is responsible only for movement and movement input.
## It reads the player's movement inputs, calculates the movement direction,
## applies the movement speed, and then moves the CharacterBody2D.

# Movement speed measured in pixels per second.
# This can be changed in the Godot Inspector.
@export var move_speed: float = 200.0

# Reference to the CharacterBody2D that owns this movement component.
# The actual movement is performed on this player node.
var player: CharacterBody2D


func _ready() -> void:
	# The movement script is expected to be a child of the player's
	# CharacterBody2D, so get_parent() gives us the player node.
	player = get_parent() as CharacterBody2D


func _physics_process(_delta: float) -> void:
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
