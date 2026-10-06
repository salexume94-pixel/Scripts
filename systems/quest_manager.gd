extends Node
## Owns runtime quest state and objective progression.
##
## QuestManager is the authoritative gameplay system for quest tracking.
## QuestData owns static definitions, while QuestLog owns presentation.
## World interactions, NPCs, combat, and future gated-area systems can call
## this manager without needing to know how quest state is stored.
##
## Runtime state is persistent because QuestManager is an autoload. The
## get_save_data/load_save_data methods provide the serialization boundary
## required by the future disk save/load system.

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	FAILED,
}

const QUEST_DATABASE = preload("res://quests/quest_database.gd")

var quest_states: Dictionary = {}


func _ready() -> void:
	# Initialize every known quest with a clean NOT_STARTED state.
	for quest in QUEST_DATABASE.get_all_quests():
		_register_definition(quest)


func _register_definition(quest: Resource) -> void:
	# Keep runtime state keyed by stable quest ID rather than Resource references.
	if quest == null:
		return

	var quest_id: String = quest.get("quest_id")
	if quest_id.is_empty() or quest_states.has(quest_id):
		return

	var objectives: Dictionary = {}
	for objective in quest.get("objectives"):
		if not objective.has("objective_id"):
			continue

		var objective_id: String = str(objective["objective_id"])
		objectives[objective_id] = 0

	quest_states[quest_id] = {
		"state": QuestState.NOT_STARTED,
		"objectives": objectives,
	}


func get_quest_definition(quest_id: String) -> Resource:
	# Definitions remain owned by QuestDatabase.
	return QUEST_DATABASE.get_quest(quest_id)


func get_quest_state(quest_id: String) -> int:
	# Unknown quests are treated as NOT_STARTED rather than creating invalid
	# runtime entries.
	var state: Dictionary = quest_states.get(quest_id, {})
	return int(state.get("state", QuestState.NOT_STARTED))


func start_quest(quest_id: String) -> bool:
	# Only a known NOT_STARTED quest can be started.
	var quest: Resource = get_quest_definition(quest_id)
	if quest == null:
		return false

	_ensure_registered(quest)
	var current_state := get_quest_state(quest_id)

	if current_state == QuestState.COMPLETED and not quest.get("repeatable"):
		return false

	if current_state != QuestState.NOT_STARTED and current_state != QuestState.FAILED:
		return false

	var objectives: Dictionary = {}
	for objective in quest.get("objectives"):
		if objective.has("objective_id"):
			objectives[str(objective["objective_id"])] = 0

	quest_states[quest_id] = {
		"state": QuestState.ACTIVE,
		"objectives": objectives,
	}

	quest_started.emit(quest_id)
	quest_updated.emit(quest_id)
	return true


func add_objective_progress(
	quest_id: String,
	objective_id: String,
	amount: int = 1
) -> bool:
	# Objective progress is accepted only while the quest is active.
	if amount <= 0 or get_quest_state(quest_id) != QuestState.ACTIVE:
		return false

	var quest: Resource = get_quest_definition(quest_id)
	if quest == null or not _objective_exists(quest, objective_id):
		return false

	var state: Dictionary = quest_states[quest_id]
	var objectives: Dictionary = state["objectives"]
	var current: int = int(objectives.get(objective_id, 0))
	var required: int = _get_required_count(quest, objective_id)

	# Progress is capped at the objective's required amount.
	objectives[objective_id] = mini(current + amount, required)
	state["objectives"] = objectives
	quest_states[quest_id] = state

	quest_updated.emit(quest_id)

	if _are_all_objectives_complete(quest, objectives):
		complete_quest(quest_id)

	return true


func set_objective_progress(
	quest_id: String,
	objective_id: String,
	progress: int
) -> bool:
	# Absolute progress is useful for objectives driven by inventory or other
	# authoritative systems that know the current total.
	if get_quest_state(quest_id) != QuestState.ACTIVE:
		return false

	var quest: Resource = get_quest_definition(quest_id)
	if quest == null or not _objective_exists(quest, objective_id):
		return false

	var required: int = _get_required_count(quest, objective_id)
	var state: Dictionary = quest_states[quest_id]
	var objectives: Dictionary = state["objectives"]
	objectives[objective_id] = clampi(progress, 0, required)
	state["objectives"] = objectives
	quest_states[quest_id] = state

	quest_updated.emit(quest_id)

	if _are_all_objectives_complete(quest, objectives):
		complete_quest(quest_id)

	return true


func complete_quest(quest_id: String) -> bool:
	# Completion is valid only when every defined objective is complete.
	if get_quest_state(quest_id) != QuestState.ACTIVE:
		return false

	var quest: Resource = get_quest_definition(quest_id)
	if quest == null:
		return false

	var objectives: Dictionary = quest_states[quest_id]["objectives"]
	if not _are_all_objectives_complete(quest, objectives):
		return false

	var state: Dictionary = quest_states[quest_id]
	state["state"] = QuestState.COMPLETED
	quest_states[quest_id] = state

	quest_completed.emit(quest_id)
	quest_updated.emit(quest_id)
	return true


func fail_quest(quest_id: String) -> bool:
	# Failure exists in the state model now so future quests can opt into it.
	# No automatic failure conditions are imposed by the foundation.
	if get_quest_state(quest_id) != QuestState.ACTIVE:
		return false

	var state: Dictionary = quest_states[quest_id]
	state["state"] = QuestState.FAILED
	quest_states[quest_id] = state

	quest_failed.emit(quest_id)
	quest_updated.emit(quest_id)
	return true


func get_active_quests() -> Array[Resource]:
	# Return definitions whose runtime state is ACTIVE.
	return _get_quests_in_state(QuestState.ACTIVE)


func get_completed_quests() -> Array[Resource]:
	# Return definitions whose runtime state is COMPLETED.
	return _get_quests_in_state(QuestState.COMPLETED)


func get_failed_quests() -> Array[Resource]:
	# Failed quests are exposed separately so the UI can support them later.
	return _get_quests_in_state(QuestState.FAILED)


func get_objective_progress(quest_id: String, objective_id: String) -> int:
	var state: Dictionary = quest_states.get(quest_id, {})
	var objectives: Dictionary = state.get("objectives", {})
	return int(objectives.get(objective_id, 0))


func get_objective_required_count(quest_id: String, objective_id: String) -> int:
	var quest: Resource = get_quest_definition(quest_id)
	if quest == null:
		return 0
	return _get_required_count(quest, objective_id)


func get_save_data() -> Dictionary:
	# Return only primitive data so the future save system can serialize it.
	var saved_states: Dictionary = {}

	for quest_id in quest_states:
		var state: Dictionary = quest_states[quest_id]
		saved_states[quest_id] = {
			"state": int(state.get("state", QuestState.NOT_STARTED)),
			"objectives": (state.get("objectives", {}) as Dictionary).duplicate(),
		}

	return {
		"quest_states": saved_states,
	}


func load_save_data(data: Dictionary) -> void:
	# Restore only known quest IDs and valid objective IDs. Invalid save data is
	# ignored instead of allowing a malformed file to create arbitrary state.
	if not data.has("quest_states") or not data["quest_states"] is Dictionary:
		return

	var saved_states: Dictionary = data["quest_states"]

	for quest_id in saved_states:
		var quest: Resource = get_quest_definition(str(quest_id))
		if quest == null:
			continue

		var saved_state: Dictionary = saved_states[quest_id]
		if not saved_state is Dictionary:
			continue

		var state_value: int = int(saved_state.get("state", QuestState.NOT_STARTED))
		if state_value < QuestState.NOT_STARTED or state_value > QuestState.FAILED:
			continue

		var objectives: Dictionary = {}
		var saved_objectives: Dictionary = saved_state.get("objectives", {})

		for objective in quest.get("objectives"):
			if not objective.has("objective_id"):
				continue

			var objective_id: String = str(objective["objective_id"])
			var required: int = int(objective.get("required_count", 1))
			var progress: int = int(saved_objectives.get(objective_id, 0))
			objectives[objective_id] = clampi(progress, 0, max(required, 0))

		quest_states[str(quest_id)] = {
			"state": state_value,
			"objectives": objectives,
		}

		quest_updated.emit(str(quest_id))


func reset_all_quests() -> void:
	# Development utility for starting a clean runtime quest state.
	quest_states.clear()
	for quest in QUEST_DATABASE.get_all_quests():
		_register_definition(quest)


func _ensure_registered(quest: Resource) -> void:
	var quest_id: String = quest.get("quest_id")
	if not quest_states.has(quest_id):
		_register_definition(quest)


func _get_quests_in_state(target_state: int) -> Array[Resource]:
	var result: Array[Resource] = []

	for quest in QUEST_DATABASE.get_all_quests():
		var quest_id: String = quest.get("quest_id")
		if get_quest_state(quest_id) == target_state:
			result.append(quest)

	return result


func _objective_exists(quest: Resource, objective_id: String) -> bool:
	for objective in quest.get("objectives"):
		if str(objective.get("objective_id", "")) == objective_id:
			return true
	return false


func _get_required_count(quest: Resource, objective_id: String) -> int:
	for objective in quest.get("objectives"):
		if str(objective.get("objective_id", "")) == objective_id:
			return max(int(objective.get("required_count", 1)), 0)
	return 0


func _are_all_objectives_complete(
	quest: Resource,
	objectives: Dictionary
) -> bool:
	var definitions: Array = quest.get("objectives")
	if definitions.is_empty():
		return true

	for objective in definitions:
		var objective_id: String = str(objective.get("objective_id", ""))
		var required: int = max(int(objective.get("required_count", 1)), 0)
		if int(objectives.get(objective_id, 0)) < required:
			return false

	return true
