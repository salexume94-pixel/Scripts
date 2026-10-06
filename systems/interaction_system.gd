extends Node
## Owns Player-to-world interaction target selection.
##
## The Player receives the E key and calls handle_interaction_input().
## This system then chooses the nearest valid target. NPCs are checked first
## so another nearby interactable cannot prevent an NPC from responding.
##
## A temporary on-screen diagnostic is also included while NPC interaction is
## being debugged. It reports whether E reached this system, how many NPCs were
## found, which target was selected, and whether interaction was attempted.
## This makes the input path observable instead of requiring guesswork.

const MAX_INTERACTION_DISTANCE: float = 80.0

var debug_label: Label


func _ready() -> void:
    # Create the diagnostic overlay at runtime so no existing gameplay scene
    # needs to be modified just to troubleshoot interaction input.
    var canvas := CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)

    debug_label = Label.new()
    debug_label.position = Vector2(20, 20)
    debug_label.size = Vector2(900, 180)
    debug_label.add_theme_font_size_override("font_size", 18)
    debug_label.text = "INTERACTION DEBUG: Ready"
    canvas.add_child(debug_label)


func handle_interaction_input() -> void:
    # First prove that the E key reached the Player and InteractionSystem.
    _show_debug("E detected. Dialogue active: %s" % DialogueManager.is_active)

    # Dialogue has priority over world interaction. Pressing E while dialogue
    # is active dismisses it and stops here.
    if DialogueManager.is_active:
        DialogueManager.clear_dialogue()
        _show_debug("E detected -> dialogue was active -> dialogue cleared.")
        get_viewport().set_input_as_handled()
        return

    if _interact_with_nearest():
        get_viewport().set_input_as_handled()
    else:
        _show_debug(
            "E detected -> NO target within %.0f px. NPC group count: %d | "
            "Interactable count: %d"
            % [
                MAX_INTERACTION_DISTANCE,
                get_tree().get_nodes_in_group("npc").size(),
                get_tree().get_nodes_in_group("interactable").size()
            ]
        )


func _interact_with_nearest() -> bool:
    var player := get_parent() as Node2D
    if player == null:
        _show_debug("E detected -> ERROR: Player parent is not Node2D.")
        return false

    # Check NPCs separately and first. NPCs are explicitly marked with the
    # "npc" group, so their dialogue interaction does not depend on the generic
    # interactable target list.
    var npc := _find_nearest_in_group(player, "npc")
    if npc != null:
        var npc_target := npc as Node2D
        var npc_distance := player.global_position.distance_to(npc_target.global_position)
        _show_debug(
            "E detected -> NPC target: %s | distance: %.1f px | calling interact()"
            % [npc.get("npc_name"), npc_distance]
        )
        npc.interact(player)
        _show_debug(
            "NPC interact() called for %s | Dialogue active: %s"
            % [npc.get("npc_name"), DialogueManager.is_active]
        )
        return true

    # Doors, Chests, and future interactables continue using the existing
    # generic interaction group.
    var interactable := _find_nearest_in_group(player, "interactable")
    if interactable != null:
        var target := interactable as Node2D
        var distance := player.global_position.distance_to(target.global_position)
        _show_debug(
            "E detected -> Generic target: %s | distance: %.1f px | calling interact()"
            % [interactable.name, distance]
        )
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


func _show_debug(message: String) -> void:
    # Keep the most recent interaction diagnostic visible long enough to read.
    # This is intentionally temporary and can be removed once NPC interaction
    # is confirmed working.
    if debug_label != null:
        debug_label.text = "INTERACTION DEBUG\n" + message
    print("InteractionDebug: ", message)
