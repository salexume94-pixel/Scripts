extends Node2D
## Defines the reusable presentation and physical footprint of a World building.
##
## This script owns the Building's local visual footprint and wall collision.
## It does not move the Player, control the camera, or handle interaction.
##
## The collision walls form a clean rectangular outline around the visible
## Building. The wall rectangles meet at their edges instead of overlapping
## at the corners, which prevents the Player from being pushed or snagged
## while walking around the exterior.
##
## The bottom wall is split around the Door so the entrance remains a real
## physical opening.

const BUILDING_SIZE := Vector2(192.0, 128.0)
const WALL_THICKNESS := 16.0
const DOOR_WIDTH := 48.0
const PLAYER_VISUAL_CLEARANCE := 4.0


func _ready() -> void:
    # The visible Building extends 96 pixels left/right and 64 pixels
    # up/down from its center. The collision outline is placed outside that
    # footprint so the Player's visible sprite keeps a small visual gap.
    #
    # Each wall is positioned so adjacent walls meet cleanly at their edges.
    # This avoids overlapping collision rectangles at the corners, which was
    # causing the Player to be pushed away from the Building.
    var half_width := BUILDING_SIZE.x / 2.0
    var half_height := BUILDING_SIZE.y / 2.0

    var outer_half_width := half_width + PLAYER_VISUAL_CLEARANCE + 4.0
    var outer_half_height := half_height + PLAYER_VISUAL_CLEARANCE + 4.0

    var side_wall_height := BUILDING_SIZE.y - WALL_THICKNESS
    var bottom_segment_width := (BUILDING_SIZE.x + WALL_THICKNESS * 2.0 - DOOR_WIDTH) / 2.0
    var bottom_segment_offset := DOOR_WIDTH / 2.0 + bottom_segment_width / 2.0

    # Top wall:
    # Its outer edge reaches the same exterior boundary as the side walls.
    _configure_wall(
        $BuildingCollision/TopWall,
        Vector2(outer_half_width * 2.0, WALL_THICKNESS),
        Vector2(0.0, -half_height)
    )

    # Left and right walls:
    # Their height stops at the inner edge of the top/bottom walls so the
    # collision rectangles touch rather than overlap at the corners.
    _configure_wall(
        $BuildingCollision/LeftWall,
        Vector2(WALL_THICKNESS, side_wall_height),
        Vector2(-half_width, 0.0)
    )
    _configure_wall(
        $BuildingCollision/RightWall,
        Vector2(WALL_THICKNESS, side_wall_height),
        Vector2(half_width, 0.0)
    )

    # Bottom wall:
    # Split the wall around the Door so the entrance remains open. The two
    # segments extend to the same outer boundary as the side walls.
    _configure_wall(
        $BuildingCollision/BottomLeftWall,
        Vector2(bottom_segment_width, WALL_THICKNESS),
        Vector2(-bottom_segment_offset, half_height)
    )
    _configure_wall(
        $BuildingCollision/BottomRightWall,
        Vector2(bottom_segment_width, WALL_THICKNESS),
        Vector2(bottom_segment_offset, half_height)
    )


func _configure_wall(
    wall: CollisionShape2D,
    size: Vector2,
    position: Vector2
) -> void:
    # Create the rectangle used by this wall and assign its local position.
    # Keeping collision construction in one helper makes every wall follow
    # the same rules and keeps the Building scene itself simple.
    var shape := RectangleShape2D.new()
    shape.size = size
    wall.shape = shape
    wall.position = position
