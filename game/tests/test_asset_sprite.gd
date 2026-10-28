extends "res://tests/test_case.gd"

var _root: Window
var _sprite: AssetSprite


func setup(root: Window) -> void:
	_root = root
	_sprite = AssetSprite.new()
	_root.add_child(_sprite)


func teardown() -> void:
	_sprite.free()


func test_direction_from_screen_vector() -> void:
	check_eq(AssetSprite.direction_from_vector(Vector2(0, 1)), &"s", "w dół ekranu")
	check_eq(AssetSprite.direction_from_vector(Vector2(-1, 0)), &"w", "w lewo")
	check_eq(AssetSprite.direction_from_vector(Vector2(0, -1)), &"n", "w górę")
	check_eq(AssetSprite.direction_from_vector(Vector2(1, 0)), &"e", "w prawo")
	# przekątna izometryczna 2:1 na ekranie to przekątna świata
	check_eq(AssetSprite.direction_from_vector(Vector2(1, 0.5)), &"se", "izometryczny SE")
	check_eq(AssetSprite.direction_from_vector(Vector2(-1, -0.5)), &"nw", "izometryczny NW")


func test_event_table() -> void:
	var table := (
		AssetSprite
		. build_event_table(
			{
				"attack":
				{"events": [{"frame": 2, "name": "hit_end"}, {"frame": 2, "name": "combo_open"}]},
			}
		)
	)
	check_eq(table[&"attack"][2], [&"hit_end", &"combo_open"], "dwa zdarzenia na jednej klatce")


func test_built_test_asset_loads_and_emits_events() -> void:
	check_eq(_sprite.load_asset("TEST-manekin"), OK, "wczytanie TEST-manekin")
	var frames := _sprite.lead_layer().sprite_frames
	check_eq(frames.get_frame_count(&"attack_ne"), 3, "odbity kierunek ma klatki")
	var got: Array[StringName] = []
	_sprite.anim_event.connect(func(e: StringName) -> void: got.append(e))
	_sprite.play_anim(&"attack", &"e")
	_sprite.lead_layer().frame = 1
	check(&"hit_start" in got, "hit_start na klatce 1, otrzymano %s" % [got])
	check_eq(_sprite.lead_layer().offset, Vector2(0, -96), "kotwica w punkcie węzła")


func test_skipped_frames_still_emit_their_events_in_order() -> void:
	_sprite.load_asset("TEST-manekin")
	var got: Array[StringName] = []
	_sprite.anim_event.connect(func(e: StringName) -> void: got.append(e))
	_sprite.play_anim(&"attack", &"e")
	_sprite.lead_layer().frame = 2  # długa klatka: z 0 od razu na 2
	check(got.find(&"hit_start") != -1, "hit_start z pominiętej klatki 1, otrzymano %s" % [got])
	check(got.find(&"hit_start") < got.find(&"hit_end"), "kolejność: hit_start przed hit_end")
	_sprite.lead_layer().frame = 2
	check_eq(got.count(&"hit_start"), 1, "zdarzenie nie powtarza się na tej samej klatce")
