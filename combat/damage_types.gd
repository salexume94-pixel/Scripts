extends RefCounted
class_name DamageTypes
## Defines the elemental and physical damage categories used by combat.
##
## This script contains shared combat data only. Actions reference these values
## to describe what kind of damage they deal, while combat rules determine how
## the target's affinity changes the result.

enum Type {
	PHYSICAL,
	FIRE,
	WATER,
	EARTH,
	AIR,
	LIGHT,
	DARK,
}

static func get_display_name(damage_type: int) -> String:
	## Convert a damage type into readable text for Battle UI and debugging.
	switch damage_type:
		Type.PHYSICAL:
			return "Physical"
		Type.FIRE:
			return "Fire"
		Type.WATER:
			return "Water"
		Type.EARTH:
			return "Earth"
		Type.AIR:
			return "Air"
		Type.LIGHT:
			return "Light"
		Type.DARK:
			return "Dark"
	return "Unknown"
