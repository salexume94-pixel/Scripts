extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared E-key interaction path for NPCs, Chest, Door,
## and future interactable objects. Individual interactables expose an interact()
## method that owns their gameplay behavior.
##
## Interaction input is polled here instead of relying on InputEvent delivery.
## This is deliberate: UI Controls and other input consumers can intercept
## keyboard events, while polling the key state guarantees the Player's
## interaction system still sees the E key.

const MAX_INTERACTION_DISTANCE: float = 80.0

# Tracks the previous frame's E-key state so holding E does not repeatedly
# trigger interactions. A new interaction occurs only when E is newly pressed.
var e_was_pressed: bool = false


func _process(_delta: float) -> void:
	# Read the physical E key directly. This bypasses input-event consumption
	# by UI controls and makes the interaction key independent of input focus.
	var e_is_pressed := Input.is_physical_key_pressed(KEY_E)

	# Only react on the transition from "not pressed" to "pressed". This means
	# holding E cannot repeatedly open dialogue or interact with an object.
	if e_is_pressed and not e_was_pressed:
		_handle_interaction_input()

	e_was_pressed = e_is_pressed


func _handle_interaction_input() -> void:
	# When dialogue is active, E dismisses the current line instead of
	# immediately interacting with another nearby object.
	if DialogueManager.is_active:
		DialogueManager.clear_dialogue()
		return

	_interact_with_nearest()


func _interact_with_nearest() -> void:
	# The Player already has an InteractionArea. Its overlapping physics bodies
	# are checked first because NPCs, Doors, and Chests are StaticBody2D nodes.
	var interaction_area := get_node_or_null("InteractionArea") as Area2D

	if interaction_area != null:
		var nearby_target := _find_nearest_from_area(interaction_area)
		if nearby_target != null:
			nearby_target.interact(get_parent())
			return

	# Keep the distance-based search as a fallback for interactables that do not
	# participate in the expected Area2D collision configuration.
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
	# This fallback keeps interaction working even if physics-layer settings
	# prevent the InteractionArea from seeing a particular object.
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
