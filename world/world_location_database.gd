extends Node
## Provides the authoritative catalog of WorldLocationData definitions.
##
## World location definitions live in reusable Resource files and are looked up
## by stable IDs. Gameplay scenes can reference those IDs without making the
## scene itself the source of truth for player-facing location metadata.
##
## This database deliberately does not contain map coordinates. Coordinate
## conversion belongs to the later Map Foundation task so location identity and
## map presentation remain separate responsibilities.

const LOCATION_DEFINITIONS: Array[Resource] = [
    preload("res://world/definitions/tutorial_town.tres"),
    preload("res://world/definitions/inn.tres"),
    preload("res://world/definitions/shop.tres"),
    preload("res://world/definitions/church.tres"),
    preload("res://world/definitions/residence_01.tres"),
    preload("res://world/definitions/residence_02.tres"),
    preload("res://world/definitions/residence_03.tres"),
    preload("res://world/definitions/residence_04.tres"),
    preload("res://world/definitions/residence_05.tres"),
    preload("res://world/definitions/residence_06.tres"),
]


static func get_location(location_id: String) -> Resource:
    # Resolve a stable location ID to its shared definition.
    for location in LOCATION_DEFINITIONS:
        if location != null and location.get("location_id") == location_id:
            return location
    return null


static func get_all_locations() -> Array[Resource]:
    # Return a copy so callers cannot accidentally modify the authoritative
    # definition catalog.
    return LOCATION_DEFINITIONS.duplicate()
