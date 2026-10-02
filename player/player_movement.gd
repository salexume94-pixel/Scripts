extends Node
## Handles player movement.
##
## This script is responsible only for movement and movement input.

@export var move_speed: float = 200.0

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent() as CharacterBody2D


func _physics_process(_delta: float) -> void:
	if player == null:
		return

	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	player.velocity = direction * move_speed
	player.move_and_slide()
