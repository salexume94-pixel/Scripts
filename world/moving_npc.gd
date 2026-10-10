extends CharacterBody2D
## Shared movement foundation for autonomous world characters.
##
## Identity decides intent and encounter behavior. Collision and steering stay
## here so Enemy and NPC actors use the same predictable physics foundation.
## Ally is intentionally only an identity value until companion combat is designed.

enum Identity { ENEMY, NPC, ALLY }

@export var identity: Identity = Identity.NPC
## Stable per-instance key used to restore or remove this actor after Battle reloads the scene.
@export var actor_id: String = ""
@export var move_speed: float = 95.0
@export var detection_range: float = 260.0
@export var personal_space: float = 90.0
@export var wander_radius: float = 180.0
@export var enemy_id: String = "slime"
@export var think_interval: float = 0.35
@export var obstacle_probe_distance: float = 34.0

var player: Node2D
var movement_target: Vector2
var think_timer: float = 0.0
var encounter_locked: bool = false
var home_position: Vector2

@onready var obstacle_probe: RayCast2D = get_node_or_null("ObstacleProbe") as RayCast2D
@onready var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D


func _ready() -> void:
	# Enemy IDs must be stable across a Battle scene transition, where the original
	# world node is freed and a fresh copy of the test/world scene is loaded.
	if identity == Identity.ENEMY and actor_id.is_empty():
		actor_id = "%s_%d_%d" % [enemy_id, int(round(global_position.x)), int(round(global_position.y))]

	# Do not recreate an enemy the Player already defeated in this runtime session.
	if identity == Identity.ENEMY and GameState.is_moving_enemy_defeated(actor_id):
		queue_free()
		return

	# Allies are only visual identity markers for now. They should neither wander
	# nor physically block/pin the Player while companion behavior is unimplemented.
	if identity == Identity.ALLY:
		collision_layer = 0
		collision_mask = 0
		var ally_collision := get_node_or_null("Collision") as CollisionShape2D
		if ally_collision != null:
			ally_collision.set_deferred("disabled", true)

	# If the Player ran from this actor, restore its battle-start position and
	# begin its one-second recovery pause after the world has loaded again.
	if identity == Identity.ENEMY:
		var escaped_state: Dictionary = GameState.consume_escaped_enemy_return(actor_id)
		if not escaped_state.is_empty():
			global_position = escaped_state.get("position", global_position)

	home_position = global_position
	add_to_group("moving_npc")
	match identity:
		Identity.ENEMY:
			add_to_group("moving_enemy")
		Identity.NPC:
			add_to_group("moving_npc_civilian")
		Identity.ALLY:
			add_to_group("moving_ally")
	_update_identity_visual()
	_find_player()
	movement_target = home_position


func _physics_process(delta: float) -> void:
	# Ally is deliberately stationary until companion behavior is designed.
	if identity == Identity.ALLY:
		velocity = Vector2.ZERO
		return

	# Keep the escaped enemy still for its recovery window after returning to the world.
	if identity == Identity.ENEMY and GameState.is_enemy_recovery_paused(actor_id):
		velocity = Vector2.ZERO
		return

	# Never start another encounter while combat is active or after this actor
	# has already requested one. This prevents repeated contact signals/frames.
	if encounter_locked or CombatManager.is_in_combat() or SceneManager.transition_in_progress:
		velocity = Vector2.ZERO
		return

	if player == null or not is_instance_valid(player):
		_find_player()

	think_timer -= delta
	if think_timer <= 0.0:
		think_timer = think_interval
		_choose_movement_intent()

	var desired_direction := global_position.direction_to(movement_target)
	if global_position.distance_to(movement_target) < 8.0:
		velocity = Vector2.ZERO
	else:
		velocity = _avoid_obstacles(desired_direction) * move_speed
	move_and_slide()

	# Only hostile identity turns physical proximity into a combat encounter.
	if identity == Identity.ENEMY and player != null and not GameState.is_escape_invulnerable():
		if global_position.distance_to(player.global_position) <= 25.0:
			_start_contact_encounter()


func _find_player() -> void:
	# Use the Player group instead of assuming every scene has the same parent.
	var players := get_tree().get_nodes_in_group("player")
	player = players[0] as Node2D if not players.is_empty() else null


func _choose_movement_intent() -> void:
	# Ally has no autonomous movement behavior yet; avoid falling through to wandering.
	if identity == Identity.ALLY:
		movement_target = global_position
		return

	if player != null:
		var distance := global_position.distance_to(player.global_position)
		if identity == Identity.ENEMY and distance <= detection_range:
			# Hostile actors actively chase while the Player is within detection range.
			movement_target = player.global_position
			return
		if identity == Identity.NPC and distance <= personal_space:
			# Civilians move away from the Player rather than turning contact into combat.
			var away := (global_position - player.global_position).normalized()
			if away.is_zero_approx():
				away = Vector2.RIGHT.rotated(randf_range(-PI, PI))
			movement_target = global_position + away * wander_radius
			return

	# Outside their active response, both types wander near their starting point.
	var random_offset := Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	movement_target = home_position + random_offset


func _avoid_obstacles(direction: Vector2) -> Vector2:
	if obstacle_probe == null or direction.is_zero_approx():
		return direction

	# Probe ahead of the body. When a wall or solid prop blocks the direct path,
	# test angled alternatives instead of continuously pushing into the obstacle.
	obstacle_probe.target_position = direction * obstacle_probe_distance
	obstacle_probe.force_raycast_update()
	if not obstacle_probe.is_colliding():
		return direction

	var left := direction.rotated(-PI / 3.0)
	var right := direction.rotated(PI / 3.0)
	obstacle_probe.target_position = left * obstacle_probe_distance
	obstacle_probe.force_raycast_update()
	if not obstacle_probe.is_colliding():
		return left
	obstacle_probe.target_position = right * obstacle_probe_distance
	obstacle_probe.force_raycast_update()
	if not obstacle_probe.is_colliding():
		return right

	# If all three paths are blocked, stop briefly. The next AI decision retries.
	return Vector2.ZERO


func _start_contact_encounter() -> void:
	if encounter_locked or player == null:
		return
	encounter_locked = true
	velocity = Vector2.ZERO
	if not CombatManager.start_encounter(enemy_id, actor_id, global_position):
		# Invalid enemy data or missing encounter context should not permanently
		# freeze the actor; allow a later contact attempt instead.
		encounter_locked = false


func _update_identity_visual() -> void:
	# Simple diagnostic colors make the test actors easy to identify before
	# final character sprites are connected.
	if visual == null:
		return
	match identity:
		Identity.ENEMY:
			visual.color = Color(0.85, 0.18, 0.16)
		Identity.NPC:
			visual.color = Color(0.2, 0.75, 0.35)
		Identity.ALLY:
			visual.color = Color(0.2, 0.5, 0.95)
