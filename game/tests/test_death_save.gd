extends "res://tests/test_case.gd"

const SANDBOX := preload("res://world/sandbox/sandbox.tscn")
const DOG_SCENE := preload("res://actors/enemies/zdziczaly-pies/pies.tscn")
const SLOT := "test_t13"

var _root: Window
var _nodes: Array[Node] = []


func setup(root: Window) -> void:
	_root = root
	GameState.from_data({})


func teardown() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	GameState.from_data({})
	DirAccess.remove_absolute("%s/%s.json" % [SaveSystem.SAVE_DIR, SLOT])


func _sandbox() -> Node2D:
	var sandbox: Node2D = SANDBOX.instantiate()
	sandbox.save_slot = SLOT
	_root.add_child(sandbox)
	_nodes.append(sandbox)
	return sandbox


func _kill(enemy: Enemy) -> void:
	var hit := Hit.new()
	hit.damage = 999.0
	enemy.combat.receive_hit(hit)


func test_defeated_enemy_stays_defeated_by_world_id() -> void:
	var dog: Enemy = DOG_SCENE.instantiate()
	dog.world_id = &"TEST-persist"
	_root.add_child(dog)
	_nodes.append(dog)
	_kill(dog)
	check(GameState.is_collected(&"TEST-persist"), "pokonany zapisany w stanie świata")
	var again: Enemy = DOG_SCENE.instantiate()
	again.world_id = &"TEST-persist"
	_root.add_child(again)
	_nodes.append(again)
	check(again.is_queued_for_deletion(), "ten sam world_id nie odradza się")


func test_save_and_load_restore_state_from_save_not_from_the_attempt() -> void:
	var sandbox := _sandbox()
	await _root.get_tree().physics_frame
	var hero: Hero = sandbox.get_node("Hero")
	hero.get_node("Combat").health = 70.0
	hero.healing.bandages = 2
	check_eq(sandbox.save_checkpoint(), OK, "zapis w bezpiecznym miejscu")
	# próba po zapisie: obrażenia, zużyty zapas, pokonany pies
	hero.get_node("Combat").health = 15.0
	hero.healing.bandages = 0
	_kill(sandbox.get_node("Pies"))
	check(GameState.is_collected(&"SBX-pies"), "pies pokonany w próbie")
	sandbox.free()
	_nodes.clear()
	check_eq(SaveSystem.load_slot(SLOT), OK, "wczytanie")
	var reloaded := _sandbox()
	await _root.get_tree().physics_frame
	var hero2: Hero = reloaded.get_node("Hero")
	check_eq(hero2.get_node("Combat").health, 70.0, "zdrowie z zapisu")
	check_eq(hero2.healing.bandages, 2, "zapasy z zapisu")
	check(is_instance_valid(reloaded.get_node_or_null("Pies")), "pies żyje jak w zapisie")
	check(not reloaded.get_node("Pies").is_queued_for_deletion(), "pies nie jest usuwany")


func test_cannot_save_in_combat_or_with_active_enemy() -> void:
	var sandbox := _sandbox()
	await _root.get_tree().physics_frame
	var hero: Hero = sandbox.get_node("Hero")
	check(sandbox.can_save_now(), "spokój: można")
	hero.get_node("Combat").request_attack(Vector2.RIGHT, null)
	check(not sandbox.can_save_now(), "w trakcie ciosu nie")
	check_eq(sandbox.save_checkpoint(), ERR_UNAVAILABLE, "odmowa zapisu")
	hero.get_node("Combat").set_guard(false)
	var pies: Enemy = sandbox.get_node("Pies")
	pies._set_mode(Enemy.Mode.ENGAGE)
	hero.get_node("Combat").state = Combat.State.IDLE
	check(not sandbox.can_save_now(), "przy aktywnym przeciwniku nie")
