extends CharacterBody2D
## Core player controller.
##
## Player-specific systems are separated into their own scripts.
## This script coordinates access to those systems without owning
## their implementation.

@onready var movement: Node = $PlayerMovement
@onready var stats: Node = $PlayerStats
@onready var skills: Node = $PlayerSkills
@onready var inventory: Node = $PlayerInventory
@onready var equipment: Node = $PlayerEquipment
@onready var progression: Node = $PlayerProgression
