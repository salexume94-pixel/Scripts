extends Node
## Owns the authoritative party roster.
##
## This first implementation records stable companion IDs and persists roster
## membership. It deliberately does not invent companion combat AI, formation,
## stats, or turn behavior before those systems are designed.

signal party_changed(members: Array[String])

var members: Array[String] = []


func add_companion(companion_id: String) -> bool:
	# Stable IDs prevent duplicate roster entries when a scene is re-entered.
	if companion_id.is_empty() or members.has(companion_id):
		return false

	members.append(companion_id)
	party_changed.emit(get_members())
	return true


func remove_companion(companion_id: String) -> bool:
	# Removing an absent member is a harmless no-op.
	if not members.has(companion_id):
		return false

	members.erase(companion_id)
	party_changed.emit(get_members())
	return true


func has_companion(companion_id: String) -> bool:
	return members.has(companion_id)


func get_members() -> Array[String]:
	# Return a copy so callers cannot mutate the authoritative roster directly.
	return members.duplicate()


func reset_party() -> void:
	members.clear()
	party_changed.emit(get_members())


func get_save_data() -> Dictionary:
	# JSON-compatible roster data is included in SaveManager's save document.
	return {"members": members.duplicate()}


func load_save_data(data: Dictionary) -> void:
	# Validate loaded data and rebuild the roster without duplicate or blank IDs.
	members.clear()
	var saved_members = data.get("members", [])
	if typeof(saved_members) == TYPE_ARRAY:
		for value in saved_members:
			if typeof(value) != TYPE_STRING:
				continue
			var companion_id := str(value)
			if not companion_id.is_empty() and not members.has(companion_id):
				members.append(companion_id)

	party_changed.emit(get_members())
