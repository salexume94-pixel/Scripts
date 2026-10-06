extends Resource
class_name EnemyBehaviorProfile
## Defines how an enemy prioritizes its available actions.
##
## This Resource contains AI preference data only. CombatManager uses the
## profile when selecting an action, while EnemyActionData remains responsible
## only for individual action data.

enum Strategy {
	BALANCED,
	AGGRESSIVE,
	WEAKNESS_HUNTER,
}

## Stable identifier used by enemy definitions and debugging.
@export var profile_id: String = ""

## General action-selection strategy.
@export var strategy: Strategy = Strategy.BALANCED

## Multiplier applied when an action targets a known Player weakness.
@export_range(0.0, 9999.0) var weakness_priority: float = 1.0

## Probability that a weakness-hunter selects from actions targeting the Player weakness.
## The remaining probability is used for non-weakness actions.
@export_range(0.0, 1.0) var weakness_selection_chance: float = 0.6666667

## Multiplier applied to actions that target an affinity other than Normal.
## Harmful reactions such as Resist, Null, Drain, and Repel can be avoided.
@export_range(0.0, 9999.0) var unfavorable_affinity_multiplier: float = 0.25

## Minimum selection weight retained after profile adjustments.
## Zero means the action may be completely excluded by the profile.
@export_range(0.0, 9999.0) var minimum_selection_weight: float = 0.0

## Multiplier applied when the AI selected the same action on the previous enemy turn.
## This preserves a known weakness priority without making one action repeat forever.
@export_range(0.0, 1.0) var repeat_action_multiplier: float = 0.5
