extends Node2D
## Defines the physical limits of the playable World area.
##
## This script is responsible only for creating and configuring the World
## boundary collision. It does not move the Player or control the camera.
## The World scene owns this node so the playable area remains a World concern.
##
## The boundary is generated from the configured world bounds instead of
## hard-coding four unrelated collision positions into the scene. This keeps
## the system easy to resize later when the World grows beyond the current
## test area.

@export var left_bound: float = -1000.0
@export var right_bound: float = 1000.0
@export var top_bound: float = -1500.0
@export var bottom_bound: float = 1500.0

@export var boundary_thickness: float = 32.0


func _ready() -> void:
	# Build the four physical walls when the World loads.
	# Each wall is a StaticBody2D because the boundaries never move.
	_create_boundary("TopBoundary", Vector2(left_bound, top_bound), Vector2(right_bound, top_bound), true)
	_create_boundary("BottomBoundary", Vector2(left_bound, bottom_bound), Vector2(right_bound, bottom_bound), true)
	_create_boundary("LeftBoundary", Vector2(left_bound, top_bound), Vector2(left_bound, bottom_bound), false)
	_create_boundary("RightBoundary", Vector2(right_bound, top_bound), Vector2(right_bound, bottom_bound), false)


func _create_boundary(
	boundary_name: String,
	start_point: Vector2,
	end_point: Vector2,
	is_horizontal: bool
) -> void:
	# Create a static physics body for one side of the World.
	var body := StaticBody2D.new()
	body.name = boundary_name
	add_child(body)

	# Create the collision shape that will physically block the Player.
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	body.add_child(collision)

	# Calculate the wall's center and length from the configured World bounds.
	var center := (start_point + end_point) / 2.0
	var length := start_point.distance_to(end_point)

	# A rectangle is used for each wall. Horizontal walls use width for their
	# length, while vertical walls use height for their length.
	var shape := RectangleShape2D.new()

	if is_horizontal:
		shape.size = Vector2(length, boundary_thickness)
	else:
		shape.size = Vector2(boundary_thickness, length)

	collision.shape = shape
	body.position = center
