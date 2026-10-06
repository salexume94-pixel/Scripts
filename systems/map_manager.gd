extends Node
## Owns the Player's current map/world position.
##
## MapManager is runtime state, not map presentation. It receives the Player's
## current gameplay position, converts it through WorldMapData, and keeps the
## resulting logical map position available to the UI and future map systems.
##
## This autoload survives scene changes, which prevents the map state from
## being tied to one particular World scene instance.

const WORLD_MAP_DATABASE = preload("res://world/world_map_database.gd")
const WORLD_LOCATION_DATABASE = preload("res://world/world_location_database.gd")

var current_world_id: String = ""
var current_world_position: Vector2 = Vector2.ZERO
var current_map_position: Vector2 = Vector2.ZERO
var has_player_position: bool = false

func update_player_position(world_id: String, world_position: Vector2) -> void:
	# Ignore empty world IDs because there is no map definition to resolve.
	if world_id.is_empty():
		return

	var map_data := WORLD_MAP_DATABASE.get_map(world_id)

	if map_data == null:
		push_error("MapManager could not find a map for world_id: %s" % world_id)
		return

	current_world_id = world_id
	current_world_position = world_position
	current_map_position = map_data.world_to_map(world_position)
	has_player_position = true

func get_current_map() -> Resource:
	# The current world determines which map should be presented.
	if current_world_id.is_empty():
		return null
	return WORLD_MAP_DATABASE.get_map(current_world_id)

func get_current_location() -> WorldLocationData:
	# SceneManager owns the authoritative location context. MapManager only
	# resolves that ID to shared location data when a caller needs it.
	if SceneManager.current_location_id.is_empty():
		return null
	return WORLD_LOCATION_DATABASE.get_location(SceneManager.current_location_id)
