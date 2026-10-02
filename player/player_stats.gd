extends Node
## Handles the player's core statistics.
##
## This script owns player stat values only.
## It does not handle movement, combat, inventory, equipment, or UI.

@export var level: int = 1
@export var experience: int = 0

@export var max_hp: int = 100
@export var hp: int = 100

@export var max_mp: int = 20
@export var mp: int = 20

@export var attack: int = 10
@export var defense: int = 10
@export var magic_attack: int = 10
@export var magic_defense: int = 10
@export var speed: int = 10
