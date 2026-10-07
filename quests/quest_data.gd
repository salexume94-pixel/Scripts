extends Resource
## Defines the static data for a quest.
##
## QuestData contains only definition data. Runtime state such as whether the
## quest is active and how far each objective has progressed belongs to
## QuestManager. This keeps reusable quest content separate from save state.

class_name QuestData

## Stable identifier used by QuestManager and future world-gating systems.
@export var quest_id: String = ""

## Display title shown in the Quest Log.
@export var title: String = ""

## Short description explaining the quest.
@export_multiline var description: String = ""

## Objective definitions. Each dictionary must contain:
## - objective_id: stable identifier
## - description: player-facing objective text
## - required_count: amount needed for completion
@export var objectives: Array[Dictionary] = []

## Reward definitions. Each dictionary may contain:
## - experience: XP granted on completion
## - gold: currency granted on completion
## - item_id: stable item ID granted on completion
## - quantity: amount of the item granted
@export var rewards: Array[Dictionary] = []

## Whether the quest may be started more than once after completion.
## This is reserved for future repeatable quest support.
@export var repeatable: bool = false
