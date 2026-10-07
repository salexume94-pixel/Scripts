extends Node
## Owns the Player's level and experience progression rules.
##
## PlayerStats remains the owner of the resulting numerical stat values.
## This script decides how much experience is required, when a level is gained,
## and which permanent stat increases are applied at each level.
##
## Keeping progression rules here prevents CombatManager, QuestManager, and
## reward systems from inventing their own level-up behavior.

const BASE_XP_TO_NEXT_LEVEL: int = 100
const MAX_LEVEL: int = 50

# Permanent stat growth applied each time the Player gains a level.
const HP_PER_LEVEL: int = 10
const MP_PER_LEVEL: int = 2
const ATTACK_PER_LEVEL: int = 2
const DEFENSE_PER_LEVEL: int = 2
const MAGIC_ATTACK_PER_LEVEL: int = 1
const MAGIC_DEFENSE_PER_LEVEL: int = 1
const SPEED_PER_LEVEL: int = 1

signal level_up(new_level: int)

func get_experience_required_for_next_level(level: int) -> int:
	# XP requirements increase with the Player's current level. Level 1 needs
	# 100 XP for level 2, level 2 needs 200 XP for level 3, and so on.
	if level >= MAX_LEVEL:
		return 0
	return BASE_XP_TO_NEXT_LEVEL * maxi(level, 1)

func get_experience_to_next_level() -> int:
	# Read the current PlayerStats value instead of keeping a second level value.
	var stats := get_parent().get_node_or_null("PlayerStats")
	if stats == null:
		return 0

	var level: int = int(stats.get("level"))
	if level >= MAX_LEVEL:
		return 0

	var required := get_experience_required_for_next_level(level)
	return maxi(required - int(stats.get("experience")), 0)

func add_experience(amount: int) -> int:
	# Apply experience to the active Player and return how many levels were gained.
	if amount <= 0:
		return 0

	var stats := get_parent().get_node_or_null("PlayerStats")
	if stats == null:
		return 0

	var result: Dictionary = apply_experience_to_snapshot(stats_to_snapshot(stats), amount)
	apply_snapshot_to_stats(stats, result["stats"])

	var levels_gained: int = int(result["levels_gained"])
	for i in range(levels_gained):
		level_up.emit(int(stats.get("level")) - levels_gained + i + 1)

	return levels_gained

static func apply_experience_to_snapshot(snapshot: Dictionary, amount: int) -> Dictionary:
	# This static form uses the same progression rules when the Player scene is
	# not present, such as while Battle.tscn is active and rewards are granted.
	var stats := snapshot.duplicate()
	var levels_gained := 0

	if amount <= 0:
		return {"stats": stats, "levels_gained": 0}

	var level: int = clampi(int(stats.get("level", 1)), 1, MAX_LEVEL)
	var experience: int = maxi(int(stats.get("experience", 0)), 0)

	experience += amount

	while level < MAX_LEVEL:
		var required := get_experience_required_for_level(level)
		if experience < required:
			break

		experience -= required
		level += 1
		levels_gained += 1

		# Level-up growth is applied to the base stat snapshot. Equipment bonuses
		# are reapplied separately by PlayerEquipment when the Player is restored.
		stats["max_hp"] = int(stats.get("max_hp", 100)) + HP_PER_LEVEL
		stats["hp"] = int(stats.get("hp", stats["max_hp"])) + HP_PER_LEVEL
		stats["max_mp"] = int(stats.get("max_mp", 20)) + MP_PER_LEVEL
		stats["mp"] = int(stats.get("mp", stats["max_mp"])) + MP_PER_LEVEL
		stats["attack"] = int(stats.get("attack", 10)) + ATTACK_PER_LEVEL
		stats["defense"] = int(stats.get("defense", 10)) + DEFENSE_PER_LEVEL
		stats["magic_attack"] = int(stats.get("magic_attack", 10)) + MAGIC_ATTACK_PER_LEVEL
		stats["magic_defense"] = int(stats.get("magic_defense", 10)) + MAGIC_DEFENSE_PER_LEVEL
		stats["speed"] = int(stats.get("speed", 10)) + SPEED_PER_LEVEL

	stats["level"] = level
	stats["experience"] = experience

	return {"stats": stats, "levels_gained": levels_gained}

static func get_experience_required_for_level(level: int) -> int:
	# Static helper keeps the level curve available to systems that operate
	# while the Player scene is not instantiated.
	if level >= MAX_LEVEL:
		return 0
	return BASE_XP_TO_NEXT_LEVEL * maxi(level, 1)

static func stats_to_snapshot(stats: Node) -> Dictionary:
	# PlayerStats already stores base Attack/Defense separately in GameState by
	# removing equipment modifiers. Mirror that same representation here.
	var equipment_attack_bonus: int = int(stats.get("equipment_attack_bonus"))
	var equipment_defense_bonus: int = int(stats.get("equipment_defense_bonus"))

	return {
		"level": int(stats.get("level")),
		"experience": int(stats.get("experience")),
		"max_hp": int(stats.get("max_hp")),
		"hp": int(stats.get("hp")),
		"max_mp": int(stats.get("max_mp")),
		"mp": int(stats.get("mp")),
		"attack": int(stats.get("attack")) - equipment_attack_bonus,
		"defense": int(stats.get("defense")) - equipment_defense_bonus,
		"magic_attack": int(stats.get("magic_attack")),
		"magic_defense": int(stats.get("magic_defense")),
		"speed": int(stats.get("speed")),
	}

static func apply_snapshot_to_stats(stats: Node, snapshot: Dictionary) -> void:
	# Restore the base progression values, then let the existing equipment
	# modifiers remain applied to the resulting Attack/Defense values.
	var old_equipment_attack: int = int(stats.get("equipment_attack_bonus"))
	var old_equipment_defense: int = int(stats.get("equipment_defense_bonus"))

	stats.set("level", int(snapshot.get("level", stats.get("level"))))
	stats.set("experience", int(snapshot.get("experience", stats.get("experience"))))
	stats.set("max_hp", int(snapshot.get("max_hp", stats.get("max_hp"))))
	stats.set("hp", int(snapshot.get("hp", stats.get("hp"))))
	stats.set("max_mp", int(snapshot.get("max_mp", stats.get("max_mp"))))
	stats.set("mp", int(snapshot.get("mp", stats.get("mp"))))
	stats.set("attack", int(snapshot.get("attack", stats.get("attack"))) + old_equipment_attack)
	stats.set("defense", int(snapshot.get("defense", stats.get("defense"))) + old_equipment_defense)
	stats.set("magic_attack", int(snapshot.get("magic_attack", stats.get("magic_attack"))))
	stats.set("magic_defense", int(snapshot.get("magic_defense", stats.get("magic_defense"))))
	stats.set("speed", int(snapshot.get("speed", stats.get("speed"))))

	# PlayerStats remains responsible for synchronizing its resulting values.
	stats.call("_sync_to_game_state")
