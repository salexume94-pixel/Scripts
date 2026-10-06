extends Node
## Owns Player-to-world interaction target selection.
##
## The Player receives the E key and calls handle_interaction_input().
## NPCs are checked before generic interactables so nearby Doors or Chests
## cannot steal an interaction intended for an NPC.
##
## This script also contains temporary diagnostics used to verify the actual
## group members and global positions involved in interaction selection.

const MAX_INTERACTION_DISTANCE: float = 80.0

var debug_label: Label


func _ready() -> void:
    # Create the diagnostic overlay at runtime so no existing scene layout
    # needs to be changed while we investigate NPC interaction.
    var canvas := CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)

    debug_label = Label.new()
    debug_label.position = Vector2(20, 20)
    debug_label.size = Vector2(1100, 260)
    debug_label.add_theme_font_size_override("font_size", 18)
    debug_label.text = "INTERACTION DEBUG: Ready"
    canvas.add_child(debug_label)


func handle_interaction_input() -> void:
    # This proves that the E key reached the Player and then this system.
    _show_debug("E detected. Dialogue active: %s" % str(DialogueManager.is_active))

    # Dialogue always gets priority. Pressing E while dialogue is visible
    # dismisses it instead of immediately interacting with another target.
    if DialogueManager.is_active:
        DialogueManager.clear_dialogue()
        _show_debug("E detected -> dialogue was active -> dialogue cleared.")
        get_viewport().set_input_as_handled()
        return

    var player := get_parent() as Node2D
    if player == null:
        _show_debug("E detected -> ERROR: Player parent is not Node2D.")
        return

    # NPCs use their dedicated group as the authoritative interaction list.
    # We report the group members and their actual global positions here so
    # scene/local coordinate problems cannot hide behind a generic 'no target'.
    var npc := _find_nearest_npc(player)
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
        get_viewport().set_input_as_handled()
        return

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
        get_viewport().set_input_as_handled()
        return

    _show_debug(_build_no_target_debug(player))


func _find_nearest_npc(player: Node2D) -> Node:
    # NPC group membership is intentionally checked separately from generic
    # interactables. The group is declared on the World scene and reinforced
    # by npc.gd, so NPC selection does not depend on another system finding
    # these nodes first.
    var nearest: Node = null
    var nearest_distance := MAX_INTERACTION_DISTANCE
    var diagnostic_lines: Array[String] = []

    for candidate in get_tree().get_nodes_in_group("npc"):
        if not is_instance_valid(candidate):
            continue

        var target := candidate as Node2D
        if target == null:
            diagnostic_lines.append("%s: not Node2D" % candidate.name)
            continue

        var distance := player.global_position.distance_to(target.global_position)
        diagnostic_lines.append(
            "%s=%s %.1fpx" % [
                candidate.name,
                str(candidate.get("npc_name")),
                distance
            ]
        )

        # The NPC group should contain only actual NPC interactables. Keep a
        # method check as a safety guard before invoking interact().
        if not candidate.has_method("interact"):
            diagnostic_lines.append("%s: MISSING interact()" % candidate.name)
            continue

        if distance <= MAX_INTERACTION_DISTANCE and distance < nearest_distance:
            nearest_distance = distance
            nearest = candidate

    if nearest == null:
        _show_debug(
            "NPC SCAN | Player: %s | %s"
            % [str(player.global_position), " | ".join(diagnostic_lines)]
        )

    return nearest


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


func _build_no_target_debug(player: Node2D) -> String:
    # This final message confirms the player position and the number of
    # registered NPC/interactable nodes if nothing was close enough.
    var npc_count := get_tree().get_nodes_in_group("npc").size()
    var interactable_count := get_tree().get_nodes_in_group("interactable").size()

    return (
        "E detected -> NO target within %d px | Player: %s | NPCs: %d | Interactables: %d"
        % [
            int(MAX_INTERACTION_DISTANCE),
            str(player.global_position),
            npc_count,
            interactable_count
        ]
    )


func _show_debug(message: String) -> void:
    # Update both the on-screen label and Godot's Output panel so we have two
    # ways to see exactly where interaction processing stops.
    if debug_label != null:
        debug_label.text = "INTERACTION DEBUG\n" + message

    print("InteractionDebug: ", message)
