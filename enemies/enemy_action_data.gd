extends Resource
class_name EnemyActionData

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
## Defines one action an enemy can perform during combat.
##
## This Resource contains action data only. CombatManager decides when an
## action is used and applies the combat rules, while Battle only presents
## the result. Keeping actions separate from EnemyData lets one enemy have
## several attacks, skills, or other behaviors without hardcoding them.

## Stable identifier used to reference this action.
@export var action_id: String = ""

## Name shown by the Battle presentation when this action is performed.
@export var display_name: String = ""

## Base power used by the current damage calculation.
@export_range(0, 99999) var power: int = 0

## Damage category used to resolve the target's elemental affinity.
@export var damage_type: int = DAMAGE_TYPES.Type.PHYSICAL

## Relative chance used when an enemy has multiple available actions.
## A value of 0 removes the action from normal weighted selection.
@export_range(0.0, 9999.0) var selection_weight: float = 1.0

## Multiplier applied to this action's selection weight when its damage type
## matches a known Player weakness. The base selection weight is never replaced.
## This lets AI become more intelligent without changing existing action data.
@export_range(0.0, 9999.0) var weakness_weight_multiplier: float = 3.0

## Accuracy used by CombatRules when this action is resolved.
@export_range(0.0, 100.0) var accuracy: float = 100.0

## Critical-hit chance used by CombatRules when this action is resolved.
@export_range(0.0, 100.0) var critical_chance: float = 0.0

## Damage multiplier applied when this action scores a critical hit.
@export_range(0.0, 9999.0) var critical_multiplier: float = 2.0
