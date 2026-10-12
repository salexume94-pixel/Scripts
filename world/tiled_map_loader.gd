extends Node2D
## Loads the Havenreach Tiled CSV map into native Godot TileMapLayer nodes.
##
## Godot does not load Tiled .tmx files natively. This focused loader reads the
## current finite, orthogonal TMX map at runtime and converts its CSV tile layers
## into Godot atlas cells. Tiled remains the editable source of truth for layout.
##
## The loader intentionally supports the two external tilesets currently used by
## Havenreach. If the map gains more tilesets, flip flags, or non-CSV layer data,
## extend this conversion rather than silently drawing incorrect tiles.

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


func _ready() -> void:
	# Build the TileSet and each visual layer only after the scene enters the tree.
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
		var node_name := parser.get_node_name()

		if node_type == XMLParser.NODE_ELEMENT:
			if node_name == "map":
				map_width = parser.get_attribute_value("width").to_int()
				map_height = parser.get_attribute_value("height").to_int()
				tile_width = parser.get_attribute_value("tilewidth").to_int()
				tile_height = parser.get_attribute_value("tileheight").to_int()
			elif node_name == "layer":
				inside_layer = true
				current_layer = {
					"name": parser.get_attribute_value("name"),
					"width": parser.get_attribute_value("width").to_int(),
					"height": parser.get_attribute_value("height").to_int(),
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

	parser.close()

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

	for layer_index in range(layers.size()):
		var layer_data: Dictionary = layers[layer_index]
		var layer_width: int = int(layer_data["width"])
		var layer_height: int = int(layer_data["height"])
		var raw_cells: PackedStringArray = str(layer_data["csv"]).strip_edges().split(",", false)
		var expected_cells := layer_width * layer_height

		if raw_cells.size() != expected_cells:
			push_error(
				"Havenreach TiledMapLoader layer '%s' has %d cells; expected %d."
				% [str(layer_data["name"]), raw_cells.size(), expected_cells]
			)
			continue

		var tile_layer := TileMapLayer.new()
		tile_layer.name = str(layer_data["name"]).replace(" ", "")
		tile_layer.tile_set = tile_set
		tile_layer.position = map_origin
		tile_layer.z_index = layer_index
		add_child(tile_layer)

		for cell_index in range(raw_cells.size()):
			var gid := raw_cells[cell_index].to_int()
			if gid == 0:
				continue

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

			var cell_coords := Vector2i(cell_index % layer_width, floori(float(cell_index) / float(layer_width)))
			tile_layer.set_cell(cell_coords, source_id, atlas_coords)


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
