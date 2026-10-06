extends RefCounted
class_name Affinities
## Defines how a target reacts to a specific damage type.
##
## Affinity data is separate from damage actions so the same action can behave
## differently against different enemies without changing the action itself.

enum Type {
	NORMAL,
	WEAK,
	RESIST,
	NULLIFY,
	DRAIN,
	REPEL,
}

static func get_display_name(affinity: int) -> String:
	## Convert an affinity into readable text for Battle UI and debugging.
	switch affinity:
		Type.NORMAL:
			return "Normal"
		Type.WEAK:
			return "Weak"
		Type.RESIST:
			return "Resist"
		Type.NULLIFY:
			return "Null"
		Type.DRAIN:
			return "Drain"
		Type.REPEL:
			return "Repel"
	return "Unknown"
