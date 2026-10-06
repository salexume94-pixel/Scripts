extends StaticBody2D
## Handles a reusable doorway that transitions the Player to another scene.
##
## This script owns the Door's transition behavior and its physical blocking
## body. Interaction input is handled by the shared Player InteractionSystem,
## while SceneManager owns the actual scene-loading work.
##
## The Door is physically solid so the Player cannot simply walk through the
## doorway. Pressing E while nearby is the intentional transition action.

@export_file("*.tscn") var target_scene: String
@export var target_player_position: Vector2 = Vector2.ZERO

var transition_started: bool = false


func _ready() -> void:
	# Register this Door with the shared interaction system so E can select it.
	add_to_group("interactable")


func interact(_player: Node) -> void:
	# The shared InteractionSystem calls this method when the Player presses E
	# while close enough to this Door.
	if transition_started:
		return

	if target_scene.is_empty():
		push_error("Door has no target scene configured.")
		return

	transition_started = true

	# SceneManager performs the actual scene replacement and places the Player
	# at the configured entry position in the destination scene.
	SceneManager.change_scene(target_scene, target_player_position)
