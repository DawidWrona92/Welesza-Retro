extends "res://tests/test_case.gd"

const HERO_SCENE := preload("res://actors/hero/hero.tscn")
const DOG_SCENE := preload("res://actors/enemies/zdziczaly-pies/pies.tscn")
const DT := 1.0 / 60.0
const TREE := "PROP-drzewo-lisciaste"
const WAGON := "PROP-woz"

var _root: Window
var _spawned: Array[Node] = []


func setup(root: Window) -> void:
	_root = root


func teardown() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.free()


func _prop(asset: String, at := Vector2.ZERO) -> Prop:
	var prop := Prop.new()
	prop.asset_id = asset
	_root.add_child(prop)
	prop.global_position = at
	_spawned.append(prop)
	return prop


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var node: Node2D = scene.instantiate()
	_root.add_child(node)
	node.global_position = at
	_spawned.append(node)
	return node


func _fade(prop: Prop, feet: Array[Vector2], seconds: float) -> void:
	for i in int(seconds / DT):
		prop.step_fade(DT, feet)


func _crown_alpha(prop: Prop) -> float:
	return prop.layer(&"crown").modulate.a


func test_only_the_crown_fades_ground_and_bodies_do_not() -> void:
	check(not Prop.layer_occludes(&"crown"), "korona zanika, nie daje sylwetki")
	check(not Prop.layer_occludes(&"ground"), "ground jest zawsze pod postaciami")
	check(Prop.layer_occludes(&"trunk"), "pień daje sylwetkę")
	check(Prop.layer_occludes(&"full"), "wóz daje sylwetkę")


func test_occlusion_line_comes_from_meta_relative_to_the_anchor() -> void:
	var tree := _prop(TREE, Vector2(100, 500))
	# occlusion_y 690 przy kotwicy 720: linia 30 px nad miejscem styku
	check(tree.is_behind(Vector2(100, 469.0)), "powyżej linii: za rekwizytem")
	check(not tree.is_behind(Vector2(100, 471.0)), "poniżej linii: przed rekwizytem")
	var wagon := _prop(WAGON, Vector2.ZERO)
	check(wagon.is_behind(Vector2(0, -1.0)), "wóz: linia w punkcie styku")
	check(not wagon.is_behind(Vector2(0, 1.0)), "przed wozem")


func test_body_occludes_only_behind_the_line_and_inside_the_outline() -> void:
	var tree := _prop(TREE)
	check(tree.opaque_at(&"trunk", Vector2(0, -100)), "założenie: pień nieprzezroczysty w (0,-100)")
	check(tree.body_occludes(Vector2(0, -100)), "za pniem, w obrysie: sylwetka")
	check(tree.body_occludes(Vector2(0, -35)), "tuż nad linią: za pniem")
	check(not tree.body_occludes(Vector2(0, -25)), "tuż pod linią: nie zasłania")
	check(not tree.body_occludes(Vector2(0, 60)), "przed drzewem: nie zasłania")
	check(not tree.body_occludes(Vector2(400, -100)), "za drzewem, ale poza obrysem: nie zasłania")
	var wagon := _prop(WAGON, Vector2(1000, 0))
	check(wagon.body_occludes(Vector2(1000, -60)), "za wozem: sylwetka")
	check(not wagon.body_occludes(Vector2(1000, 8)), "przed wozem: nie")


func test_crown_fades_when_the_hero_is_behind_it_and_returns() -> void:
	var tree := _prop(TREE)
	var behind: Array[Vector2] = [Vector2(0, -330)]
	check(
		tree.opaque_at(&"crown", Vector2(0, -400)), "założenie: korona nieprzezroczysta w (0,-400)"
	)
	check(tree.crown_covers(Vector2(0, -330)), "korona zasłania postać")
	check_eq(_crown_alpha(tree), 1.0, "na początku pełna")
	_fade(tree, behind, 0.5)
	check(is_equal_approx(_crown_alpha(tree), tree.crown_alpha), "półprzezroczysta za koroną")
	_fade(tree, [], 0.5)
	check(is_equal_approx(_crown_alpha(tree), 1.0), "wraca, gdy postać wyjdzie")


func test_crown_stays_opaque_when_nobody_is_behind_it() -> void:
	var tree := _prop(TREE)
	_fade(tree, [Vector2(400, -330)], 0.5)
	check_eq(_crown_alpha(tree), 1.0, "postać obok drzewa")
	_fade(tree, [Vector2(0, 80)], 0.5)
	check_eq(_crown_alpha(tree), 1.0, "postać przed drzewem")


func test_crown_fade_is_gradual() -> void:
	var tree := _prop(TREE)
	tree.step_fade(DT, [Vector2(0, -330)])
	var after_one := _crown_alpha(tree)
	check(after_one < 1.0 and after_one > tree.crown_alpha, "jedna klatka: dopiero zaczyna")


func test_ground_layer_is_never_faded_or_treated_as_a_cover() -> void:
	var tree := _prop(TREE)
	var image := Image.create(512, 768, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var ground := Sprite2D.new()
	ground.texture = ImageTexture.create_from_image(image)
	ground.name = "ground"
	tree.add_child(ground)
	tree._layers[&"ground"] = ground
	Prop._mask_cache["res://assets/%s/ground.png" % TREE] = image
	var beside := Vector2(-200, -100)
	check(tree.opaque_at(&"ground", beside), "założenie: ground pokrywa to miejsce")
	check(not tree.body_occludes(beside), "ground nie daje sylwetki")
	check(not tree.crown_covers(beside), "ground nie jest koroną")
	_fade(tree, [beside], 0.5)
	check_eq(ground.modulate.a, 1.0, "ground nie zanika")
	check_eq(_crown_alpha(tree), 1.0, "korona nietknięta")
	Prop._mask_cache.erase("res://assets/%s/ground.png" % TREE)


func test_hero_and_enemies_in_combat_are_the_tracked_subjects() -> void:
	var hero := _spawn(HERO_SCENE, Vector2(900, 0))
	var dog: Enemy = _spawn(DOG_SCENE, Vector2(900, 0))
	check(hero.is_in_group(Prop.OCCLUSION_GROUP), "bohater zawsze")
	check(not dog.is_in_group(Prop.OCCLUSION_GROUP), "przeciwnik w spoczynku nie")
	for mode in [Enemy.Mode.ALERT, Enemy.Mode.ENGAGE, Enemy.Mode.WARN, Enemy.Mode.ATTACK]:
		dog._set_mode(mode)
		check(dog.is_in_group(Prop.OCCLUSION_GROUP), "w walce (%s) śledzony" % mode)
	dog._set_mode(Enemy.Mode.RETURN)
	check(not dog.is_in_group(Prop.OCCLUSION_GROUP), "po powrocie nie")


func test_crown_fades_for_an_enemy_in_combat_but_not_for_an_idle_one() -> void:
	var tree := _prop(TREE)
	var dog: Enemy = _spawn(DOG_SCENE, Vector2(0, -330))
	dog.ai_enabled = false
	await _root.get_tree().create_timer(0.4).timeout
	check_eq(_crown_alpha(tree), 1.0, "przeciwnik poza walką nie przezroczy korony")
	dog._set_mode(Enemy.Mode.WARN)
	await _root.get_tree().create_timer(0.5).timeout
	check(_crown_alpha(tree) < 0.5, "zapowiedź ataku za koroną jest widoczna")


func test_hero_behind_the_crown_makes_it_fade_in_the_running_game() -> void:
	var tree := _prop(TREE)
	var hero := _spawn(HERO_SCENE, Vector2(0, -330))
	await _root.get_tree().create_timer(0.5).timeout
	check(_crown_alpha(tree) < 0.5, "bohater za koroną: półprzezroczysta")
	hero.global_position = Vector2(600, 100)
	await _root.get_tree().create_timer(0.5).timeout
	check(_crown_alpha(tree) > 0.95, "po wyjściu pełna")


# --- sylwetka --------------------------------------------------------------------------------


func _silhouette(actor: Node2D) -> Silhouette:
	return actor.get_node("Silhouette")


func test_hero_behind_trunk_gets_a_silhouette_in_front_does_not() -> void:
	_prop(TREE)
	var hero := _spawn(HERO_SCENE, Vector2(0, -100))
	var silhouette := _silhouette(hero)
	silhouette.update_silhouette()
	check(silhouette.visible, "za pniem: widoczna sylwetka")
	hero.global_position = Vector2(0, 60)
	silhouette.update_silhouette()
	check(not silhouette.visible, "przed drzewem: bez sylwetki")
	hero.global_position = Vector2(400, -100)
	silhouette.update_silhouette()
	check(not silhouette.visible, "poza obrysem: bez sylwetki")


func test_hero_behind_the_wagon_gets_a_silhouette() -> void:
	_prop(WAGON, Vector2(1000, 0))
	var hero := _spawn(HERO_SCENE, Vector2(1000, -60))
	var silhouette := _silhouette(hero)
	silhouette.update_silhouette()
	check(silhouette.visible, "za wozem: sylwetka")


func test_silhouette_follows_the_animation_frame_and_draws_above_props() -> void:
	_prop(TREE)
	var hero: Hero = _spawn(HERO_SCENE, Vector2(0, -100)) as Hero
	var silhouette := _silhouette(hero)
	check(silhouette.z_index >= Silhouette.DRAW_Z, "rysowana nad rekwizytami")
	hero.sprite.play_anim(&"walk", &"e")
	silhouette.update_silhouette()
	var source := hero.sprite.lead_layer()
	var clone: AnimatedSprite2D = silhouette.get_child(0)
	check_eq(clone.animation, source.animation, "ta sama animacja")
	source.frame = 1
	silhouette.update_silhouette()
	check_eq(clone.frame, 1, "ta sama klatka")


func test_enemy_silhouette_only_in_combat_and_with_telegraph_tint() -> void:
	_prop(TREE)
	var dog: Enemy = _spawn(DOG_SCENE, Vector2(0, -100))
	dog.ai_enabled = false
	var silhouette := _silhouette(dog)
	silhouette.update_silhouette()
	check(not silhouette.visible, "przeciwnik poza walką bez sylwetki")
	dog._warn_kind = &"bite"
	dog._set_mode(Enemy.Mode.WARN)
	silhouette.update_silhouette()
	check(silhouette.visible, "zapowiedź ataku za pniem jest widoczna")
	var color: Color = silhouette._material.get_shader_parameter(&"silhouette_color")
	var plain := silhouette.base_color
	check(color.b < plain.b, "kolor zapowiedzi (żółty/czerwony) widać w sylwetce")
