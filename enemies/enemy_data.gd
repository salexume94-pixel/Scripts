extends Resource
class_name EnemyData
## Defines the shared data structure for one enemy type.
##
## This Resource is the authoritative definition of an enemy's base gameplay
## values. It contains data only. CombatManager uses these values to create the
## active combat state, while Battle remains responsible only for presentation.
##
## Keeping enemy definitions in Resources means new enemy types can be added
## without hardcoding their stats into the combat flow.

## Stable identifier used by systems to find this enemy definition.
@export var enemy_id: String = ""

## Name shown to the Player in Battle UI and future menus.
@export var display_name: String = ""

## Enemy level used by future scaling and progression systems.
@export_range(1, 999) var level: int = 1

## Maximum HP for this enemy type.
@export_range(1, 999999) var max_hp: int = 1

## Physical Attack value used by the current basic enemy action.
@export_range(0, 99999) var attack: int = 0

## Physical Defense value reserved for future defensive combat calculations.
@export_range(0, 99999) var defense: int = 0

## Magic Attack value reserved for future elemental and skill systems.
@export_range(0, 99999) var magic_attack: int = 0

## Magic Defense value reserved for future elemental and skill systems.
@export_range(0, 99999) var magic_defense: int = 0

## Speed value reserved for future turn-order and enemy behavior systems.
@export_range(0, 99999) var speed: int = 0

## Actions this enemy can perform. The first action is the current basic action.
@export var actions: Array[Resource] = []

## Experience awarded when this enemy is defeated.
@export_range(0, 999999) var experience_reward: int = 0

## Gold awarded when this enemy is defeated.
@export_range(0, 999999) var gold_reward: int = 0
