extends Node2D
## Loads a small forest/field Tiled map using the project's shared 16x16 exterior atlas.
## This loader handles the CSV tile layers used by Waking Area and Mira's clearing.
## It builds a single static collision body from the opaque pixels of every
## placed tree tile across all tree layers. Trunks and canopies are both solid;
## transparent atlas margins remain walkable.

const TILE_SIZE := Vector2i(16, 16)
const ATLAS_TEXTURE_PATH := "res://assets/maps_tileset/town_map/towns_tileset/PNG/exterior.png"
const ATLAS_COLUMNS := 15
const ATLAS_ROWS := 50

@export_file("*.tmx") var map_path: String = ""


func _ready() -> void:
	# Fail clearly when a scene has not configured its source map.
	if map_path.is_empty():
		push_error("ForestTiledMapLoader requires a TMX map_path.")
		return
	_load_map()


func _load_map() -> void:
	# Parse map dimensions and layer CSV data directly from the tracked TMX.
	var parser := XMLParser.new()
	var open_error := parser.open(map_path)
	if open_error != OK:
		push_error("ForestTiledMapLoader could not open map: %s" % map_path)
		return

	var map_width := 0
	var map_height := 0
	var tile_width := 0
	var tile_height := 0
	var layers: Array[Dictionary] = []
	var current_layer: Dictionary = {}
	var inside_layer := false
	var inside_data := false

	while parser.read() == OK:
		var node_type := parser.get_node_type()
		var node_name := ""
		if node_type == XMLParser.NODE_ELEMENT or node_type == XMLParser.NODE_ELEMENT_END:
			node_name = parser.get_node_name()

		if node_type == XMLParser.NODE_ELEMENT:
			if node_name == "map":
				map_width = parser.get_named_attribute_value("width").to_int()
				map_height = parser.get_named_attribute_value("height").to_int()
				tile_width = parser.get_named_attribute_value("tilewidth").to_int()
				tile_height = parser.get_named_attribute_value("tileheight").to_int()
			elif node_name == "layer":
				inside_layer = true
				current_layer = {
					"name": parser.get_named_attribute_value("name"),
					"width": parser.get_named_attribute_value("width").to_int(),
					"height": parser.get_named_attribute_value("height").to_int(),
					"csv": ""
				}
			elif node_name == "data" and inside_layer:
				inside_data = true
		elif node_type == XMLParser.NODE_TEXT and inside_data and inside_layer:
			current_layer["csv"] = str(current_layer["csv"]) + parser.get_node_data()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "data":
				inside_data = false
			elif node_name == "layer" and inside_layer:
				layers.append(current_layer.duplicate())
				current_layer.clear()
				inside_layer = false
				inside_data = false

	# The two current forest maps use a finite 20x20 grid of 16px cells.
	if map_width <= 0 or map_height <= 0 or tile_width != TILE_SIZE.x or tile_height != TILE_SIZE.y:
		push_error("ForestTiledMapLoader found unsupported map dimensions: %s" % map_path)
		return
	if layers.is_empty():
		push_error("ForestTiledMapLoader found no tile layers: %s" % map_path)
		return

	# Load the same exterior atlas used by the TMX tileset definition.
	var atlas_texture := load(ATLAS_TEXTURE_PATH) as Texture2D
	if atlas_texture == null:
		push_error("ForestTiledMapLoader could not load atlas: %s" % ATLAS_TEXTURE_PATH)
		return

	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	var atlas := TileSetAtlasSource.new()
	atlas.texture = atlas_texture
	atlas.texture_region_size = TILE_SIZE
	for y in range(ATLAS_ROWS):
		for x in range(ATLAS_COLUMNS):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, 0)

	# Center the map so scene actors and the boundary use world coordinates around (0, 0).
	var map_origin := Vector2(
		-float(map_width * tile_width) / 2.0,
		-float(map_height * tile_height) / 2.0
	)

	# One static body owns all generated tree collision, matching Havenreach's
	# approach without creating a separate physics body for every occupied tile.
	var collision_body := StaticBody2D.new()
	collision_body.name = "GeneratedTreeCollision"
	collision_body.position = map_origin
	collision_body.collision_layer = 1
	collision_body.collision_mask = 1
	add_child(collision_body)
	var collision_count := 0
	var tree_layer_found := false
	var atlas_image := atlas_texture.get_image()

	for layer_index in range(layers.size()):
		var layer_data: Dictionary = layers[layer_index]
		var layer_name := str(layer_data["name"])
		var layer_width: int = int(layer_data["width"])
		var layer_height: int = int(layer_data["height"])
		var raw_cells: PackedStringArray = str(layer_data["csv"]).strip_edges().split(",", false)
		var expected_cells := layer_width * layer_height
		if raw_cells.size() != expected_cells:
			push_error(
				"ForestTiledMapLoader layer '%s' has %d cells; expected %d."
				% [layer_name, raw_cells.size(), expected_cells]
			)
			continue

		var tile_layer := TileMapLayer.new()
		tile_layer.name = layer_name.to_pascal_case().replace(" ", "")
		tile_layer.tile_set = tile_set
		tile_layer.position = map_origin
		# Tiled's later tree layers contain upper canopy art and must draw above actors.
		var normalized_name := layer_name.to_lower()
		if normalized_name.contains("tree layer 4") or normalized_name.contains("tree layer 3"):
			tile_layer.z_index = 20 + layer_index
		elif normalized_name.contains("tree layer 2"):
			tile_layer.z_index = -1
		elif normalized_name.contains("tree layer 1"):
			tile_layer.z_index = -2
		else:
			tile_layer.z_index = -10 + layer_index
		add_child(tile_layer)

		# Tree artwork is split across multiple Tiled layers. All of those layers
		# contribute to one shared StaticBody2D, so the full visible tree
		# footprint, including canopy, is impassable without stacked physics bodies.
		var layer_is_tree := layer_name.to_lower().contains("tree layer")
		if layer_is_tree:
			tree_layer_found = true

		for cell_index in range(raw_cells.size()):
			var gid := raw_cells[cell_index].to_int()
			if gid <= 0:
				continue
			var local_id := gid - 1
			if local_id < 0 or local_id >= ATLAS_COLUMNS * ATLAS_ROWS:
				push_warning("Forest Tiled map has unsupported tile GID %d in %s." % [gid, layer_name])
				continue
			var cell_coords := Vector2i(cell_index % layer_width, floori(float(cell_index) / float(layer_width)))
			var atlas_coords := Vector2i(local_id % ATLAS_COLUMNS, floori(float(local_id) / float(ATLAS_COLUMNS)))
			tile_layer.set_cell(cell_coords, 0, atlas_coords)

			# Use every opaque pixel in each tree tile, including upper canopy tiles.
			# Collision shapes remain children of the same body, making the whole
			# visible tree footprint solid while preserving transparent gaps.
			if layer_is_tree:
				for rect in _get_alpha_collision_rects(atlas_image, atlas_coords):
					var collision_shape := CollisionShape2D.new()
					collision_shape.name = "TreePixel_%d_%d_%d" % [cell_coords.x, cell_coords.y, collision_count]
					var rectangle := RectangleShape2D.new()
					rectangle.size = Vector2(rect.size)
					collision_shape.shape = rectangle
					collision_shape.position = Vector2(
						float(cell_coords.x) * TILE_SIZE.x,
						float(cell_coords.y) * TILE_SIZE.y
					) + Vector2(rect.position) + Vector2(rect.size) / 2.0
					collision_body.add_child(collision_shape)
					collision_count += 1

	if not tree_layer_found:
		push_warning("ForestTiledMapLoader found no tree layers to generate collision from: %s" % map_path)
	elif collision_count == 0:
		push_warning("ForestTiledMapLoader generated no tree collision shapes for: %s" % map_path)
	else:
		print("ForestTiledMapLoader generated %d tree collision shapes for %s." % [collision_count, map_path])

	print("ForestTiledMapLoader loaded %s (%dx%d, %d layers)." % [map_path, map_width, map_height, layers.size()])


func _get_alpha_collision_rects(image: Image, atlas_coords: Vector2i) -> Array[Rect2i]:
	# Convert contiguous runs of opaque atlas pixels into merged rectangles,
	# reducing invisible blockers around transparent tree edges.
	var completed: Array[Rect2i] = []
	if image == null or image.is_empty():
		return completed

	var origin := atlas_coords * TILE_SIZE
	var active_runs: Dictionary = {}
	for y in range(TILE_SIZE.y):
		var row_runs: Array[Vector2i] = []
		var run_start := -1
		for x in range(TILE_SIZE.x):
			var alpha := image.get_pixel(origin.x + x, origin.y + y).a
			if alpha > 0.5:
				if run_start < 0:
					run_start = x
			elif run_start >= 0:
				row_runs.append(Vector2i(run_start, x))
				run_start = -1
		if run_start >= 0:
			row_runs.append(Vector2i(run_start, TILE_SIZE.x))

		var row_keys: Dictionary = {}
		for run in row_runs:
			var key := "%d:%d" % [run.x, run.y]
			row_keys[key] = true
			if active_runs.has(key):
				var active_rect: Rect2i = active_runs[key]
				active_rect.size.y += 1
				active_runs[key] = active_rect
			else:
				active_runs[key] = Rect2i(run.x, y, run.y - run.x, 1)

		var old_keys: Array = active_runs.keys()
		for key in old_keys:
			if not row_keys.has(key):
				completed.append(active_runs[key])
				active_runs.erase(key)

	for rect in active_runs.values():
		completed.append(rect)
	return completed
