extends Node
## Defines the runtime world identity for a World scene.
##
## SceneManager owns persistent transition context, but individual World scenes
## need a reusable way to declare which world they represent. This script
## supplies that identity when the scene loads without making the map UI or
## Player controller responsible for world ownership.

@export var world_id: String = ""
@export var location_id: String = ""

func _ready() -> void:
	# Register the scene's world/location context as soon as the World loads.
	# This also resets the active location from a building back to its parent
	# world when the Player returns from an interior.
	if world_id.is_empty():
		push_error("WorldContext has no world_id configured.")
		return

	SceneManager.current_world_id = world_id
	SceneManager.current_location_id = location_id
