extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared E-key interaction path for Chest, Door, and
## future interactable objects. Individual interactables expose an interact()
## method that owns their gameplay behavior.
##
## The system tracks nearby Area2D interaction ranges and selects the nearest
## valid interactable. It does not know what a Chest or Door does.

@onready var interaction_area: Area2D = $InteractionArea

var nearby_interactables: Array[Area2D] = []


func _ready() -> void:
	# Listen for interaction ranges entering and leaving the Player's shared
	# detection area. Interactable scripts remain responsible for their actions.
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)


func _unhandled_input(event: InputEvent) -> void:
	# All world interactions now use the same E-key input path.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact_with_nearest()


func _interact_with_nearest() -> void:
	# Remove freed or invalid interaction areas before choosing a target.
	nearby_interactables = nearby_interactables.filter(
		func(area: Area2D) -> bool:
			return is_instance_valid(area) and _get_interactable(area) != null
	)

	var nearest_area: Area2D = _get_nearest_interactable()
	if nearest_area == null:
		return

	var interactable: Node = _get_interactable(nearest_area)
	if interactable != null:
		interactable.interact(get_parent())


func _get_nearest_interactable() -> Area2D:
	# Choose the closest valid interaction target when multiple ranges overlap.
	var nearest: Area2D = null
	var nearest_distance := INF

	for area in nearby_interactables:
		var interactable: Node = _get_interactable(area)
		if interactable == null:
			continue

		var player: Node2D = get_parent() as Node2D
		var distance: float = player.global_position.distance_to(area.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = area

	return nearest


func _get_interactable(area: Area2D) -> Node:
	# An interaction Area can either own interact() itself or belong to a
	# parent node that owns the actual interactable behavior, such as a Chest.
	if area == null:
		return null

	if area.has_method("interact"):
		return area

	var parent: Node = area.get_parent()
	if parent != null and parent.has_method("interact"):
		return parent

	return null


func _on_area_entered(area: Area2D) -> void:
	# Only track Areas that expose the shared interaction contract.
	if _get_interactable(area) == null:
		return

	if not nearby_interactables.has(area):
		nearby_interactables.append(area)


func _on_area_exited(area: Area2D) -> void:
	# Stop considering an interaction target once its range is left.
	nearby_interactables.erase(area)
