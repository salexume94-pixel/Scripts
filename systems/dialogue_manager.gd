extends Node
## Owns the current dialogue state for the game.
##
## DialogueManager keeps dialogue progression separate from individual NPCs and
## from the visual dialogue box. NPCs only provide the speaker name and text,
## while the UI decides how that information is presented.
##
## The manager also gives the InteractionSystem a single source of truth for
## whether dialogue is currently being displayed. Pressing E while dialogue is
## active clears it instead of immediately interacting with another NPC.

signal dialogue_started(speaker_name: String, dialogue_text: String)
signal dialogue_cleared

var is_active: bool = false
var current_speaker: String = ""
var current_text: String = ""

func show_dialogue(speaker_name: String, dialogue_text: String) -> void:
	# Store the current line so the dialogue remains active until the Player
	# explicitly presses E again to dismiss it.
	current_speaker = speaker_name
	current_text = dialogue_text
	is_active = true
	dialogue_started.emit(current_speaker, current_text)

func clear_dialogue() -> void:
	# Clearing dialogue resets all state and tells the UI to hide itself.
	if not is_active:
		return

	is_active = false
	current_speaker = ""
	current_text = ""
	dialogue_cleared.emit()
