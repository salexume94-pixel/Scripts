extends Node2D
## Defines the reusable presentation, physical footprint, and location identity
## of a World building.
##
## Each building references a WorldLocationData resource instead of storing
## player-facing location metadata directly in the scene. This keeps the
## building reusable and makes its location identity part of the same data
## foundation used by the future map system.
##
## This script owns the Building's local visual footprint and wall collision.
## It does not move the Player, control the camera, or handle interaction.

## Shared location definition for this building.
##
## The resource supplies the stable world/location IDs that are passed to the
## Door, so a building cannot silently point at a different world location.
@export var location_data: WorldLocationData

@export_file("*.tscn") var interior_scene: String = ""

const BUILDING_SIZE := Vector2(192.0, 128.0)
const WALL_THICKNESS := 16.0
const DOOR_WIDTH := 48.0


func _ready() -> void:
    # Every World building must have a location definition. Failing loudly
    # here catches incomplete map integration during development instead of
    # allowing the Door to carry empty or incorrect identity data.
    if location_data == null:
        push_error("Building '%s' has no WorldLocationData assigned." % name)
        return

    if location_data.location_id.is_empty():
        push_error("Building '%s' has a WorldLocationData with no location_id." % name)
        return

    if location_data.world_id.is_empty():
        push_error("Building '%s' has a WorldLocationData with no world_id." % name)
        return

    # A Building configures its own Door so destination identity stays attached
    # to the building instance rather than being hidden in a shared Door scene.
    var door := $Door
    door.world_id = location_data.world_id
    door.location_id = location_data.location_id
    door.target_scene = interior_scene

    var half_width := BUILDING_SIZE.x / 2.0
    var half_height := BUILDING_SIZE.y / 2.0
    var collision_half_width := half_width + WALL_THICKNESS / 2.0
    var collision_half_height := half_height + WALL_THICKNESS / 2.0

    _configure_wall(
        $BuildingCollision/TopWall,
        Vector2(collision_half_width * 2.0, WALL_THICKNESS),
        Vector2(0.0, -half_height)
    )

    _configure_wall(
        $BuildingCollision/LeftWall,
        Vector2(WALL_THICKNESS, BUILDING_SIZE.y - WALL_THICKNESS),
        Vector2(-half_width, 0.0)
    )
    _configure_wall(
        $BuildingCollision/RightWall,
        Vector2(WALL_THICKNESS, BUILDING_SIZE.y - WALL_THICKNESS),
        Vector2(half_width, 0.0)
    )

    var bottom_total_width := collision_half_width * 2.0
    var bottom_segment_width := (bottom_total_width - DOOR_WIDTH) / 2.0
    var bottom_segment_offset := DOOR_WIDTH / 2.0 + bottom_segment_width / 2.0

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
    var shape := RectangleShape2D.new()
    shape.size = size
    wall.shape = shape
    wall.position = position
