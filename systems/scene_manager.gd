extends Node
## Handles transitions between game scenes and places the Player at the
## requested entry position after the new scene has loaded.
##
## This script owns scene-transition coordination only. Individual doors
## decide which scene should be entered, while SceneManager performs the
## actual transition and Player placement.
##
## Keeping this responsibility global prevents every Door or world object
## from implementing its own scene-loading and spawn logic.

var pending_player_position: Vector2
var has_pending_player_position: bool = false


func change_scene(scene_path: String, player_position: Vector2) -> void:
    # Store the position before changing scenes because the current Player
    # node will be destroyed when the old scene is replaced.
    pending_player_position = player_position
    has_pending_player_position = true

    # Ask Godot to replace the current scene with the requested scene.
    var error := get_tree().change_scene_to_file(scene_path)

    if error != OK:
        has_pending_player_position = false
        push_error(
            "SceneManager could not change scene to: %s (error %d)"
            % [scene_path, error]
        )
        return

    # Wait until the new scene has been added to the scene tree before
    # searching for its Player node and applying the requested position.
    call_deferred("_place_player")


func _place_player() -> void:
    if not has_pending_player_position:
        return

    # The deferred call gives Godot time to finish constructing the new
    # scene before we try to access its Player.
    await get_tree().process_frame

    var current_scene := get_tree().current_scene

    if current_scene == null:
        push_error("SceneManager could not find the new current scene.")
        has_pending_player_position = false
        return

    var player := current_scene.get_node_or_null("Player") as Node2D

    if player == null:
        push_error(
            "SceneManager could not find a Player node in scene: %s"
            % current_scene.scene_file_path
        )
        has_pending_player_position = false
        return

    # Place the new Player at the position supplied by the Door that started
    # the transition.
    player.position = pending_player_position
    has_pending_player_position = false
