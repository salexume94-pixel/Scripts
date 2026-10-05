extends Node
## Provides a small set of test item definitions for development.
##
## This script exists only to give the inventory, item-use, and equipment
## systems concrete items to work with while the full item catalog is built.
##
## The item definitions remain ItemData Resources. This script creates those
## Resources in memory and exposes them through stable IDs so gameplay systems
## can use the same definitions consistently during development.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")

const TEST_POTION := "test_potion"
const TEST_SWORD := "test_sword"
const TEST_GOLD := "test_gold"

static func create_test_items() -> Dictionary:
	# Build representative items for the major item behavior categories.
	var items: Dictionary = {}

	# The potion is a consumable that restores HP when used.
	var potion: Resource = ITEM_DATA_SCRIPT.new()
	potion.set("item_id", TEST_POTION)
	potion.set("display_name", "Test Potion")
	potion.set("description", "A temporary test consumable that restores 25 HP.")
	potion.set("item_type", ITEM_DATA_SCRIPT.ItemType.CONSUMABLE)
	potion.set("heal_hp", 25)
	potion.set("max_stack_size", 10)
	items[TEST_POTION] = potion

	# The sword is equipment that occupies the weapon slot and grants attack.
	var sword: Resource = ITEM_DATA_SCRIPT.new()
	sword.set("item_id", TEST_SWORD)
	sword.set("display_name", "Test Sword")
	sword.set("description", "A temporary test weapon that grants +5 Attack.")
	sword.set("item_type", ITEM_DATA_SCRIPT.ItemType.EQUIPMENT)
	sword.set("equipment_slot", "weapon")
	sword.set("attack_bonus", 5)
	sword.set("max_stack_size", 1)
	items[TEST_SWORD] = sword

	# Gold represents a currency-style item. It is intentionally not usable
	# through the normal consumable action.
	var gold: Resource = ITEM_DATA_SCRIPT.new()
	gold.set("item_id", TEST_GOLD)
	gold.set("display_name", "Test Gold")
	gold.set("description", "A temporary stackable item representing currency.")
	gold.set("item_type", ITEM_DATA_SCRIPT.ItemType.CURRENCY)
	gold.set("max_stack_size", 999)
	items[TEST_GOLD] = gold

	return items
