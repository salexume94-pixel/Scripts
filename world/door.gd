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

var transition_started: bool = false


func _ready() -> void:
    # Register this Door with the shared interaction system so E can select it.
    add_to_group("interactable")


func interact(_player: Node) -> void:
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

    # SceneManager performs the actual scene replacement and Player placement.
    SceneManager.change_scene(target_scene, target_player_position)
