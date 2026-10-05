extends Resource
## Defines the shared data structure for an item.
##
## This script describes what an item is, but does not control how the item
## is stored, used, equipped, or awarded. Those responsibilities belong to
## the inventory, equipment, and World systems respectively.
##
## Using a Resource lets individual item definitions be created as reusable
## data assets while keeping the item behavior separate from the data.

class_name ItemData

## A stable identifier used by game systems to recognize this item.
@export var item_id: String = ""

## The name shown to the Player in menus and other UI.
@export var display_name: String = ""

## A short description explaining what the item is or does.
@export_multiline var description: String = ""

## The broad category used to organize the item.
@export var category: String = "misc"

## The maximum number of copies that can occupy one inventory stack.
@export_range(1, 999) var max_stack_size: int = 1
