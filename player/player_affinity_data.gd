extends Resource
class_name PlayerAffinityData
## Defines how the Player reacts to one damage type.
##
## PlayerStats owns the Player's configured affinity list. Enemy AI reads that
## list when selecting an action, while CombatManager remains responsible for
## executing the selected enemy action.
##
## Keeping this data separate means Player weaknesses can later come from
## equipment, progression, status effects, or other systems without changing
## enemy action definitions.

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
const AFFINITIES = preload("res://combat/affinities.gd")

## Damage category this affinity applies to.
@export var damage_type: int = DAMAGE_TYPES.Type.PHYSICAL

## Reaction the Player has to the selected damage category.
@export var affinity: int = AFFINITIES.Type.NORMAL
