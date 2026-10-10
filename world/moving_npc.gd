extends CharacterBody2D
## Shared movement foundation for autonomous world characters.
##
## Identity controls intent and encounter behavior, while this script owns
## collision, obstacle avoidance, home-area limits, and optional story movement.
## Allies use civilian-style movement and collision, but never initiate combat.

enum Identity { ENEMY, NPC, ALLY }

## Emitted when the Player enters or leaves this Ally's non-blocking detection area.
## Story/interaction systems can listen for these events without making the Ally
## physically collide with the Player or automatically starting dialogue.
signal ally_player_entered(ally: Node2D, player: Node2D)
signal ally_player_exited(ally: Node2D, player: Node2D)

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
## Radius used by the Ally sensor; it detects proximity independently of body collision.
@export var ally_detection_radius: float = 56.0
## Story movement can explicitly bypass static world collision for a cutscene.
## Normal autonomous movement always respects walls, doors, chests, and boundaries.
var story_movement_active: bool = false
var story_ignore_world_collision: bool = false
var story_movement_target: Vector2 = Vector2.ZERO
## Enables temporary console messages for validating the Ally sensor in the shared test scene.
@export var debug_ally_detection: bool = false

var player: Node2D
var movement_target: Vector2
var think_timer: float = 0.0
var encounter_locked: bool = false
var home_position: Vector2

@onready var obstacle_probe: RayCast2D = get_node_or_null("ObstacleProbe") as RayCast2D
@onready var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
var ally_detection_area: Area2D


func _ready() -> void:
	# Enemy IDs must be stable across a Battle scene transition, where the original
	# world node is freed and a fresh copy of the test/world scene is loaded.
	if identity == Identity.ENEMY and actor_id.is_empty():
		actor_id = "%s_%d_%d" % [enemy_id, int(round(global_position.x)), int(round(global_position.y))]

	# Do not recreate an enemy the Player already defeated in this runtime session.
	if identity == Identity.ENEMY and GameState.is_moving_enemy_defeated(actor_id):
		queue_free()
		return

	# Allies use the same physical collision layers as moving civilians. Their
	# separate Area2D remains only a proximity sensor; it does not replace the
	# CharacterBody2D collision shape, so the Player and Ally respect each other.
	if identity == Identity.ALLY:
		collision_layer = 2
		collision_mask = 3
		var ally_collision := get_node_or_null("Collision") as CollisionShape2D
		if ally_collision != null:
			ally_collision.set_deferred("disabled", false)
		_ensure_ally_detection_area()

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

	# A cutscene may temporarily issue an explicit target. Normal autonomous
	# movement remains home-bound and uses obstacle avoidance as usual.
	if story_movement_active:
		movement_target = story_movement_target
	else:
		think_timer -= delta
		if think_timer <= 0.0:
			think_timer = think_interval
			_choose_movement_intent()

	var desired_direction := global_position.direction_to(movement_target)
	if global_position.distance_to(movement_target) < 8.0:
		velocity = Vector2.ZERO
	else:
		var safe_direction := desired_direction
		if not (story_movement_active and story_ignore_world_collision):
			safe_direction = _avoid_obstacles(desired_direction)
		velocity = safe_direction * move_speed
	move_and_slide()

	# Only hostile identity turns physical proximity into a combat encounter.
	if identity == Identity.ENEMY and player != null and not GameState.is_escape_invulnerable():
		if global_position.distance_to(player.global_position) <= 25.0:
			_start_contact_encounter()


func _ensure_ally_detection_area() -> void:
	# Use a separate Area2D sensor instead of the CharacterBody2D collision.
	# The Ally stays pass-through, while other systems can react to proximity.
	ally_detection_area = get_node_or_null("DetectionArea") as Area2D
	if ally_detection_area == null:
		ally_detection_area = Area2D.new()
		ally_detection_area.name = "DetectionArea"
		var sensor_shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = ally_detection_radius
		sensor_shape.shape = circle
		ally_detection_area.add_child(sensor_shape)
		add_child(ally_detection_area)
	else:
		# Reuse a scene-authored sensor if one is added later, and keep its
		# detection distance consistent with the Ally's exported setting.
		var sensor_shape := ally_detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if sensor_shape != null:
			var circle := sensor_shape.shape as CircleShape2D
			if circle != null:
				circle.radius = ally_detection_radius

	# Detect Player bodies only. Layer 0 means the sensor itself does not
	# participate as a physical collision object for other actors.
	ally_detection_area.collision_layer = 0
	ally_detection_area.collision_mask = 1
	ally_detection_area.monitoring = true
	ally_detection_area.monitorable = false
	if not ally_detection_area.body_entered.is_connected(_on_ally_detection_body_entered):
		ally_detection_area.body_entered.connect(_on_ally_detection_body_entered)
	if not ally_detection_area.body_exited.is_connected(_on_ally_detection_body_exited):
		ally_detection_area.body_exited.connect(_on_ally_detection_body_exited)


func _on_ally_detection_body_entered(body: Node2D) -> void:
	# Filter out anything except the Player so an Ally's sensor cannot trigger
	# from enemies, civilians, props, or other physics bodies.
	if identity != Identity.ALLY or not body.is_in_group("player"):
		return
	ally_player_entered.emit(self, body)
	if debug_ally_detection:
		print("Ally detection entered: %s" % actor_id if not actor_id.is_empty() else "Ally detection entered: %s" % name)


func _on_ally_detection_body_exited(body: Node2D) -> void:
	if identity != Identity.ALLY or not body.is_in_group("player"):
		return
	ally_player_exited.emit(self, body)
	if debug_ally_detection:
		print("Ally detection exited: %s" % actor_id if not actor_id.is_empty() else "Ally detection exited: %s" % name)


func _find_player() -> void:
	# Use the Player group instead of assuming every scene has the same parent.
	var players := get_tree().get_nodes_in_group("player")
	player = players[0] as Node2D if not players.is_empty() else null


func _choose_movement_intent() -> void:
	# Allies behave like civilians: they make room for the Player and wander, but
	# their targets stay near their original position unless a story script takes over.
	if identity == Identity.ALLY and global_position.distance_to(home_position) >= wander_radius * 0.8:
		movement_target = home_position
		return

	if player != null:
		var distance := global_position.distance_to(player.global_position)
		if identity == Identity.ENEMY and distance <= detection_range:
			# Hostile actors actively chase while the Player is within detection range.
			movement_target = player.global_position
			return
		if identity in [Identity.NPC, Identity.ALLY] and distance <= personal_space:
			# Civilians move away from the Player rather than turning contact into combat.
			var away := (global_position - player.global_position).normalized()
			if away.is_zero_approx():
				away = Vector2.RIGHT.rotated(randf_range(-PI, PI))
			var retreat_target := global_position + away * wander_radius
			if identity == Identity.ALLY:
				# Keep the retreat destination inside the Ally's home radius even
				# when the Player approaches from the far edge of that radius.
				var home_offset := retreat_target - home_position
				var home_limit := wander_radius * 0.75
				if home_offset.length() > home_limit:
					retreat_target = home_position + home_offset.normalized() * home_limit
			movement_target = retreat_target
			return

	# Pick a point inside a circular home area. This prevents Allies from gradually
	# drifting across a town even after many random movement decisions.
	var random_angle := randf_range(-PI, PI)
	var random_distance := sqrt(randf()) * wander_radius
	var random_offset := Vector2.RIGHT.rotated(random_angle) * random_distance
	movement_target = home_position + random_offset


func move_to_story_target(target_position: Vector2, ignore_world_collision: bool = false) -> void:
	# Cutscene/story scripts can deliberately move an Ally outside its normal home
	# radius. Static-world collision is still respected unless the caller explicitly
	# requests a scripted pass-through for a controlled cutscene.
	story_movement_active = true
	story_ignore_world_collision = ignore_world_collision
	story_movement_target = target_position
	if story_ignore_world_collision:
		collision_mask = 2 # Keep actor-to-actor collision while ignoring static world layer 1.
	else:
		collision_mask = 3


func clear_story_movement() -> void:
	# Return control to autonomous AI and restore normal world collision. The next
	# AI decision will choose a target inside the actor's usual home area.
	story_movement_active = false
	story_ignore_world_collision = false
	collision_mask = 3
	movement_target = home_position


func _avoid_obstacles(direction: Vector2) -> Vector2:
	if obstacle_probe == null or direction.is_zero_approx():
		return direction

	# Test the full width of the actor's path, not just one center line. This helps
	# keep the Ally clear of building walls, door collision, chests, and boundaries
	# whose edges would otherwise clip the body while the center ray looked clear.
	if _is_direction_clear(direction):
		return direction

	# Try progressively wider turns. A narrow pair of alternatives can fail
	# when the Player pushes a civilian or Ally against a door or chest, leaving
	# the actor with no valid way to escape the obstacle.
	for angle in [PI / 4.0, -PI / 4.0, PI / 2.0, -PI / 2.0, PI * 3.0 / 4.0, -PI * 3.0 / 4.0, PI]:
		var alternative := direction.rotated(angle)
		if _is_direction_clear(alternative):
			return alternative

	# If every route is blocked, stop rather than continually driving into a wall.
	return Vector2.ZERO


func _is_direction_clear(direction: Vector2) -> bool:
	# Three parallel ray checks approximate the width of the 24x24 actor while
	# reusing the scene's existing RayCast2D and its world-obstacle collision mask.
	var original_position := obstacle_probe.position
	var lateral := direction.rotated(PI / 2.0).normalized() * 10.0
	for offset in [Vector2.ZERO, lateral, -lateral]:
		obstacle_probe.position = original_position + offset
		obstacle_probe.target_position = direction.normalized() * obstacle_probe_distance
		obstacle_probe.force_raycast_update()
		if obstacle_probe.is_colliding():
			obstacle_probe.position = original_position
			return false
	obstacle_probe.position = original_position
	return true


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
