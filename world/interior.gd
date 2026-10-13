extends Node2D
## Defines the physical boundaries of a simple building interior.
##
## This script owns the interior room's static collision only. It does not
## control the Player, the Door, or scene transitions.
##
## The Player collision radius is 16px, while the current Player visual
## extends 20px from its center vertically and horizontally. The interior
## walls are therefore positioned 4px inside the visible room edge so the
## larger Player visual cannot overlap the border before its collision stops.
##
## The bottom wall is split around the ExitDoor so the Player has a real
## opening to leave the interior.

@export var interior_size: Vector2 = Vector2(480.0, 320.0)
@export var door_width: float = 48.0

const WALL_THICKNESS := 16.0
const PLAYER_VISUAL_CLEARANCE := 4.0


func _ready() -> void:
	# Build the three complete walls and the two bottom wall segments.
	# StaticBody2D is used because the room boundaries never move.
	_create_wall(
		"TopWall",
		Vector2(interior_size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS),
		Vector2(
			0.0,
			-interior_size.y / 2.0
			+ PLAYER_VISUAL_CLEARANCE
			- WALL_THICKNESS / 2.0
		)
	)
	_create_wall(
		"LeftWall",
		Vector2(WALL_THICKNESS, interior_size.y + WALL_THICKNESS * 2.0),
		Vector2(
			-interior_size.x / 2.0
			+ PLAYER_VISUAL_CLEARANCE
			- WALL_THICKNESS / 2.0,
			0.0
		)
	)
	_create_wall(
		"RightWall",
		Vector2(WALL_THICKNESS, interior_size.y + WALL_THICKNESS * 2.0),
		Vector2(
			interior_size.x / 2.0
			- PLAYER_VISUAL_CLEARANCE
			+ WALL_THICKNESS / 2.0,
			0.0
		)
	)

	# Split the bottom wall around the doorway so the ExitDoor is an actual
	# opening in the room instead of a trigger placed on top of solid wall.
	var segment_width := (interior_size.x - door_width) / 2.0
	var segment_x := door_width / 2.0 + segment_width / 2.0

	_create_wall(
		"BottomLeftWall",
		Vector2(segment_width, WALL_THICKNESS),
		Vector2(
			-segment_x,
			interior_size.y / 2.0
			- PLAYER_VISUAL_CLEARANCE
			+ WALL_THICKNESS / 2.0
		)
	)
	_create_wall(
		"BottomRightWall",
		Vector2(segment_width, WALL_THICKNESS),
		Vector2(
			segment_x,
			interior_size.y / 2.0
			- PLAYER_VISUAL_CLEARANCE
			+ WALL_THICKNESS / 2.0
		)
	)


func _create_wall(
	wall_name: String,
	size: Vector2,
	position: Vector2
) -> void:
	# Create one immovable collision wall and configure its rectangle.
	var body := StaticBody2D.new()
	body.name = wall_name
	add_child(body)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	body.add_child(collision)

	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.position = position
