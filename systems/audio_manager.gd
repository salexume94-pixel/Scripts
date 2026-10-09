extends Node
## Owns background music playback and music transitions.
##
## Location scenes request music by stable location/world IDs. Battle music is
## selected while the Battle scene is active, then the correct location track
## is restored when combat ends. Missing MP3 files are handled safely so the
## project remains runnable while the user is still uploading assets.

const OVERWORLD_MUSIC_PATH := "res://assets/audio/music/overworld.mp3"
const TUTORIAL_TOWN_MUSIC_PATH := "res://assets/audio/music/tutorial_town.mp3"
const BATTLE_MUSIC_PATH := "res://assets/audio/music/battle.mp3"

var music_player: AudioStreamPlayer
var current_track_path: String = ""
var _last_scene_path: String = ""
var _check_timer: float = 0.0


func _ready() -> void:
	# A single persistent player prevents separate scenes from accidentally
	# leaving multiple background tracks running at the same time.
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusicPlayer"
	music_player.bus = "Master"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	# Re-evaluate the track after every scene transition. SceneManager's
	# scene_changed signal fires after the new current scene is established.
	get_tree().scene_changed.connect(_on_scene_changed)
	set_process(true)
	call_deferred("_on_scene_changed")


func _process(delta: float) -> void:
	# Poll occasionally as a safety net in case a scene transition bypasses the
	# expected signal timing, or a track stops unexpectedly without an error.
	_check_timer += delta
	if _check_timer < 0.5:
		return
	_check_timer = 0.0

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	if current_scene.scene_file_path != _last_scene_path:
		_on_scene_changed()
	elif not current_track_path.is_empty() and not music_player.playing:
		_on_scene_changed()


func _on_scene_changed() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	var scene_path := current_scene.scene_file_path
	_last_scene_path = scene_path
	print("AudioManager: scene detected: ", scene_path)
	if scene_path == "res://ui/MainMenu.tscn":
		stop_music()
		return

	if scene_path.ends_with("/Battle.tscn") or scene_path == "res://scenes/Battle.tscn":
		play_track(BATTLE_MUSIC_PATH)
		return

	# Prefer the stable world/location IDs maintained by SceneManager. A future
	# world can receive its own track without hard-coding a scene-node name.
	var location_id := SceneManager.current_location_id
	if not location_id.is_empty():
		var location_track_path := "res://assets/audio/music/%s.mp3" % location_id
		if ResourceLoader.exists(location_track_path):
			play_track(location_track_path)
			return

	# The world map uses the overworld theme. Every town or other local
	# world uses the shared Tutorial Town theme by default, including towns
	# added later. A location-specific <location_id>.mp3 above overrides this.
	if SceneManager.current_world_id == "world_map":
		play_track(OVERWORLD_MUSIC_PATH)
	else:
		play_track(TUTORIAL_TOWN_MUSIC_PATH)


func play_track(track_path: String) -> void:
	if track_path == current_track_path and music_player.playing:
		return

	if not ResourceLoader.exists(track_path):
		# Keep a missing track visible in the debugger instead of failing silently.
		music_player.stop()
		current_track_path = ""
		push_warning("AudioManager: music file not found: " + track_path)
		return

	var loaded_resource := load(track_path)
	if not loaded_resource is AudioStream:
		push_warning("AudioManager: music file could not be loaded: " + track_path)
		music_player.stop()
		current_track_path = ""
		return

	music_player.stop()
	music_player.stream = loaded_resource as AudioStream
	current_track_path = track_path
	music_player.play()
	print("AudioManager: playing music: ", track_path)


func stop_music() -> void:
	music_player.stop()
	current_track_path = ""


func _on_music_finished() -> void:
	# Loop explicitly as a fallback for stream formats/import settings that do
	# not preserve the loop flag in the imported resource.
	if music_player.stream != null:
		music_player.play()
