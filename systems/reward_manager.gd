extends Node
## Coordinates rewards granted by gameplay systems.
##
## Combat, quests, and future world rewards can send XP, gold, and item
## definitions here instead of each system implementing its own reward rules.
## PlayerProgression owns XP/level rules, while PlayerInventory remains the
## owner of normal inventory operations.
##
## Battle can grant rewards while no Player scene exists, so this manager also
## provides a GameState-backed fallback for runtime-only inventory snapshots.

const PLAYER_PROGRESSION = preload("res://player/player_progression.gd")
const ITEM_DATABASE = preload("res://items/item_database.gd")

func grant_experience(amount: int) -> int:
	# Apply XP using the exact same progression rules used by PlayerProgression.
	var stats := GameState.get_player_stats()
	if stats.is_empty() or amount <= 0:
		return 0

	var result: Dictionary = PLAYER_PROGRESSION.apply_experience_to_snapshot(stats, amount)
	GameState.set_player_stats(result["stats"])
	return int(result["levels_gained"])

func grant_gold(amount: int) -> bool:
	# Gold is a separate currency rather than an inventory stack.
	if amount <= 0:
		return false
	GameState.set_gold(GameState.get_gold() + amount)
	return true

func grant_item(item_id: String, quantity: int = 1) -> bool:
	# Resolve rewards through ItemDatabase so reward definitions use stable IDs.
	var item: Resource = ITEM_DATABASE.get_item(item_id)
	if item == null or quantity <= 0:
		return false

	# Use the active PlayerInventory when the Player scene exists. This preserves
	# the normal inventory validation path during overworld/quest rewards.
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var inventory := players[0].get_node_or_null("PlayerInventory")
		if inventory != null:
			return inventory.add_item(item, quantity)

	# Battle has no Player node, so modify the same GameState snapshot directly.
	# The same ItemData stack limit is enforced here to prevent invalid rewards.
	var inventory_snapshot := GameState.get_inventory()
	var current_quantity: int = int(inventory_snapshot.get(item_id, 0))
	var max_stack_size: int = int(item.get("max_stack_size"))
	if current_quantity + quantity > max_stack_size:
		return false

	inventory_snapshot[item_id] = current_quantity + quantity
	GameState.set_inventory(inventory_snapshot)
	return true

func grant_quest_rewards(rewards: Array) -> Dictionary:
	# Quest rewards may contain experience, gold, and/or item_id + quantity.
	var result := {
		"experience": 0,
		"gold": 0,
		"items_granted": 0,
		"items_failed": 0,
		"levels_gained": 0,
	}

	for reward in rewards:
		if typeof(reward) != TYPE_DICTIONARY:
			continue

		var experience: int = int(reward.get("experience", 0))
		var gold: int = int(reward.get("gold", 0))
		var item_id: String = str(reward.get("item_id", ""))
		var quantity: int = int(reward.get("quantity", 1))

		if experience > 0:
			result["levels_gained"] += grant_experience(experience)
			result["experience"] += experience

		if gold > 0 and grant_gold(gold):
			result["gold"] += gold

		if not item_id.is_empty():
			if grant_item(item_id, quantity):
				result["items_granted"] += quantity
			else:
				result["items_failed"] += quantity

	return result
