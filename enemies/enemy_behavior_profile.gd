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
	DEFENSIVE,
}

## Stable identifier used by enemy definitions and debugging.
@export var profile_id: String = ""

## General action-selection strategy.
@export var strategy: Strategy = Strategy.BALANCED

## Multiplier applied when an action targets a known Player weakness.
@export_range(0.0, 9999.0) var weakness_priority: float = 1.0

## Probability that weakness-aware Aggressive behavior selects from actions targeting the Player weakness.
## A value of 0.65 gives an approximate 13-in-20 weakness selection rate.
## The remaining probability is used for non-weakness actions.
@export_range(0.0, 1.0) var weakness_selection_chance: float = 0.65

## Multiplier applied to actions that target an affinity other than Normal.
## Harmful reactions such as Resist, Null, Drain, and Repel can be avoided.
@export_range(0.0, 9999.0) var unfavorable_affinity_multiplier: float = 0.25

## Minimum selection weight retained after profile adjustments.
## Zero means the action may be completely excluded by the profile.
@export_range(0.0, 9999.0) var minimum_selection_weight: float = 0.0

## Multiplier applied when the AI selected the same action on the previous enemy turn.
## This preserves a known weakness priority without making one action repeat forever.
@export_range(0.0, 1.0) var repeat_action_multiplier: float = 0.5

## Multiplier applied to the Defend action after the profile strategy is applied.
## This lets every profile retain Defend while Defensive enemies prefer it more.
@export_range(0.0, 9999.0) var defend_weight_multiplier: float = 1.0

## Controls how strongly Aggressive and Defensive behavior bias action power.
## Higher values make the profile distinction more pronounced. A value of 0.0
## disables the power bias while leaving normal action weights intact.
@export_range(0.0, 5.0) var power_bias_strength: float = 0.0
