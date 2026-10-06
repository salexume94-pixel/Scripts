extends StaticBody2D
## Handles a reusable NPC that can be spoken to with the shared E interaction.
##
## The NPC owns its identity and dialogue content, but it does not own the
## dialogue UI. DialogueManager handles the active dialogue state so every NPC
## can use the same presentation and dismissal behavior.

@export var npc_name: String = "Townsperson"
@export_multiline var dialogue_text: String = "Hello there."

func _ready() -> void:
	# Register the NPC with the existing interaction system so the Player can
	# select it with E using the same interaction range as Doors and Chests.
	add_to_group("interactable")

func interact(_player: Node) -> void:
	# NPC interaction only supplies the dialogue content. DialogueManager owns
	# the active state and notifies the shared dialogue UI.
	DialogueManager.show_dialogue(npc_name, dialogue_text)
