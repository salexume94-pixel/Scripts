extends Control
## Owns the game's startup menu.
##
## The Main Menu is intentionally small: it only decides whether the player
## starts a new game, loads the existing save, or quits. Gameplay systems
## remain responsible for actually running the game once a choice is made.

const NEW_GAME_SCENE := "res://scenes/WakingArea.tscn"


func _ready() -> void:
	# Give keyboard focus to New Game so the menu is immediately usable with
	# a keyboard or controller without requiring a mouse click.
	$Menu/VBoxContainer/NewGameButton.grab_focus()


func _on_new_game_button_pressed() -> void:
	# New Game begins the new story opening rather than resuming an old runtime
	# state or entering either of the retained example settlements.
	DialogueManager.clear_dialogue()
	GameState.reset_runtime_state()
	QuestManager.reset_all_quests()
	PartyManager.reset_party()

	# Start the opening quest before loading its first scene so the waking
	# sequence can safely advance its objective through the shared QuestManager.
	QuestManager.start_quest("the_stranger")
	SceneManager.change_scene(
		NEW_GAME_SCENE,
		Vector2.ZERO,
		"world_map",
		"waking_area"
	)


func _on_load_button_pressed() -> void:
	# SaveManager owns the save-file format and scene restoration. The Main Menu
	# only asks it to perform the load.
	if SaveManager.has_save_file():
		SaveManager.load_game()
	else:
		$Menu/StatusLabel.text = "No save data found."


func _on_options_button_pressed() -> void:
	# OptionsManager owns the shared overlay so these same preferences are
	# available during gameplay through Escape as well as from this menu.
	OptionsManager.open_options()


func _on_quit_button_pressed() -> void:
	# Quit is kept here rather than inside SaveManager or SceneManager because
	# exiting the application is a menu concern, not a persistence concern.
	get_tree().quit()
