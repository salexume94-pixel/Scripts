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

## Logical map-space position for this location.
## This is deliberately separate from a scene node's world position so map
## presentation can use a stable coordinate system independent of world pixels.
@export var map_position: Vector2 = Vector2.ZERO

## Controls whether the location is currently shown on the player-facing map.
## The location remains registered even when its marker is hidden.
@export var map_visible: bool = true

## Physical position of this location's entry region in its owning world.
## This is used by the overworld to create reusable location-entry triggers.
@export var world_position: Vector2 = Vector2.ZERO

## Size of the physical entry region in the owning world.
## A rectangular region allows the Player to approach from any direction.
@export var world_entry_size: Vector2 = Vector2(160.0, 120.0)

## Scene loaded when the Player enters this location from the owning world.
@export_file("*.tscn") var entry_scene: String = ""

## Player position used when the destination scene is entered.
@export var entry_player_position: Vector2 = Vector2.ZERO

## World identity assigned after entering the destination scene.
@export var entry_world_id: String = ""

## Location identity assigned after entering the destination scene.
@export var entry_location_id: String = ""

## Enables automatic entry-region creation for this location.
## Locations can remain registered without becoming physical entrances yet.
@export var entry_enabled: bool = false
