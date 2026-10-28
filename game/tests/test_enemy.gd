extends "res://tests/test_case.gd"

const HERO_SCENE := preload("res://actors/hero/hero.tscn")
const DOG_SCENE := preload("res://actors/enemies/zdziczaly-pies/pies.tscn")
const DRWAL_SCENE := preload("res://actors/enemies/drwal/drwal.tscn")

var _root: Window
var _spawned: Array[Node] = []


func setup(root: Window) -> void:
	_root = root


func teardown() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.free()


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var node: Node2D = scene.instantiate()
	_root.add_child(node)
	node.global_position = at
	_spawned.append(node)
	return node


func _frames(seconds: float) -> void:
	await _root.get_tree().create_timer(seconds).timeout


# --- decyzje AI bez fizyki ---------------------------------------------------------------------


func test_dog_attack_choice_by_distance() -> void:
	check_eq(Dog.choose_attack(60.0, 90.0, 120.0, 210.0), Dog.BITE, "z bliska kłapnięcie")
	check_eq(Dog.choose_attack(160.0, 90.0, 120.0, 210.0), Dog.LEAP, "z dystansu skok")
	check_eq(Dog.choose_attack(105.0, 90.0, 120.0, 210.0), &"", "pomiędzy: nic")
	check_eq(Dog.choose_attack(400.0, 90.0, 120.0, 210.0), &"", "za daleko: nic")


func test_dog_waits_while_target_swings_or_dodges() -> void:
	check(Dog.target_exposed(Combat.State.IDLE), "bezczynny cel jest odsłonięty")
	check(Dog.target_exposed(Combat.State.GUARD), "garda nie chroni przed nieparowalnym")
	check(not Dog.target_exposed(Combat.State.ATTACK), "cel w zamachu: pies czeka")
	check(not Dog.target_exposed(Combat.State.DODGE), "cel w uniku: pies czeka")


func test_dog_circles_on_available_side() -> void:
	check_eq(Dog.pick_side(Dog.CLOCKWISE, false, false), Dog.CLOCKWISE, "zostaje przy stronie")
	check_eq(Dog.pick_side(Dog.CLOCKWISE, true, false), Dog.COUNTERCLOCKWISE, "zmienia stronę")
	check_eq(
		Dog.pick_side(Dog.COUNTERCLOCKWISE, true, true), Dog.COUNTERCLOCKWISE, "obie zablokowane"
	)


func test_drwal_cleaves_only_after_persistent_guard() -> void:
	check_eq(Drwal.choose_attack(100.0, 120.0, false), Drwal.SLASH, "zwykłe cięcie w zasięgu")
	check_eq(Drwal.choose_attack(100.0, 120.0, true), Drwal.CLEAVE, "rozłupanie przy gardzie")
	check_eq(Drwal.choose_attack(200.0, 120.0, false), &"", "poza zasięgiem nic")
	check(not Drwal.is_persistent_guard(1, 0.0, 2, 4.0), "jeden blok to jeszcze nie upór")
	check(Drwal.is_persistent_guard(2, 0.0, 2, 4.0), "dwa bloki z rzędu")
	check(Drwal.is_persistent_guard(0, 4.5, 2, 4.0), "długa garda")


func test_drwal_first_block_does_not_trigger_cleave() -> void:
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	check(not drwal.persistent_guard(), "na początku brak uporu")
	drwal._on_attack_result(Hit.Result.BLOCKED)
	check(not drwal.persistent_guard(), "pierwszy blok")
	drwal._on_attack_result(Hit.Result.BLOCKED)
	check(drwal.persistent_guard(), "drugi blok z rzędu")
	drwal._on_attack_result(Hit.Result.PARRIED)
	check(not drwal.persistent_guard(), "parada zeruje serię")


func test_drwal_counts_guard_time_every_frame() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(100, 0))
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	drwal._acquire_target()
	hero.get_node("Combat").set_guard(true, Vector2.LEFT)
	drwal._observe_target(2.0)
	check(not drwal.persistent_guard(), "krótka garda to jeszcze nie upór")
	drwal._observe_target(drwal.guard_seconds_limit)
	check(drwal.persistent_guard(), "długa garda gracza")


func test_drwal_telegraphs_before_attacking() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(100, 0))
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	var warned: Array = []
	drwal.telegraphed.connect(
		func(kind: StringName, parryable: bool) -> void: warned.append([kind, parryable])
	)
	drwal.mode = Enemy.Mode.ENGAGE
	hero.global_position = Vector2(100, 0)
	drwal._acquire_target()
	drwal.step(1.0 / 60.0)
	check_eq(drwal.mode, Enemy.Mode.WARN, "najpierw zapowiedź")
	check_eq(warned, [[Drwal.SLASH, true]], "pierwszy atak to parowalne cięcie")
	check_eq(drwal.combat.state, Combat.State.IDLE, "w zapowiedzi walka jeszcze nie atakuje")


func test_active_enemy_limit() -> void:
	var a: Enemy = _spawn(DOG_SCENE, Vector2(0, 0))
	var b: Enemy = _spawn(DOG_SCENE, Vector2(10, 0))
	var c: Enemy = _spawn(DRWAL_SCENE, Vector2(20, 0))
	a._set_mode(Enemy.Mode.ENGAGE)
	b._set_mode(Enemy.Mode.ENGAGE)
	check(not c._can_activate(), "trzeci nie wchodzi do walki")
	check(a._can_activate(), "aktywny pozostaje aktywny")
	b._set_mode(Enemy.Mode.WATCH)
	check(c._can_activate(), "po wyjściu jednego trzeci może wejść")


# --- walka przez obszary trafień ---------------------------------------------------------------


func test_hero_hits_enemy_through_hitbox_and_hurtbox() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2.ZERO)
	var dog: Dog = _spawn(DOG_SCENE, Vector2(60, 0))
	dog.ai_enabled = false
	hero.get_node("Combat").request_attack(Vector2.RIGHT, null)
	await _frames(1.0)
	check(dog.combat.health < dog.combat.max_health, "cios bohatera zranił psa")


func test_hit_window_shorter_than_physics_step_still_lands() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2.ZERO)
	var dog: Dog = _spawn(DOG_SCENE, Vector2(60, 0))
	dog.ai_enabled = false
	var combat: Combat = hero.get_node("Combat")
	combat.request_attack(Vector2.RIGHT, null)
	await _root.get_tree().physics_frame
	await _root.get_tree().physics_frame
	# hit_start i hit_end w tej samej klatce, bez kroku fizyki pomiędzy
	combat.on_anim_event(&"hit_start")
	combat.on_anim_event(&"hit_end")
	check(dog.combat.health < dog.combat.max_health, "krótkie okno trafienia zraniło psa")


func test_enemy_hitbox_does_not_hit_other_enemies() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(-2000, 0))
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	var dog: Dog = _spawn(DOG_SCENE, Vector2(70, 0))
	drwal.ai_enabled = false
	dog.ai_enabled = false
	drwal.combat.request_attack(Vector2.RIGHT, hero, drwal.slash)
	await _frames(1.0)
	check_eq(dog.combat.health, dog.combat.max_health, "przeciwnik nie rani przeciwnika")
	check(drwal.combat.state != Combat.State.ATTACK, "cios się wykonał")


func test_dog_leap_misses_target_off_the_track() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(120, 200))
	var dog: Dog = _spawn(DOG_SCENE, Vector2.ZERO)
	dog.ai_enabled = false
	dog.combat.request_attack(Vector2.RIGHT, hero, dog.leap)
	await _frames(0.45)
	var hero_combat: Combat = hero.get_node("Combat")
	check_eq(hero_combat.health, hero_combat.max_health, "cel poza torem nie dostaje obrażeń")
	check_eq(dog.combat.state, Combat.State.RECOVER, "chybiony skok: pies odzyskuje równowagę")
	check(dog.global_position.x > 100.0, "pies przeskoczył po torze")


func test_dog_leap_hits_target_on_the_track() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(120, 0))
	var dog: Dog = _spawn(DOG_SCENE, Vector2.ZERO)
	dog.ai_enabled = false
	dog.combat.request_attack(Vector2.RIGHT, hero, dog.leap)
	await _frames(0.6)
	var hero_combat: Combat = hero.get_node("Combat")
	check(hero_combat.health < hero_combat.max_health, "skok po torze trafia")


# --- granica pościgu ---------------------------------------------------------------------------


func test_beyond_leash_enemy_returns_and_is_invulnerable() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(900, 0))
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	drwal.home = Vector2(-1000, 0)
	drwal.mode = Enemy.Mode.ENGAGE
	check(drwal.home_distance() > drwal.leash_radius, "poza granicą pościgu")
	drwal.step(1.0 / 60.0)
	check_eq(drwal.mode, Enemy.Mode.RETURN, "wraca na miejsce")
	await _frames(0.1)
	hero.global_position = drwal.global_position + Vector2(-50, 0)
	hero.get_node("Combat").request_attack(Vector2.LEFT, null)
	await _frames(0.8)
	check_eq(
		drwal.combat.health, drwal.combat.max_health, "w drodze powrotnej nie przyjmuje obrażeń"
	)


func test_returning_enemy_reaches_home_and_watches() -> void:
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2(300, 0))
	drwal.home = Vector2.ZERO
	drwal._set_mode(Enemy.Mode.RETURN)
	for i in 600:
		drwal.step(1.0 / 60.0)
	check_eq(drwal.mode, Enemy.Mode.WATCH, "po powrocie pilnuje miejsca")
	check(drwal.vulnerable, "znów przyjmuje obrażenia")
	check(drwal.home_distance() <= drwal.arrive_distance + 1.0, "stoi na miejscu")
