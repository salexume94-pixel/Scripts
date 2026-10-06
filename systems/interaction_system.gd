extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared E-key interaction path for NPCs, Chest, Door,
## and future interactable objects. Individual interactables expose an interact()
## method that owns their gameplay behavior.
##
## The Player already has an InteractionArea. We use that Area2D to identify
## nearby physics bodies, then keep distance-based selection as a fallback.
## This makes interaction reliable for StaticBody2D NPCs while preserving the
## existing behavior used by Doors and Chests.

const MAX_INTERACTION_DISTANCE: float = 80.0


func _input(event: InputEvent) -> void:
	# Listen during the earliest input stage so UI Controls cannot prevent the
	# Player's interaction key from reaching this system.
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	# Accept the physical E key as well as the normal keycode. This prevents
	# keyboard-layout differences from silently blocking interaction.
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
	# The InteractionArea is the Player's explicit interaction range. Its
	# overlapping bodies are the first and most reliable source of nearby
	# interactables because NPCs, Doors, and Chests are physics bodies.
	var interaction_area := get_node_or_null("InteractionArea") as Area2D

	if interaction_area != null:
		var nearby_target := _find_nearest_from_area(interaction_area)
		if nearby_target != null:
			nearby_target.interact(get_parent())
			return

	# Keep the distance-based search as a fallback for interactables that may
	# not currently participate in Area2D collision detection.
	_interact_by_distance()


func _find_nearest_from_area(interaction_area: Area2D) -> Node:
	# Only select bodies that explicitly belong to the shared interactable
	# group and expose the expected interact() method.
	var player := get_parent() as Node2D
	if player == null:
		return null

	var nearest: Node = null
	var nearest_distance := MAX_INTERACTION_DISTANCE

	for candidate in interaction_area.get_overlapping_bodies():
		if not is_instance_valid(candidate):
			continue

		if not candidate.is_in_group("interactable"):
			continue

		if not candidate.has_method("interact"):
			continue

		var target := candidate as Node2D
		if target == null:
			continue

		var distance := player.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate

	return nearest


func _interact_by_distance() -> void:
	# Find the closest explicitly registered interactable in the current scene.
	# This fallback keeps existing interactions working even if a future
	# interactable does not use compatible physics layers.
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

		var distance := player.global_position.distance_to(target.global_position)

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
