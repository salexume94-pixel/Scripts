extends CanvasLayer
## Presents the Player's tracked quests.
##
## QuestManager owns quest state and progression. This script only reads that
## state and formats it for the Player. Q toggles the Quest Log so it can be
## used independently from the Character/Inventory screen.

@onready var screen: Control = $Screen
@onready var active_list: VBoxContainer = $Screen/Panel/Margin/Content/ActiveSection/ActiveList
@onready var completed_list: VBoxContainer = $Screen/Panel/Margin/Content/CompletedSection/CompletedList
@onready var notification_label: Label = $Screen/Notification

var notification_generation: int = 0

const ITEM_DATABASE = preload("res://items/item_database.gd")


func _ready() -> void:
	# Start closed so opening the World does not interrupt gameplay.
	screen.visible = false

	QuestManager.quest_started.connect(_on_quest_changed)
	QuestManager.quest_updated.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_failed.connect(_on_quest_changed)

	_refresh_log()


func _unhandled_input(event: InputEvent) -> void:
	# Q toggles the Quest Log.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			screen.visible = not screen.visible
			if screen.visible:
				_refresh_log()


func _on_quest_changed(_quest_id: String) -> void:
	# Refresh immediately when quest state changes, even if the log is closed.
	_refresh_log()


func _on_quest_completed(quest_id: String) -> void:
	# Completion feedback is shown independently of whether the log is open.
	_refresh_log()

	var quest: Resource = QuestManager.get_quest_definition(quest_id)
	if quest == null:
		return

	_show_notification("Quest Complete: %s" % quest.get("title"))


func _refresh_log() -> void:
	# Rebuild only presentation controls. QuestManager remains the sole owner of
	# runtime state.
	_clear_list(active_list)
	_clear_list(completed_list)

	var active_quests := QuestManager.get_active_quests()
	var completed_quests := QuestManager.get_completed_quests()

	if active_quests.is_empty():
		_add_empty_label(active_list, "No active quests.")

	for quest in active_quests:
		active_list.add_child(_create_quest_entry(quest, true))

	if completed_quests.is_empty():
		_add_empty_label(completed_list, "No completed quests.")

	for quest in completed_quests:
		completed_list.add_child(_create_quest_entry(quest, false))


func _create_quest_entry(quest: Resource, show_progress: bool) -> Control:
	# Each quest gets a title, description, and objective list.
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)

	var title := Label.new()
	title.text = str(quest.get("title"))
	title.add_theme_font_size_override("font_size", 18)
	container.add_child(title)

	var description := Label.new()
	description.text = str(quest.get("description"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(description)

	var rewards := Label.new()
	rewards.text = _format_rewards(quest)
	rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(rewards)

	for objective in quest.get("objectives"):
		var objective_id: String = str(objective.get("objective_id", ""))
		var objective_text: String = str(objective.get("description", ""))
		var required: int = max(int(objective.get("required_count", 1)), 0)
		var progress := QuestManager.get_objective_progress(
			str(quest.get("quest_id")),
			objective_id
		)

		var objective_label := Label.new()
		if show_progress:
			objective_label.text = "[%s] %d / %d" % [
				"X" if progress >= required else " ",
				progress,
				required,
			]
		else:
			objective_label.text = "[X] %s" % objective_text

		if show_progress:
			objective_label.text = "%s %s" % [
				"[X]" if progress >= required else "[ ]",
				objective_text
			]
			objective_label.text += "  (%d / %d)" % [progress, required]

		objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(objective_label)

	return container


func _format_rewards(quest: Resource) -> String:
	# Rewards are definition data at this stage. A future reward application
	# system can grant them when the quest completes without changing the UI.
	var rewards: Array = quest.get("rewards")
	if rewards.is_empty():
		return "Rewards: None"

	var labels: Array[String] = []
	for reward in rewards:
		var item_id: String = str(reward.get("item_id", ""))
		var quantity: int = max(int(reward.get("quantity", 1)), 1)
		var item: Resource = ITEM_DATABASE.get_item(item_id)
		var display_name: String = str(item.get("display_name")) if item != null else item_id
		labels.append("%s x%d" % [display_name, quantity])

	return "Rewards: " + ", ".join(labels)


func _show_notification(message: String) -> void:
	# Use a generation token so an older timer cannot hide a newer notification.
	notification_generation += 1
	var generation: int = notification_generation
	notification_label.text = message
	notification_label.visible = true

	await get_tree().create_timer(3.0).timeout

	if generation == notification_generation:
		notification_label.visible = false


func _add_empty_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)


func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()
