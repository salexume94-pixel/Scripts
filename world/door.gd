extends StaticBody2D
## Handles a reusable doorway that transitions the Player to another scene.
##
## The Door carries the world/location identity supplied by its parent Building.
## This makes each doorway explicitly belong to the world map that owns it and
## prevents future maps from relying on an unrelated shared destination.

@export_file("*.tscn") var target_scene: String
@export var target_player_position: Vector2 = Vector2.ZERO
@export var world_id: String = ""
@export var location_id: String = ""
@export var use_return_position: bool = false

var transition_started: bool = false


func _ready() -> void:
    # Register this Door with the shared interaction system so E can select it.
    add_to_group("interactable")

    # Interior exit doors are intentionally generic reusable scenes. When such
    # a Door has no explicit world/location identity, inherit the location that
    # opened the current scene from SceneManager.
    if world_id.is_empty() and not SceneManager.current_world_id.is_empty():
        world_id = SceneManager.current_world_id
    if location_id.is_empty() and not SceneManager.current_location_id.is_empty():
        location_id = SceneManager.current_location_id


func interact(player: Node) -> void:
    # The shared InteractionSystem calls this method when the Player presses E.
    if transition_started:
        return

    if world_id.is_empty():
        push_error("Door has no world_id configured.")
        return

    if location_id.is_empty():
        push_error("Door has no location_id configured.")
        return

    if target_scene.is_empty():
        push_error("Door has no target scene configured.")
        return

    transition_started = true

    # Interior exits use the exact world position where the Player entered the
    # building. This prevents every building from returning to town center.
    var destination_position := target_player_position
    if use_return_position and SceneManager.has_return_player_position:
        destination_position = SceneManager.return_player_position

    # A Door leading into an interior records the Player's current world
    # position before the scene is replaced. The reusable interior can then
    # restore that position when its ExitDoor is used.
    var should_set_return_position := not use_return_position
    var return_position := player.global_position

    SceneManager.change_scene(
        target_scene,
        destination_position,
        world_id,
        location_id,
        return_position,
        should_set_return_position
    )
