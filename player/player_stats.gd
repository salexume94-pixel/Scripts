extends Node
## Handles the player's core statistics.
##
## This script owns the resulting Player stat values.
## It does not handle movement, inventory, equipment ownership, or UI.
##
## Equipment systems can change the derived combat values through the public
## equipment modifier methods below. Keeping the resulting values here gives
## combat and UI systems one authoritative place to read current stats.

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

# Equipment modifiers are tracked separately so an equipment change can be
# reversed cleanly without losing the Player's underlying base statistics.
var equipment_attack_bonus: int = 0
var equipment_defense_bonus: int = 0

## Apply direct damage for combat systems and temporary development testing.
## The returned value is the actual HP lost after clamping at zero.
func take_damage(amount: int) -> int:
	if amount <= 0:
		return 0

	var old_hp := hp
	hp = maxi(hp - amount, 0)
	return old_hp - hp


func restore_hp(amount: int) -> int:
	# Restore HP without allowing it to exceed the Player's maximum.
	# Returning the actual amount restored lets item-use systems distinguish
	# between a successful heal and an already-full HP bar.
	if amount <= 0:
		return 0

	var old_hp := hp
	hp = mini(hp + amount, max_hp)
	return hp - old_hp


func restore_mp(amount: int) -> int:
	# Restore MP using the same bounded behavior as HP.
	if amount <= 0:
		return 0

	var old_mp := mp
	mp = mini(mp + amount, max_mp)
	return mp - old_mp


func apply_equipment_modifiers(attack_bonus: int, defense_bonus: int) -> void:
	# Apply equipment changes to the resulting stats. PlayerEquipment owns which
	# items are equipped; PlayerStats owns the resulting numerical values.
	equipment_attack_bonus += attack_bonus
	equipment_defense_bonus += defense_bonus
	attack += attack_bonus
	defense += defense_bonus


func remove_equipment_modifiers(attack_bonus: int, defense_bonus: int) -> void:
	# Reverse modifiers when equipment is removed.
	equipment_attack_bonus -= attack_bonus
	equipment_defense_bonus -= defense_bonus
	attack -= attack_bonus
	defense -= defense_bonus
