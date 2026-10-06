extends Resource
class_name EnemyAffinityData
## Defines one enemy affinity for one damage type.
##
## EnemyData owns a list of these Resources. Keeping each affinity as its own
## data object makes enemy definitions readable and allows new damage types or
## affinity rules to be added without hardcoding enemy-specific behavior.

## Damage category this affinity applies to.
@export var damage_type: int = DamageTypes.Type.PHYSICAL

## Reaction the enemy has to the selected damage category.
@export var affinity: int = Affinities.Type.NORMAL
