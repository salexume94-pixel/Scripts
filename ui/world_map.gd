extends Control
## Presents the reusable player-facing world map.
##
## This script owns only map presentation. WorldMapData provides coordinate
## conversion, WorldLocationData provides location identity/positions, and
## MapManager provides the Player's current runtime map position.
##
## Press M to open or close the map. The map is deliberately simple for this
## foundation pass: a map panel, world title, location markers, labels, and
## the current Player marker. More advanced cartography can be added later
## without changing the underlying world/map data model.

const WORLD_LOCATION_DATABASE = preload("res://world/world_location_database.gd")

@export var map_rect: Rect2 = Rect2(230.0, 90.0, 692.0, 500.0)

var _map_open: bool = false
var _font: Font

func _ready() -> void:
	# Cache the default font once because the map is redrawn frequently while
	# the Player marker moves.
	_font = ThemeDB.fallback_font
	visible = false
	set_process(true)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# Toggle the map with M without adding another project-wide input action.
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	if key_event.physical_keycode == KEY_M or key_event.keycode == KEY_M:
		_map_open = not _map_open
		visible = _map_open
		queue_redraw()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# Keep the runtime map position synchronized with the active World Player.
	var player := get_tree().get_first_node_in_group("player") as Node2D

	if player != null and not SceneManager.current_world_id.is_empty():
		MapManager.update_player_position(
			SceneManager.current_world_id,
			player.global_position
		)

	if _map_open:
		queue_redraw()

func _draw() -> void:
	if not _map_open:
		return

	# Dim the game behind the map so the map reads as a focused overlay.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.02, 0.78))

	# Draw the main map panel and a simple border.
	draw_rect(map_rect, Color(0.08, 0.10, 0.08, 0.98), true)
	draw_rect(map_rect, Color(0.70, 0.72, 0.65, 1.0), false, 3.0)

	var map_data := MapManager.get_current_map()

	if map_data == null:
		draw_string(_font, Vector2(40.0, 60.0), "MAP DATA UNAVAILABLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		return

	# Display the current world name using map metadata rather than a hard-coded
	# string in the UI.
	var title := str(map_data.get("display_name"))
	draw_string(_font, Vector2(40.0, 50.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28)

	# Draw a light grid to make the logical map coordinate space visible.
	_draw_grid(map_rect)

	# Draw every registered location belonging to the current world.
	for location_resource in WORLD_LOCATION_DATABASE.get_all_locations():
		if location_resource == null:
			continue

		if str(location_resource.get("world_id")) != MapManager.current_world_id:
			continue

		if not bool(location_resource.get("map_visible")):
			continue

		var location_map_position_variant = location_resource.get("map_position")
		if not location_map_position_variant is Vector2:
			continue

		var location_map_position := location_map_position_variant as Vector2
		_draw_location_marker(location_resource, location_map_position)

	# Draw the Player after locations so the current position is always visible.
	if MapManager.has_player_position:
		_draw_player_marker(MapManager.current_map_position)

	draw_string(
		_font,
		Vector2(40.0, size.y - 24.0),
		"M: Close Map",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18
	)

func _draw_grid(panel: Rect2) -> void:
	# The grid is presentation-only. It does not alter the logical map data.
	var columns := 8
	var rows := 8

	for column in range(1, columns):
		var x := panel.position.x + panel.size.x * float(column) / float(columns)
		draw_line(
			Vector2(x, panel.position.y),
			Vector2(x, panel.end.y),
			Color(0.35, 0.40, 0.35, 0.35),
			1.0
		)

	for row in range(1, rows):
		var y := panel.position.y + panel.size.y * float(row) / float(rows)
		draw_line(
			Vector2(panel.position.x, y),
			Vector2(panel.end.x, y),
			Color(0.35, 0.40, 0.35, 0.35),
			1.0
		)

func _draw_location_marker(location: Resource, map_position: Vector2) -> void:
	var map_data := MapManager.get_current_map()

	if map_data == null:
		return

	var logical_bounds: Rect2 = map_data.get("map_bounds")
	var screen_position := _map_to_screen_position(logical_bounds, map_position)

	var location_type := int(location.get("location_type"))
	var marker_radius := 7.0 if location_type == 1 else 5.0

	draw_circle(screen_position, marker_radius, Color(0.85, 0.85, 0.78, 1.0))
	draw_circle(screen_position, marker_radius + 2.0, Color(0.15, 0.18, 0.15, 1.0), false, 1.5)

	var label := str(location.get("display_name"))
	draw_string(
		_font,
		screen_position + Vector2(10.0, 5.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		15
	)

func _draw_player_marker(map_position: Vector2) -> void:
	var map_data := MapManager.get_current_map()

	if map_data == null:
		return

	var logical_bounds: Rect2 = map_data.get("map_bounds")
	var normalized := Vector2(
		inverse_lerp(logical_bounds.position.x, logical_bounds.end.x, map_position.x),
		inverse_lerp(logical_bounds.position.y, logical_bounds.end.y, map_position.y)
	)

	var screen_position := Vector2(
		lerp(map_rect.position.x, map_rect.end.x, normalized.x),
		lerp(map_rect.position.y, map_rect.end.y, normalized.y)
	)

	# The Player marker is intentionally distinct from location markers.
	draw_circle(screen_position, 8.0, Color(0.95, 0.95, 0.95, 1.0))
	draw_circle(screen_position, 4.0, Color(0.15, 0.35, 0.90, 1.0))
	draw_circle(screen_position, 10.0, Color(0.90, 0.90, 0.90, 0.9), false, 2.0)


func _map_to_screen_position(logical_bounds: Rect2, map_position: Vector2) -> Vector2:
	# Convert logical map coordinates into the visible panel. Keeping this
	# conversion in one helper keeps location and Player markers consistent.
	var normalized := Vector2(
		inverse_lerp(logical_bounds.position.x, logical_bounds.end.x, map_position.x),
		inverse_lerp(logical_bounds.position.y, logical_bounds.end.y, map_position.y)
	)

	return Vector2(
		lerp(map_rect.position.x, map_rect.end.x, normalized.x),
		lerp(map_rect.position.y, map_rect.end.y, normalized.y)
	)
