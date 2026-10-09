extends Node2D
## Owns the one-time waking beat inside waking_area.
##
## The QuestManager objective is the durable record that this beat finished.
## This avoids adding a second story flag solely to remember whether the line ran.

const QUEST_ID := "the_stranger"
const OBJECTIVE_ID := "complete_waking"
const WAKING_LINE := "Where am I?"

var _waking_line_active: bool = false


func _ready() -> void:
	DialogueManager.dialogue_cleared.connect(_on_dialogue_cleared)

	# A loaded save that already completed the waking beat must not replay it.
	if QuestManager.get_quest_state(QUEST_ID) != QuestManager.QuestState.ACTIVE:
		return
	if QuestManager.get_objective_progress(QUEST_ID, OBJECTIVE_ID) > 0:
		return

	_waking_line_active = true
	DialogueManager.show_dialogue("Wanderer", WAKING_LINE)


func _on_dialogue_cleared() -> void:
	# Only the line started by this scene can advance the waking objective.
	if not _waking_line_active:
		return

	_waking_line_active = false
	QuestManager.add_objective_progress(QUEST_ID, OBJECTIVE_ID, 1)
