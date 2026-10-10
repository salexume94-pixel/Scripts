extends Node
## Provides the authoritative catalog of world map definitions.
##
## Map definitions describe how each playable world is represented on the
## player-facing map. The database is intentionally separate from the UI so
## additional worlds can be registered without changing map presentation code.

const MAP_DEFINITIONS: Array[Resource] = [
	preload("res://world/definitions/havenreach_map.tres"),
	preload("res://world/definitions/tutorial_town_map.tres"),
	preload("res://world/definitions/northbridge_village_map.tres"),
	preload("res://world/definitions/world_map.tres"),
]

static func get_map(world_id: String) -> Resource:
	# Resolve the map definition from its stable world ID.
	for map_data in MAP_DEFINITIONS:
		if map_data != null and map_data.get("world_id") == world_id:
			return map_data
	return null

static func get_all_maps() -> Array[Resource]:
	# Return a copy so callers cannot modify the authoritative catalog.
	return MAP_DEFINITIONS.duplicate()
