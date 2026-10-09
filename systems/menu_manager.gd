extends Node
## Coordinates mutually exclusive player-facing menus.
##
## Menus request ownership before becoming visible and release their claim
## when closed. This prevents shortcuts and buttons from stacking overlays.
## The manager also owns the shared menu movement lock, so every menu stops
## the Player consistently instead of relying on each UI script to remember it.

var active_menu_id: String = ""


func try_open_menu(menu_id: String) -> bool:
	# Only one menu may own the screen at a time.
	if not active_menu_id.is_empty() and active_menu_id != menu_id:
		return false

	active_menu_id = menu_id
	_update_player_movement_lock(true)
	return true


func close_menu(menu_id: String) -> void:
	# A menu can release only its own claim. A blocked or unrelated menu must
	# never clear another menu's movement lock.
	if active_menu_id != menu_id:
		return

	active_menu_id = ""
	_update_player_movement_lock(false)


func is_menu_open() -> bool:
	return not active_menu_id.is_empty()


func is_menu_active(menu_id: String) -> bool:
	return active_menu_id == menu_id


func _update_player_movement_lock(locked: bool) -> void:
	# The Player may not exist when Options is opened from the Main Menu.
	# Looking up the active Player each time keeps this safe across scene changes.
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var movement: Node = player.get_node_or_null("PlayerMovement")
	if movement == null or not movement.has_method("set_movement_lock"):
		return

	# A named lock is independent from dialogue, transition, and other movement
	# restrictions. Releasing a menu therefore cannot unlock those systems.
	movement.set_movement_lock("menu", locked)
