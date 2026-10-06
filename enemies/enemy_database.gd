extends Node
## Provides the game's authoritative enemy-definition catalog.
##
## Enemy combat instances store their current HP and temporary combat state,
## while this database owns the mapping from stable enemy IDs to EnemyData
## Resources. CombatManager asks this catalog for definitions instead of
## hardcoding enemy statistics.
##
## New enemy Resource files can be registered here as the game expands.

const SLIME: Resource = preload("res://enemies/definitions/slime.tres")
const SLIME_RESIST: Resource = preload("res://enemies/definitions/slime_resist.tres")
const SLIME_NULL: Resource = preload("res://enemies/definitions/slime_null.tres")

static func get_enemy(enemy_id: String) -> Resource:
	# Resolve a stable enemy ID to its shared EnemyData Resource.
	match enemy_id:
		"slime":
			return SLIME
		"slime_resist":
			return SLIME_RESIST
		"slime_null":
			return SLIME_NULL
		_:
			return null

static func get_all_enemies() -> Array[Resource]:
	# Return every currently registered enemy definition for future tools,
	# encounter tables, and debug systems.
	return [
		SLIME,
		SLIME_RESIST,
		SLIME_NULL,
	]
