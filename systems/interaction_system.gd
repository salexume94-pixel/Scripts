extends Node
## Owns Player-to-world interaction input and interactable selection.
##
## This system provides one shared interaction path for NPCs, Chests, Doors,
## and future interactable objects. Individual interactables expose an
## interact() method and remain responsible for their own gameplay behavior.
##
## The Player receives the physical E input and calls handle_interaction_input().
## Keeping input entry on the Player prevents scene-local child input handling
## from becoming another variable in the interaction system.

const MAX_INTERACTION_DISTANCE: float = 80.0


func handle_interaction_input() -> void:
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
