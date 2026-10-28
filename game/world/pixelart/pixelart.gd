extends Node2D
## Osobna próba kierunku pixel art; używa pełnej logiki walki z prototypu.

const HERO_SCENE := preload("res://actors/hero/hero.tscn")
const DOG_SCENE := preload("res://actors/enemies/zdziczaly-pies/pies.tscn")
const TREE_POSITIONS: Array[Vector2] = [
	Vector2(-900, 430),
	Vector2(-850, -150),
	Vector2(-1080, 50),
	Vector2(900, 440),
	Vector2(1000, 40),
	Vector2(850, -180),
]

var hero: Hero
var dog: Dog
var _hero_health: ProgressBar
var _stamina: ProgressBar
var _dog_health: ProgressBar
var _status: Label
var _elapsed := 0.0
var _demo := false
var _hero_hits := 0
var _dog_hits := 0
var _trees: Array[Prop] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("10191d"))
	_build_world()
	_build_hud()
	_demo = "--demo" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture(arg.trim_prefix("--capture="))
	if _demo:
		_run_demo()


func _build_world() -> void:
	var ground := Sprite2D.new()
	ground.texture = load("res://assets/pixelart/clearing.png")
	ground.z_index = -10
	add_child(ground)
	for point in TREE_POSITIONS:
		var tree := _add_prop("PROP-drzewo-lisciaste-pixel", point)
		_trees.append(tree)
	_add_prop("PROP-woz-pixel", Vector2(640, -270))
	_add_prop("PROP-kamien-pixel", Vector2(-640, 230))
	_add_prop("PROP-kamien-pixel", Vector2(640, 300))
	var navigation := NavigationRegion2D.new()
	var polygon := NavigationPolygon.new()
	polygon.add_outline(
		PackedVector2Array(
			[Vector2(-730, -480), Vector2(730, -480), Vector2(730, 480), Vector2(-730, 480)]
		)
	)
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.parsed_collision_mask = 1
	polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	polygon.source_geometry_group_name = &"nav_obstacles"
	polygon.agent_radius = 22.0
	navigation.navigation_polygon = polygon
	add_child(navigation)
	navigation.bake_navigation_polygon(false)
	hero = HERO_SCENE.instantiate() as Hero
	hero.get_node("Sprite").asset_id = "HERO-bohater-pixel"
	hero.position = Vector2(-100, 100)
	add_child(hero)
	_add_shadow(hero, 32.0)
	dog = DOG_SCENE.instantiate() as Dog
	dog.get_node("Sprite").asset_id = "ENM-zdziczaly-pies-pixel"
	dog.position = Vector2(130, 25)
	add_child(dog)
	_add_shadow(dog, 24.0)
	var camera: Camera2D = hero.get_node("Camera2D")
	camera.offset = Vector2(0, -100)
	camera.position_smoothing_enabled = true
	camera.limit_left = -1280
	camera.limit_right = 1280
	camera.limit_top = -768
	camera.limit_bottom = 768
	camera.reset_smoothing()
	hero.get_node("Combat").hit_landed.connect(_on_hero_hit)
	dog.get_node("Combat").hit_landed.connect(_on_dog_hit)
	hero.died.connect(func() -> void: _status.text = "Zginąłeś.  [R] Spróbuj ponownie")
	dog.get_node("Combat").died.connect(
		func() -> void: _status.text = "Pies pokonany.  [R] Nowe starcie"
	)


func _add_prop(id: String, point: Vector2) -> Prop:
	var prop := Prop.new()
	prop.asset_id = id
	prop.position = point
	add_child(prop)
	return prop


func _add_shadow(actor: Node2D, radius: float) -> void:
	var shadow := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 12:
		var angle := TAU * float(i) / 12.0
		points.append(
			Vector2(
				roundf(cos(angle) * radius / 2.0) * 2.0, roundf(sin(angle) * radius / 6.0) * 2.0
			)
		)
	shadow.polygon = points
	shadow.color = Color(0.03, 0.05, 0.06, 0.45)
	shadow.z_index = -1
	actor.add_child(shadow)


func _panel_style(background: String, border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.set_border_width_all(2)
	style.content_margin_left = 18
	style.content_margin_top = 12
	style.content_margin_right = 18
	style.content_margin_bottom = 12
	return style


func _text(parent: Node, words: String, size: int, color := Color("bbc0a4")) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _meter(parent: Node, tint: String, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, 10)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _panel_style("10191d", "352a24"))
	bar.add_theme_stylebox_override("fill", _panel_style(tint, tint))
	parent.add_child(bar)
	return bar


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(margin)
	var title_panel := PanelContainer.new()
	title_panel.position = Vector2(24, 18)
	title_panel.add_theme_stylebox_override("panel", _panel_style("18242af0", "49382a"))
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(title_panel)
	var top := VBoxContainer.new()
	title_panel.add_child(top)
	_text(top, "W E L E S Z A", 26, Color("cfad75"))
	_text(top, "Trakt pod Niemirem", 16)
	_text(top, "PRÓBA KIERUNKU  /  PIXEL ART", 12, Color("87968b"))
	var target := VBoxContainer.new()
	target.position = Vector2(830, 32)
	hud.add_child(target)
	var target_name := _text(target, "ZDZICZAŁY PIES", 14, Color("cfad75"))
	target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dog_health = _meter(target, "895d43", 260)
	var bottom := PanelContainer.new()
	bottom.position = Vector2(32, 952)
	bottom.size = Vector2(1856, 100)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_stylebox_override("panel", _panel_style("18242af0", "604833"))
	hud.add_child(bottom)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	bottom.add_child(row)
	var stats := VBoxContainer.new()
	row.add_child(stats)
	_text(stats, "PODRÓŻNIK", 13, Color("cfad75"))
	_hero_health = _meter(stats, "895d43", 240)
	_stamina = _meter(stats, "52603b", 240)
	var controls := VBoxContainer.new()
	row.add_child(controls)
	_text(controls, "LPM  ruch / cios w psa     Ctrl + LPM  cios w miejscu", 15)
	_text(controls, "Spacja  unik     Q  garda     Shift  sprint     1 / 2  leczenie", 14)
	_status = _text(
		controls,
		"Uważaj na skok. Zejdź z toru, potem kontratakuj.     [R] Restart",
		13,
		Color("cfad75")
	)


func _process(delta: float) -> void:
	_elapsed += delta
	var combat: Combat = hero.get_node("Combat")
	_hero_health.value = combat.health / combat.max_health * 100.0
	_stamina.value = hero.stamina.value / hero.stamina.max_value * 100.0
	if is_instance_valid(dog):
		_dog_health.value = dog.combat.health / dog.combat.max_health * 100.0
	else:
		_dog_health.value = 0
	for tree in _trees:
		var crown := tree.layer(&"crown")
		var behind := (
			hero.position.y < tree.position.y and absf(hero.position.x - tree.position.x) < 180
		)
		crown.modulate.a = move_toward(crown.modulate.a, 0.35 if behind else 1.0, delta * 3)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _on_hero_hit(_target: Combat, result: Hit.Result, _damage: float, _crit: bool) -> void:
	if result == Hit.Result.HIT:
		_hero_hits += 1


func _on_dog_hit(_target: Combat, result: Hit.Result, _damage: float, _crit: bool) -> void:
	if result == Hit.Result.HIT:
		_dog_hits += 1


func _run_demo() -> void:
	# Scenariusz korzysta z poleceń gracza; nie zadaje obrażeń bezpośrednio.
	# Najpierw pozwól psu dokończyć atak. Inaczej bohater może przerwać każdy jego cios.
	while _elapsed < 12.0 and _dog_hits == 0 and not hero.dead:
		await get_tree().physics_frame
	while _elapsed < 22.0 and is_instance_valid(dog) and not hero.dead:
		hero.attack_target(dog)
		await get_tree().create_timer(0.55).timeout
	print("PIXEL_DEMO hero_hits=%d dog_hits=%d" % [_hero_hits, _dog_hits])
	get_tree().quit(0 if _hero_hits > 0 and _dog_hits > 0 else 1)


func _capture(path: String) -> void:
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("PIXEL_CAPTURE %s: %s" % [path, error_string(error)])
	if not _demo:
		get_tree().quit(error)
