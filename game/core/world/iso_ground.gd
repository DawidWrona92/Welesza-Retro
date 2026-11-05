class_name IsoGround
extends TileMapLayer
## Podłoże z kafli z kontraktu assetu (TILE-…, rzut 2:1). Zestaw kafli powstaje z meta.json
## w czasie gry: każdy wariant to osobne źródło atlasu. Wypełnienie testowe: tło z pierwszego
## assetu, pas traktu z drugiego wzdłuż osi x mapy; warianty losowane z ustalonym ziarnem.

@export var tile_assets: PackedStringArray = ["TILE-sciolka", "TILE-bloto"]
## Połowa boku wypełnianego kwadratu mapy (w kaflach).
@export var half_size := 14
## Połowa szerokości pasa traktu (w kaflach).
@export var path_half_width := 1
@export var fill_seed := 7

## {asset_id: [id źródła wariantu, ...]}
var sources: Dictionary = {}


func _ready() -> void:
	build_tile_set()
	fill()


func build_tile_set() -> void:
	var tiles := TileSet.new()
	tiles.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tiles.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	sources.clear()
	for id in tile_assets:
		var meta: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://assets/%s/meta.json" % id)
		)
		var size := Vector2i(int(meta["cell"][0]), int(meta["cell"][1]))
		tiles.tile_size = size
		var ids: Array[int] = []
		for variant in int(meta["variants"]):
			var atlas := TileSetAtlasSource.new()
			atlas.texture = load("res://assets/%s/%02d.png" % [id, variant + 1])
			atlas.texture_region_size = size
			atlas.create_tile(Vector2i.ZERO)
			ids.append(tiles.add_source(atlas))
		sources[id] = ids
	tile_set = tiles


func fill() -> void:
	clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = fill_seed
	for x in range(-half_size, half_size + 1):
		for y in range(-half_size, half_size + 1):
			var on_path := tile_assets.size() > 1 and absi(y) <= path_half_width
			var ids: Array = sources[tile_assets[1 if on_path else 0]]
			set_cell(Vector2i(x, y), ids[rng.randi() % ids.size()], Vector2i.ZERO)
