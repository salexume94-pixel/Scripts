extends Node
## Provides the authoritative catalog of QuestData definitions.
##
## Quest content is intentionally separate from runtime QuestManager state.
## New quest Resource files can be registered here without changing the
## tracking, save-state, or UI systems.

const QUEST_DEFINITIONS: Array[Resource] = []

static func get_quest(quest_id: String) -> Resource:
	# Resolve a stable quest ID to its shared QuestData definition.
	for quest in QUEST_DEFINITIONS:
		if quest != null and quest.get("quest_id") == quest_id:
			return quest
	return null

static func get_all_quests() -> Array[Resource]:
	# Return the complete definition catalog for future content tools and
	# validation systems.
	return QUEST_DEFINITIONS.duplicate()
