extends Node
## Owns persistent display/audio preferences and the globally accessible
## Options overlay. UI widgets only edit values; this manager applies and saves
## them so the same settings work from the Main Menu and during gameplay.

const OPTIONS_SCENE_PATH := "res://ui/OptionsMenu.tscn"
const SETTINGS_PATH := "user://settings.cfg"

var brightness: float = 1.0
var master_volume: float = 0.8

var _brightness_overlay: ColorRect
var _options_canvas_layer: CanvasLayer
var _options_menu: Control
var _options_access_button: Button
var _options_access_layer: CanvasLayer


func _ready() -> void:
	_load_settings()
	_create_brightness_overlay()
	_create_options_canvas_layer()
	_create_options_access_button()
	_apply_loaded_settings()

	# Keep the gameplay entry point visible in every scene, but use the Main
	# Menu's dedicated Options button while the startup menu is active.
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_on_scene_changed")

	# ESC opens/closes Options in gameplay and on the Main Menu. The Options
	# menu itself handles ESC as a close action while it is visible.
	set_process_unhandled_key_input(true)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _options_menu != null and is_instance_valid(_options_menu):
			close_options()
		else:
			open_options()
		get_viewport().set_input_as_handled()


func _on_scene_changed() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null or _options_access_button == null:
		return
	_options_access_button.visible = current_scene.scene_file_path != "res://ui/MainMenu.tscn"


func _create_options_access_button() -> void:
	# A visible in-game button makes settings discoverable without requiring the
	# player to already know the Escape shortcut.
	_options_access_layer = CanvasLayer.new()
	_options_access_layer.name = "OptionsAccessLayer"
	_options_access_layer.layer = 19
	add_child(_options_access_layer)

	_options_access_button = Button.new()
	_options_access_button.name = "OptionsAccessButton"
	_options_access_button.text = "Options (Esc)"
	_options_access_button.tooltip_text = "Open display and audio settings"
	_options_access_button.anchor_left = 1.0
	_options_access_button.anchor_right = 1.0
	_options_access_button.anchor_top = 0.0
	_options_access_button.anchor_bottom = 0.0
	_options_access_button.offset_left = -150.0
	_options_access_button.offset_top = 12.0
	_options_access_button.offset_right = -16.0
	_options_access_button.offset_bottom = 48.0
	_options_access_button.pressed.connect(open_options)
	_options_access_layer.add_child(_options_access_button)


func open_options() -> void:
	if _options_menu != null and is_instance_valid(_options_menu):
		return

	var packed_scene := load(OPTIONS_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("OptionsManager could not load " + OPTIONS_SCENE_PATH)
		return

	_options_menu = packed_scene.instantiate() as Control
	_options_menu.tree_exited.connect(_on_options_menu_exited)
	_options_canvas_layer.add_child(_options_menu)
	_options_menu.set_brightness_value(brightness)
	_options_menu.set_volume_value(master_volume)


func close_options() -> void:
	if _options_menu != null and is_instance_valid(_options_menu):
		_options_menu.queue_free()
	_options_menu = null


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.25, 1.5)
	if _brightness_overlay != null:
		# Values below 1 darken the game; values above 1 use no black overlay
		# because a black overlay cannot brighten. Keep the slider range simple
		# and apply darkness only to the lower half of the range.
		_brightness_overlay.color.a = clampf(1.0 - brightness, 0.0, 0.75)
	_save_settings()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.0001)))
		AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)
	_save_settings()


func _create_brightness_overlay() -> void:
	# A translucent black layer dims the rendered game without modifying each
	# scene's lighting. It sits below the Options overlay itself.
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "BrightnessOverlayLayer"
	canvas_layer.layer = 15
	add_child(canvas_layer)

	_brightness_overlay = ColorRect.new()
	_brightness_overlay.name = "BrightnessOverlay"
	_brightness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brightness_overlay.color = Color(0, 0, 0, 0)
	canvas_layer.add_child(_brightness_overlay)


func _create_options_canvas_layer() -> void:
	# Keep the menu above the brightness overlay so its labels and controls stay
	# readable while the user adjusts the brightness setting.
	_options_canvas_layer = CanvasLayer.new()
	_options_canvas_layer.name = "OptionsOverlayLayer"
	_options_canvas_layer.layer = 20
	add_child(_options_canvas_layer)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_apply_loaded_settings()
		return

	brightness = clampf(float(config.get_value("display", "brightness", 1.0)), 0.25, 1.5)
	master_volume = clampf(float(config.get_value("audio", "master_volume", 0.8)), 0.0, 1.0)
	_apply_loaded_settings()


func _apply_loaded_settings() -> void:
	if _brightness_overlay != null:
		_brightness_overlay.color.a = clampf(1.0 - brightness, 0.0, 0.75)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.0001)))
		AudioServer.set_bus_mute(master_bus, master_volume <= 0.001)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "brightness", brightness)
	config.set_value("audio", "master_volume", master_volume)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("OptionsManager could not save settings. Error: %d" % error)


func _on_options_menu_exited() -> void:
	_options_menu = null
