extends Node2D
## Handles the presentation side of the World scene.
##
## This script is responsible for keeping the World camera focused on
## the active player. It does not handle player movement, world gameplay,
## or world objects. Those responsibilities remain in their own systems.
##
## The camera provides the visible window into the World. The project's
## 1152x648 viewport is the presentation baseline, while the actual World
## can extend beyond that visible area.

@export var target_path: NodePath = NodePath("../Player")

@onready var camera: Camera2D = $Camera2D

var target: Node2D


func _ready() -> void:
	# Find the object that the presentation camera should follow.
	# The target is supplied by the World scene instead of hard-coding
	# a specific gameplay system into this presentation script.
	target = get_node_or_null(target_path) as Node2D

	# Explicitly enable and make this camera the active World camera.
	# Enabling allows the camera to operate, while make_current() removes
	# any ambiguity about which Camera2D should control the viewport.
	camera.enabled = true
	camera.make_current()

	# Position the camera immediately so the first rendered frame is
	# already centered on the target instead of starting at the origin.
	_update_camera_position()


func _physics_process(_delta: float) -> void:
	# Update the camera after the Player's physics movement.
	# This keeps the camera in the World presentation system while making
	# the camera position follow the Player on the same movement cycle.
	_update_camera_position()


func _update_camera_position() -> void:
	if target == null:
		return

	# Use global coordinates because the Player is a sibling of
	# WorldPresentation rather than a child of the camera node.
	camera.global_position = target.global_position
