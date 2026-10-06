extends RefCounted
## Provides the shared catalog of elemental enemy actions.
##
## Elemental action Resources live here so individual EnemyData definitions do
## not need to carry every elemental option. An enemy only assigns the elemental
## actions it is intended to use. Future enemy definitions can pull any shared
## elemental action from this catalog when they need it.

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")

const FIRE: Resource = preload("res://enemies/definitions/slime_fire_attack.tres")
const WATER: Resource = preload("res://enemies/definitions/slime_water_attack.tres")
const EARTH: Resource = preload("res://enemies/definitions/slime_earth_attack.tres")
const AIR: Resource = preload("res://enemies/definitions/slime_air_attack.tres")
const LIGHT: Resource = preload("res://enemies/definitions/slime_light_attack.tres")
const DARK: Resource = preload("res://enemies/definitions/slime_dark_attack.tres")

static func get_action(damage_type: int) -> Resource:
	# Resolve a shared elemental action by its damage type.
	match damage_type:
		DAMAGE_TYPES.Type.FIRE:
			return FIRE
		DAMAGE_TYPES.Type.WATER:
			return WATER
		DAMAGE_TYPES.Type.EARTH:
			return EARTH
		DAMAGE_TYPES.Type.AIR:
			return AIR
		DAMAGE_TYPES.Type.LIGHT:
			return LIGHT
		DAMAGE_TYPES.Type.DARK:
			return DARK
		_:
			return null

static func get_all_actions() -> Array[Resource]:
	# Return every shared elemental action for future enemy-definition tooling.
	return [FIRE, WATER, EARTH, AIR, LIGHT, DARK]
