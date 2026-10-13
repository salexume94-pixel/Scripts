extends Node2D
## Loads a small forest/field Tiled map using the project's shared 16x16 exterior atlas.
## This loader intentionally handles the CSV tile layers used by Waking Area and Mira's clearing.
## Collision is not inferred from artwork; map collision will be authored separately if needed.

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

	# Center the 320x320 map so scene actors and the boundary use world coordinates around (0, 0).
	var map_origin := Vector2(
		-float(map_width * tile_width) / 2.0,
		-float(map_height * tile_height) / 2.0
	)

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

	print("ForestTiledMapLoader loaded %s (%dx%d, %d layers)." % [map_path, map_width, map_height, layers.size()])
