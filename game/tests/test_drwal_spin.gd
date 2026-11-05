extends "res://tests/test_case.gd"

const HERO_SCENE := preload("res://actors/hero/hero.tscn")
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


func test_spin_is_chosen_only_when_allowed_and_near() -> void:
	check_eq(Drwal.choose_attack(100.0, 120.0, false, true, 150.0), Drwal.SPIN, "krążący blisko")
	check_eq(
		Drwal.choose_attack(100.0, 120.0, false, false, 150.0), Drwal.SLASH, "bez zgody cięcie"
	)
	check_eq(
		Drwal.choose_attack(140.0, 120.0, false, true, 150.0), Drwal.SPIN, "obrót ma dłuższy zasięg"
	)
	check_eq(Drwal.choose_attack(160.0, 120.0, false, true, 150.0), &"", "za daleko na wszystko")
	check_eq(
		Drwal.choose_attack(100.0, 120.0, true, true, 150.0),
		Drwal.CLEAVE,
		"uporczywa garda ma pierwszeństwo"
	)


func test_spin_is_rare_and_never_twice_in_a_row() -> void:
	check(Drwal.spin_allowed(true, 0.0, Drwal.SLASH), "krąży, czas minął")
	check(not Drwal.spin_allowed(false, 0.0, Drwal.SLASH), "bez krążenia nie")
	check(not Drwal.spin_allowed(true, 3.0, Drwal.SLASH), "przed końcem odstępu nie")
	check(not Drwal.spin_allowed(true, 0.0, Drwal.SPIN), "nie dwa razy z rzędu")


func test_circling_needs_swept_angle_near_the_drwal() -> void:
	var swept := 0.0
	for i in 10:
		swept = Drwal.update_swept(swept, 0.2, 0.1, 0.4, true)
	check(swept >= 1.5 - 0.1, "obiegnięty kąt się sumuje: %s" % swept)
	check_eq(Drwal.update_swept(swept, 0.5, 0.1, 0.4, false), 0.0, "daleko zeruje")
	var idle := 1.0
	for i in 20:
		idle = Drwal.update_swept(idle, 0.0, 0.1, 0.4, true)
	check(idle < 1.0, "bez krążenia kąt opada")


func test_drwal_circling_player_unlocks_spin_and_it_is_rare() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(100, 0))
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	drwal._acquire_target()
	check(not drwal.circling(), "stojący gracz nie krąży")
	for i in 40:
		hero.global_position = Steering.to_screen(Vector2.RIGHT.rotated(i * 0.12) * 100.0)
		drwal._observe_target(1.0 / 60.0)
	check(drwal.circling(), "gracz biegnący wokół Drwala krąży")
	drwal._spin_wait = 0.0
	drwal.mode = Enemy.Mode.ENGAGE
	drwal.step(1.0 / 60.0)
	check_eq(drwal._warn_kind, Drwal.SPIN, "wybrany obrót")
	check_eq(drwal.mode, Enemy.Mode.WARN, "zapowiedź obrotu")
	check(
		drwal._warn_time_of(Drwal.SPIN) > drwal._warn_time_of(Drwal.SLASH),
		"dłuższa zapowiedź niż cięcie"
	)
	check(not drwal.circling(), "po obrocie licznik krążenia zerowy")
	check(drwal._spin_wait > 0.0, "kolejny obrót dopiero po odstępie")


func test_spin_profile_is_long_recovery_parryable_around_self() -> void:
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	check(drwal.spin.around_self, "obszar wokół Drwala")
	check(drwal.spin.parryable, "parowalny")
	check(drwal.spin.recovery > drwal.slash.recovery, "dłuższe odzyskiwanie niż cięcie")
	check(drwal.spin.recovery > drwal.cleave.recovery, "okazja dla gracza")


func test_spin_hitbox_is_centered_on_the_drwal_not_in_front() -> void:
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2(300, 100))
	drwal.ai_enabled = false
	var hitbox: Area2D = drwal.combat.get_node("Hitbox")
	drwal.combat.request_attack(Vector2.RIGHT, null, drwal.slash)
	drwal.combat.place_hitbox()
	check(
		hitbox.global_position.x > drwal.global_position.x + 40.0, "cięcie: obszar przed postacią"
	)
	drwal.combat._set_state(Combat.State.IDLE)
	drwal.combat.request_attack(Vector2.RIGHT, null, drwal.spin)
	drwal.combat.place_hitbox()
	check_eq(hitbox.global_position, drwal.global_position, "obrót: obszar wokół postaci")
	check(hitbox.scale.x > 1.0, "obrót sięga dalej")


func test_spin_hits_target_behind_the_drwal_but_slash_does_not() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(-70, 0))
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	drwal.ai_enabled = false
	var hero_combat: Combat = hero.get_node("Combat")
	drwal.combat.request_attack(Vector2.RIGHT, hero, drwal.slash)
	await _frames(1.6)
	check_eq(hero_combat.health, hero_combat.max_health, "cięcie nie sięga za plecy")
	check_eq(drwal.combat.state, Combat.State.IDLE, "Drwal po cięciu znów gotowy")
	drwal.combat.request_attack(Vector2.RIGHT, hero, drwal.spin)
	await _frames(1.0)
	check(hero_combat.health < hero_combat.max_health, "obrót trafia za plecami")
	check_eq(drwal.combat.state, Combat.State.RECOVER, "po obrocie odsłonięty (RECOVER)")


func test_spin_is_blocked_by_guard_toward_the_drwal() -> void:
	var hero: Node2D = _spawn(HERO_SCENE, Vector2(80, 0))
	var drwal: Drwal = _spawn(DRWAL_SCENE, Vector2.ZERO)
	drwal.ai_enabled = false
	var hero_combat: Combat = hero.get_node("Combat")
	hero_combat.set_guard(true, Vector2.LEFT)
	await _frames(0.4)  # po oknie parady, więc zwykły blok
	drwal.combat.request_attack(Vector2.RIGHT, hero, drwal.spin)
	await _frames(1.0)
	check_eq(hero_combat.health, hero_combat.max_health, "garda w stronę Drwala zatrzymuje obrót")
