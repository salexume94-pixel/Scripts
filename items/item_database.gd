extends Node
## Provides the game's authoritative item-definition catalog.
##
## Item quantities are stored by item_id, while this database owns the mapping
## from those IDs to the actual ItemData Resources used by gameplay systems.
## Keeping definitions in Resource files means inventory, equipment, chests, and
## UI all reference the same persistent definitions instead of rebuilding items
## in code.
##
## The catalog is intentionally small while the project is under construction.
## New item Resource files can be added here without changing the systems that
## consume them.

const POTION: Resource = preload("res://items/definitions/potion.tres")
const IRON_SWORD: Resource = preload("res://items/definitions/iron_sword.tres")
const WOODEN_SHIELD: Resource = preload("res://items/definitions/wooden_shield.tres")
const LEATHER_HELM: Resource = preload("res://items/definitions/leather_helm.tres")
const LEATHER_ARMOR: Resource = preload("res://items/definitions/leather_armor.tres")
const POWER_RING: Resource = preload("res://items/definitions/power_ring.tres")
const GOLD: Resource = preload("res://items/definitions/gold.tres")

static func get_item(item_id: String) -> Resource:
	# Resolve a stable item ID to its shared Resource definition.
	match item_id:
		"potion":
			return POTION
		"iron_sword":
			return IRON_SWORD
		"wooden_shield":
			return WOODEN_SHIELD
		"leather_helm":
			return LEATHER_HELM
		"leather_armor":
			return LEATHER_ARMOR
		"power_ring":
			return POWER_RING
		"gold":
			return GOLD
		_:
			return null

static func get_all_items() -> Array[Resource]:
	# Return every currently registered definition for tools and future catalogs.
	return [
		POTION,
		IRON_SWORD,
		WOODEN_SHIELD,
		LEATHER_HELM,
		LEATHER_ARMOR,
		POWER_RING,
		GOLD,
	]
