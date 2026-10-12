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
	# Dedicated foreground layers let the Player pass behind selected roof/canopy
	# tiles without moving walkable ground or every map tile above the Player.
	var foreground_layer := TileMapLayer.new()
	foreground_layer.name = "ForegroundOcclusion"
	foreground_layer.tile_set = tile_set
	foreground_layer.position = map_origin
	# Use an absolute, high Z index so this child layer reliably draws over the
	# Player even though the map is nested under WorldContent and the Player is
	# a sibling of WorldContent in Havenreach.tscn.
	foreground_layer.z_as_relative = false
	foreground_layer.z_index = 100
	add_child(foreground_layer)

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

			# Duplicate only designated roof/canopy cells into the foreground layer.
			# The original cell stays behind the Player; this copy draws over the
			# Player when they walk behind the corresponding part of the object.
			if _should_draw_foreground(layer_name, gid):
				foreground_layer.set_cell(cell_coords, source_id, atlas_coords)

			# Use object-specific footprints instead of treating every occupied
			# tile as a full 16x16 obstacle. Canopy tiles deliberately return no shape.
			var footprint := _get_collision_footprint(layer_name, gid, cell_coords)
			if footprint.size != Vector2.ZERO:
				var collision_shape := CollisionShape2D.new()
				collision_shape.name = "ObjectCell_%d_%d" % [cell_coords.x, cell_coords.y]
				var rectangle := RectangleShape2D.new()
				rectangle.size = footprint.size
				collision_shape.shape = rectangle
				# footprint.position is local to the tile's top-left corner.
				collision_shape.position = Vector2(
					float(cell_coords.x) * TILE_SIZE.x,
					float(cell_coords.y) * TILE_SIZE.y
				) + footprint.position + footprint.size / 2.0
				collision_body.add_child(collision_shape)
				collision_count += 1

	if collision_count == 0:
		push_warning("Havenreach TiledMapLoader generated no object collision shapes.")
	else:
		print("Havenreach TiledMapLoader generated %d object collision shapes." % collision_count)


func _get_collision_footprint(layer_name: String, gid: int, cell_coords: Vector2i) -> Rect2:
	# Tree leaves/canopies must never block movement. These GIDs describe the
	# four canopy rows of the large tree placed at the northwest of Havenreach.
	if layer_name == "Rocks, Flowers" and _is_tree_canopy_gid(gid):
		return Rect2()

	# Church facade cells block movement, except the approach gap at the entrance.
	# Use full tile footprints here because these cells represent solid walls.
	if gid >= CHURCH_GID_MIN and gid <= CHURCH_GID_MAX:
		if cell_coords.x >= 30 and cell_coords.x <= 32 and cell_coords.y >= 12 and cell_coords.y <= 14:
			return Rect2()
		return Rect2(Vector2.ZERO, Vector2(TILE_SIZE))

	# House/fence cells on the building layer retain full tile collision, while
	# the known doorway cells stay open.
	if layer_name == "Buildings, Roads" and gid >= HOUSE_AND_FENCE_GID_MIN and gid <= HOUSE_AND_FENCE_GID_MAX:
		var doorway_gids: Array[int] = [52, 53, 67, 68, 82, 83, 97, 98]
		if doorway_gids.has(gid):
			return Rect2()
		return Rect2(Vector2.ZERO, Vector2(TILE_SIZE))

	# Rocks, trunks, and dense bushes use a compact footprint near the bottom
	# of their tile. This lets the Player pass their transparent/upper artwork.
	# Small decorative ground tiles (grass/flowers) remain completely walkable.
	if layer_name == "Rocks, Flowers":
		if gid >= DECORATIVE_GID_MIN and gid <= DECORATIVE_GID_MAX:
			return Rect2()
		if _is_tree_trunk_gid(gid):
			return Rect2(Vector2(3, 8), Vector2(10, 8))
		return Rect2(Vector2(2, 8), Vector2(12, 8))

	return Rect2()


func _is_tree_canopy_gid(gid: int) -> bool:
	# Keep these atlas ranges explicit: the current Havenreach tree is assembled
	# from four rows of 16x16 cells. Canopy artwork has no physical collision.
	return (
		(gid >= 446 and gid <= 449)
		or (gid >= 460 and gid <= 464)
		or (gid >= 475 and gid <= 480)
		or (gid >= 490 and gid <= 494)
	)


func _is_tree_trunk_gid(gid: int) -> bool:
	# The fifth row directly beneath that canopy contains the trunk/base tiles.
	return gid >= 506 and gid <= 509


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



func _should_draw_foreground(layer_name: String, gid: int) -> bool:
	# The house atlas is arranged in 15 columns. GIDs 1-40 are the first three
	# rows of the atlas, but the house roofs also use later rows. Include all
	# placed house/fence atlas cells so roof edges are not omitted from occlusion.
	# Doorway cells are excluded to keep the entrance visually open.
	if layer_name == "Buildings, Roads":
		if gid >= HOUSE_AND_FENCE_GID_MIN and gid <= HOUSE_AND_FENCE_GID_MAX:
			var doorway_gids: Array[int] = [52, 53, 67, 68, 82, 83, 97, 98]
			return not doorway_gids.has(gid)

		# The church's upper roof tiles are in the first three placed rows of its
		# atlas. Keep those rows in front, but leave its lower facade behind actors.
		if gid >= 752 and gid <= 790:
			return true

	# The four-row tree canopy is assembled from these atlas GIDs. Duplicate all
	# canopy tiles, not trunks or small decorative plants, into the foreground.
	if layer_name == "Rocks, Flowers":
		if (gid >= 446 and gid <= 449) or (gid >= 460 and gid <= 464):
			return true
		if (gid >= 475 and gid <= 480) or (gid >= 490 and gid <= 494):
			return true

	return false
