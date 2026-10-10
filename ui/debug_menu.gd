extends CanvasLayer
## Provides a small, development-only menu for global test toggles.
##
## F3 opens or closes this panel during gameplay. The menu changes only the
## overworld encounter enable flag in GameState; combat rules and affinities
## remain owned by their existing systems and are not edited here.

@onready var panel: PanelContainer = $Panel
@onready var encounters_toggle: CheckBox = $Panel/Margin/VBox/EncountersToggle


func _ready() -> void:
	# Keep the menu out of the way until explicitly requested.
	panel.visible = false
	encounters_toggle.button_pressed = GameState.overworld_encounters_enabled
	encounters_toggle.toggled.connect(_on_encounters_toggled)


func _input(event: InputEvent) -> void:
	# Use F3 as a predictable global debug-menu shortcut. Consume the key so
	# it does not also trigger an unrelated gameplay action.
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_F3 and key_event.physical_keycode != KEY_F3:
		return

	panel.visible = not panel.visible
	if panel.visible:
		encounters_toggle.button_pressed = GameState.overworld_encounters_enabled
	get_viewport().set_input_as_handled()


func _on_encounters_toggled(enabled: bool) -> void:
	# WorldEncounterSystem reads this shared setting before rolling an encounter.
	GameState.overworld_encounters_enabled = enabled
