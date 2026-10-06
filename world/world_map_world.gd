extends Node2D
## Presents the playable overworld travel space.
##
## This scene is the first larger world layer outside Tutorial Town. It owns
## only the physical presentation of that space. SceneManager handles travel,
## WorldContext identifies the active map, and MapManager tracks the Player.

func _ready() -> void:
	# Keep the overworld presentation independent from the Player and map UI.
	# The Player is placed by SceneManager after the scene finishes loading.
	pass
