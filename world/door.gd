extends Area2D
## Handles a reusable doorway that transitions the Player to another scene.
##
## This script is responsible only for detecting the Player and requesting
## a scene transition. SceneManager owns the actual scene-loading work.
## The Door therefore remains a small world-interaction component that can
## be reused for entrances, exits, and future interior connections.

@export_file("*.tscn") var target_scene: String
@export var target_player_position: Vector2 = Vector2.ZERO

var transition_started: bool = false


func _ready() -> void:
    # Listen for bodies entering the doorway trigger so the Player can cross
    # the entrance without requiring a separate interaction system yet.
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
    # Ignore anything that is not the Player.
    if body.name != "Player":
        return

    # Prevent multiple transition requests if several physics frames detect
    # the Player while the scene is being replaced.
    if transition_started:
        return

    if target_scene.is_empty():
        push_error("Door has no target scene configured.")
        return

    transition_started = true

    # SceneManager performs the actual scene replacement and places the
    # Player at the configured entry position in the destination scene.
    SceneManager.change_scene(target_scene, target_player_position)
