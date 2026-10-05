extends Node
## Provides a small set of test item definitions for development.
##
## This script exists only to give the inventory and Chest systems concrete
## items to work with while the full item catalog is still being built.
##
## The item definitions themselves remain ItemData Resources. This script
## creates those Resources in memory and exposes them through named constants
## so other systems can use consistent test data during development.
##
## The ItemData script is explicitly preloaded instead of relying on Godot's
## global class-name cache. This keeps the dependency deterministic when the
## project is opened or pulled into a fresh editor session.

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")

const TEST_POTION := "test_potion"
const TEST_SWORD := "test_sword"
const TEST_GOLD := "test_gold"

static func create_test_items() -> Dictionary:
	# Build a small collection of representative items so later systems can
	# test stacking, equipment-style items, and ordinary consumables without
	# requiring the complete item database to exist yet.
	var items: Dictionary = {}

	# Create the test potion from the explicitly loaded ItemData script.
	var potion: Resource = ITEM_DATA_SCRIPT.new()
	potion.set("item_id", TEST_POTION)
	potion.set("display_name", "Test Potion")
	potion.set("description", "A temporary test consumable for inventory development.")
	potion.set("category", "consumable")
	potion.set("max_stack_size", 10)
	items[TEST_POTION] = potion

	# Create the test sword from the same ItemData definition.
	var sword: Resource = ITEM_DATA_SCRIPT.new()
	sword.set("item_id", TEST_SWORD)
	sword.set("display_name", "Test Sword")
	sword.set("description", "A temporary test weapon for inventory development.")
	sword.set("category", "weapon")
	sword.set("max_stack_size", 1)
	items[TEST_SWORD] = sword

	# Create the test gold item as a large stackable Resource.
	var gold: Resource = ITEM_DATA_SCRIPT.new()
	gold.set("item_id", TEST_GOLD)
	gold.set("display_name", "Test Gold")
	gold.set("description", "A temporary stackable item representing currency.")
	gold.set("category", "currency")
	gold.set("max_stack_size", 999)
	items[TEST_GOLD] = gold

	return items
