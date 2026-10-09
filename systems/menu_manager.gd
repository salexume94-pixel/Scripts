extends Node
## Coordinates mutually exclusive player-facing menus.
##
## Menus request ownership before becoming visible and release their claim
## when closed. This prevents shortcuts and buttons from stacking overlays.

var active_menu_id: String = ""

func try_open_menu(menu_id: String) -> bool:
	# Only one menu may own the screen at a time.
	if active_menu_id.is_empty() or active_menu_id == menu_id:
		active_menu_id = menu_id
		return true
	return false

func close_menu(menu_id: String) -> void:
	# A menu can release only its own claim.
	if active_menu_id == menu_id:
		active_menu_id = ""

func is_menu_open() -> bool:
	return not active_menu_id.is_empty()

func is_menu_active(menu_id: String) -> bool:
	return active_menu_id == menu_id
