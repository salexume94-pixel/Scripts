extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared interaction path for NPCs, Chests, Doors,
## and future interactable objects. Individual interactables only need to expose
## an interact() method. The Player does not need to know what it is talking to.
##
## Interaction is deliberately handled from the Player's InteractionSystem so
## every interactable uses the same key, range, and dialogue-dismissal rules.
## The target search uses the scene's interactable group and a distance check,
## which keeps NPC interaction independent of physics-layer configuration.

const MAX_INTERACTION_DISTANCE: float = 80.0
const INTERACT_KEY := KEY_E

var e_was_pressed: bool = false

func _ready() -> void:
	# Make sure this node is actively processing every frame. This is explicit
	# because interaction is a core Player system and should not depend on the
	# default processing state inherited from another scene.
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)

func _process(_delta: float) -> void:
	# Poll the physical E key directly. This avoids relying on InputMap setup or
	# keyboard event propagation, both of which can be affected by UI Controls.
	var e_is_pressed := Input.is_physical_key_pressed(INTERACT_KEY)

	# Only react to the initial key-down transition. Holding E therefore cannot
	# repeatedly open and immediately close the same dialogue.
	if e_is_pressed and not e_was_pressed:
		_handle_interaction_input()

	e_was_pressed = e_is_pressed

func _handle_interaction_input() -> void:
	# Dialogue has priority over world interaction. Pressing E while a dialogue
	# line is visible dismisses that line and stops here.
	if DialogueManager.is_active:
		DialogueManager.clear_dialogue()
		return

	_interact_with_nearest()

func _interact_with_nearest() -> void:
	var player := get_parent() as Node2D
	if player == null:
		return

	var nearest_interactable: Node = null
	var nearest_distance := MAX_INTERACTION_DISTANCE

	# Search only the explicitly registered interactable objects in the current
	# scene. NPCs, Doors, and Chests all register themselves in this group.
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate):
			continue

		if not candidate.has_method("interact"):
			continue

		var target := candidate as Node2D
		if target == null:
			continue

		var distance := player.global_position.distance_to(target.global_position)

		# Objects at exactly the interaction limit are still considered valid.
		if distance > MAX_INTERACTION_DISTANCE:
			continue

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_interactable = candidate

	if nearest_interactable != null:
		# Pass the actual Player instance so the interactable can use it for any
		# object-specific behavior without performing its own Player lookup.
		nearest_interactable.interact(player)
