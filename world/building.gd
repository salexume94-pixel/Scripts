extends Node2D
## Defines the reusable presentation and physical footprint of a World building.
##
## This script is intentionally small. The Building scene owns the building's
## local setup, while the World scene decides where the building is placed.
## Interaction, doors, and interiors will be separate systems later.
##
## The current building is a simple rectangular test structure. Its visual
## and collision are kept separate so the presentation can eventually be
## replaced without changing the physical wall layout.

const BUILDING_SIZE := Vector2(192.0, 128.0)
const WALL_THICKNESS := 16.0


func _ready() -> void:
    # Configure the four wall collision shapes around the building footprint.
    # The walls block the Player from entering the test building.
    _configure_wall($BuildingCollision/TopWall, Vector2(BUILDING_SIZE.x, WALL_THICKNESS))
    _configure_wall($BuildingCollision/BottomWall, Vector2(BUILDING_SIZE.x, WALL_THICKNESS))
    _configure_wall($BuildingCollision/LeftWall, Vector2(WALL_THICKNESS, BUILDING_SIZE.y))
    _configure_wall($BuildingCollision/RightWall, Vector2(WALL_THICKNESS, BUILDING_SIZE.y))


func _configure_wall(wall: CollisionShape2D, size: Vector2) -> void:
    # Each wall uses its own RectangleShape2D so the building collision
    # remains simple, predictable, and easy to resize later.
    var shape := RectangleShape2D.new()
    shape.size = size
    wall.shape = shape
