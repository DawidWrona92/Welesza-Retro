extends "res://tests/test_case.gd"

const HERO_SCENE := preload("res://actors/hero/hero.tscn")
const DT := 1.0 / 60.0

var _root: Window
var _hero: Hero
var _healing: Healing
var _combat: Combat
var _events: Array = []


func setup(root: Window) -> void:
	_root = root
	_fresh()


func teardown() -> void:
	_hero.free()


func _fresh(health := 50.0) -> void:
	if _hero:
		_hero.free()
	_hero = HERO_SCENE.instantiate()
	_root.add_child(_hero)
	_healing = _hero.healing
	_combat = _hero.get_node("Combat")
	_combat.health = health
	_events.clear()
	_healing.completed.connect(func(kind: StringName) -> void: _events.append(["done", kind]))
	_healing.interrupted.connect(func(kind: StringName) -> void: _events.append(["cut", kind]))
	_healing.blocked.connect(
		func(kind: StringName, why: StringName) -> void: _events.append(["no", kind, why])
	)


func _tick(seconds: float) -> void:
	var steps := int(round(seconds / DT))
	for i in steps:
		_healing.tick(DT)


func _hit(damage := 5.0) -> void:
	var hit := Hit.new()
	hit.damage = damage
	_combat.receive_hit(hit)


func test_bandage_settles_only_at_completion() -> void:
	check(_healing.start(Healing.BANDAGE), "opatrunek się zaczyna")
	_tick(_healing.bandage_time - 0.2)
	check_eq(_combat.health, 50.0, "przed końcem zdrowie bez zmian")
	check_eq(_healing.bandages, 3, "przed końcem przedmiot nie zużyty")
	_tick(0.4)
	check_eq(_combat.health, 50.0 + _healing.bandage_heal, "po końcu leczy")
	check_eq(_healing.bandages, 2, "po końcu zużywa przedmiot")
	check_eq(_events, [["done", Healing.BANDAGE]], "sygnał ukończenia")


func test_bandage_is_interrupted_by_move_dodge_guard_and_hit() -> void:
	for cause in [&"move", &"dodge", &"guard", &"hit"]:
		_fresh()
		_healing.start(Healing.BANDAGE)
		_tick(1.0)
		match cause:
			&"move":
				_hero.move_to(Vector2(500, 0))
			&"dodge":
				_combat.request_dodge(Vector2.RIGHT)
			&"guard":
				_combat.set_guard(true, Vector2.RIGHT)
			&"hit":
				_hit()
		_tick(0.1)
		check(not _healing.is_busy(), "przerwany przez %s" % cause)
		check_eq(_healing.bandages, 3, "bez zużycia przy %s" % cause)
		check(_combat.health <= 50.0, "bez leczenia przy %s" % cause)
		check_eq(_events, [["cut", Healing.BANDAGE]], "sygnał przerwania przy %s" % cause)


func test_repeated_cancelling_gives_no_free_healing() -> void:
	for i in 5:
		_healing.start(Healing.BANDAGE)
		_tick(_healing.bandage_time - 0.3)
		_hero.move_to(Vector2(100, 0))
	check_eq(_combat.health, 50.0, "częściowe leczenie nie istnieje")
	check_eq(_healing.bandages, 3, "zapas nietknięty")


func test_potion_heals_gradually_after_drinking() -> void:
	check(_healing.start(Healing.POTION), "nalewka się zaczyna")
	_tick(_healing.potion_time + 0.1)
	check_eq(_healing.potions, 0, "zużyta po wypiciu")
	var after_drink := _combat.health
	_tick(1.0)
	check(_combat.health > after_drink, "leczenie płynie")
	check(_combat.health < 50.0 + _healing.potion_heal, "nie od razu całość")
	_tick(_healing.potion_duration)
	check(is_equal_approx(_combat.health, 50.0 + _healing.potion_heal), "po czasie cała dawka")


func test_second_potion_is_blocked_without_loss() -> void:
	_healing.potions = 2
	_healing.start(Healing.POTION)
	_tick(_healing.potion_time + 0.1)
	check(not _healing.start(Healing.POTION), "aktywny efekt blokuje użycie")
	check_eq(_healing.potions, 1, "przedmiot nie przepada")
	check_eq(_events.back(), ["no", Healing.POTION, &"active"], "powód odmowy")


func test_potion_survives_hit_but_not_dodge_or_guard() -> void:
	_healing.start(Healing.POTION)
	_tick(0.2)
	_hit()
	_tick(0.1)
	check(_healing.is_busy(), "trafienie nie przerywa nalewki")
	_tick(_healing.potion_time)
	check_eq(_healing.potions, 0, "wypita mimo trafienia")
	for cause in [&"dodge", &"guard"]:
		_fresh()
		_healing.start(Healing.POTION)
		_tick(0.2)
		if cause == &"dodge":
			_combat.request_dodge(Vector2.RIGHT)
		else:
			_combat.set_guard(true, Vector2.RIGHT)
		_tick(0.1)
		check(not _healing.is_busy(), "przerwana przez %s" % cause)
		check_eq(_healing.potions, 1, "bez zużycia przy %s" % cause)


func test_refusals_cost_nothing() -> void:
	_fresh(_combat.max_health)
	check(not _healing.start(Healing.BANDAGE), "pełne zdrowie")
	_fresh()
	_healing.bandages = 0
	check(not _healing.start(Healing.BANDAGE), "brak zapasu")
	_fresh()
	_combat.set_guard(true, Vector2.RIGHT)
	check(not _healing.start(Healing.BANDAGE), "w gardzie nie wolno")
	check_eq(_healing.bandages, 3, "zapas nietknięty")


func test_death_stops_healing_and_ignores_input() -> void:
	_healing.start(Healing.BANDAGE)
	var died := [false]
	_hero.died.connect(func() -> void: died[0] = true)
	_hit(500.0)
	check(_hero.dead, "bohater martwy")
	check(died[0], "sygnał died")
	check(not _healing.is_busy(), "leczenie przerwane")
	check(not _healing.start(Healing.BANDAGE), "martwy się nie leczy")
	_hero.move_to(Vector2(100, 0))
	_hero._physics_process(DT)
	check_eq(_hero.global_position, Vector2.ZERO, "martwy się nie rusza")


func test_hero_data_roundtrip() -> void:
	_healing.bandages = 1
	_healing.potions = 0
	_combat.health = 42.0
	_hero.global_position = Vector2(120, -40)
	var data := _hero.to_data()
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(data))
	_fresh(100.0)
	_hero.from_data(parsed)
	check_eq(_hero.healing.bandages, 1, "opatrunki")
	check_eq(_hero.healing.potions, 0, "nalewki")
	check_eq(_hero.get_node("Combat").health, 42.0, "zdrowie")
	check_eq(_hero.global_position, Vector2(120, -40), "miejsce")
