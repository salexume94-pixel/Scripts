extends Node2D
## Handles the presentation side of the Interior scene.
##
## This script owns the Interior camera's presentation behavior. It does not
## move the Player, create interior collision, or handle scene transitions.
##
## The camera follows the Player using the same presentation pattern as the
## World camera so entering an interior does not leave the game without an
## active camera.

@export var target_path: NodePath = NodePath("../Player")

@onready var camera: Camera2D = $Camera2D

var target: Node2D


func _ready() -> void:
	# Resolve the Player from the Interior scene so the camera follows the
	# active Player instance rather than assuming a fixed world position.
	target = get_node_or_null(target_path) as Node2D

	if target == null:
		push_error(
			"InteriorPresentation could not find camera target at: %s"
			% target_path
		)
		return

	# Explicitly enable this camera and make it current. The World scene is
	# replaced during an interior transition, so the Interior needs its own
	# active Camera2D.
	camera.enabled = true
	camera.make_current()

	if not camera.is_current():
		push_error("InteriorPresentation Camera2D failed to become current.")
		return

	# Center the first rendered frame on the Player immediately. This prevents
	# the Interior from briefly displaying its origin before the first update.
	_update_camera_position()

	print("InteriorPresentation: camera target = ", target.get_path())


func _physics_process(_delta: float) -> void:
	# Follow the Player after physics movement so the camera remains centered
	# as the Player moves around the Interior.
	_update_camera_position()


func _update_camera_position() -> void:
	if target == null:
		return

	# Player and InteriorPresentation are siblings, so global coordinates keep
	# camera positioning independent of either node's parent transform.
	camera.global_position = target.global_position
