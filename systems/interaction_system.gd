extends Node
## Owns Player-to-world interaction target selection.
##
## The Player receives the E key and calls handle_interaction_input().
## NPCs are checked before generic interactables so nearby Doors or Chests
## cannot steal an interaction intended for an NPC.
##
## This script also contains temporary visible diagnostics. They show whether
## E reached the interaction system and which target, if any, was selected.

const MAX_INTERACTION_DISTANCE: float = 80.0

var debug_label: Label


func _ready() -> void:
    # Create the diagnostic overlay at runtime so no existing scene layout
    # needs to be changed while we investigate the NPC interaction problem.
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
    # This first message proves that the E key reached the Player and then
    # reached InteractionSystem.
    _show_debug("E detected. Dialogue active: %s" % str(DialogueManager.is_active))

    # Dialogue always gets priority. Pressing E while dialogue is visible
    # dismisses it instead of immediately interacting with another target.
    if DialogueManager.is_active:
        DialogueManager.clear_dialogue()
        _show_debug("E detected -> dialogue was active -> dialogue cleared.")
        get_viewport().set_input_as_handled()
        return

    if _interact_with_nearest():
        get_viewport().set_input_as_handled()
    else:
        var npc_count := get_tree().get_nodes_in_group("npc").size()
        var interactable_count := get_tree().get_nodes_in_group("interactable").size()
        _show_debug(
            "E detected -> NO target within %d px. NPC group count: %d | Interactable count: %d"
            % [int(MAX_INTERACTION_DISTANCE), npc_count, interactable_count]
        )


func _interact_with_nearest() -> bool:
    var player := get_parent() as Node2D
    if player == null:
        _show_debug("E detected -> ERROR: Player parent is not Node2D.")
        return false

    # NPCs are checked separately and first. Their dedicated group makes this
    # path independent of the generic Door/Chest target selection.
    var npc := _find_nearest_in_group(player, "npc")
    if npc != null:
        var npc_target := npc as Node2D
        var npc_distance := player.global_position.distance_to(npc_target.global_position)
        var npc_name := str(npc.get("npc_name"))

        _show_debug(
            "E detected -> NPC target: %s | distance: %.1f px | calling interact()"
            % [npc_name, npc_distance]
        )

        npc.interact(player)

        _show_debug(
            "NPC interact() called for %s | Dialogue active: %s"
            % [npc_name, str(DialogueManager.is_active)]
        )
        return true

    # Doors, Chests, and future generic interactables retain their existing
    # interaction path when no NPC is close enough.
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
    # Update both the on-screen label and Godot's Output panel so we have two
    # ways to see the exact point where interaction processing stops.
    if debug_label != null:
        debug_label.text = "INTERACTION DEBUG\n" + message

    print("InteractionDebug: ", message)
