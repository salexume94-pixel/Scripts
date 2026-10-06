extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared E-key interaction path for Chest, Door, and
## future interactable objects. Individual interactables expose an interact()
## method that owns their gameplay behavior.
##
## Interaction targets are selected by explicit distance from the Player rather
## than by Area2D overlap state. This keeps interaction selection independent
## from physics-trigger timing and prevents a Door from being selected because
## of a stale or unrelated Area2D overlap.

const MAX_INTERACTION_DISTANCE: float = 80.0

func _input(event: InputEvent) -> void:
	# Use _input instead of _unhandled_input so the shared interaction key is
	# received even when a UI Control consumes the keyboard event first.
	# This is important for NPC dialogue because the Player must still be able
	# to press E while the dialogue UI is present.
	# All world interactions use the same E-key input path.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			# When dialogue is active, the same E key dismisses the current line.
			# Return immediately so that one key press cannot dismiss the dialogue
			# and interact with another NPC at the same time.
			if DialogueManager.is_active:
				DialogueManager.clear_dialogue()
				return

			_interact_with_nearest()


func _interact_with_nearest() -> void:
	# Find the closest explicitly registered interactable in the current scene.
	# Only objects inside the interaction distance can respond to E.
	var player := get_parent() as Node2D
	if player == null:
		return

	var nearest_interactable: Node = null
	var nearest_distance := MAX_INTERACTION_DISTANCE

	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate):
			continue

		if not candidate.has_method("interact"):
			continue

		var target := candidate as Node2D
		if target == null:
			continue

		var distance: float = player.global_position.distance_to(
			target.global_position
		)

		if distance > MAX_INTERACTION_DISTANCE:
			continue

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_interactable = candidate

	if nearest_interactable != null:
		# Pass the actual Player that initiated the interaction. The target
		# object owns its own gameplay behavior and does not search the scene
		# for another Player.
		nearest_interactable.interact(player)
