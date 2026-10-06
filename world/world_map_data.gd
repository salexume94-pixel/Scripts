extends Resource
## Defines the map metadata and coordinate relationship for one world.
##
## WorldMapData is the bridge between gameplay world coordinates and the
## player-facing map coordinate space. It contains no UI logic and does not
## track the Player. This keeps map math reusable for future regions and worlds.

class_name WorldMapData

## Stable ID matching the world_id used by WorldLocationData and scene state.
@export var world_id: String = ""

## Player-facing name shown by the map UI.
@export var display_name: String = ""

## Physical world rectangle represented by this map.
@export var world_bounds: Rect2 = Rect2(-1000.0, -1500.0, 2000.0, 3000.0)

## Logical map rectangle used by location definitions and map presentation.
## Keeping map coordinates separate from world pixels means the map can later
## be redrawn at a different size without changing gameplay positions.
@export var map_bounds: Rect2 = Rect2(0.0, 0.0, 400.0, 600.0)

## Converts a gameplay/world position into this world's logical map space.
func world_to_map(world_position: Vector2) -> Vector2:
	var normalized_x := inverse_lerp(
		world_bounds.position.x,
		world_bounds.end.x,
		world_position.x
	)
	var normalized_y := inverse_lerp(
		world_bounds.position.y,
		world_bounds.end.y,
		world_position.y
	)

	return Vector2(
		lerp(map_bounds.position.x, map_bounds.end.x, normalized_x),
		lerp(map_bounds.position.y, map_bounds.end.y, normalized_y)
	)

## Converts a logical map position back into gameplay/world coordinates.
## This will be useful later for map clicking, waypoints, or fast travel.
func map_to_world(map_position: Vector2) -> Vector2:
	var normalized_x := inverse_lerp(
		map_bounds.position.x,
		map_bounds.end.x,
		map_position.x
	)
	var normalized_y := inverse_lerp(
		map_bounds.position.y,
		map_bounds.end.y,
		map_position.y
	)

	return Vector2(
		lerp(world_bounds.position.x, world_bounds.end.x, normalized_x),
		lerp(world_bounds.position.y, world_bounds.end.y, normalized_y)
	)
