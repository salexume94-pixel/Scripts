extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared interaction path for NPCs, Chests, Doors,
## and future interactable objects. Individual interactables expose an
## interact() method that owns their gameplay behavior.
##
## The interaction key is registered as a real InputMap action at runtime.
## This keeps interaction input centralized and avoids relying on raw keyboard
## event propagation through the scene tree or UI Controls.

const MAX_INTERACTION_DISTANCE: float = 80.0
const INTERACT_ACTION: StringName = &"interact"

func _ready() -> void:
	# Register the shared interaction action once. The action is created here
	# so the system remains self-contained while still using Godot's standard
	# input-action system.
	if not InputMap.has_action(INTERACT_ACTION):
		InputMap.add_action(INTERACT_ACTION)

		var interact_key := InputEventKey.new()
		interact_key.physical_keycode = KEY_E
		InputMap.action_add_event(INTERACT_ACTION, interact_key)

func _process(_delta: float) -> void:
	# Input.is_action_just_pressed() detects the initial E press only, so holding
	# E cannot repeatedly interact with the same NPC or object.
	if Input.is_action_just_pressed(INTERACT_ACTION):
		_handle_interaction_input()

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
