extends StaticBody2D
## Handles the behavior of a reusable World chest.
##
## This script is responsible only for the chest's World interaction state.
## It detects when the Player is close enough to interact, listens for the
## interaction key, and changes the chest from closed to open.
##
## The chest does not own inventory logic or item definitions. Those systems
## will be connected later when the item and inventory architecture exists.

# Tracks whether the Player is currently close enough to interact.
var player_in_range: bool = false

# Tracks whether this chest has already been opened.
# A chest can only be opened once in this initial implementation.
var is_opened: bool = false


func _ready() -> void:
	# Connect the interaction Area signals so the chest knows when the Player
	# enters or leaves its interaction range.
	$InteractionArea.body_entered.connect(_on_interaction_area_body_entered)
	$InteractionArea.body_exited.connect(_on_interaction_area_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	# Ignore input after the chest has already been opened.
	if is_opened:
		return

	# Only accept the interaction key while the Player is within range.
	if not player_in_range:
		return

	# The first chest test uses the E key directly.
	# A shared interaction input system can replace this later without
	# changing the chest's open/closed responsibilities.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			open_chest()


func open_chest() -> void:
	# Prevent duplicate opening calls if the function is triggered again.
	if is_opened:
		return

	# Record the new chest state before changing the presentation.
	is_opened = true

	# Change the visible lid to show that the chest is now open.
	$ChestVisual.color = Color(0.65, 0.45, 0.18, 1.0)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	# Only the Player should activate this chest's interaction range.
	if body.name != "Player":
		return

	player_in_range = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	# Only clear the interaction state when the Player leaves the range.
	if body.name != "Player":
		return

	player_in_range = false
