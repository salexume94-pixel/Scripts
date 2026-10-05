extends StaticBody2D
## Handles the behavior of a reusable World chest.
##
## This script is responsible for the chest's World interaction state and
## deciding when its reward is granted. It does not define the item itself
## or store the Player's inventory.
##
## ItemData defines the reward, while PlayerInventory stores it. Keeping
## those responsibilities separate preserves the project's one-primary-job
## architecture.

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

	# Find the Player from the current World scene. The Chest is a child of
	# WorldContent while the Player is a sibling under the World root.
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	# The Player's inventory is a dedicated child system, so the Chest asks
	# that system to store the reward instead of modifying inventory data
	# directly.
	var inventory := player.get_node_or_null("PlayerInventory")
	if inventory == null:
		return

	# Create the temporary development reward used to prove that the Chest
	# can pass an ItemData object into the Player's inventory.
	var test_items := TestItems.create_test_items()
	var reward: ItemData = test_items[TestItems.TEST_POTION]

	# Only mark the Chest as opened after the inventory successfully accepts
	# the reward. This prevents a failed inventory operation from consuming
	# the Chest's reward.
	if not inventory.add_item(reward, 1):
		return

	# Record the new chest state after the reward has been granted.
	is_opened = true

	# Change the visible Chest to show that it has been opened.
	$ChestVisual.color = Color(0.65, 0.45, 0.18, 1.0)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	# Only the Player should activate this Chest's interaction range.
	if body.name != "Player":
		return

	player_in_range = true


func _on_interaction_area_body_exited(body: Node2D) -> void:
	# Only clear the interaction state when the Player leaves the range.
	if body.name != "Player":
		return

	player_in_range = false
