extends Node2D
## Defines the reusable presentation and physical footprint of a World building.
##
## This script owns the Building's local visual footprint and wall collision.
## It does not move the Player, control the camera, or handle interaction.
##
## The collision walls are placed at the visual edges of the Building. This
## keeps the physical boundary aligned with what the player sees instead of
## hiding the wall inside the building graphic.

const BUILDING_SIZE := Vector2(192.0, 128.0)
const WALL_THICKNESS := 16.0


func _ready() -> void:
    # Place each wall so its inner edge is aligned with the corresponding
    # edge of the visual building footprint. The wall itself extends outward,
    # leaving the Building interior clear while preventing visual overlap.
    _configure_wall(
        $BuildingCollision/TopWall,
        Vector2(BUILDING_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS),
        Vector2(0.0, -BUILDING_SIZE.y / 2.0 - WALL_THICKNESS / 2.0)
    )
    _configure_wall(
        $BuildingCollision/BottomWall,
        Vector2(BUILDING_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS),
        Vector2(0.0, BUILDING_SIZE.y / 2.0 + WALL_THICKNESS / 2.0)
    )
    _configure_wall(
        $BuildingCollision/LeftWall,
        Vector2(WALL_THICKNESS, BUILDING_SIZE.y),
        Vector2(-BUILDING_SIZE.x / 2.0 - WALL_THICKNESS / 2.0, 0.0)
    )
    _configure_wall(
        $BuildingCollision/RightWall,
        Vector2(WALL_THICKNESS, BUILDING_SIZE.y),
        Vector2(BUILDING_SIZE.x / 2.0 + WALL_THICKNESS / 2.0, 0.0)
    )


func _configure_wall(
    wall: CollisionShape2D,
    size: Vector2,
    position: Vector2
) -> void:
    # Create the rectangle used by this wall and assign its local position.
    # Keeping this setup in one helper makes all four walls use the same
    # collision construction rules.
    var shape := RectangleShape2D.new()
    shape.size = size
    wall.shape = shape
    wall.position = position
