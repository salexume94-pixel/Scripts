extends Resource
class_name CombatState
## Stores the state of one active combat encounter.
##
## This Resource is data only. It does not start scenes, calculate damage, or
## control UI. CombatManager owns the active instance and uses this data to
## coordinate the combat flow.

enum Phase {
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT,
}

@export var enemy_id: String = ""
@export var phase: Phase = Phase.PLAYER_TURN
@export var enemy_hp: int = 0
@export var enemy_max_hp: int = 0

# Four full Press Turns are available to the Player at the start of a round.
# A fractional value allows future weakness/critical actions to consume half.
@export var player_press_turns: int = 4
@export var player_press_turns_remaining: float = 4.0

@export var last_player_attack: int = 0
@export var last_damage: int = 0
@export var enemy_attack: int = 0
@export var last_enemy_damage: int = 0
