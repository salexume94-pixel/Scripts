extends Node2D
## Presents the playable overworld travel space.
##
## This scene owns the physical presentation of the larger world. Location
## identity comes from WorldLocationData resources, while SceneManager handles
## the actual scene transition. This keeps town entrances data-driven so future
## towns can be added without creating a new hard-coded Door for each one.

const WORLD_LOCATION_DATABASE = preload("res://world/world_location_database.gd")

var transition_started: bool = false

# Stores the current location marker while an entry transition is being built.
# It must be available to the transition handler, not just the region-creation loop.
var active_world_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Build automatic entry regions for every world location that declares an
	# entry point in this world. Each region is a non-solid Area2D, so the
	# Player can approach a town from north, south, east, or west.
	_create_location_entry_regions()

	_create_location_markers()


func _create_location_entry_regions() -> void:
	for location in WORLD_LOCATION_DATABASE.get_all_locations():
		if location == null:
			continue

		# Only definitions owned by this playable world can create entry
		# regions here. Other worlds remain registered for their own scenes.
		if location.get("world_id") != "world_map":
			continue

		if not bool(location.get("entry_enabled")):
			continue

		var world_position_variant = location.get("world_position")
		var entry_size_variant = location.get("world_entry_size")

		if not world_position_variant is Vector2:
			push_error(
				"WorldMapWorld entry location has invalid world_position: %s"
				% location.get("location_id")
			)
			continue

		if not entry_size_variant is Vector2:
			push_error(
				"WorldMapWorld entry location has invalid world_entry_size: %s"
				% location.get("location_id")
			)
			continue

		var area := Area2D.new()
		area.name = "LocationEntry_%s" % String(location.get("location_id"))
		area.collision_layer = 0
		area.collision_mask = 1
		area.position = world_position_variant
		add_child(area)

		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"

		var shape := RectangleShape2D.new()
		shape.size = entry_size_variant
		collision.shape = shape

		area.add_child(collision)

		# Bind the location resource so the same handler can transition into
		# any future town or other world location.
		area.body_entered.connect(
			_on_location_entry_body_entered.bind(location)
		)


func _on_location_entry_body_entered(body: Node2D, location: Resource) -> void:
	# Only the Player can activate a world-location entry region.
	if transition_started:
		return

	if not body.is_in_group("player"):
		return

	var target_scene := String(location.get("entry_scene"))
	var target_world_id := String(location.get("entry_world_id"))
	var target_location_id := String(location.get("entry_location_id"))
	var target_player_position_variant = location.get("entry_player_position")

	if target_scene.is_empty():
		push_error(
			"World location has no entry_scene: %s"
			% location.get("location_id")
		)
		return

	if target_world_id.is_empty():
		push_error(
			"World location has no entry_world_id: %s"
			% location.get("location_id")
		)
		return

	if target_location_id.is_empty():
		push_error(
			"World location has no entry_location_id: %s"
			% location.get("location_id")
		)
		return

	if not target_player_position_variant is Vector2:
		push_error(
			"World location has invalid entry_player_position: %s"
			% location.get("location_id")
		)
		return

	transition_started = true

	# Enter the destination scene without requiring the Player to interact with
	# a Door. The destination data determines the Player's starting position.
	var destination_position := target_player_position_variant
	var approach_direction := _get_entry_direction(body.global_position, world_position_variant)

	# Enter the town on the same side from which the Player approached its
	# World Map marker rather than always using one fixed spawn point.
	if approach_direction.x != 0.0:
		destination_position.x += approach_direction.x * 100.0
	else:
		destination_position.y += approach_direction.y * 100.0

	SceneManager.change_scene(
		target_scene,
		destination_position,
		target_world_id,
		target_location_id
	)


func _create_location_markers() -> void:
	# Create physical town markers from WorldLocationData so new towns
	# automatically appear on the playable World Map.
	for location in WORLD_LOCATION_DATABASE.get_all_locations():
		if location == null:
			continue

		if str(location.get("world_id")) != "world_map":
			continue

		if not bool(location.get("map_visible")):
			continue

		var world_position_variant = location.get("world_position")
		if not world_position_variant is Vector2:
			continue

		var marker := Polygon2D.new()
		marker.name = "LocationMarker_%s" % String(location.get("location_id"))
		marker.polygon = PackedVector2Array([
			Vector2(-80.0, -60.0),
			Vector2(80.0, -60.0),
			Vector2(80.0, 60.0),
			Vector2(-80.0, 60.0),
		])
		marker.color = Color(0.28, 0.28, 0.32, 1.0)
		marker.position = world_position_variant
		$WorldMapContent.add_child(marker)

		var label := Label.new()
		label.name = "LocationLabel_%s" % String(location.get("location_id"))
		label.text = str(location.get("display_name")).to_upper()
		label.position = world_position_variant + Vector2(-90.0, -80.0)
		$WorldMapContent.add_child(label)


func _get_entry_direction(player_position: Vector2, location_position: Vector2) -> Vector2:
	# Determine which cardinal side of the town marker the Player approached.
	var relative := player_position - location_position
	if absf(relative.x) > absf(relative.y):
		return Vector2(sign(relative.x), 0.0)
	return Vector2(0.0, sign(relative.y))
