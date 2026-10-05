extends Node
## Handles transitions between game scenes and places the Player at the
## requested entry position after the new scene has finished loading.
##
## This script owns scene-transition coordination only. Individual doors
## decide which scene should be entered, while SceneManager performs the
## actual transition and Player placement.
##
## Scene changes are deferred because Doors receive body_entered signals
## during physics processing. Removing the current scene from inside that
## callback is unsafe in Godot, so the actual transition is performed later.

var pending_player_position: Vector2
var has_pending_player_position: bool = false
var transition_in_progress: bool = false


func change_scene(scene_path: String, player_position: Vector2) -> void:
	# Ignore additional transition requests while the current transition
	# is waiting for Godot to finish changing scenes.
	if transition_in_progress:
		return

	if scene_path.is_empty():
		push_error("SceneManager cannot change to an empty scene path.")
		return

	# Store the destination Player position before the current scene is
	# removed. The Player node from the old scene will not survive the change.
	pending_player_position = player_position
	has_pending_player_position = true
	transition_in_progress = true

	# Defer the actual scene change until the physics callback that requested
	# it has finished. This prevents Godot from removing CollisionObject2D
	# nodes while the physics engine is still processing the Door signal.
	call_deferred("_perform_scene_change", scene_path)


func _perform_scene_change(scene_path: String) -> void:
	# Ask Godot to replace the current scene now that the physics callback
	# that requested the transition has completed.
	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		has_pending_player_position = false
		transition_in_progress = false
		push_error(
			"SceneManager could not change scene to: %s (error %d)"
			% [scene_path, error]
		)
		return

	# SceneTree changes the current scene after the new scene has been
	# loaded and added to the tree. Waiting for scene_changed guarantees
	# that current_scene points to the destination before we find Player.
	await get_tree().scene_changed

	_place_player()


func _place_player() -> void:
	if not has_pending_player_position:
		transition_in_progress = false
		return

	var current_scene := get_tree().current_scene

	if current_scene == null:
		push_error("SceneManager could not find the new current scene.")
		has_pending_player_position = false
		transition_in_progress = false
		return

	var player := current_scene.get_node_or_null("Player") as Node2D

	if player == null:
		push_error(
			"SceneManager could not find a Player node in scene: %s"
			% current_scene.scene_file_path
		)
		has_pending_player_position = false
		transition_in_progress = false
		return

	# Place the new Player at the destination position supplied by the Door.
	# The destination scene's camera can then center itself on this position
	# during its own _ready() processing.
	player.position = pending_player_position
	has_pending_player_position = false
	transition_in_progress = false
