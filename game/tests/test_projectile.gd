extends "res://tests/test_case.gd"

const PROJECTILE := preload("res://core/combat/projectile.tscn")
const HERO_SCENE := preload("res://actors/hero/hero.tscn")
const DOG_SCENE := preload("res://actors/enemies/zdziczaly-pies/pies.tscn")
const STRZELEC_SCENE := preload("res://actors/enemies/test-strzelec/strzelec.tscn")
const DT := 1.0 / 60.0


## Cel o strukturze z Combat::_scan_hitbox: Hurtbox w grupie „hurtbox” i dziecko „Combat”.
class FakeTarget:
	extends Node2D
	var combat: Recorder

	func _init() -> void:
		var hurtbox := Area2D.new()
		hurtbox.name = "Hurtbox"
		hurtbox.collision_layer = 8
		hurtbox.collision_mask = 0
		hurtbox.add_to_group(&"hurtbox")
		var shape := CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		hurtbox.add_child(shape)
		add_child(hurtbox)
		combat = Recorder.new()
		combat.name = "Combat"
		add_child(combat)


class Recorder:
	extends Combat
	var hits: Array[Hit] = []

	func receive_hit(hit: Hit) -> Dictionary:
		hits.append(hit)
		return {"result": Hit.Result.HIT, "damage": hit.damage, "crit": false}


var _root: Window
var _spawned: Array[Node] = []


func setup(root: Window) -> void:
	_root = root


func teardown() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.free()


func _launch(from: Vector2, direction: Vector2) -> Projectile:
	var projectile := Projectile.launch(PROJECTILE, _root, null, from, direction)
	_spawned.append(projectile)
	return projectile


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var node: Node2D = scene.instantiate()
	_root.add_child(node)
	node.global_position = at
	_spawned.append(node)
	return node


func _add_wall(position: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = size
	wall.add_child(shape)
	_root.add_child(wall)
	_spawned.append(wall)
	wall.global_position = position


func _wait(seconds: float) -> void:
	await _root.get_tree().create_timer(seconds).timeout


func test_flies_straight_in_isometric_projection() -> void:
	var down := _launch(Vector2.ZERO, Vector2(0, 1))
	var right := _launch(Vector2.ZERO, Vector2(1, 0))
	for i in 30:
		down.step(DT)
		right.step(DT)
	var distance := down.speed * DT * 30.0
	check(is_equal_approx(right.global_position.x, distance), "w poziomie pełna prędkość")
	check(is_equal_approx(down.global_position.y, distance * AssetSprite.ISO_Y), "pion o połowę")
	check(is_equal_approx(down.global_position.x, 0.0), "bez znoszenia na boki")


func test_path_is_fixed_at_launch() -> void:
	var projectile := _launch(Vector2.ZERO, Vector2(1, 0.5))
	var before := projectile.world_direction()
	for i in 20:
		projectile.step(DT)
	check_eq(projectile.world_direction(), before, "kierunek nie zmienia się w locie")
	var a := projectile.global_position
	projectile.step(DT)
	var b := projectile.global_position
	projectile.step(DT)
	var c := projectile.global_position
	check((b - a).is_equal_approx(c - b), "stały krok wzdłuż prostej")


func test_vanishes_after_range() -> void:
	var projectile := _launch(Vector2.ZERO, Vector2.RIGHT)
	projectile.max_range = 100.0
	for i in 60:
		projectile.step(DT)
	check(projectile.is_queued_for_deletion(), "po zasięgu znika")
	check(projectile.global_position.x <= 100.0 + 0.01, "nie leci dalej niż zasięg")


func test_stops_at_obstacle() -> void:
	_add_wall(Vector2(200, 0), Vector2(20, 400))
	await _root.get_tree().physics_frame
	var projectile := _launch(Vector2.ZERO, Vector2.RIGHT)
	await _wait(0.8)
	check(not is_instance_valid(projectile) or projectile.is_queued_for_deletion(), "przeszkoda")


func test_hits_hero_on_track_for_damage() -> void:
	var hero := _spawn(HERO_SCENE, Vector2(240, 0))
	var combat: Combat = hero.get_node("Combat")
	var projectile := _launch(Vector2.ZERO, Vector2.RIGHT)
	var damage := projectile.damage
	await _wait(1.0)
	check_eq(combat.health, combat.max_health - damage, "obrażenia z pocisku")
	check(
		not is_instance_valid(projectile) or projectile.is_queued_for_deletion(), "trafiony znika"
	)


func test_misses_hero_off_track() -> void:
	var hero := _spawn(HERO_SCENE, Vector2(240, 150))
	var combat: Combat = hero.get_node("Combat")
	var projectile := _launch(Vector2.ZERO, Vector2.RIGHT)
	await _wait(0.8)
	check_eq(combat.health, combat.max_health, "cel poza torem bez obrażeń")
	check(projectile.global_position.x > 240.0, "pocisk przeleciał obok")


func test_does_not_follow_a_target_that_moves_away() -> void:
	var hero := _spawn(HERO_SCENE, Vector2(300, 0))
	var combat: Combat = hero.get_node("Combat")
	var projectile := _launch(Vector2.ZERO, Vector2.RIGHT)
	hero.global_position = Vector2(300, 220)
	await _wait(1.0)
	check_eq(combat.health, combat.max_health, "bez naprowadzania")
	check(absf(projectile.global_position.y) < 1.0, "tor pozostał prosty")


func test_passes_enemies_without_friendly_fire() -> void:
	var dog: Enemy = _spawn(DOG_SCENE, Vector2(150, 0))
	dog.ai_enabled = false
	var projectile := _launch(Vector2.ZERO, Vector2.RIGHT)
	await _wait(0.8)
	check_eq(dog.combat.health, dog.combat.max_health, "pocisk mija przeciwnika")
	check(projectile.global_position.x > 150.0, "leci dalej")


func test_hit_is_unparryable_blockable_and_originates_at_the_projectile() -> void:
	var target := FakeTarget.new()
	_root.add_child(target)
	_spawned.append(target)
	target.global_position = Vector2(150, 0)
	var projectile := _launch(Vector2(10, 0), Vector2.RIGHT)
	var damage := projectile.damage
	await _wait(0.8)
	check_eq(target.combat.hits.size(), 1, "jedno trafienie")
	var hit := target.combat.hits[0]
	check(not hit.parryable, "pocisk nie podlega paradzie")
	check(hit.blockable, "garda może go zatrzymać")
	check(
		hit.origin.x > 10.0 and hit.origin.x < 150.0, "origin to pozycja pocisku: %s" % hit.origin
	)
	check_eq(hit.damage, damage, "obrażenia z pocisku")


func test_guard_toward_the_shooter_blocks_but_does_not_parry() -> void:
	var hero := _spawn(HERO_SCENE, Vector2(240, 0))
	var combat: Combat = hero.get_node("Combat")
	var results: Array = []
	combat.hit_received.connect(
		func(result: Hit.Result, _damage: float) -> void: results.append(result)
	)
	combat.set_guard(true, Vector2.LEFT)
	_launch(Vector2.ZERO, Vector2.RIGHT)
	await _wait(1.0)
	check_eq(combat.health, combat.max_health, "garda zatrzymuje pocisk")
	check_eq(results, [Hit.Result.BLOCKED], "blok, nie parada (nawet w oknie parady)")


func test_guard_facing_away_does_not_block() -> void:
	var hero := _spawn(HERO_SCENE, Vector2(240, 0))
	var combat: Combat = hero.get_node("Combat")
	combat.set_guard(true, Vector2.RIGHT)
	var projectile := _launch(Vector2.ZERO, Vector2.RIGHT)
	var damage := projectile.damage
	await _wait(1.0)
	check_eq(combat.health, combat.max_health - damage, "garda tyłem nie chroni")


func test_profile_with_projectile_launches_on_hit_start_along_the_attack_direction() -> void:
	var shooter: Strzelec = _spawn(STRZELEC_SCENE, Vector2.ZERO)
	shooter.ai_enabled = false
	var hero := _spawn(HERO_SCENE, Vector2(300, 0))
	var combat: Combat = hero.get_node("Combat")
	shooter.combat.request_attack(Vector2.RIGHT, hero, shooter.shot)
	check_eq(_projectiles(), 0, "przed hit_start nic nie leci")
	await _wait(1.2)
	check_eq(combat.health, combat.max_health - shooter.shot.damage, "strzał z profilu trafił")
	check_eq(shooter.combat.state != Combat.State.ATTACK, true, "strzał zakończony")


func test_shooter_does_not_open_a_melee_hit_window() -> void:
	var shooter: Strzelec = _spawn(STRZELEC_SCENE, Vector2.ZERO)
	shooter.ai_enabled = false
	var hero := _spawn(HERO_SCENE, Vector2(40, 0))
	var combat: Combat = hero.get_node("Combat")
	combat.set_guard(true, Vector2.LEFT)
	shooter.combat.request_attack(Vector2.UP, hero, shooter.shot)  # strzał w bok od bohatera
	await _wait(1.0)
	check_eq(combat.health, combat.max_health, "bohater obok toru nie dostaje ciosu z Hitboxa")


func test_shooter_ai_telegraphs_then_shoots_and_projectile_does_not_hurt_enemies() -> void:
	var hero := _spawn(HERO_SCENE, Vector2(300, 0))
	var shooter: Strzelec = _spawn(STRZELEC_SCENE, Vector2.ZERO)
	var dog: Enemy = _spawn(DOG_SCENE, Vector2(150, 0))
	dog.ai_enabled = false
	var warned := [false]
	shooter.telegraphed.connect(func(_kind: StringName, _parryable: bool) -> void: warned[0] = true)
	await _wait(2.5)
	check(warned[0], "strzelec najpierw ostrzega")
	check_eq(dog.combat.health, dog.combat.max_health, "pocisk nie rani przeciwnika na torze")
	var combat: Combat = hero.get_node("Combat")
	check(combat.health < combat.max_health, "strzał dosięga bohatera")


func _projectiles() -> int:
	var count := 0
	for child in _root.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			count += 1
	return count


func test_projectile_still_hits_after_the_shooter_is_gone() -> void:
	var shooter := Recorder.new()
	_root.add_child(shooter)
	var target := FakeTarget.new()
	_root.add_child(target)
	_spawned.append(target)
	target.global_position = Vector2(300, 0)
	Projectile.launch(PROJECTILE, _root, shooter, Vector2.ZERO, Vector2.RIGHT)
	shooter.free()
	await _wait(1.0)
	check_eq(target.combat.hits.size(), 1, "pocisk leci i trafia mimo braku strzelca")
	check_eq(
		target.combat.hits[0].attacker, null, "attacker pusty, bez odwołania do zwolnionego węzła"
	)


func test_combat_without_a_parent_does_not_crash_when_launching() -> void:
	var combat := Combat.new()
	var profile := AttackProfile.new()
	profile.projectile = PROJECTILE
	combat.request_attack(Vector2.RIGHT, null, profile)
	combat.on_anim_event(&"hit_start")
	check_eq(_projectiles(), 0, "brak rodzica: nic nie wypuszczone")
	combat.free()
