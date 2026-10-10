extends Node
## Builds the Player's directional SpriteFrames and selects idle/walk/run animations.
##
## The art is stored as individual 32x32 PNG frames in GitHub. Loading those
## frames here avoids a manually maintained SpriteFrames resource and keeps the
## asset folder layout as the single source of truth.

const ANIMATION_ROOT := "res://assets/player_animations/Player/Player_Sprites/animations/"
const DIRECTIONS: Array[String] = [
	"south", "north", "west", "east",
	"south-west", "south-east", "north-west", "north-east"
]
const ANIMATION_FOLDERS := {
	"idle": "idle_breathing",
	"walk": "Walking",
	"run": "Running"
}
const ANIMATION_SPEEDS := {
	"idle": 4.0,
	"walk": 10.0,
	"run": 12.0
}
const FRAME_COUNT := 8

@onready var sprite: AnimatedSprite2D = $"../PlayerSprite"

# The Player keeps facing the last direction it moved in while idle.
var facing_direction: String = "south"


func _ready() -> void:
	_build_sprite_frames()
	update_motion(Vector2.ZERO, false)


func _build_sprite_frames() -> void:
	# Generate all 24 combinations: three movement states in eight directions.
	var sprite_frames := SpriteFrames.new()
	sprite_frames.clear_all()

	for state in ANIMATION_FOLDERS:
		for direction in DIRECTIONS:
			var animation_name := _animation_name(state, direction)
			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, ANIMATION_SPEEDS[state])
			sprite_frames.set_animation_loop(animation_name, true)

			for frame_index in range(FRAME_COUNT):
				var frame_path := "%s%s/%s/frame_%03d.png" % [
					ANIMATION_ROOT,
					ANIMATION_FOLDERS[state],
					direction,
					frame_index
				]
				var texture := load(frame_path) as Texture2D
				if texture == null:
					push_error("Player animation frame could not be loaded: " + frame_path)
					continue
				sprite_frames.add_frame(animation_name, texture)

	sprite.sprite_frames = sprite_frames
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func update_motion(direction: Vector2, is_running: bool) -> void:
	# Update facing only while moving, so idle keeps the correct view.
	if direction.length_squared() > 0.001:
		facing_direction = _direction_from_vector(direction)

	var state := "idle"
	if direction.length_squared() > 0.001:
		state = "run" if is_running else "walk"

	var animation_name := _animation_name(state, facing_direction)
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name):
		# Avoid restarting the animation every physics frame.
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)


func _direction_from_vector(direction: Vector2) -> String:
	# Godot's 2D coordinates increase downward, so negative Y is north.
	var horizontal := signf(direction.x)
	var vertical := signf(direction.y)

	if vertical < 0.0:
		if horizontal < 0.0:
			return "north-west"
		if horizontal > 0.0:
			return "north-east"
		return "north"

	if vertical > 0.0:
		if horizontal < 0.0:
			return "south-west"
		if horizontal > 0.0:
			return "south-east"
		return "south"

	return "west" if horizontal < 0.0 else "east"


func _animation_name(state: String, direction: String) -> String:
	return state + "_" + direction
