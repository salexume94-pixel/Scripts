extends Node
## Owns the current dialogue state for the game.
##
## DialogueManager keeps dialogue progression separate from individual NPCs and
## from the visual dialogue box. It also owns choice selection so any encounter
## can present reusable options without implementing its own UI buttons.

signal dialogue_started(speaker_name: String, dialogue_text: String)
signal dialogue_choices_started(speaker_name: String, dialogue_text: String, choices: Array[Dictionary])
signal dialogue_choice_selected(choice_id: String)
signal dialogue_cleared

var is_active: bool = false
var current_speaker: String = ""
var current_text: String = ""
var current_choices: Array[Dictionary] = []


func has_choices() -> bool:
	return not current_choices.is_empty()


func show_dialogue(speaker_name: String, dialogue_text: String) -> void:
	# A normal line clears any stale options from a previous conversation.
	current_speaker = speaker_name
	current_text = dialogue_text
	current_choices.clear()
	is_active = true
	dialogue_started.emit(current_speaker, current_text)


func show_choices(
	speaker_name: String,
	dialogue_text: String,
	choices: Array[Dictionary]
) -> void:
	# Choice IDs are stable machine-readable values; labels are player-facing.
	current_speaker = speaker_name
	current_text = dialogue_text
	current_choices = choices.duplicate(true)
	is_active = true
	dialogue_started.emit(current_speaker, current_text)
	dialogue_choices_started.emit(current_speaker, current_text, current_choices.duplicate(true))


func select_choice(choice_id: String) -> void:
	# Ignore stale button presses or arbitrary IDs not offered by the current dialogue.
	var valid_choice := false
	for choice in current_choices:
		if str(choice.get("id", "")) == choice_id:
			valid_choice = true
			break

	if not is_active or not valid_choice:
		return

	clear_dialogue()
	dialogue_choice_selected.emit(choice_id)


func clear_dialogue() -> void:
	# Clear all active dialogue state before notifying UI and gameplay listeners.
	if not is_active:
		return

	is_active = false
	current_speaker = ""
	current_text = ""
	current_choices.clear()
	dialogue_cleared.emit()
