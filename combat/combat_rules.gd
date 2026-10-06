extends RefCounted
class_name CombatRules
## Resolves shared combat math such as accuracy, critical hits, affinities,
## damage, and Press Turn costs.
##
## CombatManager owns combat flow, while this script owns reusable combat rules.
## Keeping these calculations here prevents Battle UI and data Resources from
## becoming responsible for resolving combat outcomes.

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
const AFFINITIES = preload("res://combat/affinities.gd")

static func resolve_damage(
	base_damage: int,
	damage_type: int,
	enemy_data: Resource,
	accuracy: float = 100.0,
	critical_chance: float = 0.0,
	critical_multiplier: float = 2.0
) -> Dictionary:
	## Resolve accuracy first, then apply affinity and critical-hit rules.
	##
	## A miss deals no damage and consumes one full Press Turn. A critical hit
	## increases damage and consumes only half a Press Turn. Affinity behavior
	## remains authoritative for Weak, Resist, Null, Drain, and Repel.
	if randf_range(0.0, 100.0) > clampf(accuracy, 0.0, 100.0):
		return {
			"damage": 0,
			"affinity": get_enemy_affinity(enemy_data, damage_type),
			"damage_type": damage_type,
			"turn_cost": 1.0,
			"result_type": "miss",
			"multiplier": 0.0,
			"critical": false,
		}

	var affinity := get_enemy_affinity(enemy_data, damage_type)
	var damage := maxi(base_damage, 0)
	var turn_cost := 1.0
	var result_type := "damage"
	var multiplier := 1.0

	match affinity:
		AFFINITIES.Type.WEAK:
			# Weakness increases damage and consumes only half a Press Turn.
			multiplier = 1.5
			turn_cost = 0.5
		AFFINITIES.Type.RESIST:
			# Resistance reduces damage but still consumes a normal turn.
			multiplier = 0.5
		AFFINITIES.Type.NULLIFY:
			# Nullification prevents damage and consumes two Press Turns.
			damage = 0
			turn_cost = 2.0
		AFFINITIES.Type.DRAIN:
			# Drain turns the would-be damage into healing for the target and
			# consumes the entire remaining Press Turn set.
			result_type = "drain"
			turn_cost = 4.0
		AFFINITIES.Type.REPEL:
			# Repel sends the would-be damage back to the attacker.
			result_type = "repel"

	var critical := false
	if result_type == "damage" and randf_range(0.0, 100.0) <= clampf(critical_chance, 0.0, 100.0):
		# Critical hits are resolved after affinity so the final damage reflects
		# both the target's affinity and the action's critical multiplier.
		critical = true
		multiplier *= maxf(critical_multiplier, 1.0)
		turn_cost = 0.5

	if result_type == "damage":
		damage = maxi(int(round(float(damage) * multiplier)), 0)
	elif result_type == "drain":
		damage = maxi(int(round(float(damage) * multiplier)), 0)
	elif result_type == "repel":
		damage = maxi(int(round(float(damage) * multiplier)), 0)

	return {
		"damage": damage,
		"affinity": affinity,
		"damage_type": damage_type,
		"turn_cost": turn_cost,
		"result_type": result_type,
		"multiplier": multiplier,
		"critical": critical,
	}

static func get_enemy_affinity(enemy_data: Resource, damage_type: int) -> int:
	## Return the configured affinity for a damage type.
	## Unconfigured damage types intentionally behave as Normal.
	if enemy_data == null:
		return AFFINITIES.Type.NORMAL

	for entry in enemy_data.affinities:
		if entry == null:
			continue
		if entry.damage_type == damage_type:
			return entry.affinity

	return AFFINITIES.Type.NORMAL
