extends Resource
class_name PlayerActionData
## Defines one action the Player can use during combat.
##
## This Resource contains Player action data only. CombatManager resolves the
## action through the shared combat rules, while Battle is responsible only for
## presenting the available actions and forwarding Player input.
##
## Keeping the action as data allows elemental attacks and future skills to use
## the same combat resolution path without hardcoding each attack in Battle.

## Stable identifier used to reference this action.
@export var action_id: String = ""

## Name shown by the Battle presentation when this action is used.
@export var display_name: String = ""

## Damage category used to resolve the target's elemental affinity.
@export var damage_type: int = 0

## Multiplier applied to the Player's Attack stat before affinity resolution.
@export_range(0.0, 9999.0) var power_multiplier: float = 1.0
