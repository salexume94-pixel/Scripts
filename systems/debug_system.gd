extends Node
## Provides development-only debug actions.
##
## This script owns test and diagnostic gameplay actions that are useful while
## building the game but are not part of normal Player gameplay.
##
## Keeping these actions here prevents the Character/Inventory HUD from
## directly modifying PlayerStats. The HUD only presents the debug control
## and requests the action from this system.

static func test_damage(player: Node, amount: int = 25) -> bool:
	# Apply a controlled amount of damage through PlayerStats so item behavior
	# can be tested before the full combat system exists.
	if player == null:
		return false

	var stats: Node = player.get_node_or_null("PlayerStats")
	if stats == null:
		return false

	stats.take_damage(amount)
	return true
