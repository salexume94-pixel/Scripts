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
##
## The item scripts are explicitly preloaded so this scene does not depend
## on Godot's global class-name cache being refreshed first.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")
const ITEM_DATABASE = preload("res://items/item_database.gd")

## Stable item ID used to choose the development reward for this chest.
@export var reward_item_id: String = "potion"

# Tracks whether the Player is currently close enough to interact.
var player_in_range: bool = false

# Tracks whether this chest has already been opened.
# A chest can only be opened once in this initial implementation.
var is_opened: bool = false


func interact(_player: Node) -> void:
	# The shared InteractionSystem calls this method when the Player presses E
	# near the Chest. The Chest owns the reward and open-state behavior.
	open_chest()


func open_chest() -> void:
	# Prevent duplicate opening calls if the function is triggered again.
	if is_opened:
		return

	# Find the active Player from the current gameplay scene. The interaction
	# system already verified that this Chest is within interaction range.
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	# The Player's inventory is a dedicated child system, so the Chest asks
	# that system to store the reward instead of modifying inventory data
	# directly.
	var inventory := player.get_node_or_null("PlayerInventory")
	if inventory == null:
		return

	# Resolve the configured reward ID through the authoritative item catalog.
	# The Chest owns the reward event, while ItemDatabase owns the definition.
	var reward: Resource = ITEM_DATABASE.get_item(reward_item_id)

	# Refuse invalid IDs rather than creating or inventing item data at runtime.
	if reward == null or reward.get_script() != ITEM_DATA_SCRIPT:
		return

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
