extends Node2D
## Handles arrival in the active first settlement.
##
## Entering Havenreach advances the final objective. QuestManager automatically
## completes MAIN_001 once the waking, Mira, and arrival objectives are done.
## Re-entering or loading Havenreach cannot grant duplicate quest rewards because
## QuestManager ignores progress changes for completed quests.

const QUEST_ID := "the_stranger"
const ARRIVAL_OBJECTIVE_ID := "reach_havenreach"


func _ready() -> void:
	if QuestManager.get_quest_state(QUEST_ID) == QuestManager.QuestState.ACTIVE:
		QuestManager.add_objective_progress(QUEST_ID, ARRIVAL_OBJECTIVE_ID, 1)
