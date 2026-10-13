extends Node2D
## Loads a Tiled CSV map into native Godot TileMapLayer nodes. Map and atlas settings are configurable.
##
## Tiled remains the source of truth for visual layout. This loader also builds
## simple static collision from the placed object tiles because the current TMX
## has no authored collision/object layer.
##
## Collision policy:
## - In exterior mode, house/fence tiles and church tiles block movement.
## - Large rocks, trees, and bushes placed on "Rocks, Flowers" block movement.
## - Grass and small decorative ground plants are ignored.
## - In exterior mode, church and visible house doorway tiles remain open.
## - Roads and ground tiles are not treated as obstacles.

@export_file("*.tmx") var map_path: String = "res://world/maps/havensreach/house_1_interior.tmx"
const EXTERIOR_TEXTURE_PATH := "res://assets/maps_tileset/town_map/towns_tileset/PNG/exterior.png"
@export_file("*.png") var secondary_texture_path: String = "res://assets/maps_tileset/town_map/towns_tileset/PNG/Interior.png"

const TILE_SIZE := Vector2i(16, 16)
const EXTERIOR_FIRST_GID := 1
const EXTERIOR_COLUMNS := 15
const EXTERIOR_ROWS := 50
@export var secondary_first_gid: int = 751
@export var secondary_columns: int = 12
@export var secondary_rows: int = 25

# The exterior atlas's first 114 cells contain the house/fence artwork.
const HOUSE_AND_FENCE_GID_MIN := 1
const HOUSE_AND_FENCE_GID_MAX := 114

# The church's placed atlas cells are in this GID interval.
@export var interior_mode: bool = true

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
	var open_error := parser.open(map_path)
	if open_error != OK:
		push_error("Havenreach TiledMapLoader could not open: %s" % map_path)
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

	var church_source := _create_atlas_source(secondary_texture_path, secondary_columns, secondary_rows)
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
	# Keep roof tiles in front of the Player; tree canopy layering is deferred.
	var foreground_layer := TileMapLayer.new()
	foreground_layer.name = "BuildingForeground"
	foreground_layer.tile_set = tile_set
	foreground_layer.position = map_origin
	foreground_layer.z_as_relative = false
	foreground_layer.z_index = 100
	add_child(foreground_layer)
	# Read each atlas image once instead of copying it for every occupied map cell.
	var exterior_image := exterior_source.texture.get_image()
	var secondary_image := church_source.texture.get_image()

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
			if gid >= secondary_first_gid:
				# Tiled GIDs are one-based and include the first GID offset.
				var secondary_local_id := gid - secondary_first_gid
				if secondary_local_id < 0 or secondary_local_id >= secondary_columns * secondary_rows:
					push_warning("Havenreach map contains an unsupported church tileset GID: %d" % gid)
					continue
				source_id = 1
				atlas_coords = Vector2i(
					secondary_local_id % secondary_columns,
					floori(float(secondary_local_id) / float(secondary_columns))
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

			# Preserve house/church roof occlusion, but do not attempt tree-canopy layering yet.
			if _should_draw_building_foreground(layer_name, gid):
				foreground_layer.set_cell(cell_coords, source_id, atlas_coords)

			# Build collision only where the tile image has visible, non-transparent
			# pixels. This avoids invisible rectangular blockers in transparent margins.
			var atlas_image: Image = exterior_image if source_id == 0 else secondary_image
			var collision_rects := _get_collision_rects(layer_name, gid, atlas_coords, atlas_image, cell_coords)
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
	atlas_coords: Vector2i,
	image: Image,
	cell_coords: Vector2i
) -> Array[Rect2i]:
	# Interior floors and rugs are walkable. Furnishings block only where their
	# atlas pixels are opaque, so transparent margins cannot trap the Player.
	if interior_mode:
		if layer_name == "Ground/Floor" or layer_name == "Rugs":
			return []
		if layer_name != "Furniture" and layer_name != "Close Items" and layer_name != "Items on the very top":
			return []
	else:
		# Ground and small decorative plants never block movement.
		if layer_name == "Ground":
			return []
		if layer_name == "Rocks, Flowers":
			if gid >= DECORATIVE_GID_MIN and gid <= DECORATIVE_GID_MAX:
				return []
		elif layer_name == "Buildings, Roads":
			var is_house_or_fence := gid >= HOUSE_AND_FENCE_GID_MIN and gid <= HOUSE_AND_FENCE_GID_MAX
			var is_church := gid >= secondary_first_gid and gid < secondary_first_gid + secondary_columns * secondary_rows
			if not is_house_or_fence and not is_church:
				return []
			if is_house_or_fence:
				var doorway_gids: Array[int] = [52, 53, 67, 68, 82, 83, 97, 98]
				if doorway_gids.has(gid):
					return []
			if is_church and cell_coords.x >= 30 and cell_coords.x <= 32 and cell_coords.y >= 12 and cell_coords.y <= 14:
				return []
		else:
			return []

	# Scan the exact 16x16 atlas tile's alpha channel. Collision rectangles are
	# merged from contiguous visible pixel runs, reducing invisible blockers.
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


func _should_draw_building_foreground(layer_name: String, gid: int) -> bool:
	# Close and top item layers render over the Player inside interiors.
	if interior_mode:
		return layer_name == "Close Items" or layer_name == "Items on the very top"
	# Keep house/fence roof tiles in front, excluding known doorway cells.
	if layer_name != "Buildings, Roads":
		return false
	if gid >= HOUSE_AND_FENCE_GID_MIN and gid <= HOUSE_AND_FENCE_GID_MAX:
		var doorway_gids: Array[int] = [52, 53, 67, 68, 82, 83, 97, 98]
		return not doorway_gids.has(gid)
	# Only the upper church roof rows are drawn over actors.
	return gid >= 752 and gid <= 790
