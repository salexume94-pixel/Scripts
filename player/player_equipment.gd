extends Node
## Owns the Player's equipped item set.
##
## This script is the single owner of equipment state and equipment-slot rules.
## It validates equipment definitions, transfers ownership between inventory
## and equipment, applies stat modifiers, and restores equipment after a scene
## transition. It does not draw UI or decide which item the Player selected.
##
## Equipment is stored by stable item ID so scene recreation does not depend on
## a particular Resource instance remaining alive.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")
const ITEM_DATABASE = preload("res://items/item_database.gd")

# Each key is an ItemData.EquipmentSlot value and each value is the equipped
# item's stable ID. Only one item may occupy a slot at a time.
var equipped_items: Dictionary = {}


func _ready() -> void:
	# Restore equipment from the runtime owner when a new Player is created.
	var saved_equipment: Dictionary = GameState.get_equipment()
	var stats: Node = get_parent().get_node_or_null("PlayerStats")

	if stats == null:
		return

	# Save files are JSON, so Dictionary keys are decoded as strings even
	# though equipment slots are stored as integer enum values at runtime.
	# Convert each key back to an integer before validating and restoring it.
	for saved_slot in saved_equipment:
		var slot: int = int(saved_slot)
		var item_id: String = str(saved_equipment[saved_slot])
		var item: Resource = ITEM_DATABASE.get_item(item_id)

		if not _is_valid_equipment(item, slot):
			continue

		# A slot can only be restored once, even if corrupted state contains
		# duplicate information.
		if equipped_items.has(slot):
			continue

		equipped_items[slot] = item_id
		stats.apply_equipment_modifiers(
			item.get("attack_bonus"),
			item.get("defense_bonus")
		)

	_sync_to_game_state()


func equip_item(item: Resource) -> bool:
	# Only valid ItemData equipment can be equipped.
	if item == null or item.get_script() != ITEM_DATA_SCRIPT:
		return false

	var item_data: Resource = item
	if not _is_valid_equipment(item_data, item_data.get("equipment_slot")):
		return false

	var inventory: Node = get_parent().get_node_or_null("PlayerInventory")
	var stats: Node = get_parent().get_node_or_null("PlayerStats")
	if inventory == null or stats == null:
		return false

	# The Player must own the item before equipment can take ownership of it.
	if not inventory.has_item(item_data):
		return false

	var slot: int = item_data.get("equipment_slot")

	# If this slot is already occupied, the old item must successfully return
	# to inventory before the new item can replace it.
	if equipped_items.has(slot):
		var old_item_id: String = equipped_items[slot]
		var old_item: Resource = ITEM_DATABASE.get_item(old_item_id)
		if old_item == null or not _unequip_slot(slot, old_item, inventory, stats):
			return false

	# Transfer one copy from inventory into the equipment slot.
	if not inventory.remove_item(item_data):
		return false

	equipped_items[slot] = item_data.get("item_id")
	stats.apply_equipment_modifiers(
		item_data.get("attack_bonus"),
		item_data.get("defense_bonus")
	)
	_sync_to_game_state()
	return true


func unequip_slot(slot: int) -> bool:
	# Only occupied slots can be unequipped.
	if not equipped_items.has(slot):
		return false

	var inventory: Node = get_parent().get_node_or_null("PlayerInventory")
	var stats: Node = get_parent().get_node_or_null("PlayerStats")
	if inventory == null or stats == null:
		return false

	var item_id: String = equipped_items[slot]
	var item: Resource = ITEM_DATABASE.get_item(item_id)
	if item == null:
		return false

	return _unequip_slot(slot, item, inventory, stats)


func is_equipped(item: Resource) -> bool:
	# Compare by stable item ID so separately loaded Resource references still
	# represent the same equipment definition.
	if item == null:
		return false

	var item_id: String = item.get("item_id")
	for equipped_id in equipped_items.values():
		if equipped_id == item_id:
			return true
	return false


func get_equipped_items() -> Dictionary:
	# Return a copy so UI systems can inspect equipment without owning it.
	return equipped_items.duplicate()


func get_equipped_item(slot: int) -> Resource:
	# Return the definition currently occupying a specific equipment slot.
	if not equipped_items.has(slot):
		return null

	return ITEM_DATABASE.get_item(equipped_items[slot])


func get_equipment_slot_name(slot: int) -> String:
	# Convert the internal enum value into a readable UI label.
	match slot:
		ITEM_DATA_SCRIPT.EquipmentSlot.WEAPON:
			return "Weapon"
		ITEM_DATA_SCRIPT.EquipmentSlot.SHIELD:
			return "Shield"
		ITEM_DATA_SCRIPT.EquipmentSlot.HEAD:
			return "Head"
		ITEM_DATA_SCRIPT.EquipmentSlot.BODY:
			return "Body"
		ITEM_DATA_SCRIPT.EquipmentSlot.ACCESSORY:
			return "Accessory"
		_:
			return "None"


func _is_valid_equipment(item: Resource, slot: int) -> bool:
	# An item must be equipment and must name one of the supported slots.
	if item == null or item.get("item_type") != ITEM_DATA_SCRIPT.ItemType.EQUIPMENT:
		return false

	if item.get("item_id").is_empty():
		return false

	return slot in [
		ITEM_DATA_SCRIPT.EquipmentSlot.WEAPON,
		ITEM_DATA_SCRIPT.EquipmentSlot.SHIELD,
		ITEM_DATA_SCRIPT.EquipmentSlot.HEAD,
		ITEM_DATA_SCRIPT.EquipmentSlot.BODY,
		ITEM_DATA_SCRIPT.EquipmentSlot.ACCESSORY,
	]


func _unequip_slot(
	slot: int,
	item: Resource,
	inventory: Node,
	stats: Node
) -> bool:
	# Unequipping is treated as one ownership transaction. The item must either
	# already be present in inventory or be successfully returned there before
	# the equipment slot is cleared.
	#
	# The first case repairs a stale runtime state where the same item ID is
	# already present in inventory. Because equipment stacks are limited, trying
	# to add another copy would fail and make the HUD appear unable to unequip.
	if not inventory.has_item(item):
		if not inventory.add_item(item):
			return false

	# Only clear the equipment slot after inventory ownership is confirmed.
	# This prevents a failed inventory transfer from leaving a half-updated
	# equipment/stat state.
	stats.remove_equipment_modifiers(
		item.get("attack_bonus"),
		item.get("defense_bonus")
	)
	equipped_items.erase(slot)
	_sync_to_game_state()
	return true


func _sync_to_game_state() -> void:
	# GameState keeps equipment ownership alive across World <-> Interior.
	GameState.set_equipment(equipped_items)
