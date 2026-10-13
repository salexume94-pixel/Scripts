extends Node2D
## Loads the Tiled overworld CSV map into native Godot TileMapLayer nodes.
##
## Tiled remains the source of truth for visual layout. This loader also builds
## simple static collision from the placed object tiles because the current TMX
## has no authored collision/object layer.
##
## This first integration pass displays the tracked 256x256 overworld TMX over the legacy placeholder polygons.
## Collision remains owned by the existing world boundaries and location-entry areas; terrain collision authoring is a separate pass.

const MAP_PATH := "res://world/maps/overworld/Overworld.tmx"
const EXTERIOR_TEXTURE_PATH := "res://assets/maps_tileset/town_map/towns_tileset/PNG/exterior.png"
const HAVENREACH_MARKER_TEXTURE_PATH := "res://world/maps/havensreach/havensreach_marker.png"
const MIRA_MARKER_TEXTURE_PATH := "res://world/maps/miras encounter/mira_encounter_marker.png"
const WAKING_MARKER_TEXTURE_PATH := "res://world/maps/waking/waking_area_marker.png"

# Embedded fallbacks keep the marker art available if a local checkout has not
# refreshed its new PNG files yet. The tracked PNGs remain the editable source.
const HAVENREACH_MARKER_PNG_BASE64 := "iVBORw0KGgoAAAANSUhEUgAAADYAAAAmCAMAAAC4TZh0AAAAAXNSR0IArs4c
6QAAAARnQU1BAACxjwv8YQUAAAFoUExURXqtVTp7QB1ELWiWPYerPnQcJSdf
PmOmPXOTTHC4NyBHLE2EOygoLooqKp45MV8aKJ4+N0+RQlaMTZRuXmx6hj8U
KDprQiFFLDAVEoJQP20ZJNTStHaJllZaZWxANuLVucGrk0dAPEgqKpRhSqt3
V2oyPXuFw2RueWKERkUjMv/94joeLUZHUsSOXkZRaDQ7T5pAQGYvOcG/ulAo
NlssOWNgn09SXatKQII5QUI0MmGDRmB+R/FnTceolpp7cWqeT4qx2zk6QjxH
XrGDXG9ibGSi6PP15fHUiefcxPbryZ+YmU9qthU8MUOUYA43NkBBVdfc0+C9
hTGy7byXbzaMRydzRSZnVKhFUos5RDJ9WzVxN2k3P1uSUpbFX5e6OuBztbrT
Ym1COrtPPFMYLlkZLUCiPaFKPpdZPkq3NKZHRSNmQpi/V8djUGiWUR1SP4e3
WEEiHjw9RhpTR1EUHoc2M5qEea+ah3+lOQu5Z3MAAAAJcEhZcwAAEnMAABJz
AYwiuQcAAAAZdEVYdFNvZnR3YXJlAFBhaW50Lk5FVCA1LjEuMTITAUd0AAAA
uGVYSWZJSSoACAAAAAUAGgEFAAEAAABKAAAAGwEFAAEAAABSAAAAKAEDAAEA
AAACAAAAMQECABEAAABaAAAAaYcEAAEAAABsAAAAAAAAALXUAQDoAwAAtdQB
AOgDAABQYWludC5ORVQgNS4xLjEyAAADAACQBwAEAAAAMDIzMAGgAwABAAAA
AQAAAAWgBAABAAAAlgAAAAAAAAACAAEAAgAEAAAAUjk4AAIABwAEAAAAMDEw
MAAAAABdh+yyXWbnNgAAA2tJREFUSEuNVQl3GzUQHjtRemwkN2Zbqm3Xa9aJ
N23TUm+wIWklAqGJmuZYoCk0PQDH9AJaIFD+Pm9G0mbtkPf4/J6k0eqbQ5oZ
A0CtDv8DU9M0MS/XZmbOVL87nIVztYp4PpgOAGa5aKB0AWCuPue/Nz+oHIT6
TEUIgmAKIOS8QTyAuTM1tHYR15fsVpPGup0cPrwMwJiQUSOKIty4cgXgaixK
r08H562kHUWMaIiQsYblfYRD2plPccL1wjGNyXbSbTNWWsi4YA3OuBMXFxcX
He3a9Rtww223lhDxTW9NCJGkvKTdAvgY5xRuX+vly5/03LHZftwfZJ1B7GQu
EilTwYWTHVL4tNfLlxc+c/IKYXVlBQDuoLUOoXWC1uvld/PSGkEpjdPnOKxl
/azb+cJZ/9KdSGH9q/zeRr55TAIwxvjlaoKYT+5XvwOkva0Heb5xb2sZYNtv
qmOalTVa39mFvb29PaDxdvF1/k3+bbEAD/dPoxmk7T56VNkqiu/yrfz7IneJ
gwEpNUEjNY8PKltFsV48KTaLvLJnnbJ6gv+wTrS8eFLkxRYKT2ef4VQ5Fjyf
AtBKVSnj+AHg6Y+0MoasIQ6mAozNGGMUjpXz4xIE/t0QB1hMClkGx6rVcQmm
q1fS/Mk6bYxSaFDjVEpV2smb9FDaaKPRV6U0Oa000fFnP01SajWKxppR6DEt
tMHAnQd6LNohVhF2IzPmBZKRRVdlFKJyl/HV6NBVH2ULAPWoxwBanxIMIh4O
oxGjPmTfM+SHI4BdVIO07Z9tLr/AC2xik3uJfUsMZYTwL8Vj0TgckRqU91+9
fgO/lE3NL8RQttsjxrG5WBoTjcahVaMUPHzzK5WAtJzfHPdiK5mfTyLqSZbG
k6Q1sjIm3dv9t9iUO6jn3e+eBlkWZtkfYUbvpgA4qmkRjWJ9+Q4vIOqMyh5J
WItl1pUSaWQtHAwGYRxilyizknHWikZcjDM96Fg/7GZ9KUN3k3/u4MtymaRM
DCf6N77nyeQF5QuKyX7STcVwor9R9mnMBzg6IgJGeaxGWqTeybr9Y/SpWuac
ffgytiWZdeKBHCw5lvt/04YKxiZfmYW2/poAf/39HpEm753WcVDSowpt09+M
JaUvt3/wAcvd88/RNWfJ9wgvoBo9WbaEZrXfWXiKoiqkxG7+Cy84vFqMV8UP
AAAAAElFTkSuQmCC
"
const MIRA_MARKER_PNG_BASE64 := "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAAXNSR0IArs4c
6QAAAARnQU1BAACxjwv8YQUAAACfUExURXqtVVaMTWqeT4e3WB1ELTp7QE+R
QmiWUZ4+N7DHXk6CSSdfPlFsP2OmPXC4NyBLMUdAPDgxLiE+LWRdUHlyX41I
K7dyOWB+R1OJTY6IczprQlFKQNTStO3szBc1JLCtklOITUI8OHOTTCFFLKt/
Npi/V30yMD9WNeBztU56GsXVYP/CMdy3UEsoI8OgfpdZPls0Lm1COlw0NHWV
Uk5oPc3Mb9wAAAAJcEhZcwAAEnMAABJzAYwiuQcAAAAZdEVYdFNvZnR3YXJl
AFBhaW50Lk5FVCA1LjEuMTITAUd0AAAAuGVYSWZJSSoACAAAAAUAGgEFAAEA
AABKAAAAGwEFAAEAAABSAAAAKAEDAAEAAAACAAAAMQECABEAAABaAAAAaYcE
AAEAAABsAAAAAAAAALXUAQDoAwAAtdQBAOgDAABQYWludC5ORVQgNS4xLjEy
AAADAACQBwAEAAAAMDIzMAGgAwABAAAAAQAAAAWgBAABAAAAlgAAAAAAAAAC
AAEAAgAEAAAAUjk4AAIABwAEAAAAMDEwMAAAAABdh+yyXWbnNgAABTZJREFU
WEfNl21320QQhVfS3CnkMrJkOa3iKLWTUCAUWgr8/9/GuSvJlhza8PIB7smJ
5dnZ1cxo5H02pb+ioqyKS9taBgc8X75K6auvJ7NsSCmV1dXCGXSDzKO+ySaE
gwtrdgRqJ83TcroF6yAYS2fAI/zZAvSoQS6tVWWAw8HYnB1hDUG2HjxFLXNL
mW26F4ACBbhtZW08bF7APRytbR3KDYrPU/IIoLUGyKGBQQdMvuyabWAuWqK7
K9ocGzhH7QjAa8CdzuTKx0m6A7kIME4R0Mk2Ah0MlqPuwpOCMdQG11KGNi+P
gNPqsJ3bHEEyhJkxDzu2ZtlXD6VtLRAMog6gY5vzMdPiztMCqqK7dS2iVnw5
FafBHNhEDafrEm7uQaejabaIOYNEtZG1agR3oq7b1nUv/ZH614TC98hFdje0
rmBTur5W68EjW1UY7BqlrhrrYcCxIbcKEB0hhc/+lq5fK/7Y1DV9E6QKqNI1
etKmoVo3NtThWsusNZ79U0pvVEJFqc5Cae5bB/U8nWXVjylFbaZ2CK3ucfaf
CujekNy28N6ontkpT1hVpJ5qsEDjMT4+hXH2T7kVc5HNrFadkvXkTW6FqyIV
+S2DsTMaSbuhqc8W/rmPXYUxGZlSv78dhru3Objr5N4ioCcS3B9uu+GY23bh
nxKJrgnfWY1Akfqhub8b+nH+A9WEHVRC9o9398OxX/mPXUDDTv82ZJFSL+WB
hzdqEUIpUzcb7Uv/XETs9LOhQp06a6G+uR0Oj4uRZ/4kIpSpO1P69uw5qh8O
w6E5Hk+Gtf9oIXaqu74/nKdO6o9935/nX/iPLr3dDsa3px+YF/TMv98Pd4dm
P1buS9KLs/S/Kt+Nlv2x3B8/N//hu/nqWo0vzf5F+cJm8bL+9QKzvn9e/FeX
hv9EP1waLnQ5/vW8pc56Wn5Z5jRdr8b/ROWl4UIvjf8dfbHky8EfF9f/Y02v
zKwzL/xFvVm15YIX/pkWvPCytNldOC55Iesiv6UsI0yslljzgizfL0YvpO1C
v7YreFvxwmJgpffjR4YE0GptcNPQzAsG8cJyUtZP40dOC7pVw9Y2wTBHXuK7
NPHCyAPr2ePGc5KHi2m2efNX6Sd3ba5LHvishC+MEXfdYbnqlnnhkgfsWSgS
RQIZqrSPb7fa/LUNC8XWPCBiER1dKpupqpt1QhqAtUqIFQ8gWNfE5oy5p/kK
Oz93r2uSLZUVyFphnXjAhLuLfCYV1XheaAB2VqOTU0ty0+pNmHnARbIm/mov
krg6nRdIAalR9I9u2+oZBMQD4ubsYt0up7h6v07nBXaodR+RCUXaJrbMHapF
M3fqGw0rZjifFxCYAF9f0cA9IlpzgYrmBWrfQdSWUno3/rAuzgsbKAVJEJLh
VZHtsktnrQA2LOOgIriqNH95XiBs1x0aRbhzR9tZsO/tlJKPtN5i1dnn84Ke
xDAM+2PGYuuUiosH5LJ1R6clxJurl/N0XnCG23153x8FMs5drnrmAYaeoBYc
i71+MU7nhYzYo/qezS33syfQuo4JBp03ePaTMterOWJ66cUNfXlzGHZVn6p3
Re5U9ZFuDru7n0hytYI6TPHqbJjZpy8fq0qOVaEVQMG2ot8P9+P8nz98OC3x
ls3NxKNjAE9P6XjMeCjoziHJ5S2ZZuZ7/Pjhl4/Tdb8/dIehnBA56ykVaQlR
fdV0h8PjMvZPv34aG6kq+n1ZVVV/fH+dHl4/pFfjhlqWGv8tpacypWNfPe4f
x+Sn8UK5zTqOQ7+Pp5hJ8/h4n+OaWCf9AZFRVo01UwfDAAAAAElFTkSuQmCC
"
const WAKING_MARKER_PNG_BASE64 := "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
"

const TILE_SIZE := Vector2i(16, 16)
const EXTERIOR_FIRST_GID := 1
const EXTERIOR_COLUMNS := 15
const EXTERIOR_ROWS := 50
# These first-GID ranges must match the tileset declarations already in Overworld.tmx.
# Do not add duplicate markers here; these atlas sources only render the existing TMX cells.
const HAVENREACH_MARKER_FIRST_GID := 751
const HAVENREACH_MARKER_COLUMNS := 3
const HAVENREACH_MARKER_ROWS := 2
const MIRA_MARKER_FIRST_GID := 757
const MIRA_MARKER_COLUMNS := 4
const MIRA_MARKER_ROWS := 4
const WAKING_MARKER_FIRST_GID := 773
const WAKING_MARKER_COLUMNS := 4
const WAKING_MARKER_ROWS := 4

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
		push_error("Overworld TiledMapLoader could not open: %s" % MAP_PATH)
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

	var havenreach_marker_source := _create_atlas_source(
		HAVENREACH_MARKER_TEXTURE_PATH, HAVENREACH_MARKER_COLUMNS, HAVENREACH_MARKER_ROWS,
		HAVENREACH_MARKER_PNG_BASE64
	)
	if havenreach_marker_source == null:
		return
	tile_set.add_source(havenreach_marker_source, 1)

	var mira_marker_source := _create_atlas_source(
		MIRA_MARKER_TEXTURE_PATH, MIRA_MARKER_COLUMNS, MIRA_MARKER_ROWS,
		MIRA_MARKER_PNG_BASE64
	)
	if mira_marker_source == null:
		return
	tile_set.add_source(mira_marker_source, 2)

	var waking_marker_source := _create_atlas_source(
		WAKING_MARKER_TEXTURE_PATH, WAKING_MARKER_COLUMNS, WAKING_MARKER_ROWS,
		WAKING_MARKER_PNG_BASE64
	)
	if waking_marker_source == null:
		return
	tile_set.add_source(waking_marker_source, 3)

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
	var havenreach_marker_image := havenreach_marker_source.texture.get_image()
	var mira_marker_image := mira_marker_source.texture.get_image()
	var waking_marker_image := waking_marker_source.texture.get_image()

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
		tile_layer.z_index = layer_index
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
			# Tiled global IDs identify three marker sheets after the exterior tileset.
			# Route each range to its own texture instead of mistakenly drawing markers
			# from an unrelated atlas.
			if gid >= WAKING_MARKER_FIRST_GID:
				var local_id := gid - WAKING_MARKER_FIRST_GID
				if local_id >= WAKING_MARKER_COLUMNS * WAKING_MARKER_ROWS:
					push_warning("Overworld map contains an unsupported waking marker GID: %d" % gid)
					continue
				source_id = 3
				atlas_coords = Vector2i(local_id % WAKING_MARKER_COLUMNS, floori(float(local_id) / WAKING_MARKER_COLUMNS))
			elif gid >= MIRA_MARKER_FIRST_GID:
				var local_id := gid - MIRA_MARKER_FIRST_GID
				if local_id >= MIRA_MARKER_COLUMNS * MIRA_MARKER_ROWS:
					push_warning("Overworld map contains an unsupported Mira marker GID: %d" % gid)
					continue
				source_id = 2
				atlas_coords = Vector2i(local_id % MIRA_MARKER_COLUMNS, floori(float(local_id) / MIRA_MARKER_COLUMNS))
			elif gid >= HAVENREACH_MARKER_FIRST_GID:
				var local_id := gid - HAVENREACH_MARKER_FIRST_GID
				if local_id >= HAVENREACH_MARKER_COLUMNS * HAVENREACH_MARKER_ROWS:
					push_warning("Overworld map contains an unsupported Havenreach marker GID: %d" % gid)
					continue
				source_id = 1
				atlas_coords = Vector2i(local_id % HAVENREACH_MARKER_COLUMNS, floori(float(local_id) / HAVENREACH_MARKER_COLUMNS))
			else:
				var exterior_local_id := gid - EXTERIOR_FIRST_GID
				if exterior_local_id < 0 or exterior_local_id >= EXTERIOR_COLUMNS * EXTERIOR_ROWS:
					push_warning("Overworld map contains an unsupported exterior GID: %d" % gid)
					continue
				source_id = 0
				atlas_coords = Vector2i(exterior_local_id % EXTERIOR_COLUMNS, floori(float(exterior_local_id) / EXTERIOR_COLUMNS))

			tile_layer.set_cell(cell_coords, source_id, atlas_coords)

			# Only building roof tiles belong in the foreground occlusion layer.
			# Markers stay on their normal map layer so their artwork cannot cover the Player.
			if _should_draw_building_foreground(layer_name, gid):
				foreground_layer.set_cell(cell_coords, source_id, atlas_coords)

			# Build collision only where the tile image has visible, non-transparent
			# pixels. This avoids invisible rectangular blockers in transparent margins.
			var atlas_image: Image = exterior_image
			if source_id == 1:
				atlas_image = havenreach_marker_image
			elif source_id == 2:
				atlas_image = mira_marker_image
			elif source_id == 3:
				atlas_image = waking_marker_image
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
		push_warning("Overworld TiledMapLoader generated no object collision shapes.")
	else:
		print("Overworld TiledMapLoader generated %d object collision shapes." % collision_count)


func _get_collision_rects(
	layer_name: String,
	gid: int,
	atlas_coords: Vector2i,
	image: Image,
	cell_coords: Vector2i
) -> Array[Rect2i]:
	# Location markers are decorative transition art, not solid obstacles.
	if _is_marker_gid(gid):
		return []

	# Ground and small decorative plants never block movement.
	if layer_name == "Ground":
		return []
	if layer_name == "Rocks, Flowers":
		if gid >= DECORATIVE_GID_MIN and gid <= DECORATIVE_GID_MAX:
			return []
	elif layer_name == "Buildings, Roads":
		# Roads and unrelated atlas cells are walkable. Only house/fence and
		# church tiles are solid on this layer.
		var is_house_or_fence := gid >= HOUSE_AND_FENCE_GID_MIN and gid <= HOUSE_AND_FENCE_GID_MAX
		var is_church := false
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
	# created from contiguous visible pixel runs, not the tile's transparent area.
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

		# Merge identical horizontal runs on adjacent rows into fewer rectangles.
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
	rows: int,
	embedded_png_base64: String = ""
) -> TileSetAtlasSource:
	# Load the tracked PNG normally. If a checkout has not refreshed the new
	# marker files yet, reconstruct that small texture from its embedded fallback.
	var texture := load(texture_path) as Texture2D
	if texture == null and not embedded_png_base64.is_empty():
		var fallback_image := Image.new()
		var image_error := fallback_image.load_png_from_buffer(Marshalls.base64_to_raw(embedded_png_base64))
		if image_error == OK:
			texture = ImageTexture.create_from_image(fallback_image)
		else:
			push_error("Could not decode embedded marker texture fallback for: %s" % texture_path)
	if texture == null:
		push_error("TiledMapLoader could not load tileset image or fallback: %s" % texture_path)
		return null

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE

	for y in range(rows):
		for x in range(columns):
			atlas.create_tile(Vector2i(x, y))

	return atlas


func _should_draw_building_foreground(layer_name: String, gid: int) -> bool:
	# Keep house/fence roof tiles in front, excluding known doorway cells.
	if layer_name != "Buildings, Roads":
		return false
	if gid >= HOUSE_AND_FENCE_GID_MIN and gid <= HOUSE_AND_FENCE_GID_MAX:
		var doorway_gids: Array[int] = [52, 53, 67, 68, 82, 83, 97, 98]
		return not doorway_gids.has(gid)
	# Only the upper church roof rows are drawn over actors.
	return false



func _is_marker_gid(gid: int) -> bool:
	# Keep the marker ranges synchronized with the GIDs in Overworld.tmx.
	return (
		gid >= HAVENREACH_MARKER_FIRST_GID
		and gid < WAKING_MARKER_FIRST_GID + WAKING_MARKER_COLUMNS * WAKING_MARKER_ROWS
	)
