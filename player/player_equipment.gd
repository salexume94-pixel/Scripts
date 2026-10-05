extends Node
## Owns the Player's equipped items.
##
## This script is responsible for deciding what equipment is currently equipped
## and applying its stat effects through PlayerStats.
## It does not draw UI and does not decide which inventory slot is selected.
##
## Equipment is transferred out of PlayerInventory while equipped. When it is
## unequipped, the item is returned to PlayerInventory. GameState stores the
## equipped item IDs so the equipment survives scene transitions.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")
const TEST_ITEMS_SCRIPT = preload("res://items/test_items.gd")

# Each key is an equipment slot and each value is the item_id equipped there.
var equipped_items: Dictionary = {}


func _ready() -> void:
	# Restore the runtime equipment snapshot whenever a new Player is created.
	equipped_items = GameState.get_equipment()


func equip_item(item: Resource) -> bool:
	# Only equipment definitions can enter PlayerEquipment.
	if item == null or item.get_script() != ITEM_DATA_SCRIPT:
		return false

	if item.get("item_type") != ITEM_DATA_SCRIPT.ItemType.EQUIPMENT:
		return false

	var slot: String = item.get("equipment_slot")
	var item_id: String = item.get("item_id")

	if slot == "" or item_id == "":
		return false

	var inventory = get_parent().get_node_or_null("PlayerInventory")
	var stats = get_parent().get_node_or_null("PlayerStats")
	if inventory == null or stats == null:
		return false

	# The item must be owned by the Player before it can be equipped.
	if not inventory.has_item(item):
		return false

	# Replace existing equipment in this slot by returning it to inventory.
	if equipped_items.has(slot):
		var old_item_id: String = equipped_items[slot]
		var old_item: Resource = _get_item_definition(old_item_id)
		if old_item == null:
			return false

		if not _unequip_slot(slot, old_item, inventory, stats):
			return false

	# Transfer ownership from inventory to equipment.
	if not inventory.remove_item(item):
		return false

	equipped_items[slot] = item_id
	stats.apply_equipment_modifiers(
		item.get("attack_bonus"),
		item.get("defense_bonus")
	)
	_sync_to_game_state()
	return true


func unequip_slot(slot: String) -> bool:
	# Unequip by slot so UI does not need to know how equipment storage works.
	if not equipped_items.has(slot):
		return false

	var inventory = get_parent().get_node_or_null("PlayerInventory")
	var stats = get_parent().get_node_or_null("PlayerStats")
	if inventory == null or stats == null:
		return false

	var item_id: String = equipped_items[slot]
	var item: Resource = _get_item_definition(item_id)
	if item == null:
		return false

	return _unequip_slot(slot, item, inventory, stats)


func is_equipped(item: Resource) -> bool:
	# Equipment state is queried by item ID so recreated Resource instances still
	# match the same equipped item after a scene transition.
	if item == null:
		return false

	var item_id: String = item.get("item_id")
	for equipped_id in equipped_items.values():
		if equipped_id == item_id:
			return true
	return false


func get_equipped_items() -> Dictionary:
	# Return a copy so the UI can inspect equipment without owning its data.
	return equipped_items.duplicate()


func _unequip_slot(
	slot: String,
	item: Resource,
	inventory: Node,
	stats: Node
) -> bool:
	# Return the item to inventory before removing its stat effects. If the
	# inventory cannot accept it, leave the equipment unchanged.
	if not inventory.add_item(item):
		return false

	stats.remove_equipment_modifiers(
		item.get("attack_bonus"),
		item.get("defense_bonus")
	)
	equipped_items.erase(slot)
	_sync_to_game_state()
	return true


func _get_item_definition(item_id: String) -> Resource:
	# Test item definitions are temporary, so this lookup currently resolves
	# against the development catalog. A full item database can replace this
	# without changing the equipment ownership logic.
	var definitions: Dictionary = TEST_ITEMS_SCRIPT.create_test_items()
	return definitions.get(item_id)


func _sync_to_game_state() -> void:
	# GameState keeps equipment alive when scene transitions recreate Player.
	GameState.set_equipment(equipped_items)
