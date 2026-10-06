extends Resource
class_name EnemyActionData

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
## Defines one action an enemy can perform during combat.
##
## This Resource contains action data only. CombatManager decides when an
## action is used and applies the combat rules, while Battle only presents the
## result. Keeping actions separate from EnemyData lets one enemy later have
## several attacks, skills, or other behaviors without hardcoding them.

## Stable identifier used to reference this action.
@export var action_id: String = ""

## Name shown by the Battle presentation when this action is performed.
@export var display_name: String = ""

## Base power used by the current damage calculation.
@export_range(0, 99999) var power: int = 0

## Damage category used to resolve the target's elemental affinity.
@export var damage_type: int = DamageTypes.Type.PHYSICAL

## Relative chance used when an enemy has multiple available actions.
## A value of 0 removes the action from normal weighted selection.
@export_range(0.0, 9999.0) var selection_weight: float = 1.0
