extends Node2D
## Loads the Havenreach Tiled CSV map into native Godot TileMapLayer nodes.
##
## Tiled remains the source of truth for visual layout. This loader also builds
## simple static collision from the placed object tiles because the current TMX
## has no authored collision/object layer.
##
## Collision policy:
## - House/fence tiles and church tiles block movement.
## - Large rocks, trees, and bushes placed on "Rocks, Flowers" block movement.
## - Grass and small decorative ground plants are ignored.
## - The church doorway and the visible house doorway tiles remain open.
## - Roads and ground tiles are not treated as obstacles.

const MAP_PATH := "res://world/maps/havensreach/Havensreach.tmx"
const EXTERIOR_TEXTURE_PATH := "res://assets/maps_tileset/town_map/towns_tileset/PNG/exterior.png"
const CHURCH_TEXTURE_PATH := "res://assets/maps_tileset/town_map/church_tileset/PNG/Exterior.png"

const TILE_SIZE := Vector2i(16, 16)
const EXTERIOR_FIRST_GID := 1
const EXTERIOR_COLUMNS := 15
const EXTERIOR_ROWS := 50
const CHURCH_FIRST_GID := 751
const CHURCH_COLUMNS := 16
const CHURCH_ROWS := 19

# The exterior atlas's first 114 cells contain the house/fence artwork.
const HOUSE_AND_FENCE_GID_MIN := 1
const HOUSE_AND_FENCE_GID_MAX := 114

# The church's placed atlas cells are in this GID interval.
const CHURCH_GID_MIN := 752
const CHURCH_GID_MAX := 902

# These are small decorative ground tiles near the bottom of the exterior atlas.
# They are intentionally non-blocking, as requested.
const DECORATIVE_GID_MIN := 645
const DECORATIVE_GID_MAX := 750


func _ready() -> void:
	# Build the TileSet, visuals, and collision after entering the scene tree.
	_load_tiled_map()


func _load_tiled_map() -> void:
	# Parse map dimensions and CSV layers directly from the tracked Tiled file.
	var parser := XMLParser.new()
	var open_error := parser.open(MAP_PATH)
	if open_error != OK:
		push_error("Havenreach TiledMapLoader could not open: %s" % MAP_PATH)
		return

	var map_width := 0
	var map_height := 0
	var tile_width := TILE_SIZE.x
	var tile_height := TILE_SIZE.y
	var layers: Array[Dictionary] = []
	var current_layer: Dictionary = {}
	var inside_layer := false
	var inside_data := false

	while parser.read() == OK:
		var node_type := parser.get_node_type()
		# XMLParser only exposes element names for element nodes, not whitespace/text nodes.
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

	# XMLParser has no close() method; reaching EOF ends this read loop.

	if map_width <= 0 or map_height <= 0 or tile_width != TILE_SIZE.x or tile_height != TILE_SIZE.y:
		push_error("Havenreach TiledMapLoader found unsupported or invalid map dimensions.")
		return
	if layers.is_empty():
		push_error("Havenreach TiledMapLoader found no tile layers in the TMX file.")
		return

	# Both atlases share one TileSet so every layer can reference either source.
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE

	var exterior_source := _create_atlas_source(EXTERIOR_TEXTURE_PATH, EXTERIOR_COLUMNS, EXTERIOR_ROWS)
	if exterior_source == null:
		return
	tile_set.add_source(exterior_source, 0)

	var church_source := _create_atlas_source(CHURCH_TEXTURE_PATH, CHURCH_COLUMNS, CHURCH_ROWS)
	if church_source == null:
		return
	tile_set.add_source(church_source, 1)

	# Center the 800x560 pixel map around the town's world origin.
	var map_origin := Vector2(
		-float(map_width * tile_width) / 2.0,
		-float(map_height * tile_height) / 2.0
	)

	# One static body holds the generated collision shapes to avoid creating a
	# separate physics body for every tile.
	var collision_body := StaticBody2D.new()
	collision_body.name = "GeneratedObjectCollision"
	collision_body.position = map_origin
	collision_body.collision_layer = 1
	collision_body.collision_mask = 1
	add_child(collision_body)
	var collision_count := 0

	for layer_index in range(layers.size()):
		var layer_data: Dictionary = layers[layer_index]
		var layer_name := str(layer_data["name"])
		var layer_width: int = int(layer_data["width"])
		var layer_height: int = int(layer_data["height"])
		var raw_cells: PackedStringArray = str(layer_data["csv"]).strip_edges().split(",", false)
		var expected_cells := layer_width * layer_height

		if raw_cells.size() != expected_cells:
			push_error(
				"Havenreach TiledMapLoader layer '%s' has %d cells; expected %d."
				% [layer_name, raw_cells.size(), expected_cells]
			)
			continue

		var tile_layer := TileMapLayer.new()
		tile_layer.name = layer_name.replace(" ", "")
		tile_layer.tile_set = tile_set
		tile_layer.position = map_origin
		# Keep static map layers behind actors so walkable roads and grass do not
		# render over the Player sprite. Add dedicated foreground layers later if needed.
		tile_layer.z_index = -100 + layer_index
		add_child(tile_layer)

		for cell_index in range(raw_cells.size()):
			var gid := raw_cells[cell_index].to_int()
			if gid == 0:
				continue

			var cell_coords := Vector2i(
				cell_index % layer_width,
				floori(float(cell_index) / float(layer_width))
			)

			var source_id: int
			var atlas_coords: Vector2i
			if gid >= CHURCH_FIRST_GID:
				# Tiled GIDs are one-based and include the first GID offset.
				var church_local_id := gid - CHURCH_FIRST_GID
				if church_local_id < 0 or church_local_id >= CHURCH_COLUMNS * CHURCH_ROWS:
					push_warning("Havenreach map contains an unsupported church tileset GID: %d" % gid)
					continue
				source_id = 1
				atlas_coords = Vector2i(
					church_local_id % CHURCH_COLUMNS,
					floori(float(church_local_id) / float(CHURCH_COLUMNS))
				)
			else:
				var exterior_local_id := gid - EXTERIOR_FIRST_GID
				if exterior_local_id < 0 or exterior_local_id >= EXTERIOR_COLUMNS * EXTERIOR_ROWS:
					push_warning("Havenreach map contains an unsupported exterior tileset GID: %d" % gid)
					continue
				source_id = 0
				atlas_coords = Vector2i(
					exterior_local_id % EXTERIOR_COLUMNS,
					floori(float(exterior_local_id) / float(EXTERIOR_COLUMNS))
				)

			tile_layer.set_cell(cell_coords, source_id, atlas_coords)

			# Build collision only where the tile image has visible, non-transparent
			# pixels. This avoids invisible rectangular blockers in transparent margins.
			var collision_rects := _get_collision_rects(layer_name, gid, source_id, atlas_coords, exterior_source.texture if source_id == 0 else church_source.texture, cell_coords)
			for rect in collision_rects:
				var collision_shape := CollisionShape2D.new()
				collision_shape.name = "ObjectPixel_%d_%d_%d" % [cell_coords.x, cell_coords.y, collision_count]
				var rectangle := RectangleShape2D.new()
				rectangle.size = Vector2(rect.size)
				collision_shape.shape = rectangle
				collision_shape.position = Vector2(
					float(cell_coords.x) * TILE_SIZE.x,
					float(cell_coords.y) * TILE_SIZE.y
				) + Vector2(rect.position) + Vector2(rect.size) / 2.0
				collision_body.add_child(collision_shape)
				collision_count += 1

	if collision_count == 0:
		push_warning("Havenreach TiledMapLoader generated no object collision shapes.")
	else:
		print("Havenreach TiledMapLoader generated %d object collision shapes." % collision_count)


func _get_collision_rects(
	layer_name: String,
	gid: int,
	source_id: int,
	atlas_coords: Vector2i,
	texture: Texture2D,
	cell_coords: Vector2i
) -> Array[Rect2i]:
	# Return no collision for decorative ground plants and known open door cells.
	if layer_name == "Ground":
		return []
	if layer_name == "Rocks, Flowers" and gid >= DECORATIVE_GID_MIN and gid <= DECORATIVE_GID_MAX:
		return []
	if gid >= CHURCH_GID_MIN and gid <= CHURCH_GID_MAX:
		if cell_coords.x >= 30 and cell_coords.x <= 32 and cell_coords.y >= 12 and cell_coords.y <= 14:
			return []
	if layer_name == "Buildings, Roads" and gid >= HOUSE_AND_FENCE_GID_MIN and gid <= HOUSE_AND_FENCE_GID_MAX:
		var doorway_gids: Array[int] = [52, 53, 67, 68, 82, 83, 97, 98]
		if doorway_gids.has(gid):
			return []

	# Scan the exact 16x16 atlas tile's alpha channel. Collision rectangles are
	# created from contiguous visible pixel runs, not the tile's transparent area.
	# The atlas is tiny, so this work is inexpensive for a town map.
	var image := texture.get_image()
	if image == null or image.is_empty():
		return []
	var origin := atlas_coords * TILE_SIZE
	var active_runs: Dictionary = {}
	var completed: Array[Rect2i] = []
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
				active_runs[key].size.y += 1
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


func _create_atlas_source(
	texture_path: String,
	columns: int,
	rows: int
) -> TileSetAtlasSource:
	# Define each 16x16 atlas cell so TMX global tile IDs can map to Godot cells.
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("Havenreach TiledMapLoader could not load tileset image: %s" % texture_path)
		return null

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE

	for y in range(rows):
		for x in range(columns):
			atlas.create_tile(Vector2i(x, y))

	return atlas
