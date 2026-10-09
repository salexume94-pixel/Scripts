extends CanvasLayer
## Presents dialogue and reusable player choices.
##
## DialogueManager owns the conversation state. This script only renders the
## speaker, text, and any choice buttons, then reports a selected choice ID.

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/Speaker
@onready var dialogue_label: Label = $Panel/Margin/VBox/Dialogue
@onready var prompt_label: Label = $Panel/Margin/VBox/Prompt
@onready var choices_container: VBoxContainer = $Panel/Margin/VBox/Choices


func _ready() -> void:
	panel.visible = false
	choices_container.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_choices_started.connect(_on_dialogue_choices_started)
	DialogueManager.dialogue_cleared.connect(_on_dialogue_cleared)

	# A scene created while dialogue is already active must show the current state.
	if DialogueManager.is_active:
		_on_dialogue_started(DialogueManager.current_speaker, DialogueManager.current_text)
		if DialogueManager.has_choices():
			_on_dialogue_choices_started(
				DialogueManager.current_speaker,
				DialogueManager.current_text,
				DialogueManager.current_choices
			)


func _on_dialogue_started(speaker_name: String, dialogue_text: String) -> void:
	speaker_label.text = speaker_name
	dialogue_label.text = ">>" + dialogue_text
	prompt_label.text = "Press E to continue"
	prompt_label.visible = true
	choices_container.visible = false
	_clear_choice_buttons()
	panel.visible = true


func _on_dialogue_choices_started(
	speaker_name: String,
	dialogue_text: String,
	choices: Array[Dictionary]
) -> void:
	# Present options as real buttons while keeping the same shared dialogue box.
	speaker_label.text = speaker_name
	dialogue_label.text = ">>" + dialogue_text
	prompt_label.text = "Choose an option"
	prompt_label.visible = false
	_clear_choice_buttons()
	choices_container.visible = true
	panel.visible = true

	for choice in choices:
		var choice_id := str(choice.get("id", ""))
		var choice_text := str(choice.get("text", ""))
		if choice_id.is_empty() or choice_text.is_empty():
			continue

		var button := Button.new()
		button.text = choice_text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_choice_button_pressed.bind(choice_id))
		choices_container.add_child(button)


func _on_choice_button_pressed(choice_id: String) -> void:
	# Bind each button to its own stable ID rather than relying on loop-variable
	# capture inside a closure.
	DialogueManager.select_choice(choice_id)


func _on_dialogue_cleared() -> void:
	panel.visible = false
	choices_container.visible = false
	_clear_choice_buttons()


func _clear_choice_buttons() -> void:
	for child in choices_container.get_children():
		child.queue_free()
