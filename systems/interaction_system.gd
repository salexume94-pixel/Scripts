extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared interaction path for NPCs, Chests, Doors,
## and future interactable objects. Individual interactables expose an
## interact() method and remain responsible for their own gameplay behavior.
##
## Interaction is handled from a real key-press event instead of polling the
## key every frame. This is important for scene transitions: the Player and its
## InteractionSystem are recreated when a scene changes, so a frame-based
## "previously pressed" flag could be reset while E is still held and cause a
## Door to fire again in the newly loaded scene.

const MAX_INTERACTION_DISTANCE: float = 80.0
const INTERACT_ACTION: StringName = &"interact"

func _input(event: InputEvent) -> void:
	# Only respond to an actual key-down event. Ignoring key-repeat events keeps
	# one physical E press from producing multiple interactions.
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	# Accept both the physical key and the logical keycode so the interaction
	# remains reliable across keyboard layouts.
	if key_event.physical_keycode != KEY_E and key_event.keycode != KEY_E:
		return

	_handle_interaction_input()

func _handle_interaction_input() -> void:
	# Dialogue has priority over world interaction. Pressing E while a dialogue
	# line is visible dismisses that line and stops here.
	if DialogueManager.is_active:
		DialogueManager.clear_dialogue()
		get_viewport().set_input_as_handled()
		return

	# Only mark the input handled if an actual interactable was found. This lets
	# other game/UI systems continue receiving E when the Player is not near an
	# interactable.
	if _interact_with_nearest():
		get_viewport().set_input_as_handled()

func _interact_with_nearest() -> bool:
	var player := get_parent() as Node2D
	if player == null:
		return false

	var nearest_interactable: Node = null
	var nearest_distance := MAX_INTERACTION_DISTANCE

	# Search the current scene's interactable group rather than depending on
	# Area2D collision layers. NPCs, Doors, and Chests all register themselves
	# in this group during _ready().
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate):
			continue

		if not candidate.has_method("interact"):
			continue

		var target := candidate as Node2D
		if target == null:
			continue

		var distance := player.global_position.distance_to(target.global_position)

		# Objects at exactly the interaction limit are valid targets.
		if distance > MAX_INTERACTION_DISTANCE:
			continue

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_interactable = candidate

	if nearest_interactable == null:
		return false

	# Pass the actual Player that initiated the interaction. The target owns its
	# own behavior and does not need to search the scene for another Player.
	nearest_interactable.interact(player)
	return true
