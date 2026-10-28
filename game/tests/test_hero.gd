extends "res://tests/test_case.gd"

const HERO_SCENE := preload("res://actors/hero/hero.tscn")
const DT := 1.0 / 60.0


## Atrapa walki o API z docs/PLAN.md (T10): wystarcza do sprawdzenia strony bohatera.
class FakeCombat:
	extends Combat
	var guard_calls: Array[bool] = []
	var locked := false
	var speed_factor := 1.0
	var attacks: Array = []

	func _init() -> void:
		attack_range = 90.0

	func is_movement_locked() -> bool:
		return locked

	func move_speed_factor() -> float:
		return speed_factor

	func request_attack(
		direction: Vector2, target: Node2D = null, _profile: AttackProfile = null
	) -> void:
		attacks.append([direction, target])

	func request_dodge(_direction: Vector2) -> void:
		pass

	func set_guard(up: bool, _direction: Vector2 = Vector2.ZERO) -> void:
		guard_calls.append(up)


var _root: Window
var _hero: Hero
var _combat: FakeCombat
var _extras: Array[Node] = []


func setup(root: Window) -> void:
	_root = root
	_hero = _spawn_hero(false)


func teardown() -> void:
	_hero.free()
	for node in _extras:
		node.free()


func _spawn_hero(with_combat: bool) -> Hero:
	var hero: Hero = HERO_SCENE.instantiate()
	if with_combat:
		hero.get_node("Combat").free()
		_combat = FakeCombat.new()
		_combat.name = "Combat"
		hero.add_child(_combat)
		hero.get_node("Healing").combat = _combat
	_root.add_child(hero)
	hero.global_position = Vector2.ZERO
	return hero


func _run(hero: Hero, steps: int, sprint := false) -> void:
	for i in steps:
		hero.step(DT, sprint)


func test_sprint_uses_stamina_walk_does_not() -> void:
	_hero.move_to(Vector2(5000, 0))
	_run(_hero, 30)
	check_eq(_hero.stamina.value, _hero.stamina.max_value, "chód nie kosztuje")
	_run(_hero, 30, true)
	var spent := _hero.stamina.max_value - _hero.stamina.value
	check(
		is_equal_approx(spent, _hero.sprint_cost_per_second * 0.5), "sprint przez 0,5 s: %s" % spent
	)
	check(_hero.sprinting, "bohater sprintuje")


func test_sprint_is_faster() -> void:
	_hero.move_to(Vector2(5000, 0))
	_run(_hero, 60)
	var walked := _hero.global_position.x
	_hero.global_position = Vector2.ZERO
	_run(_hero, 60, true)
	check(_hero.global_position.x > walked * 1.5, "sprint szybszy od chodu")


func test_exhaustion_blocks_sprint() -> void:
	_hero.move_to(Vector2(5000, 0))
	_hero.stamina.consume(1000.0)
	check(_hero.stamina.is_exhausted(), "wyczerpany")
	_run(_hero, 60, true)
	check(not _hero.sprinting, "sprint niedostępny")
	check(is_equal_approx(_hero.global_position.x, _hero.walk_speed), "idzie zwykłym krokiem")
	check_eq(_hero.stamina.value, 0.0, "nic nie zużywa")


func test_sprint_runs_out_of_stamina() -> void:
	_hero.move_to(Vector2(50000, 0))
	_run(_hero, int(_hero.stamina.max_value / _hero.sprint_cost_per_second / DT) + 5, true)
	check(_hero.stamina.is_exhausted(), "sprint wyczerpał wytrzymałość")
	_run(_hero, 2, true)
	check(not _hero.sprinting, "po wyczerpaniu sprint wyłączony mimo Shift")


func test_vertical_speed_is_halved() -> void:
	_hero.move_to(Vector2(0, 5000))
	_run(_hero, 1)
	check(
		is_equal_approx(_hero.velocity.y, _hero.walk_speed * AssetSprite.ISO_Y),
		"pion o połowę wolniejszy"
	)
	check(is_equal_approx(_hero.velocity.x, 0.0), "bez ruchu w poziomie")


func test_direction_selects_animation() -> void:
	var cases := {
		&"s": Vector2(0, 1),
		&"sw": Vector2(-1, 0.5),
		&"w": Vector2(-1, 0),
		&"nw": Vector2(-1, -0.5),
		&"n": Vector2(0, -1),
		&"ne": Vector2(1, -0.5),
		&"e": Vector2(1, 0),
		&"se": Vector2(1, 0.5),
	}
	for dir: StringName in cases:
		_hero.global_position = Vector2.ZERO
		_hero.move_to(cases[dir] * 4000.0)
		_run(_hero, 2)
		check_eq(_hero.sprite.direction, dir, "kierunek animacji")
		check_eq(_hero.sprite.animation, &"walk", "ruch gra walk (%s)" % dir)


func test_move_to_ends_at_point() -> void:
	var target := Vector2(173, -61)
	_hero.move_to(target)
	_run(_hero, 600)
	check(not _hero.is_moving(), "polecenie zakończone")
	check(
		_hero.global_position.distance_to(target) < 1.0,
		"bohater stoi w punkcie: %s" % _hero.global_position
	)
	check_eq(_hero.sprite.animation, &"idle", "po dojściu idle")
	check_eq(_hero.velocity, Vector2.ZERO, "bez prędkości")


func _add_wall(position: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = size
	wall.add_child(shape)
	_root.add_child(wall)
	_extras.append(wall)
	wall.global_position = position


func test_blocked_move_is_abandoned() -> void:
	_add_wall(Vector2(200, 0), Vector2(40, 2000))
	await _root.get_tree().physics_frame
	_hero.move_to(Vector2(600, 0))
	_run(_hero, 300)
	check(not _hero.is_moving(), "zablokowane polecenie porzucone")
	check(_hero.global_position.x < 200.0, "bohater nie przeniknął przez ścianę")


func test_combat_lock_and_speed_factor() -> void:
	_hero.free()
	_hero = _spawn_hero(true)
	_hero.move_to(Vector2(5000, 0))
	_combat.speed_factor = 0.5
	_run(_hero, 60)
	check(
		is_equal_approx(_hero.global_position.x, _hero.walk_speed * 0.5),
		"mnożnik prędkości z walki"
	)
	_combat.locked = true
	var before := _hero.global_position
	_run(_hero, 30)
	check_eq(_hero.global_position, before, "blokada ruchu z walki")
	check(_hero.is_moving(), "polecenie ruchu przetrwało blokadę")


func test_attack_target_approaches_then_requests_once() -> void:
	_hero.free()
	_hero = _spawn_hero(true)
	var enemy := Node2D.new()
	_root.add_child(enemy)
	_extras.append(enemy)
	enemy.global_position = Vector2(400, 0)
	_hero.attack_target(enemy)
	_run(_hero, 30)
	check(_combat.attacks.is_empty(), "poza zasięgiem jeszcze bez ataku")
	_run(_hero, 120)
	check_eq(_combat.attacks.size(), 1, "jedno żądanie ataku")
	check_eq(_combat.attacks[0][1], enemy, "cel ataku")
	var distance := Steering.to_world(enemy.global_position - _hero.global_position).length()
	check(distance <= _combat.attack_range, "bohater stoi w zasięgu")
	check(not _hero.is_moving(), "po żądaniu bohater stoi")


func test_dash_moves_and_stops_at_obstacle() -> void:
	_hero.free()
	_hero = _spawn_hero(true)
	_combat.dash_requested.emit(Vector2(100, 0), 0.2)
	_run(_hero, 30)
	check(is_equal_approx(_hero.global_position.x, 100.0), "odskok o zadany wektor")
	_add_wall(Vector2(200, 0), Vector2(20, 400))
	await _root.get_tree().physics_frame
	_combat.dash_requested.emit(Vector2(400, 0), 0.2)
	_run(_hero, 30)
	check(
		_hero.global_position.x < 190.0,
		"odskok zatrzymany przez ścianę: %s" % _hero.global_position
	)


func test_guard_is_reasserted_while_key_held() -> void:
	preload("res://autoload/controls.gd").apply_defaults()
	_hero.free()
	_hero = _spawn_hero(true)
	Input.action_press(&"guard")
	for i in 3:
		_hero._physics_process(DT)
	check_eq(_combat.guard_calls, [true, true, true], "garda ponawiana co klatkę przy wciśniętym Q")
	_combat.guard_calls.clear()
	Input.action_release(&"guard")
	for i in 3:
		_hero._physics_process(DT)
	check_eq(_combat.guard_calls, [false], "puszczenie Q opuszcza gardę raz")
