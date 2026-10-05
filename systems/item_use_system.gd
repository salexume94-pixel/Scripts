extends Node
## Applies the gameplay effect of using an item.
##
## This system keeps item-use rules out of the HUD and PlayerInventory.
## ItemData describes the effect, PlayerInventory owns the item quantity,
## PlayerStats owns the resulting HP/MP values, and this script coordinates
## the operation.
##
## The system is intentionally small so future consumable behaviors can be
## added here without turning the UI into a collection of gameplay rules.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")


static func use_item(player: Node, item: Resource) -> bool:
	# Validate the Player and item before attempting to change either system.
	if player == null or item == null or item.get_script() != ITEM_DATA_SCRIPT:
		return false

	if item.get("item_type") != ITEM_DATA_SCRIPT.ItemType.CONSUMABLE:
		return false

	var inventory = player.get_node_or_null("PlayerInventory")
	var stats = player.get_node_or_null("PlayerStats")
	if inventory == null or stats == null:
		return false

	if not inventory.has_item(item):
		return false

	var hp_restore: int = item.get("heal_hp")
	var mp_restore: int = item.get("heal_mp")

	# Do not consume an item that would have no effect. This prevents wasting a
	# healing item while the relevant Player resource is already full.
	var restored_hp := stats.restore_hp(hp_restore)
	var restored_mp := stats.restore_mp(mp_restore)
	if restored_hp == 0 and restored_mp == 0:
		return false

	# Consume exactly one copy after the effect has successfully been applied.
	return inventory.remove_item(item)
