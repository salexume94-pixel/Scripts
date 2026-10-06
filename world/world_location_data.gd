extends Resource
## Defines reusable data for a named world location.
##
## WorldLocationData contains static identity and metadata only. It does not
## track the Player's current position, scene transitions, quest state, or UI.
## Those responsibilities remain in their owning systems.
##
## Keeping location identity in a Resource means scenes can reference a stable
## location ID and display name without making the map UI responsible for
## discovering locations from scene-node names.

class_name WorldLocationData

enum LocationType {
	WORLD,
	TOWN,
	BUILDING,
	LANDMARK,
	DUNGEON,
	REGION,
}

## Stable identifier used by world systems, map data, quests, and future saves.
@export var location_id: String = ""

## Stable identifier for the world/map that owns this location.
@export var world_id: String = ""

## Player-facing name used by future map and location UI.
@export var display_name: String = ""

## Broad category used by future map presentation and filtering.
@export var location_type: LocationType = LocationType.WORLD

## Optional description for future map details, dialogue, lore, or story UI.
@export_multiline var description: String = ""

## Indicates that this location has deliberate story/lore significance.
## The flag does not itself trigger story content. It is metadata for systems
## that may need to distinguish ordinary locations from important ones.
@export var story_significant: bool = false
