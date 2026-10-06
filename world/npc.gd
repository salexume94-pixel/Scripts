extends StaticBody2D
## Reusable NPC behavior.
##
## NPC scenes own their identity, collision, and interaction behavior.
## DialogueManager owns the shared dialogue state, while DialogueBox owns
## presentation. Keeping those responsibilities separate lets the same NPC
## scene be reused on any future map without copying interaction logic.

@export var npc_name: String = "Townsperson"
@export_multiline var dialogue_text: String = "Hello there."
@export var collision_radius: float = 16.0


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
    # NPC interaction only supplies the dialogue content. DialogueManager owns
    # the active state and notifies the shared dialogue UI.
    DialogueManager.show_dialogue(npc_name, dialogue_text)
