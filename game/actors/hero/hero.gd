class_name Hero
extends CharacterBody2D
## Bohater: ruch myszą po siatce nawigacji, sprint na wytrzymałości, polecenia dla walki.
## Początek układu leży w punkcie styku z ziemią. Logika używa akcji z autoload/controls.gd.
##
## Walka (core/combat/combat.gd) to opcjonalne dziecko "Combat": bez niego bohater tylko chodzi.
## Kierunki przekazywane walce to wektory na ekranie od bohatera ku celowi lub kursorowi.

const LAYER_WORLD := 1
const LAYER_ENEMIES := 4
const ENEMY_GROUP := &"enemies"
const HERO_GROUP := &"hero"
const COMBAT_NODE := "Combat"

@export var walk_speed := 220.0
@export var sprint_multiplier := 1.7
@export var sprint_cost_per_second := 20.0
## Tolerancja dojścia do punktu (w jednostkach świata, nie ekranu).
@export var arrive_distance := 1.0
## Sekundy bez postępu, po których polecenie ruchu jest porzucane (zablokowana droga).
@export var stuck_timeout := 0.4

var sprinting := false

var _goal := Vector2.ZERO
var _has_goal := false
var _attack_target: Node2D
var _holding_move := false
var _stuck_time := 0.0
var _dash_velocity := Vector2.ZERO
var _dash_left := 0.0
var _guard_held := false
var _combat: Node

@onready var sprite: AssetSprite = $Sprite
@onready var stamina: Stamina = $Stamina
@onready var _agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	add_to_group(HERO_GROUP)
	_combat = get_node_or_null(COMBAT_NODE)
	if _combat and _combat.has_signal(&"dash_requested"):
		_combat.connect(&"dash_requested", _on_dash_requested)
	if sprite.meta.is_empty():
		return
	sprite.play_anim(&"idle", &"s")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"move_attack"):
		_click(get_global_mouse_position(), Input.is_action_pressed(&"attack_in_place"))
	elif event.is_action_released(&"move_attack"):
		_holding_move = false
	elif event.is_action_pressed(&"dodge") and _combat:
		_combat.request_dodge(_cursor_direction())


func _physics_process(delta: float) -> void:
	if _holding_move:
		if Input.is_action_pressed(&"move_attack"):
			move_to(get_global_mouse_position())
		else:
			_holding_move = false
	if _combat:
		_update_guard()
	step(delta, Input.is_action_pressed(&"sprint"))


## Jeden krok fizyki. Wejście (sprint) podawane z zewnątrz, żeby dało się go testować bez myszy.
func step(delta: float, wants_sprint: bool) -> void:
	if _dash_left > 0.0:
		_step_dash(delta)
		return
	_update_attack_order()
	if _combat and _combat.is_movement_locked():
		velocity = Vector2.ZERO
		return
	var moved := false
	if _has_goal:
		moved = _step_toward_goal(delta, wants_sprint)
	else:
		sprinting = false
		velocity = Vector2.ZERO
	_update_animation(velocity if moved else Vector2.ZERO)


func move_to(point: Vector2) -> void:
	_attack_target = null
	_set_goal(point)


## Podejdź na zasięg walki i zleć jeden atak. Bez walki: zwykły ruch do celu.
func attack_target(target: Node2D) -> void:
	if _combat == null:
		move_to(target.global_position)
		return
	_attack_target = target
	_set_goal(target.global_position)


func clear_orders() -> void:
	_attack_target = null
	_holding_move = false
	_has_goal = false
	_stuck_time = 0.0


func is_moving() -> bool:
	return _has_goal


func _click(point: Vector2, in_place: bool) -> void:
	var enemy := _enemy_at(point)
	if in_place:
		if _combat:
			_combat.request_attack(_direction_to(point), enemy)
		return
	if enemy:
		attack_target(enemy)
	else:
		move_to(point)
		_holding_move = true


func _enemy_at(point: Vector2) -> Node2D:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = LAYER_ENEMIES
	query.collide_with_areas = true
	for hit in get_world_2d().direct_space_state.intersect_point(query):
		var node := hit["collider"] as Node
		while node and not node.is_in_group(ENEMY_GROUP):
			node = node.get_parent()
		if node:
			return node as Node2D
	return null


func _set_goal(point: Vector2) -> void:
	_goal = point
	_has_goal = true
	_stuck_time = 0.0
	_agent.target_position = point


func _update_attack_order() -> void:
	if _attack_target == null:
		return
	if not is_instance_valid(_attack_target):
		clear_orders()
		return
	var to_target := _attack_target.global_position - global_position
	if Steering.to_world(to_target).length() <= float(_combat.attack_range):
		var target := _attack_target
		clear_orders()
		_combat.request_attack(to_target.normalized(), target)
	elif _attack_target.global_position.distance_to(_goal) > 8.0:
		_set_goal(_attack_target.global_position)


func _step_toward_goal(delta: float, wants_sprint: bool) -> bool:
	var next := _next_point()
	var to_next := Steering.to_world(next - global_position)
	var distance := to_next.length()
	if _arrived(distance):
		clear_orders()
		sprinting = false
		velocity = Vector2.ZERO
		return false
	var speed := walk_speed
	if _combat:
		speed *= float(_combat.move_speed_factor())
	sprinting = wants_sprint and not stamina.is_exhausted()
	if sprinting:
		speed *= sprint_multiplier
		stamina.drain(sprint_cost_per_second, delta)
	# Nie przeskakuj punktu docelowego: ostatni krok kończy się dokładnie w nim.
	speed = minf(speed, distance / delta)
	velocity = Steering.to_screen(to_next.normalized() * speed)
	var before := global_position
	Steering.move(self, velocity * delta)
	_track_progress(delta, Steering.to_world(global_position - before).length(), speed)
	return true


func _track_progress(delta: float, travelled: float, intended: float) -> void:
	if travelled < intended * delta * 0.2:
		_stuck_time += delta
		if _stuck_time >= stuck_timeout:
			clear_orders()
	else:
		_stuck_time = 0.0


func _next_point() -> Vector2:
	return Steering.next_point(_agent, _goal)


func _arrived(distance_to_next: float) -> bool:
	if distance_to_next > arrive_distance:
		return false
	return _agent.is_navigation_finished() or _next_point() == _goal


func _update_animation(move: Vector2) -> void:
	if sprite.meta.is_empty():
		return
	if _combat and _combat.state == Combat.State.GUARD:
		return  # animację gardy prowadzi walka
	var anim := &"walk" if move.length_squared() > 0.0 else &"idle"
	var dir := sprite.direction
	if move.length_squared() > 0.0:
		dir = AssetSprite.direction_from_vector(move)
	if anim != sprite.animation or dir != sprite.direction:
		sprite.play_anim(anim, dir)


func _direction_to(point: Vector2) -> Vector2:
	return (point - global_position).normalized()


func _cursor_direction() -> Vector2:
	return _direction_to(get_global_mouse_position())


## Zasada: Q wciśnięte oznacza gardę. Polecenie ponawiane co klatkę, więc wraca po ogłuszeniu,
## odskoku czy pęknięciu; to, czy parada należy się graczowi, pilnuje walka.
func _update_guard() -> void:
	if Input.is_action_pressed(&"guard"):
		_guard_held = true
		_combat.set_guard(true, _cursor_direction())
	elif _guard_held:
		_guard_held = false
		_combat.set_guard(false)


func _on_dash_requested(offset: Vector2, duration: float) -> void:
	clear_orders()
	sprinting = false
	if duration <= 0.0:
		move_and_collide(offset)
		return
	_dash_velocity = offset / duration
	_dash_left = duration


func _step_dash(delta: float) -> void:
	var slice := minf(delta, _dash_left)
	var hit := move_and_collide(_dash_velocity * slice)
	_dash_left = 0.0 if hit else _dash_left - slice
	velocity = Vector2.ZERO if _dash_left <= 0.0 else _dash_velocity
