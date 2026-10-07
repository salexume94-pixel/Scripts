extends Node
## Owns disk-based Save/Load for the current gameplay state.
##
## SaveManager is the boundary between the runtime systems and the save file.
## It does not own Player stats, inventory, equipment, quests, or chest logic.
## Instead, it asks each authoritative system for serializable data and combines
## those pieces into one versioned save document.
##
## The first save format intentionally uses a JSON file in user://. JSON keeps
## the save format human-readable during development and makes malformed or
## missing data easier to diagnose before a more advanced save format is needed.
##
## Loading remains available through F9 during development/testing. Saving is
## deliberately controlled by in-world save points so the game does not expose
## an unrestricted save shortcut.
##
## Saving is only allowed from a scene containing the Player. This prevents
## accidentally saving Battle.tscn or another transitional scene as the point
## from which the game should resume.

const SAVE_PATH: String = "user://save_01.json"
const SAVE_VERSION: int = 1


signal save_completed
signal save_failed(reason: String)
signal load_completed
signal load_failed(reason: String)


var is_loading: bool = false


func _input(event: InputEvent) -> void:
	# Loading remains available through F9 for development and testing.
	# Saving is intentionally not bound to a global key. Designated in-world
	# save-point NPCs call save_game() when the Player interacts with them.
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	if key_event.physical_keycode == KEY_F9 or key_event.keycode == KEY_F9:
		load_game()
		get_viewport().set_input_as_handled()


func save_game() -> bool:
	# Saving while a load is already in progress could capture a half-restored
	# scene. Refuse that operation rather than writing a corrupt save.
	if is_loading:
		return _fail_save("Save blocked while a load is in progress.")

	var player := _get_active_player()
	if player == null:
		return _fail_save("No active Player was found in the current scene.")

	var scene_path: String = get_tree().current_scene.scene_file_path
	if scene_path.is_empty():
		return _fail_save("The current scene has no file path.")

	# Build the save document from authoritative runtime owners. Each subsystem
	# remains responsible for deciding which of its data is safe to serialize.
	var save_data := {
		"save_version": SAVE_VERSION,
		"scene_path": scene_path,
		"player_position": {
			"x": player.global_position.x,
			"y": player.global_position.y,
		},
		"world_context": {
			"world_id": SceneManager.current_world_id,
			"location_id": SceneManager.current_location_id,
			"return_player_position": {
				"x": SceneManager.return_player_position.x,
				"y": SceneManager.return_player_position.y,
			},
			"has_return_player_position": SceneManager.has_return_player_position,
		},
		"game_state": {
			"inventory": GameState.get_inventory(),
			"equipment": GameState.get_equipment(),
			"player_stats": GameState.get_player_stats(),
			"gold": GameState.get_gold(),
		},
		"quests": QuestManager.get_save_data(),
		"chests": _get_chest_save_data(),
		"metadata": {
			"saved_at": Time.get_datetime_string_from_system(),
		},
	}

	# Write to a temporary file first. The existing save is replaced only after
	# the complete JSON document has been written successfully.
	var temp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return _fail_save("Could not open the temporary save file for writing.")

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	# Replace the previous save only after the temporary file exists.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(SAVE_PATH)
	)

	if rename_error != OK:
		return _fail_save("Could not finalize the save file. Error %d." % rename_error)

	print("SaveManager: game saved to ", SAVE_PATH)
	save_completed.emit()
	return true


func load_game() -> bool:
	# Prevent a second load from racing the scene transition started by the
	# first one.
	if is_loading:
		return _fail_load("Load already in progress.")

	if not FileAccess.file_exists(SAVE_PATH):
		return _fail_load("No save file exists at %s." % SAVE_PATH)

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _fail_load("Could not open the save file for reading.")

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail_load("The save file does not contain a valid JSON object.")

	var save_data: Dictionary = parsed

	# Versioning is established now so future save-format changes can be handled
	# deliberately instead of silently interpreting incompatible data.
	var version := int(save_data.get("save_version", 0))
	if version != SAVE_VERSION:
		return _fail_load(
			"Unsupported save version %d. Expected version %d."
			% [version, SAVE_VERSION]
		)

	var scene_path := str(save_data.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return _fail_load("The save references a missing scene: %s" % scene_path)

	var player_position := _read_vector2(
		save_data.get("player_position", {}),
		Vector2.ZERO
	)

	var world_context: Dictionary = save_data.get("world_context", {})
	var world_id := str(world_context.get("world_id", ""))
	var location_id := str(world_context.get("location_id", ""))

	if world_id.is_empty() or location_id.is_empty():
		return _fail_load("The save is missing world/location context.")

	var game_state_data: Dictionary = save_data.get("game_state", {})
	if typeof(game_state_data) != TYPE_DICTIONARY:
		return _fail_load("The save contains invalid GameState data.")

	# Restore runtime-owned data before creating the destination Player. The
	# Player's _ready() methods then consume these snapshots when the new scene
	# instantiates its Player components.
	GameState.set_inventory(game_state_data.get("inventory", {}))
	GameState.set_equipment(game_state_data.get("equipment", {}))
	GameState.set_player_stats(game_state_data.get("player_stats", {}))
	GameState.set_gold(int(game_state_data.get("gold", 0)))

	# Restore transition context before the scene loads so reusable interior
	# doors know where the Player should return after loading an interior save.
	SceneManager.current_world_id = world_id
	SceneManager.current_location_id = location_id
	SceneManager.return_player_position = _read_vector2(
		world_context.get("return_player_position", {}),
		Vector2.ZERO
	)
	SceneManager.has_return_player_position = bool(
		world_context.get("has_return_player_position", false)
	)

	# QuestManager is an autoload, so its runtime state must be restored
	# separately from GameState.
	var quest_data: Dictionary = save_data.get("quests", {})
	if typeof(quest_data) == TYPE_DICTIONARY:
		QuestManager.load_save_data(quest_data)

	is_loading = true

	# Use the normal SceneManager transition path so the same scene lifecycle
	# and Player placement rules are used by both gameplay and Save/Load.
	SceneManager.change_scene(
		scene_path,
		player_position,
		world_id,
		location_id
	)

	await get_tree().scene_changed

	# SceneManager also places the Player, but explicitly applying the saved
	# position here makes SaveManager's restore contract independent of timing
	# inside the scene-transition implementation.
	var player := _get_active_player()
	if player == null:
		is_loading = false
		return _fail_load("Destination scene loaded without a Player node.")

	player.global_position = player_position

	# Chests are scene-owned objects, so their saved state can only be applied
	# after the destination scene has finished instantiating them.
	_apply_chest_save_data(save_data.get("chests", {}))

	is_loading = false
	print("SaveManager: game loaded from ", SAVE_PATH)
	load_completed.emit()
	return true


func has_save_file() -> bool:
	# UI and future menus can use this without knowing where the save file lives.
	return FileAccess.file_exists(SAVE_PATH)


func delete_save_file() -> bool:
	# Development/testing utility for resetting the local save slot.
	if not FileAccess.file_exists(SAVE_PATH):
		return true

	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	return error == OK


func _get_active_player() -> Node2D:
	# Player is registered in a shared group so SaveManager does not depend on
	# a specific World, Interior, or future map scene path.
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null

	return players[0] as Node2D


func _get_chest_save_data() -> Dictionary:
	# Each reusable Chest supplies its own stable runtime state. The scene path
	# and node path form its identity, so the same chest can be recognized after
	# the scene is recreated without hard-coding individual chest IDs here.
	var result: Dictionary = {}

	for chest in get_tree().get_nodes_in_group("persistent_chest"):
		if not chest.has_method("get_save_id") or not chest.has_method("get_save_data"):
			continue

		var save_id: String = str(chest.get_save_id())
		if save_id.is_empty():
			continue

		result[save_id] = chest.get_save_data()

	return result


func _apply_chest_save_data(saved_chests) -> void:
	# Chests absent from the save remain in their default unopened state.
	# Chests present in the save receive their authoritative saved state.
	if typeof(saved_chests) != TYPE_DICTIONARY:
		return

	for chest in get_tree().get_nodes_in_group("persistent_chest"):
		if not chest.has_method("get_save_id") or not chest.has_method("load_save_data"):
			continue

		var save_id: String = str(chest.get_save_id())
		if saved_chests.has(save_id):
			chest.load_save_data(saved_chests[save_id])


func _read_vector2(value, fallback: Vector2) -> Vector2:
	# JSON has no native Vector2 type, so saved positions are stored as simple
	# x/y dictionaries and reconstructed through this validation helper.
	if typeof(value) != TYPE_DICTIONARY:
		return fallback

	if not value.has("x") or not value.has("y"):
		return fallback

	return Vector2(float(value["x"]), float(value["y"]))


func _fail_save(reason: String) -> bool:
	push_error("SaveManager: " + reason)
	save_failed.emit(reason)
	return false


func _fail_load(reason: String) -> bool:
	push_error("SaveManager: " + reason)
	load_failed.emit(reason)
	return false
