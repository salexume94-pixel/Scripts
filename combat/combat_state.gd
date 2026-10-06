extends Resource
class_name CombatState
## Stores the state of one active combat encounter.
##
## This Resource is data only. It does not start scenes, calculate damage, or
## control UI. CombatManager owns the active instance and uses this data to
## coordinate the combat flow.
##
## Enemy definitions and stats are intentionally represented by an enemy_id
## for now. The Enemy Foundation will replace that identifier with the
## authoritative enemy data system later.

enum Phase {
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT,
}

@export var enemy_id: String = ""
@export var phase: Phase = Phase.PLAYER_TURN
@export var enemy_hp: int = 0
