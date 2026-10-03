extends Node2D
## Handles the presentation side of the World scene.
##
## This script owns the World camera's presentation behavior. It does not
## move the Player or contain World gameplay logic. The Player and World
## content remain separate nodes so each system keeps a clear responsibility.
##
## The project's 1152x648 viewport is the presentation baseline. The World
## itself is larger, and the camera determines which portion is visible.

@export var target_path: NodePath = NodePath("../Player")

@onready var camera: Camera2D = $Camera2D

var target: Node2D


func _ready() -> void:
	# Resolve the Player explicitly from the World scene. Keeping the target
	# as a configurable path lets the presentation system follow the active
	# World actor without hard-coding player movement into this script.
	target = get_node_or_null(target_path) as Node2D

	if target == null:
		push_error(
			"WorldPresentation could not find camera target at: %s"
			% target_path
		)
		return

	# Explicitly enable this camera and make it the active viewport camera.
	# This avoids relying on editor defaults or another Camera2D becoming
	# current by accident.
	camera.enabled = true
	camera.make_current()

	if not camera.is_current():
		push_error("WorldPresentation Camera2D failed to become current.")
		return

	# Center the first rendered frame on the Player immediately instead of
	# briefly showing the World origin before the first physics update.
	_update_camera_position()

	print("WorldPresentation: camera target = ", target.get_path())


func _physics_process(_delta: float) -> void:
	# Follow the Player after physics movement so the camera tracks the
	# position produced by PlayerMovement on the same simulation cycle.
	_update_camera_position()


func _update_camera_position() -> void:
	if target == null:
		return

	# Player and WorldPresentation are siblings, so global coordinates are
	# used to keep camera positioning independent of either node's parent
	# transform.
	camera.global_position = target.global_position
