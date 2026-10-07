extends StaticBody2D
## Reusable NPC behavior.
##
## NPC scenes own their identity, collision, and interaction behavior.
## DialogueManager owns the shared dialogue state, while DialogueBox owns
## presentation. Optional quest fields let the same NPC scene act as a normal
## NPC, a quest giver, or a quest objective without creating one-off scripts.

@export var npc_name: String = "Townsperson"
@export_multiline var dialogue_text: String = "Hello there."
@export var collision_radius: float = 16.0

## When set, this NPC can start the referenced quest through QuestManager.
@export var quest_id: String = ""

## When set, speaking to this NPC advances the referenced quest objective.
@export var objective_quest_id: String = ""
@export var objective_id: String = ""

## When enabled, speaking to this NPC writes the current gameplay state to disk.
## This is used for deliberate save points such as the Tutorial Town church.
@export var save_game_on_interact: bool = false


func _ready() -> void:
	# The NPC scene is the authoritative source for these groups. This also
	# protects dynamically created NPCs from forgetting to register as
	# interactable targets.
	add_to_group("interactable")
	add_to_group("npc")

	# Allow individual NPC instances, such as a quest giver, to use a larger
	# collision shape while keeping one reusable scene.
	var collision := get_node_or_null("Collision") as CollisionShape2D
	if collision != null and collision.shape is CircleShape2D:
		collision.shape = collision.shape.duplicate()
		(collision.shape as CircleShape2D).radius = collision_radius


func interact(_player: Node) -> void:
	# A quest giver starts its configured quest the first time it is used.
	# QuestManager remains responsible for validating the quest state.
	if not quest_id.is_empty():
		var quest_state := QuestManager.get_quest_state(quest_id)

		if quest_state == QuestManager.QuestState.NOT_STARTED:
			QuestManager.start_quest(quest_id)
		elif quest_state == QuestManager.QuestState.ACTIVE:
			DialogueManager.show_dialogue(
				npc_name,
				"Please speak with the person I mentioned. They should be able to help."
			)
			return
		elif quest_state == QuestManager.QuestState.COMPLETED:
			DialogueManager.show_dialogue(
				npc_name,
				"Thank you for helping Northbridge."
			)
			return

	# A normal NPC can optionally advance a quest objective when spoken to.
	if not objective_quest_id.is_empty() and not objective_id.is_empty():
		QuestManager.add_objective_progress(
			objective_quest_id,
			objective_id,
			1
		)

	DialogueManager.show_dialogue(npc_name, dialogue_text)

	# Saving is deliberately tied to an NPC interaction rather than a global key.
	# This keeps save points under world/story control and allows future towns to
	# designate their own save-point NPCs without creating special scripts.
	if save_game_on_interact:
		SaveManager.save_game()
