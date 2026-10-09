extends Control
## Presents the user's brightness and master-volume settings.
##
## OptionsManager owns applying and saving the actual preferences. This script
## only synchronizes the sliders with that manager and provides a Back button.

@onready var brightness_slider: HSlider = $Center/Panel/Margin/OptionsVBox/BrightnessSlider
@onready var volume_slider: HSlider = $Center/Panel/Margin/OptionsVBox/VolumeSlider


func _ready() -> void:
	brightness_slider.value = OptionsManager.brightness
	volume_slider.value = OptionsManager.master_volume
	brightness_slider.grab_focus()


func set_brightness_value(value: float) -> void:
	if is_node_ready():
		brightness_slider.value = value


func set_volume_value(value: float) -> void:
	if is_node_ready():
		volume_slider.value = value


func _on_brightness_changed(value: float) -> void:
	OptionsManager.set_brightness(value)


func _on_volume_changed(value: float) -> void:
	OptionsManager.set_master_volume(value)


func _on_back_button_pressed() -> void:
	OptionsManager.close_options()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		OptionsManager.close_options()
		get_viewport().set_input_as_handled()
