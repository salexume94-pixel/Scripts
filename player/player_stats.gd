extends Node
## Handles the player's core statistics.
##
## This script owns the resulting Player stat values.
## It does not handle movement, inventory, equipment ownership, or UI.
##
## Equipment systems can change the derived combat values through the public
## equipment modifier methods below. Keeping the resulting values here gives
## combat and UI systems one authoritative place to read current stats.
##
## GameState stores a runtime snapshot of the Player's base stats and current
## HP/MP so recreating the Player during a scene transition does not reset
## progress or current health.

const DEFAULT_FIRE_WEAK = preload("res://player/definitions/player_fire_weak.tres")
const DEFAULT_WATER_WEAK = preload("res://player/definitions/player_water_weak.tres")
const DEFAULT_EARTH_WEAK = preload("res://player/definitions/player_earth_weak.tres")
const DEFAULT_AIR_WEAK = preload("res://player/definitions/player_air_weak.tres")
const DEFAULT_LIGHT_WEAK = preload("res://player/definitions/player_light_weak.tres")
const DEFAULT_DARK_WEAK = preload("res://player/definitions/player_dark_weak.tres")

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

## Elemental weakness definitions available to the Player.
##
## The combat test screen cycles which one is active. Only one elemental
## weakness is marked Weak at a time so Enemy AI can be tested against each
## element independently. The definitions themselves remain reusable data.
@export var affinities: Array[Resource] = [
	DEFAULT_FIRE_WEAK,
	DEFAULT_WATER_WEAK,
	DEFAULT_EARTH_WEAK,
	DEFAULT_AIR_WEAK,
	DEFAULT_LIGHT_WEAK,
	DEFAULT_DARK_WEAK,
]

# Equipment modifiers are tracked separately so an equipment change can be
# reversed cleanly without losing the Player's underlying base statistics.
var equipment_attack_bonus: int = 0
var equipment_defense_bonus: int = 0


func _ready() -> void:
	# Restore the runtime snapshot when this Player instance is created.
	# Scene transitions create a new Player node, so loading this snapshot keeps
	# current HP, MP, level, and base combat stats instead of using scene defaults.
	var saved_stats: Dictionary = GameState.get_player_stats()

	if saved_stats.is_empty():
		# The first Player instance has no saved snapshot yet, so its exported
		# scene values become the initial runtime state.
		_sync_to_game_state()
		return

	level = saved_stats.get("level", level)
	experience = saved_stats.get("experience", experience)
	max_hp = saved_stats.get("max_hp", max_hp)
	hp = saved_stats.get("hp", hp)
	max_mp = saved_stats.get("max_mp", max_mp)
	mp = saved_stats.get("mp", mp)
	attack = saved_stats.get("attack", attack)
	defense = saved_stats.get("defense", defense)
	magic_attack = saved_stats.get("magic_attack", magic_attack)
	magic_defense = saved_stats.get("magic_defense", magic_defense)
	speed = saved_stats.get("speed", speed)

	_sync_to_game_state()


## Apply direct damage for combat systems and temporary development testing.
## The returned value is the actual HP lost after clamping at zero.
func take_damage(amount: int) -> int:
	if amount <= 0:
		return 0

	var old_hp := hp
	hp = maxi(hp - amount, 0)
	_sync_to_game_state()
	return old_hp - hp


func restore_hp(amount: int) -> int:
	# Restore HP without allowing it to exceed the Player's maximum.
	# Returning the actual amount restored lets item-use systems distinguish
	# between a successful heal and an already-full HP bar.
	if amount <= 0:
		return 0

	var old_hp := hp
	hp = mini(hp + amount, max_hp)
	_sync_to_game_state()
	return hp - old_hp


func restore_mp(amount: int) -> int:
	# Restore MP using the same bounded behavior as HP.
	if amount <= 0:
		return 0

	var old_mp := mp
	mp = mini(mp + amount, max_mp)
	_sync_to_game_state()
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


func _sync_to_game_state() -> void:
	# Store base stats plus current HP/MP so a newly created PlayerStats can
	# reconstruct the same gameplay state after a scene transition.
	GameState.set_player_stats({
		"level": level,
		"experience": experience,
		"max_hp": max_hp,
		"hp": hp,
		"max_mp": max_mp,
		"mp": mp,
		"attack": attack - equipment_attack_bonus,
		"defense": defense - equipment_defense_bonus,
		"magic_attack": magic_attack,
		"magic_defense": magic_defense,
		"speed": speed,
	})
