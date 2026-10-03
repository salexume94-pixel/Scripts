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

	# Activate this camera so it becomes the World scene's visible
	# viewpoint when the World scene is running.
	camera.enabled = true

	# Position the camera immediately so the first rendered frame is
	# already centered on the target instead of starting at the origin.
	_update_camera_position()


func _process(_delta: float) -> void:
	# Keep the camera centered on the target as the target moves.
	# This leaves camera behavior in the World presentation system
	# instead of adding camera responsibilities to the Player.
	_update_camera_position()


func _update_camera_position() -> void:
	if target == null:
		return

	camera.global_position = target.global_position
