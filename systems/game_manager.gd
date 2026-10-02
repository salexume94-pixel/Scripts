extends Node
## Global coordinator for the game.
##
## GameManager is responsible for high-level game state and coordination.
## It should not contain player, combat, inventory, or UI implementation.

var game_started: bool = false


func start_new_game() -> void:
	game_started = true


func end_game() -> void:
	game_started = false
