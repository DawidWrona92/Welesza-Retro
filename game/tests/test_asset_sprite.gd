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


func test_walk_turn_preserves_phase_and_speed_tracks_world_distance() -> void:
	_sprite.load_asset("TEST-manekin")
	_sprite.walk_cycle_distance = 100.0
	var events: Array[StringName] = []
	_sprite.anim_event.connect(func(event: StringName) -> void: events.append(event))
	_sprite.play_anim(&"walk", &"s")
	var lead := _sprite.lead_layer()
	lead.set_frame_and_progress(1, 0.4)
	var steps_before := events.count(&"step")
	_sprite.play_anim(&"walk", &"w")
	check_eq(events.count(&"step"), steps_before, "skręt nie powtarza dźwięku/zdarzenia kroku")
	check_eq(lead.frame, 1, "skręt nie resetuje nogi do klatki 0")
	check(absf(lead.frame_progress - 0.4) < 0.001, "skręt zachowuje postęp klatki")
	var spec: Dictionary = _sprite.meta["animations"]["walk"]
	var normal := 100.0 * float(spec["fps"]) / float(spec["frames"])
	_sprite.match_walk_speed(Vector2(normal, 0))
	check(absf(lead.speed_scale - 1.0) < 0.001, "nominalne tempo")
	_sprite.match_walk_speed(Vector2(0, normal))
	check(absf(lead.speed_scale - 2.0) < 0.001, "pion uwzględnia izometrię 2:1")
	_sprite.play_anim(&"attack", &"w")
	check_eq(lead.speed_scale, 1.0, "cios nie dziedziczy tempa sprintu")
