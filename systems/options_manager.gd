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


func _ready() -> void:
	_load_settings()
	_create_brightness_overlay()
	_create_options_canvas_layer()
	_apply_loaded_settings()

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
