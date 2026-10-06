extends Node
## Owns Player-to-world interaction target selection.
##
## The Player receives the E key and calls handle_interaction_input().
## This system then chooses the nearest valid target. NPCs are checked first
## so another nearby interactable can never prevent an NPC from responding
## when the Player is standing beside that NPC.

const MAX_INTERACTION_DISTANCE: float = 80.0


func handle_interaction_input() -> void:
    # Dialogue has priority over world interaction. Pressing E while a dialogue
    # line is visible dismisses that line and stops here.
    if DialogueManager.is_active:
        DialogueManager.clear_dialogue()
        get_viewport().set_input_as_handled()
        return

    if _interact_with_nearest():
        get_viewport().set_input_as_handled()


func _interact_with_nearest() -> bool:
    var player := get_parent() as Node2D
    if player == null:
        return false

    # Check NPCs separately and first. NPCs are explicitly marked with the
    # "npc" group in Tutorial Town, so their dialogue interaction does not
    # depend on sharing the generic interactable target list.
    var npc := _find_nearest_in_group(player, "npc")
    if npc != null:
        npc.interact(player)
        return true

    # Doors, Chests, and future interactables continue using the existing
    # generic interaction group.
    var interactable := _find_nearest_in_group(player, "interactable")
    if interactable != null:
        interactable.interact(player)
        return true

    return false


func _find_nearest_in_group(player: Node2D, group_name: String) -> Node:
    var nearest: Node = null
    var nearest_distance := MAX_INTERACTION_DISTANCE

    for candidate in get_tree().get_nodes_in_group(group_name):
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
            nearest = candidate

    return nearest
