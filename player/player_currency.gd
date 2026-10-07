extends Node
## Owns the Player's currency interface.
##
## Gold is stored by GameState so it survives scene transitions. This node
## provides the Player-facing API for adding, spending, and inspecting gold
## without making gameplay systems manipulate the runtime snapshot directly.

func get_gold() -> int:
	# Currency systems and UI use this read-only accessor.
	return GameState.get_gold()

func add_gold(amount: int) -> bool:
	# Reject negative rewards. Spending uses remove_gold() instead.
	if amount <= 0:
		return false
	GameState.set_gold(GameState.get_gold() + amount)
	return true

func remove_gold(amount: int) -> bool:
	# Never allow the Player's gold to become negative.
	if amount <= 0 or GameState.get_gold() < amount:
		return false
	GameState.set_gold(GameState.get_gold() - amount)
	return true
