extends Resource
## Defines the shared data structure for an item.
##
## This script describes what an item is and what basic behavior data it
## carries. It does not store Player ownership or perform the actual action.
## Inventory, equipment, stats, and item-use systems remain responsible for
## applying these definitions to the Player.
##
## Keeping behavior data here lets future item types be added without making
## the HUD or inventory system responsible for knowing every item's rules.

class_name ItemData

## Broad item categories. Additional categories can be added as the game grows
## without changing how inventory quantities are stored.
enum ItemType {
	CONSUMABLE,
	EQUIPMENT,
	CURRENCY,
	MATERIAL,
	KEY_ITEM,
}

## A stable identifier used by game systems to recognize this item.
@export var item_id: String = ""

## The name shown to the Player in menus and other UI.
@export var display_name: String = ""

## A short description explaining what the item is or does.
@export_multiline var description: String = ""

## The broad behavior category used by item systems and UI.
@export var item_type: ItemType = ItemType.MATERIAL

## The equipment slot used when this item is equipped.
## This remains empty for items that are not equipment.
@export var equipment_slot: String = ""

## HP restored when a consumable is used.
@export_range(0, 9999) var heal_hp: int = 0

## MP restored when a consumable is used.
@export_range(0, 9999) var heal_mp: int = 0

## Attack added while this equipment item is equipped.
@export var attack_bonus: int = 0

## Defense added while this equipment item is equipped.
@export var defense_bonus: int = 0

## The maximum number of copies that can occupy one inventory stack.
@export_range(1, 999) var max_stack_size: int = 1
