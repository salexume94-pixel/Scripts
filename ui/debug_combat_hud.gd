extends CanvasLayer
## Presents combat-only diagnostic information for development testing.
##
## This HUD is intentionally separate from the normal Battle UI. It reads
## CombatManager state and never changes combat rules, enemy data, or AI.
## F3 toggles the panel so normal gameplay remains uncluttered.

const DAMAGE_TYPES = preload("res://combat/damage_types.gd")
const AFFINITIES = preload("res://combat/affinities.gd")

@onready var panel: Control = $Panel
@onready var status_label: Label = $Panel/Margin/Content/Status
@onready var target_affinities_label: Label = $Panel/Margin/Content/TargetAffinities
@onready var player_affinities_label: Label = $Panel/Margin/Content/PlayerAffinities
@onready var last_player_label: Label = $Panel/Margin/Content/LastPlayer
@onready var last_enemy_label: Label = $Panel/Margin/Content/LastEnemy
@onready var ai_trace_label: Label = $Panel/Margin/Content/AITrace
@onready var log_label: Label = $Panel/Margin/Content/LogScroll/Log

func _ready() -> void:
	# Start enabled during development so affinity behavior is immediately visible.
	panel.visible = true
	CombatManager.combat_log_updated.connect(_refresh)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	# F3 provides a simple development-only toggle without adding a gameplay control.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		panel.visible = not panel.visible
		if panel.visible:
			_refresh()

func _process(_delta: float) -> void:
	# Keep the diagnostic values current while an encounter is running.
	if panel.visible:
		_refresh()

func _refresh() -> void:
	if not CombatManager.is_in_combat():
		status_label.text = "Status: No active combat"
		target_affinities_label.text = "Target affinities: None"
		player_affinities_label.text = "Player affinities: None"
		last_player_label.text = "Last Player action: None"
		last_enemy_label.text = "Last Enemy action: None"
		ai_trace_label.text = "AI trace unavailable."
		log_label.text = "No combat log."
		return

	var enemy_data: Resource = CombatManager.enemy_data_for_active_combat()
	status_label.text = "Status: %s | Enemy HP: %d / %d | Press Turns: %.1f" % [
		"Victory" if CombatManager.is_victory() else ("Defeat" if CombatManager.is_defeat() else ("Enemy Turn" if CombatManager.is_enemy_turn() else "Player Turn")),
		CombatManager.get_enemy_hp(),
		CombatManager.get_enemy_max_hp(),
		CombatManager.get_player_press_turns_remaining(),
	]
	target_affinities_label.text = "Target affinities:\n" + _format_affinities(enemy_data.get("affinities") if enemy_data != null else [])
	player_affinities_label.text = "Player affinities:\n" + _format_affinities(_get_player_affinities())
	last_player_label.text = _format_last_player()
	last_enemy_label.text = _format_last_enemy()
	ai_trace_label.text = "\n".join(CombatManager.last_enemy_ai_debug) if not CombatManager.last_enemy_ai_debug.is_empty() else "AI trace unavailable."
	log_label.text = "\n".join(CombatManager.get_combat_log())
	call_deferred("_scroll_log_to_latest")

func _get_player_affinities() -> Array:
	var current_scene := get_tree().current_scene
	if current_scene != null:
		var player := current_scene.get_node_or_null("Player")
		if player != null:
			var stats := player.get_node_or_null("PlayerStats")
			if stats != null:
				return stats.get("affinities")
	return CombatManager.active_combat.player_affinities if CombatManager.is_in_combat() else []

func _format_affinities(affinities: Array) -> String:
	if affinities.is_empty():
		return "None configured (defaults to Normal)"

	var lines: Array[String] = []
	for entry in affinities:
		if entry == null:
			continue
		lines.append("%s -> %s" % [
			DAMAGE_TYPES.get_display_name(int(entry.damage_type)),
			AFFINITIES.get_display_name(int(entry.affinity)),
		])
	return "\n".join(lines) if not lines.is_empty() else "None configured (defaults to Normal)"

func _format_last_player() -> String:
	var damage_type := DAMAGE_TYPES.get_display_name(CombatManager.get_last_player_damage_type())
	var affinity := AFFINITIES.get_display_name(CombatManager.get_last_player_affinity())
	return "Player: %s | %s | %d dmg | Crit: %s | Result: %s" % [
		damage_type,
		affinity,
		CombatManager.get_last_damage(),
		"YES" if CombatManager.get_last_player_critical() else "NO",
		CombatManager.get_last_player_result_type(),
	]

func _format_last_enemy() -> String:
	if CombatManager.get_last_enemy_action_name().is_empty():
		return "Enemy: None"
	return "Enemy: %s | %s | %d dmg | Crit: %s | Result: %s" % [
		CombatManager.get_last_enemy_action_name(),
		"%s / %s" % [
			DAMAGE_TYPES.get_display_name(CombatManager.active_combat.last_enemy_damage_type),
			AFFINITIES.get_display_name(CombatManager.active_combat.last_enemy_affinity),
		],
		CombatManager.active_combat.last_enemy_damage,
		"YES" if CombatManager.get_last_enemy_critical() else "NO",
		CombatManager.active_combat.last_enemy_result_type,
	]

func _scroll_log_to_latest() -> void:
	var scroll := $Panel/Margin/Content/LogScroll as ScrollContainer
	if scroll == null:
		return
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
