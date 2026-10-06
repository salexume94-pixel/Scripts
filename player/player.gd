extends CharacterBody2D
## Core player controller.
##
## Player-specific systems are separated into their own scripts.
## This script coordinates access to those systems without owning
## their implementation.
##
## Input that belongs to the Player is received here. The Player then
## forwards interaction requests to InteractionSystem, which keeps target
## selection and interactable behavior separate from the Player controller.

@onready var movement: Node = $PlayerMovement
@onready var stats: Node = $PlayerStats
@onready var skills: Node = $PlayerSkills
@onready var inventory: Node = $PlayerInventory
@onready var equipment: Node = $PlayerEquipment
@onready var progression: Node = $PlayerProgression
@onready var interaction_system: Node = $InteractionSystem

func _ready() -> void:
    # Register the Player with a shared group so world-level systems can find
    # the active Player without depending on a hard-coded scene path.
    add_to_group("player")


func _input(event: InputEvent) -> void:
    # Receive the physical E key at the Player root. Keeping the input entry
    # point on the Player avoids relying on a child Node to receive the event
    # while still allowing InteractionSystem to own the actual interaction
    # logic.
    if not event is InputEventKey:
        return

    var key_event := event as InputEventKey

    # Ignore key-repeat events so holding E cannot repeatedly interact with
    # the same NPC, Chest, or Door.
    if not key_event.pressed or key_event.echo:
        return

    # Accept both physical and logical E key codes for keyboard-layout
    # compatibility.
    if key_event.physical_keycode != KEY_E and key_event.keycode != KEY_E:
        return

    # InteractionSystem handles dialogue dismissal, nearest-target selection,
    # and the target's actual interact() call.
    if interaction_system != null and interaction_system.has_method("handle_interaction_input"):
        interaction_system.handle_interaction_input()
