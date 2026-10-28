# gdlint: disable=max-public-methods
extends "res://tests/test_case.gd"
## Scenariusze z docs/walka.md: rytm i wiązanki, przerwania, garda i parada, pancerz i krytyk.

const FakeStamina := preload("res://tests/fake_stamina.gd")

var _root: Window
var _hero: Combat
var _enemy: Combat
var _hero_stamina: Node
var _enemy_stamina: Node


func setup(root: Window) -> void:
	_root = root
	_hero = _actor(Vector2.ZERO)
	_enemy = _actor(Vector2(60, 0))
	_hero_stamina = _hero.stamina
	_enemy_stamina = _enemy.stamina


func teardown() -> void:
	_hero.get_parent().free()
	_enemy.get_parent().free()


func _actor(pos: Vector2) -> Combat:
	var body := Node2D.new()
	body.position = pos
	_root.add_child(body)
	var combat := Combat.new()
	combat.name = "Combat"
	combat.base_crit_chance = 0.0
	combat.finisher_crit_bonus = 0.0
	combat.rng_seed = 7
	combat.stamina = FakeStamina.new()
	body.add_child(combat.stamina)
	body.add_child(combat)
	return combat


## Jeden cios od kliknięcia: okno trafienia, opcjonalny kontakt, okno wiązanki.
func _swing_to_combo(contact: bool) -> void:
	_hero.on_anim_event(&"hit_start")
	if contact:
		_hero.register_contact(_enemy)
	_hero.on_anim_event(&"hit_end")
	_hero.on_anim_event(&"combo_open")


func test_click_attack_damages_only_in_hit_window() -> void:
	_hero.request_attack(Vector2.RIGHT)
	check_eq(_hero.state, Combat.State.ATTACK, "kliknięcie zaczyna atak")
	_hero.register_contact(_enemy)
	check_eq(_enemy.health, 100.0, "kontakt przed hit_start nie rani")
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	_hero.register_contact(_enemy)
	check_eq(_enemy.health, 90.0, "jeden cios rani raz")


func test_rhythm_click_continues_chain_with_bonus() -> void:
	var links: Array[int] = []
	_hero.attack_started.connect(func(link: int) -> void: links.append(link))
	_hero.request_attack(Vector2.RIGHT)
	_swing_to_combo(true)
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_finished()
	check_eq(links, [0, 1], "klik w oknie daje drugie ogniwo")
	_enemy.state = Combat.State.IDLE
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	check(
		is_equal_approx(_enemy.health, 100.0 - 10.0 - 11.5),
		"drugi cios mocniejszy: %s" % _enemy.health
	)


func test_early_click_locks_chain_but_not_attack() -> void:
	var ended: Array[StringName] = []
	_hero.chain_ended.connect(func(r: StringName) -> void: ended.append(r))
	_hero.request_attack(Vector2.RIGHT)
	_hero.request_attack(Vector2.RIGHT)
	check_eq(_hero.state, Combat.State.ATTACK, "przedwczesny klik nie zatrzymuje ciosu")
	_swing_to_combo(true)
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_finished()
	check_eq(_hero.state, Combat.State.IDLE, "bez drugiego ogniwa")
	check_eq(ended, [&"finished"], "koniec łańcucha zgłoszony raz")


func test_spam_clicking_gives_no_chain() -> void:
	var links: Array[int] = []
	_hero.attack_started.connect(func(link: int) -> void: links.append(link))
	_hero.request_attack(Vector2.RIGHT)
	for i in 5:
		_hero.request_attack(Vector2.RIGHT)
	_swing_to_combo(true)
	for i in 5:
		_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_finished()
	check_eq(links, [0], "spam nie przedłuża wiązanki")


func test_miss_ends_chain() -> void:
	var ended: Array[StringName] = []
	_hero.chain_ended.connect(func(r: StringName) -> void: ended.append(r))
	_hero.request_attack(Vector2.RIGHT)
	_swing_to_combo(false)
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_finished()
	check_eq(ended, [&"miss"], "cios w powietrze kończy łańcuch")
	check_eq(_hero.state, Combat.State.IDLE, "brak finiszu na pustych ciosach")


func test_chain_length_limited_by_skill() -> void:
	var links: Array[int] = []
	_hero.attack_started.connect(func(link: int) -> void: links.append(link))
	_hero.request_attack(Vector2.RIGHT)
	for i in 3:
		_enemy.state = Combat.State.IDLE
		_swing_to_combo(true)
		_hero.request_attack(Vector2.RIGHT)
		_hero.on_anim_finished()
	check_eq(links, [0, 1, 2], "stopień I: najwyżej trzy ciosy")
	check_eq(_hero.state, Combat.State.IDLE, "klik w oknie trzeciego ciosu nie daje czwartego")


func test_dodge_cancels_attack_before_contact() -> void:
	var dashes: Array[Vector2] = []
	_hero.dash_requested.connect(func(o: Vector2, _d: float) -> void: dashes.append(o))
	_hero.request_attack(Vector2.RIGHT)
	_hero.request_dodge(Vector2.RIGHT)
	check_eq(_hero.state, Combat.State.DODGE, "unik przerywa atak")
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	check_eq(_enemy.health, 100.0, "przerwany cios nie trafia")
	check_eq(dashes, [Vector2(110, 0)], "odskok w kierunku kursora")


func test_dodge_offset_respects_isometry() -> void:
	var dashes: Array[Vector2] = []
	_hero.dash_requested.connect(func(o: Vector2, _d: float) -> void: dashes.append(o))
	_hero.request_dodge(Vector2.DOWN)
	check_eq(dashes, [Vector2(0, 55)], "pion ekranu skrócony o połowę")


func test_damage_stays_after_cancel() -> void:
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	_hero.request_dodge(Vector2.LEFT)
	check_eq(_enemy.health, 90.0, "zadane obrażenia zostają po przerwaniu")


func test_no_old_attack_after_dodge() -> void:
	_hero.request_dodge(Vector2.LEFT)
	_hero.request_attack(Vector2.RIGHT)
	_hero.tick(1.0)
	check_eq(_hero.state, Combat.State.IDLE, "po uniku stare polecenie ataku nie wraca")


func test_guard_blocks_front_but_not_back() -> void:
	_enemy.set_guard(true, Vector2.LEFT)
	_enemy.tick(1.0)
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	check_eq(_enemy.health, 100.0, "garda od frontu zatrzymuje cios")
	check_eq(_enemy_stamina.value, 85.0, "zablokowany cios kosztuje wytrzymałość")
	_enemy.set_guard(false)
	_enemy.set_guard(true, Vector2.RIGHT)
	_enemy.tick(1.0)
	_hero.on_anim_finished()
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	check_eq(_enemy.health, 90.0, "garda nie chroni pleców")


func test_unparryable_attack_ignores_guard() -> void:
	_hero.attack_parryable = false
	_enemy.set_guard(true, Vector2.LEFT)
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	check_eq(_enemy.health, 90.0, "cios nieparowalny przechodzi przez gardę")


func test_precise_parry_staggers_attacker() -> void:
	_enemy.set_guard(true, Vector2.LEFT)
	_enemy.tick(0.1)
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	check_eq(_hero.state, Combat.State.STAGGER, "parada zachwiewa napastnika")
	check(_enemy_stamina.value > 85.0, "parada tańsza od bloku")


func test_parry_window_needs_release_and_rearm() -> void:
	_enemy.set_guard(true, Vector2.LEFT)
	_enemy.tick(0.1)
	_enemy.receive_hit(_hit())
	_enemy.set_guard(false)
	_enemy.set_guard(true, Vector2.LEFT)
	_enemy.tick(0.05)
	check_eq(
		_enemy.receive_hit(_hit())["result"], Hit.Result.BLOCKED, "szybkie ponowne Q bez parady"
	)
	_enemy.set_guard(false)
	_enemy.tick(0.5)
	_enemy.set_guard(true, Vector2.LEFT)
	_enemy.tick(0.05)
	check_eq(_enemy.receive_hit(_hit())["result"], Hit.Result.PARRIED, "po odczekaniu parada wraca")


func test_exhausted_guard_breaks() -> void:
	_enemy_stamina.value = 10.0
	_enemy.set_guard(true, Vector2.LEFT)
	_enemy.tick(1.0)
	check_eq(_enemy.receive_hit(_hit())["result"], Hit.Result.BLOCKED, "cios zablokowany")
	check_eq(_enemy.state, Combat.State.STAGGER, "wyczerpana garda pęka")


func test_guard_prevents_attacking() -> void:
	_hero.set_guard(true, Vector2.RIGHT)
	_hero.request_attack(Vector2.RIGHT)
	check_eq(_hero.state, Combat.State.GUARD, "w gardzie nie atakujemy")
	check_eq(_hero.move_speed_factor(), 0.5, "garda spowalnia ruch")


func test_crit_never_turns_block_into_hit() -> void:
	_hero.base_crit_chance = 1.0
	_hero.max_crit_chance = 1.0
	_enemy.set_guard(true, Vector2.LEFT)
	_enemy.tick(1.0)
	_hero.request_attack(Vector2.RIGHT)
	_hero.on_anim_event(&"hit_start")
	_hero.register_contact(_enemy)
	check_eq(_enemy.health, 100.0, "krytyk nie przebija gardy")
	_enemy.set_guard(false)
	_enemy.receive_hit(_hit(1.0))
	check_eq(_enemy.health, 80.0, "krytyk podwaja skuteczne trafienie")


func test_fourth_link_raises_crit_chance() -> void:
	_hero.max_chain = 4
	_hero.finisher_crit_bonus = 1.0
	_hero.max_crit_chance = 1.0
	var crits: Array[bool] = []
	_hero.hit_landed.connect(
		func(_t: Combat, _r: Hit.Result, _d: float, c: bool) -> void: crits.append(c)
	)
	_hero.request_attack(Vector2.RIGHT)
	for i in 4:
		_enemy.state = Combat.State.IDLE
		_swing_to_combo(true)
		_hero.request_attack(Vector2.RIGHT)
		_hero.on_anim_finished()
	check_eq(crits, [false, false, false, true], "premia krytyka tylko na czwartym ciosie")


func test_armor_reduces_damage() -> void:
	_enemy.armor = 0.5
	_enemy.receive_hit(_hit())
	check_eq(_enemy.health, 95.0, "pancerz osłabia trafienie")


func test_hit_interrupts_own_attack() -> void:
	_enemy.request_attack(Vector2.LEFT)
	_enemy.receive_hit(_hit())
	check_eq(_enemy.state, Combat.State.STAGGER, "trafienie przerywa atak")


func _hit(crit: float = 0.0) -> Hit:
	var hit := Hit.new()
	hit.attacker = _hero
	hit.origin = Vector2.ZERO
	hit.crit_chance = crit
	return hit


func test_hitbox_reach_is_equal_in_every_direction() -> void:
	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	_hero.add_child(hitbox)
	_hero.request_attack(Vector2.RIGHT)
	_hero.place_hitbox()
	check(
		hitbox.global_position.is_equal_approx(Vector2(50, 0)),
		"w prawo: %s" % hitbox.global_position
	)
	_hero.on_anim_finished()
	_hero.request_attack(Vector2.DOWN)
	_hero.place_hitbox()
	check(
		hitbox.global_position.is_equal_approx(Vector2(0, 25)), "w dół: %s" % hitbox.global_position
	)
	check_eq(hitbox.scale, Vector2(1, 0.5), "kształt spłaszczony do rzutu 2:1")
