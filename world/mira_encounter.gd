extends "res://world/npc.gd"
## Handles Mira's first encounter and the two route choices.
##
## DialogueManager presents the options, QuestManager records only that Mira
## was met, PartyManager records roster membership, and SceneManager performs
## the chosen transition. The route choice never changes quest requirements.

const QUEST_ID := "the_stranger"
const MEET_OBJECTIVE_ID := "meet_mira"
const HAVENREACH_SCENE := "res://scenes/Havenreach.tscn"
const OVERWORLD_SCENE := "res://scenes/WorldMapWorld.tscn"

const CHOICE_WITH_MIRA := "journey_with_mira"
const CHOICE_ALONE := "travel_alone"


func _ready() -> void:
	super._ready()
	npc_name = "Mira"
	DialogueManager.dialogue_choice_selected.connect(_on_dialogue_choice_selected)


func interact(_player: Node) -> void:
	# Do not offer the one-time choice again after the meeting was recorded.
	if QuestManager.get_objective_progress(QUEST_ID, MEET_OBJECTIVE_ID) > 0:
		DialogueManager.show_dialogue(
			"Mira",
			"Havenreach is still the nearest settlement. You should decide how you want to get there."
		)
		return

	DialogueManager.show_choices(
		"Mira",
		"You're a long way from the main road. Havenreach is the nearest settlement. I can travel with you, or you can go on your own.",
		[
			{"id": CHOICE_WITH_MIRA, "text": "Journey with Mira"},
			{"id": CHOICE_ALONE, "text": "Travel to Havenreach alone"},
		]
	)


func _on_dialogue_choice_selected(choice_id: String) -> void:
	# Ignore choices belonging to other dialogue interactions.
	if choice_id != CHOICE_WITH_MIRA and choice_id != CHOICE_ALONE:
		return

	# Both answers satisfy the same story beat; the selected answer is not stored
	# as a separate quest branch or a duplicate story flag.
	if QuestManager.get_quest_state(QUEST_ID) == QuestManager.QuestState.ACTIVE:
		QuestManager.add_objective_progress(QUEST_ID, MEET_OBJECTIVE_ID, 1)

	if choice_id == CHOICE_WITH_MIRA:
		PartyManager.add_companion("mira")
		SceneManager.change_scene(
			HAVENREACH_SCENE,
			Vector2(0.0, 900.0),
			"havenreach",
			"havenreach"
		)
	else:
		# Place the Player beyond the hidden encounter trigger so returning to
		# the overworld cannot immediately reopen the same scene.
		SceneManager.change_scene(
			OVERWORLD_SCENE,
			Vector2(-840.0, 0.0),
			"world_map",
			"world_map"
		)
