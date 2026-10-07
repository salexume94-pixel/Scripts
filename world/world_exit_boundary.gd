extends Node2D

const WORLD_LOCATION_DATABASE = preload("res://world/world_location_database.gd")
## Creates a reusable transition boundary around a town or other contained
## world location.
##
## The boundary is intentionally made from Area2D trigger strips instead of
## physical walls. This lets the Player leave the location from any side.
## The destination is configured by the scene that owns this boundary, so
## future towns can reuse the same script with different bounds and targets.

@export var location_bounds: Rect2 = Rect2(-1000.0, -1500.0, 2000.0, 3000.0)
@export var trigger_thickness: float = 48.0

@export_file("*.tscn") var target_scene: String = ""
@export var target_player_position: Vector2 = Vector2.ZERO
@export var target_world_id: String = ""
@export var target_location_id: String = ""

var transition_started: bool = false

const WORLD_MAP_ENTRY_OFFSET: float = 100.0


func _ready() -> void:
	# Build four non-solid trigger strips just outside the location boundary.
	# Because the strips are outside the playable area, entering a town at a
	# normal spawn position cannot immediately trigger the exit transition.
	_create_boundary_trigger(
		"NorthExit",
		Vector2(location_bounds.position.x + location_bounds.size.x / 2.0,
		location_bounds.position.y - trigger_thickness / 2.0),
		Vector2(location_bounds.size.x + trigger_thickness * 2.0, trigger_thickness)
	)

	_create_boundary_trigger(
		"SouthExit",
		Vector2(location_bounds.position.x + location_bounds.size.x / 2.0,
		location_bounds.end.y + trigger_thickness / 2.0),
		Vector2(location_bounds.size.x + trigger_thickness * 2.0, trigger_thickness)
	)

	_create_boundary_trigger(
		"WestExit",
		Vector2(location_bounds.position.x - trigger_thickness / 2.0,
		location_bounds.position.y + location_bounds.size.y / 2.0),
		Vector2(trigger_thickness, location_bounds.size.y + trigger_thickness * 2.0)
	)

	_create_boundary_trigger(
		"EastExit",
		Vector2(location_bounds.end.x + trigger_thickness / 2.0,
		location_bounds.position.y + location_bounds.size.y / 2.0),
		Vector2(trigger_thickness, location_bounds.size.y + trigger_thickness * 2.0)
	)


func _create_boundary_trigger(
	trigger_name: String,
	trigger_position: Vector2,
	trigger_size: Vector2
) -> void:
	# Area2D detects the Player without physically blocking movement.
	# Godot's body_entered signal is appropriate here because Player is a
	# CharacterBody2D.
	var area := Area2D.new()
	area.name = trigger_name
	area.collision_layer = 0
	area.collision_mask = 1
	area.position = trigger_position
	add_child(area)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"

	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	collision.shape = shape

	area.add_child(collision)
	area.body_entered.connect(_on_exit_boundary_body_entered)


func _on_exit_boundary_body_entered(body: Node2D) -> void:
	# Only the Player can activate a world-location exit.
	if transition_started:
		return

	if not body.is_in_group("player"):
		return

	if target_scene.is_empty():
		push_error("WorldExitBoundary has no target scene configured.")
		return

	if target_world_id.is_empty():
		push_error("WorldExitBoundary has no target_world_id configured.")
		return

	if target_location_id.is_empty():
		push_error("WorldExitBoundary has no target_location_id configured.")
		return

	transition_started = true

	# The boundary transition behaves like a reusable world exit rather than
	# an interactable Door. The Player simply walks across the edge and the
	# owning world determines where the next scene begins.
	var destination_position := target_player_position
	if target_world_id == "world_map":
		destination_position = _get_world_map_exit_position(body.global_position)

	SceneManager.change_scene(
		target_scene,
		destination_position,
		target_world_id,
		target_location_id
	)


func _get_exit_direction(player_position: Vector2) -> Vector2:
	# Determine which cardinal side of the town boundary the Player crossed.
	var relative := player_position - location_bounds.get_center()
	if absf(relative.x) > absf(relative.y):
		return Vector2(sign(relative.x), 0.0)
	return Vector2(0.0, sign(relative.y))


func _get_world_map_exit_position(player_position: Vector2) -> Vector2:
	# Find the town's World Map definition and offset from its marker on the
	# same side the Player used to leave the town.
	var world_context := get_parent().get_node_or_null("WorldContext")
	if world_context == null:
		return target_player_position

	var location_id := String(world_context.get("location_id"))
	# World Map definitions use the "<location>_entry" ID because they represent
	# the entry point from the overworld into that location.
	var world_map_location := WORLD_LOCATION_DATABASE.get_location("%s_entry" % location_id)
	if world_map_location == null:
		push_warning("No World Map definition found for: %s" % location_id)
		return target_player_position

	var world_position_variant = world_map_location.get("world_position")
	if not world_position_variant is Vector2:
		return target_player_position

	return world_position_variant + _get_exit_direction(player_position) * WORLD_MAP_ENTRY_OFFSET
