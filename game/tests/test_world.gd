extends "res://tests/test_case.gd"
## Elementy świata ze sceny testowej grafiki (T09): rekwizyty, podłoże z kafli, zastępstwo
## brakującej animacji. Wymagają assetów zbudowanych przez tools/sprite_pipeline.py.

const SCENE := preload("res://world/test-grafiki/test_grafiki.tscn")

var _root: Window
var _nodes: Array[Node] = []


func setup(root: Window) -> void:
	_root = root


func teardown() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _add(node: Node) -> Node:
	_root.add_child(node)
	_nodes.append(node)
	return node


func test_prop_loads_layers_at_anchor_and_flattened_collision() -> void:
	var prop := Prop.new()
	prop.asset_id = "PROP-drzewo-lisciaste"
	_add(prop)
	check(prop.layer(&"trunk") != null and prop.layer(&"crown") != null, "pień i korona")
	var anchor := Vector2(prop.meta["anchor"][0], prop.meta["anchor"][1])
	check_eq(prop.layer(&"trunk").offset, -anchor, "kotwica w początku węzła")
	var shape: CollisionShape2D = prop.find_children("*", "CollisionShape2D", false, false)[0]
	check_eq(shape.scale, Vector2(1.0, AssetSprite.ISO_Y), "kolizja spłaszczona do rzutu 2:1")
	check_eq(
		(shape.shape as CircleShape2D).radius, float(prop.meta["collision"]["circle"]), "promień"
	)
	check(prop.is_in_group(Block.NAV_GROUP), "dziura w siatce nawigacji")


func test_single_layer_prop_uses_full_image() -> void:
	var prop := Prop.new()
	prop.asset_id = "PROP-woz"
	_add(prop)
	check(prop.layer(&"full") != null, "wóz ma jedną warstwę")


func test_ground_builds_a_source_per_variant_and_fills_path() -> void:
	var ground := IsoGround.new()
	ground.half_size = 3
	_add(ground)
	check_eq(ground.tile_set.tile_shape, TileSet.TILE_SHAPE_ISOMETRIC, "rzut izometryczny")
	check_eq(ground.tile_set.tile_size, Vector2i(256, 128), "kafel 2:1 w rozdzielczości gry")
	check_eq(ground.get_used_cells().size(), 49, "wypełniony kwadrat 7×7")
	var path_ids: Array = ground.sources["TILE-bloto"]
	check(ground.get_cell_source_id(Vector2i(2, 0)) in path_ids, "trakt na osi x mapy")
	check(not ground.get_cell_source_id(Vector2i(0, 3)) in path_ids, "poza traktem ściółka")


func test_missing_idle_stands_on_first_walk_frame() -> void:
	var sprite := AssetSprite.new()
	_add(sprite)
	sprite.load_asset("ENM-zdziczaly-pies")
	sprite.play_anim(&"idle", &"s")
	var lead := sprite.lead_layer()
	check_eq(sprite.animation, &"idle", "właściciel nadal widzi bezczynność")
	check_eq(lead.animation, &"walk_s", "pokazuje chód")
	check(not lead.is_playing() and lead.frame == 0, "nieruchomo, w klatce 0")
	sprite.play_anim(&"walk", &"s")
	check(lead.is_playing(), "chód rusza po bezczynności")


func test_scene_uses_real_assets() -> void:
	var scene: Node2D = _add(SCENE.instantiate())
	var hero_sprite: AssetSprite = scene.get_node("Hero/Sprite")
	var dog_sprite: AssetSprite = scene.get_node("Pies/Sprite")
	check_eq(hero_sprite.asset_id, "HERO-bohater", "bohater z grafiki M1")
	check_eq(dog_sprite.asset_id, "ENM-zdziczaly-pies", "pies z grafiki M1")
	check_eq((scene.get_node("Woz") as Prop).meta["id"], "PROP-woz", "rekwizyt wczytany")
