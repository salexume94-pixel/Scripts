extends Node2D
## Defines the reusable presentation and physical footprint of a World building.
##
## This script owns the Building's local visual footprint and wall collision.
## It does not move the Player, control the camera, or handle interaction.
##
## The bottom wall is split around the Door so the entrance is a real opening.
## All other walls remain solid and aligned with the visible Building edge.

const BUILDING_SIZE := Vector2(192.0, 128.0)
const WALL_THICKNESS := 16.0
const DOOR_WIDTH := 48.0
const PLAYER_VISUAL_CLEARANCE := 4.0


func _ready() -> void:
    # Configure the three complete walls around the Building.
    _configure_wall(
        $BuildingCollision/TopWall,
        Vector2(BUILDING_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS),
        Vector2(0.0, -BUILDING_SIZE.y / 2.0 + WALL_THICKNESS / 2.0 - PLAYER_VISUAL_CLEARANCE)
    )
    _configure_wall(
        $BuildingCollision/LeftWall,
        Vector2(WALL_THICKNESS, BUILDING_SIZE.y),
        Vector2(-BUILDING_SIZE.x / 2.0 + WALL_THICKNESS / 2.0 - PLAYER_VISUAL_CLEARANCE, 0.0)
    )
    _configure_wall(
        $BuildingCollision/RightWall,
        Vector2(WALL_THICKNESS, BUILDING_SIZE.y),
        Vector2(BUILDING_SIZE.x / 2.0 - WALL_THICKNESS / 2.0 + PLAYER_VISUAL_CLEARANCE, 0.0)
    )

    # Split the bottom wall around the doorway. This creates a physical gap
    # that matches the Door's visible entrance instead of placing a trigger
    # on top of an otherwise impassable wall.
    var segment_width := (BUILDING_SIZE.x - DOOR_WIDTH) / 2.0
    var segment_x := DOOR_WIDTH / 2.0 + segment_width / 2.0

    _configure_wall(
        $BuildingCollision/BottomLeftWall,
        Vector2(segment_width, WALL_THICKNESS),
        Vector2(-segment_x, BUILDING_SIZE.y / 2.0 - WALL_THICKNESS / 2.0 + PLAYER_VISUAL_CLEARANCE)
    )
    _configure_wall(
        $BuildingCollision/BottomRightWall,
        Vector2(segment_width, WALL_THICKNESS),
        Vector2(segment_x, BUILDING_SIZE.y / 2.0 - WALL_THICKNESS / 2.0 + PLAYER_VISUAL_CLEARANCE)
    )


func _configure_wall(
    wall: CollisionShape2D,
    size: Vector2,
    position: Vector2
) -> void:
    # Create the rectangle used by this wall and assign its local position.
    # Keeping this setup in one helper makes every wall use the same collision
    # construction rules.
    var shape := RectangleShape2D.new()
    shape.size = size
    wall.shape = shape
    wall.position = position
