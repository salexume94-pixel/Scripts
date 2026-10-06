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
	critical_multiplier: float = 1.5
) -> Dictionary:
	## Resolve Player damage against an EnemyData definition.
	## This remains the existing public entry point for Player attacks.
	return resolve_damage_against_affinities(
		base_damage,
		damage_type,
		enemy_data.affinities if enemy_data != null else [],
		accuracy,
		critical_chance,
		critical_multiplier
	)

static func resolve_damage_against_affinities(
	base_damage: int,
	damage_type: int,
	affinities: Array[Resource],
	accuracy: float = 100.0,
	critical_chance: float = 0.0,
	critical_multiplier: float = 2.0
) -> Dictionary:
	## Resolve damage against any target affinity list.
	##
	## This shared path lets Player and Enemy actions use the same elemental
	## rules. Enemy AI can therefore select an elemental action based on the
	## Player's weakness and the resulting attack can apply that same weakness
	## when it is actually performed.
	var resolved_accuracy := clampf(accuracy, 0.0, 100.0)
	var accuracy_roll := randf() * 100.0
	if accuracy_roll >= resolved_accuracy:
		return {
			"damage": 0,
			"affinity": get_affinity_from_list(affinities, damage_type),
			"damage_type": damage_type,
			"turn_cost": 1.0,
			"result_type": "miss",
			"multiplier": 0.0,
			"critical": false,
			"accuracy": resolved_accuracy,
			"accuracy_roll": accuracy_roll,
			"critical_chance": clampf(critical_chance, 0.0, 100.0),
			"critical_roll": -1.0,
		}

	var affinity := get_affinity_from_list(affinities, damage_type)
	var damage := maxi(base_damage, 0)
	var turn_cost := 1.0
	var result_type := "damage"
	var multiplier := 1.0

	match affinity:
		AFFINITIES.Type.WEAK:
			multiplier = 1.5
			turn_cost = 0.5
		AFFINITIES.Type.RESIST:
			multiplier = 0.5
		AFFINITIES.Type.NULLIFY:
			damage = 0
			turn_cost = 2.0
		AFFINITIES.Type.DRAIN:
			result_type = "drain"
			turn_cost = 4.0
		AFFINITIES.Type.REPEL:
			result_type = "repel"

	var critical := false
	var resolved_critical_chance := clampf(critical_chance, 0.0, 100.0)
	var critical_roll := randf() * 100.0
	if result_type == "damage" and critical_roll < resolved_critical_chance:
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
		"accuracy": resolved_accuracy,
		"accuracy_roll": accuracy_roll,
		"critical_chance": resolved_critical_chance,
		"critical_roll": critical_roll,
	}

static func get_enemy_affinity(enemy_data: Resource, damage_type: int) -> int:
	## Return the configured affinity for a damage type.
	## Unconfigured damage types intentionally behave as Normal.
	if enemy_data == null:
		return AFFINITIES.Type.NORMAL
	return get_affinity_from_list(enemy_data.affinities, damage_type)

static func get_affinity_from_list(affinities: Array[Resource], damage_type: int) -> int:
	## Return the configured affinity for a damage type from any target list.
	## Unconfigured damage types intentionally behave as Normal.
	for entry in affinities:
		if entry == null:
			continue
		if entry.damage_type == damage_type:
			return entry.affinity
	return AFFINITIES.Type.NORMAL
