extends StaticBody2D
## Handles the behavior of a reusable World chest.
##
## This script owns the chest's interaction state and deciding when its reward
## is granted. It does not define the item or store inventory.
##
## ItemData defines the reward, while PlayerInventory stores it. Keeping those
## responsibilities separate preserves the project's one-primary-job
## architecture.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")
const ITEM_DATABASE = preload("res://items/item_database.gd")

## Stable item ID used to choose the reward for this chest.
@export var reward_item_id: String = "potion"

# Tracks whether this chest has already been opened.
var is_opened: bool = false


func _ready() -> void:
	# Register this Chest with the shared interaction system. The Player can
	# then find it by distance without depending on Area2D overlap callbacks.
	add_to_group("interactable")


func interact(player: Node) -> void:
	# The shared InteractionSystem passes the Player that pressed E.
	open_chest(player)


func open_chest(player: Node) -> void:
	# Prevent duplicate opening calls if the function is triggered again.
	if is_opened:
		return

	if player == null:
		return

	# The Player's inventory is a dedicated child system, so the Chest asks
	# that system to store the reward instead of modifying inventory data
	# directly.
	var inventory := player.get_node_or_null("PlayerInventory")
	if inventory == null:
		return

	# Resolve the configured reward ID through the authoritative item catalog.
	var reward: Resource = ITEM_DATABASE.get_item(reward_item_id)

	# Refuse invalid IDs rather than creating or inventing item data at runtime.
	if reward == null or reward.get_script() != ITEM_DATA_SCRIPT:
		return

	# Only mark the Chest as opened after the inventory successfully accepts
	# the reward. This prevents a failed inventory operation from consuming
	# the Chest's reward.
	if not inventory.add_item(reward, 1):
		return

	is_opened = true

	# Change the visible Chest to show that it has been opened.
	$ChestVisual.color = Color(0.65, 0.45, 0.18, 1.0)
