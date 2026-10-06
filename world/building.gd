extends Node2D
## Defines the reusable presentation, physical footprint, and destination identity
## of a World building.
##
## Each building declares its world and location identity plus the interior scene
## it belongs to. The Door receives that configuration at runtime, preventing a
## building on one world map from silently using another world's destination.
##
## This script owns the Building's local visual footprint and wall collision.
## It does not move the Player, control the camera, or handle interaction.

@export var world_id: String = ""
@export var location_id: String = ""
@export_file("*.tscn") var interior_scene: String = ""

const BUILDING_SIZE := Vector2(192.0, 128.0)
const WALL_THICKNESS := 16.0
const DOOR_WIDTH := 48.0


func _ready() -> void:
    # A Building configures its own Door so destination data stays attached to
    # the building instance rather than being hidden in a shared Door scene.
    var door := $Door
    door.world_id = world_id
    door.location_id = location_id
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
