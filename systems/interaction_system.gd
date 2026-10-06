extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared E-key interaction path for NPCs, Chest, Door,
## and future interactable objects. Individual interactables expose an interact()
## method that owns their gameplay behavior.
##
## Interaction targets are selected by explicit distance from the Player rather
## than by Area2D overlap state. This keeps interaction selection independent
## from physics-trigger timing and prevents unrelated Area2D overlaps from
## changing the selected target.

const MAX_INTERACTION_DISTANCE: float = 80.0

func _input(event: InputEvent) -> void:
	# Listen during the earliest input stage so UI Controls cannot prevent the
	# Player's interaction key from reaching this system.
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	# physical_keycode makes the interaction depend on the physical E key,
	# while keycode keeps the normal keyboard-layout value supported as well.
	# Checking both avoids silently ignoring the key on different layouts or
	# Godot input-event configurations.
	if not key_event.pressed or key_event.echo:
		return

	if key_event.physical_keycode != KEY_E and key_event.keycode != KEY_E:
		return

	# When dialogue is active, E dismisses the current line instead of
	# immediately interacting with another nearby object.
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
