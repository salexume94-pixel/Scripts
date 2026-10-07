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
	# Register every Chest with SaveManager so opened/unopened state can survive
	# scene changes and disk Save/Load without hard-coding individual chests.
	add_to_group("persistent_chest")
	add_to_group("interactable")

	# The visible Chest must match the restored runtime state immediately when
	# the scene is created. SaveManager applies saved state after scene loading,
	# while unopened chests remain in their normal default appearance.
	_update_visual()


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
	_update_visual()


func get_save_id() -> String:
	# Scene file path plus node path gives each placed Chest a stable identity
	# without requiring every future scene to maintain a separate ID registry.
	var scene_path := get_tree().current_scene.scene_file_path
	return "%s::%s" % [scene_path, str(get_path())]


func get_save_data() -> Dictionary:
	# Save only the minimal runtime state owned by the Chest itself.
	return {
		"is_opened": is_opened,
	}


func load_save_data(data: Dictionary) -> void:
	# Ignore malformed values and restore only the Chest state this script owns.
	if typeof(data) != TYPE_DICTIONARY:
		return

	is_opened = bool(data.get("is_opened", false))
	_update_visual()


func _update_visual() -> void:
	# Keep presentation derived from the authoritative is_opened state instead
	# of allowing the save system to manipulate scene visuals directly.
	if has_node("ChestVisual"):
		$ChestVisual.color = Color(0.65, 0.45, 0.18, 1.0) if is_opened else Color(0.50, 0.30, 0.12, 1.0)
