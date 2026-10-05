extends Node
## Provides a small set of test item definitions for development.
##
## This script exists only to give the inventory and Chest systems concrete
## items to work with while the full item catalog is still being built.
##
## The item definitions themselves remain ItemData Resources. This script
## creates those Resources in memory and exposes them through named constants
## so other systems can use consistent test data during development.

const TEST_POTION := "test_potion"
const TEST_SWORD := "test_sword"
const TEST_GOLD := "test_gold"


static func create_test_items() -> Dictionary:
	# Build a small collection of representative items so later systems can
	# test stacking, equipment-style items, and ordinary consumables without
	# requiring the complete item database to exist yet.
	var items: Dictionary = {}

	var potion := ItemData.new()
	potion.item_id = TEST_POTION
	potion.display_name = "Test Potion"
	potion.description = "A temporary test consumable for inventory development."
	potion.category = "consumable"
	potion.max_stack_size = 10
	items[TEST_POTION] = potion

	var sword := ItemData.new()
	sword.item_id = TEST_SWORD
	sword.display_name = "Test Sword"
	sword.description = "A temporary test weapon for inventory development."
	sword.category = "weapon"
	sword.max_stack_size = 1
	items[TEST_SWORD] = sword

	var gold := ItemData.new()
	gold.item_id = TEST_GOLD
	gold.display_name = "Test Gold"
	gold.description = "A temporary stackable item representing currency."
	gold.category = "currency"
	gold.max_stack_size = 999
	items[TEST_GOLD] = gold

	return items
