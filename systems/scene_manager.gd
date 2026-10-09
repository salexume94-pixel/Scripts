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

# Identifies the world/location that owns the current scene transition context.
# This survives scene replacement so generic interior exit doors know which
# world location they are returning to.
var current_world_id: String = ""
var current_location_id: String = ""

# Stores the exact Player position outside the building that was entered.
# The reusable Interior scene uses this when the Player leaves, so every
# building returns the Player to the doorway they actually entered rather than
# to one hard-coded town-center coordinate.
var return_player_position: Vector2 = Vector2.ZERO
var has_return_player_position: bool = false

# The transition overlay belongs to this persistent autoload, so it stays
# visible while the old scene is removed and the destination scene is loaded.
var transition_overlay: ColorRect
var transition_label: Label


func _ready() -> void:
	# Build a lightweight transition screen in code. Keeping it here avoids
	# requiring every town, interior, and battle scene to duplicate the same UI.
	var canvas := CanvasLayer.new()
	canvas.name = "TransitionCanvas"
	canvas.layer = 200
	add_child(canvas)

	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_overlay.visible = false
	canvas.add_child(transition_overlay)

	transition_label = Label.new()
	transition_label.name = "TransitionMessage"
	transition_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.add_theme_font_size_override("font_size", 28)
	transition_overlay.add_child(transition_label)


func change_scene(
    scene_path: String,
    player_position: Vector2,
    world_id: String = "",
    location_id: String = "",
    return_position: Vector2 = Vector2.ZERO,
    set_return_position: bool = false
) -> void:
	# Ignore additional transition requests while the current transition
	# is waiting for Godot to finish changing scenes.
	if transition_in_progress:
		return

	if scene_path.is_empty():
		push_error("SceneManager cannot change to an empty scene path.")
		return

	# Update the persistent world/location context when a Door supplies it.
	# Interior exit Doors can then inherit the same context when they are
	# created from the reusable Interior scene.
	if not world_id.is_empty():
		current_world_id = world_id
	if not location_id.is_empty():
		current_location_id = location_id

	# When entering an interior, preserve the exact overworld position where
	# the Player interacted with the building. The reusable interior ExitDoor
	# can then return the Player to that same doorway instead of a fixed point.
	if set_return_position:
		return_player_position = return_position
		has_return_player_position = true

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
	# Show a short fade and destination label before replacing the current scene.
	# This also hides any one-frame visual pop while Godot loads the destination.
	transition_label.text = _get_transition_message(scene_path)
	transition_overlay.visible = true
	transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	await _fade_transition_to(Color(0.0, 0.0, 0.0, 1.0), 0.12)

	# The original request can come from a physics callback, so the actual scene
	# replacement still happens only after the callback has finished.
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		has_pending_player_position = false
		push_error(
			"SceneManager could not change scene to: %s (error %d)"
			% [scene_path, error]
		)
		await _fade_transition_to(Color(0.0, 0.0, 0.0, 0.0), 0.18)
		transition_overlay.visible = false
		transition_in_progress = false
		return

	# Wait until the destination is active before placing the Player. Battle
	# scenes intentionally have no Player node, which _place_player handles.
	await get_tree().scene_changed
	_place_player()

	# Keep the destination title visible briefly so the transition reads as
	# intentional, without turning a quick scene change into a long loading wait.
	await get_tree().create_timer(0.22).timeout
	await _fade_transition_to(Color(0.0, 0.0, 0.0, 0.0), 0.18)
	transition_overlay.visible = false
	transition_in_progress = false


func _fade_transition_to(target_color: Color, duration: float) -> void:
	# Tween the overlay color instead of blocking the main thread; scene loading
	# and gameplay remain managed by Godot's normal SceneTree lifecycle.
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color", target_color, duration)
	await tween.finished


func _get_transition_message(destination_path: String) -> String:
	# Use destination/source scene paths rather than hard-coded town names so
	# future locations can reuse the same transition screen without new scripts.
	if destination_path.ends_with("/Battle.tscn"):
		return "Battle begins"
	if destination_path.ends_with("/MainMenu.tscn"):
		return "Returning to menu"
	if destination_path.contains("/interiors/"):
		return "Entering building"
	if destination_path.ends_with("/World.tscn") or destination_path.contains("/locations/"):
		return "Entering town"

	var current_scene := get_tree().current_scene
	if current_scene != null:
		var current_path: String = current_scene.scene_file_path
		var current_is_town := (
			current_path.ends_with("/World.tscn")
			or current_path.contains("/locations/")
		)
		if current_is_town and destination_path.contains("WorldMap"):
			return "Leaving town"

	return "Loading..."


func _place_player() -> void:
	if not has_pending_player_position:
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		push_error("SceneManager could not find the new current scene.")
		has_pending_player_position = false
		return

	var player := current_scene.get_node_or_null("Player") as Node2D

	# Battle scenes intentionally do not contain a Player node. The transition
	# still completes normally; the saved return position remains with CombatManager.
	if player == null:
		has_pending_player_position = false
		return

	# Place the new Player at the destination position supplied by the Door or
	# CombatManager before the transition screen fades away.
	player.position = pending_player_position
	has_pending_player_position = false
