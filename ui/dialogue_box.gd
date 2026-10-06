extends CanvasLayer
## Presents the currently active dialogue on top of the game world.
##
## This script is intentionally presentation-only. DialogueManager owns the
## actual dialogue state, while this script converts that state into the
## requested visual format:
##
## NAME
## >>dialogue text
##
## The box remains visible until the Player presses E again.

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/Speaker
@onready var dialogue_label: Label = $Panel/Margin/VBox/Dialogue
@onready var prompt_label: Label = $Panel/Margin/VBox/Prompt

func _ready() -> void:
	# Start hidden because no dialogue is active when the World loads.
	panel.visible = false

	# Listen for dialogue state changes from the global manager so this UI can
	# update without NPCs needing to know anything about its node structure.
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_cleared.connect(_on_dialogue_cleared)

func _on_dialogue_started(speaker_name: String, dialogue_text: String) -> void:
	# Display the speaker name and dialogue text in separate labels so the
	# requested format remains consistent for every NPC.
	speaker_label.text = speaker_name
	dialogue_label.text = ">>" + dialogue_text
	panel.visible = true

func _on_dialogue_cleared() -> void:
	# Hide the entire dialogue panel when the Player dismisses the conversation.
	panel.visible = false
