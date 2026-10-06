extends Resource
class_name PlayerActionData
## Defines one action the Player can use during combat.
##
## This Resource contains Player action data only. CombatManager resolves the
## action through shared combat rules, while Battle is responsible only for
## presenting the action and forwarding Player input.
##
## Accuracy and critical chance live here as action data so different skills
## can have different reliability without hardcoding those values in combat UI.

## Stable identifier used to reference this action.
@export var action_id: String = ""

## Name shown by the Battle presentation when this action is used.
@export var display_name: String = ""

## Damage category used to resolve the target's elemental affinity.
@export var damage_type: int = 0

## Multiplier applied to the Player's Attack stat before affinity resolution.
@export_range(0.0, 9999.0) var power_multiplier: float = 1.0

## Chance for the action to successfully hit, expressed as a percentage.
@export_range(0.0, 100.0) var accuracy: float = 100.0

## Chance for a successful hit to become a critical hit, expressed as a percentage.
@export_range(0.0, 100.0) var critical_chance: float = 0.0

## Damage multiplier applied when the action critically hits.
@export_range(1.0, 10.0) var critical_multiplier: float = 2.0
