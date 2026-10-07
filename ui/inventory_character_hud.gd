extends CanvasLayer
## Displays the Player's Character and Inventory screen.
##
## This script presents Player state and requests gameplay actions from the
## appropriate systems. It does not own item definitions, inventory data,
## equipment state, or stat calculations.
##
## Item definitions come from ItemDatabase. Equipment rules live in
## PlayerEquipment. The HUD only formats those systems' authoritative data.

@onready var screen: Control = $Screen
@onready var level_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/LevelLabel
@onready var experience_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/ExperienceLabel
@onready var gold_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/GoldLabel
@onready var hp_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/HPLabel
@onready var mp_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MPLabel
@onready var attack_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/AttackLabel
@onready var defense_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/DefenseLabel
@onready var magic_attack_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MagicAttackLabel
@onready var magic_defense_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/MagicDefenseLabel
@onready var speed_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/SpeedLabel
@onready var equipment_label: Label = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/EquipmentLabel
@onready var equipment_grid: VBoxContainer = $Screen/Panel/Margin/Columns/CharacterPanel/CharacterMargin/CharacterVBox/EquipmentGrid
@onready var inventory_grid: GridContainer = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/InventoryGrid
@onready var item_name_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemName
@onready var item_description_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemDescription
@onready var item_quantity_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemQuantity
@onready var item_comparison_label: Label = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemDetails/DetailsMargin/DetailsVBox/ItemComparison
@onready var item_action_button: Button = $Screen/Panel/Margin/Columns/InventoryPanel/InventoryMargin/InventoryVBox/ItemActionButton

const ITEM_DATA_SCRIPT = preload("res://items/item_data.gd")
const ITEM_DATABASE = preload("res://items/item_database.gd")
const ITEM_USE_SYSTEM = preload("res://systems/item_use_system.gd")

var selected_item_id: String = ""


func _ready() -> void:
	# Start closed so the world remains active until the Player opens the HUD.
	screen.visible = false
	item_action_button.pressed.connect(_on_item_action_button_pressed)
	_set_player_movement_enabled(true)
	_refresh_screen()


func _unhandled_input(event: InputEvent) -> void:
	# I toggles the Character/Inventory screen.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			screen.visible = not screen.visible
			_set_player_movement_enabled(not screen.visible)

			if screen.visible:
				_refresh_screen()


func _refresh_screen() -> void:
	# Locate the active Player in the current gameplay scene.
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		_show_missing_player()
		return

	_refresh_character_stats(player)
	_refresh_equipment(player)
	_refresh_inventory(player)


func _refresh_character_stats(player: Node) -> void:
	# PlayerStats is the authoritative source for resulting character values.
	var stats: Node = player.get_node_or_null("PlayerStats")
	if stats == null:
		return

	level_label.text = "Level: %d" % stats.get("level")
	experience_label.text = "XP: %d / %d" % [stats.get("experience"), _get_xp_requirement(stats.get("level"))]
	gold_label.text = "Gold: %d" % GameState.get_gold()
	hp_label.text = "HP: %d / %d" % [stats.get("hp"), stats.get("max_hp")]
	mp_label.text = "MP: %d / %d" % [stats.get("mp"), stats.get("max_mp")]
	attack_label.text = "Attack: %d" % stats.get("attack")
	defense_label.text = "Defense: %d" % stats.get("defense")
	magic_attack_label.text = "Magic Attack: %d" % stats.get("magic_attack")
	magic_defense_label.text = "Magic Defense: %d" % stats.get("magic_defense")
	speed_label.text = "Speed: %d" % stats.get("speed")


func _get_xp_requirement(level: int) -> int:
	# Mirror the PlayerProgression curve for presentation without owning it.
	if level >= 50:
		return 0
	return 100 * maxi(level, 1)

func _refresh_equipment(player: Node) -> void:
	# PlayerEquipment owns slot contents. The HUD only creates readable rows.
	var equipment: Node = player.get_node_or_null("PlayerEquipment")
	if equipment == null:
		equipment_label.text = "Equipment: unavailable"
		_clear_equipment_ui()
		return

	equipment_label.text = "Equipment"
	_clear_equipment_ui()

	for slot in [
		ITEM_DATA_SCRIPT.EquipmentSlot.WEAPON,
		ITEM_DATA_SCRIPT.EquipmentSlot.SHIELD,
		ITEM_DATA_SCRIPT.EquipmentSlot.HEAD,
		ITEM_DATA_SCRIPT.EquipmentSlot.BODY,
		ITEM_DATA_SCRIPT.EquipmentSlot.ACCESSORY,
	]:
		var item: Resource = equipment.get_equipped_item(slot)
		var row := Button.new()
		row.custom_minimum_size = Vector2(0, 30)

		if item == null:
			row.text = "%s: None" % equipment.get_equipment_slot_name(slot)
			row.disabled = true
		else:
			row.text = "%s: %s  (%s)  [Unequip]" % [
				equipment.get_equipment_slot_name(slot),
				item.get("display_name"),
				_get_item_bonus_summary(item),
			]
			row.pressed.connect(_on_unequip_slot_pressed.bind(slot))

		equipment_grid.add_child(row)


func _refresh_inventory(player: Node) -> void:
	# PlayerInventory owns quantities. The HUD only creates visual controls.
	var inventory: Node = player.get_node_or_null("PlayerInventory")
	if inventory == null:
		_clear_inventory_ui()
		_clear_item_details()
		return

	var inventory_items: Dictionary = inventory.get_inventory()

	if not inventory_items.has(selected_item_id):
		selected_item_id = ""

	_clear_inventory_slots()

	if inventory_items.is_empty():
		_add_empty_inventory_slot()
		_clear_item_details()
		return

	for item_id in inventory_items:
		_create_inventory_slot(item_id, inventory_items[item_id])

	if selected_item_id != "":
		_show_item_details(selected_item_id, inventory_items)
	else:
		_clear_item_details()


func _create_inventory_slot(item_id: String, quantity: int) -> void:
	# Each inventory entry becomes a selectable button using the shared
	# definition from ItemDatabase.
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(110, 64)
	slot.text = _get_item_display_name(item_id) + "\nx%d" % quantity
	slot.tooltip_text = "Select " + _get_item_display_name(item_id)
	slot.pressed.connect(_on_inventory_slot_pressed.bind(item_id))
	inventory_grid.add_child(slot)


func _add_empty_inventory_slot() -> void:
	# Show an explicit empty state when no items are owned.
	var slot := Label.new()
	slot.custom_minimum_size = Vector2(110, 64)
	slot.text = "Inventory is empty."
	slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_grid.add_child(slot)


func _on_inventory_slot_pressed(item_id: String) -> void:
	# Selection is UI state only. Gameplay actions use the separate action button.
	selected_item_id = item_id
	_refresh_screen()


func _show_item_details(item_id: String, inventory_items: Dictionary) -> void:
	# Display item data and expose the action appropriate to its item type.
	if not inventory_items.has(item_id):
		_clear_item_details()
		return

	var item: Resource = ITEM_DATABASE.get_item(item_id)
	if item == null:
		item_name_label.text = item_id
		item_description_label.text = "No item definition available."
		item_quantity_label.text = "Quantity: %d" % inventory_items[item_id]
		item_comparison_label.text = ""
		item_action_button.visible = false
		return

	item_name_label.text = item.get("display_name")
	item_description_label.text = item.get("description")
	item_quantity_label.text = "Quantity: %d" % inventory_items[item_id]
	item_comparison_label.text = _get_item_comparison(item)

	match item.get("item_type"):
		ITEM_DATA_SCRIPT.ItemType.CONSUMABLE:
			item_action_button.text = "Use"
			item_action_button.disabled = false
			item_action_button.visible = true
		ITEM_DATA_SCRIPT.ItemType.EQUIPMENT:
			var player: Node = get_tree().current_scene.get_node_or_null("Player")
			var equipment: Node = player.get_node_or_null("PlayerEquipment") if player != null else null
			item_action_button.text = "Equipped" if equipment != null and equipment.is_equipped(item) else "Equip"
			item_action_button.disabled = equipment != null and equipment.is_equipped(item)
			item_action_button.visible = true
		_:
			item_action_button.visible = false


func _get_item_comparison(item: Resource) -> String:
	# Compare equipment against the Player's current resulting stats. The
	# projection removes the currently equipped item in the same slot before
	# adding the selected item's modifiers, which makes replacement comparisons
	# accurate rather than simply comparing against base stats.
	if item.get("item_type") != ITEM_DATA_SCRIPT.ItemType.EQUIPMENT:
		return ""

	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return ""

	var stats: Node = player.get_node_or_null("PlayerStats")
	var equipment: Node = player.get_node_or_null("PlayerEquipment")
	if stats == null or equipment == null:
		return ""

	var current_attack: int = stats.get("attack")
	var current_defense: int = stats.get("defense")
	var projected_attack: int = current_attack
	var projected_defense: int = current_defense

	var slot: int = item.get("equipment_slot")
	var equipped: Resource = equipment.get_equipped_item(slot)

	if equipped != null:
		projected_attack -= equipped.get("attack_bonus")
		projected_defense -= equipped.get("defense_bonus")

	projected_attack += item.get("attack_bonus")
	projected_defense += item.get("defense_bonus")

	var details := "Slot: %s\nBonuses: %s" % [
		_get_equipment_slot_name(item.get("equipment_slot")),
		_get_item_bonus_summary(item),
	]

	if equipped != null:
		details += "\nCurrently equipped: %s" % equipped.get("display_name")

	details += "\n\nComparison:"
	details += "\nAttack: %d -> %d (%+d)" % [
		current_attack,
		projected_attack,
		projected_attack - current_attack,
	]
	details += "\nDefense: %d -> %d (%+d)" % [
		current_defense,
		projected_defense,
		projected_defense - current_defense,
	]

	return details


func _get_item_bonus_summary(item: Resource) -> String:
	# Format only the stat bonuses that the item actually provides.
	var bonuses: Array[String] = []

	var attack_bonus: int = item.get("attack_bonus")
	var defense_bonus: int = item.get("defense_bonus")

	if attack_bonus != 0:
		bonuses.append("Attack %+d" % attack_bonus)
	if defense_bonus != 0:
		bonuses.append("Defense %+d" % defense_bonus)

	if bonuses.is_empty():
		return "No stat bonuses"

	return ", ".join(bonuses)


func _get_equipment_slot_name(slot: int) -> String:
	# Keep slot presentation in the HUD without duplicating equipment state.
	match slot:
		ITEM_DATA_SCRIPT.EquipmentSlot.WEAPON:
			return "Weapon"
		ITEM_DATA_SCRIPT.EquipmentSlot.SHIELD:
			return "Shield"
		ITEM_DATA_SCRIPT.EquipmentSlot.HEAD:
			return "Head"
		ITEM_DATA_SCRIPT.EquipmentSlot.BODY:
			return "Body"
		ITEM_DATA_SCRIPT.EquipmentSlot.ACCESSORY:
			return "Accessory"
		_:
			return "None"


func _on_item_action_button_pressed() -> void:
	# The HUD requests an action but does not implement its gameplay effect.
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player == null or selected_item_id == "":
		return

	var item: Resource = ITEM_DATABASE.get_item(selected_item_id)
	if item == null:
		return

	match item.get("item_type"):
		ITEM_DATA_SCRIPT.ItemType.CONSUMABLE:
			ITEM_USE_SYSTEM.use_item(player, item)
		ITEM_DATA_SCRIPT.ItemType.EQUIPMENT:
			var equipment: Node = player.get_node_or_null("PlayerEquipment")
			if equipment != null:
				equipment.equip_item(item)

	_refresh_screen()


func _on_unequip_slot_pressed(slot: int) -> void:
	# PlayerEquipment owns unequipping. The HUD only requests it by slot.
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	var equipment: Node = player.get_node_or_null("PlayerEquipment")
	if equipment != null:
		equipment.unequip_slot(slot)

	_refresh_screen()


func _get_item_display_name(item_id: String) -> String:
	# Unknown IDs fall back to their stable identifier.
	var item: Resource = ITEM_DATABASE.get_item(item_id)
	if item != null:
		return item.get("display_name")
	return item_id


func _clear_equipment_ui() -> void:
	# Remove only temporary equipment controls. Equipment data is untouched.
	for child in equipment_grid.get_children():
		child.queue_free()


func _clear_inventory_slots() -> void:
	# Remove only temporary visual inventory controls. Inventory data is untouched.
	for child in inventory_grid.get_children():
		child.queue_free()


func _clear_item_details() -> void:
	# Reset the detail panel when nothing is selected.
	item_name_label.text = "Select an item"
	item_description_label.text = "Choose an inventory slot to view its details."
	item_quantity_label.text = ""
	item_comparison_label.text = ""
	item_action_button.visible = false


func _show_missing_player() -> void:
	# Keep the HUD readable if a gameplay scene ever lacks a Player.
	level_label.text = "Player not found."
	hp_label.text = ""
	mp_label.text = ""
	attack_label.text = ""
	defense_label.text = ""
	magic_attack_label.text = ""
	magic_defense_label.text = ""
	speed_label.text = ""
	experience_label.text = ""
	gold_label.text = ""
	equipment_label.text = "Equipment: --"
	_clear_equipment_ui()
	_clear_inventory_ui()
	_clear_item_details()


func _clear_inventory_ui() -> void:
	# Clear only visual inventory controls.
	_clear_inventory_slots()


func _set_player_movement_enabled(enabled: bool) -> void:
	# Disable only Player movement rather than pausing the entire SceneTree.
	var player: Node = get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return

	var movement: Node = player.get_node_or_null("PlayerMovement")
	if movement == null:
		return

	movement.set_movement_enabled(enabled)
