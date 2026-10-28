class_name Enemy
extends CharacterBody2D
## Wspólna baza zwykłego przeciwnika (T12, docs/przeciwnicy.md, część II §1): pilnuje miejsca,
## ostrzega po wykryciu gracza, walczy według reguł podklasy i wraca na miejsce po przekroczeniu
## granicy pościgu. Atak zawsze poprzedza zapowiedź (WARN); kierunek ataku zapada pod jej koniec,
## więc skok czy zamach ma ustalony tor i poprawny unik nie jest unieważniany obrotem.
##
## Podklasy dostarczają _engage() (ruch i wybór ataku), _profile_of() i _warn_time_of().
## Decyzje (wybór ataku) są statycznymi funkcjami podklas, testowanymi bez fizyki.
##
## Walka (core/combat/combat.gd) jest dzieckiem „Combat”; trafienia idą przez Hitbox i Hurtbox
## (warstwy hero_hurtbox / enemy_hurtbox rozdzielają bohatera i przeciwników).

signal mode_changed(new_mode: Mode)
signal telegraphed(kind: StringName, parryable: bool)

enum Mode { WATCH, ALERT, ENGAGE, WARN, ATTACK, RETURN, DEAD }

const GROUP := &"enemies"
const ACTIVE_GROUP := &"active_enemies"
const HERO_GROUP := &"hero"
## Zwykłe starcia mają najwyżej dwóch aktywnych przeciwników (docs/przeciwnicy.md, §1).
const MAX_ACTIVE := 2
const TINT_ALERT := Color(1.0, 0.95, 0.6)
const TINT_PARRYABLE := Color(1.0, 0.9, 0.35)
const TINT_HEAVY := Color(1.0, 0.4, 0.35)
const TINT_RETURNING := Color(1.0, 1.0, 1.0, 0.5)

## Wyłączone AI zostawia tylko ruch od walki (odskok); do testów i strojenia.
@export var ai_enabled := true
@export var walk_speed := 140.0
@export var return_speed := 220.0
## Odległość (jednostki świata), z której przeciwnik zauważa gracza.
@export var aggro_radius := 380.0
## Granica pościgu: licząc od miejsca przeciwnika. Za nią nie atakuje i nie przyjmuje obrażeń.
@export var leash_radius := 700.0
## Wejście w stan walki musi być widoczne: tyle stoi i ostrzega po wykryciu gracza.
@export var alert_time := 0.8
## Ile przed końcem zapowiedzi kierunek ataku przestaje śledzić gracza.
@export var warn_aim_lock := 0.25
@export var attack_cooldown := 0.6
@export var arrive_distance := 6.0
## Stały identyfikator w świecie: pokonany przeciwnik zostaje pokonany po wczytaniu zapisu
## (GameState.collected) i nie odradza się po śmierci bohatera. Pusty = bez trwałego stanu.
@export var world_id: StringName = &""
## Zniknięcie po śmierci (placeholder do czasu T13/T19).
@export var fade_time := 1.2

var mode := Mode.WATCH
var home := Vector2.ZERO
var vulnerable := true

var _target: Node2D
var _target_combat: Combat
var _goal := Vector2.ZERO
var _has_goal := false
var _alert_left := 0.0
var _warn_left := 0.0
var _warn_kind: StringName = &""
var _aim := Vector2.DOWN
var _aim_locked := false
var _cooldown := 0.0
var _dash_velocity := Vector2.ZERO
var _dash_left := 0.0
var _stuck_time := 0.0

@onready var sprite: AssetSprite = $Sprite
@onready var combat: Combat = $Combat
@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	if world_id != &"" and GameState.is_collected(world_id):
		set_physics_process(false)
		queue_free()  # pokonany w zapisanym stanie świata
		return
	add_to_group(GROUP)
	home = global_position
	combat.connect(&"dash_requested", _on_dash_requested)
	combat.hit_received.connect(_on_hit_received)
	combat.hit_landed.connect(_on_hit_landed)
	combat.died.connect(_on_died)
	if not sprite.meta.is_empty():
		sprite.play_anim(&"idle", &"s")


func _physics_process(delta: float) -> void:
	step(delta)


## Jeden krok AI i ruchu. Wołany z _physics_process; testy wołają wprost.
func step(delta: float) -> void:
	if mode == Mode.DEAD:
		return
	if _dash_left > 0.0:
		_step_dash(delta)
		return
	if not ai_enabled:
		velocity = Vector2.ZERO
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if has_target():
		_observe_target(delta)
	if _leash_exceeded():
		_enter_return()
	if mode == Mode.ATTACK and combat.state == Combat.State.IDLE:
		_attack_finished()
	if combat.is_movement_locked():
		velocity = Vector2.ZERO
		return
	var moved := false
	match mode:
		Mode.WATCH:
			_step_watch()
		Mode.ALERT:
			_step_alert(delta)
		Mode.ENGAGE:
			moved = _engage(delta)
		Mode.WARN:
			_step_warn(delta)
		Mode.RETURN:
			moved = _step_return(delta)
	_update_animation(velocity if moved else Vector2.ZERO)


## Odległość do punktu w jednostkach świata (pion rozciągnięty o 1/ISO_Y).
func world_distance_to(point: Vector2) -> float:
	return Steering.to_world(point - global_position).length()


func home_distance() -> float:
	return world_distance_to(home)


func has_target() -> bool:
	return is_instance_valid(_target) and not _target_combat.is_dead()


func target_state() -> Combat.State:
	return _target_combat.state if _target_combat else Combat.State.IDLE


func target_distance() -> float:
	return world_distance_to(_target.global_position) if has_target() else INF


# --- punkty zaczepienia dla podklas ------------------------------------------------------------


## Ruch i wybór ataku w stanie ENGAGE; zwraca, czy postać się ruszyła.
func _engage(_delta: float) -> bool:
	return false


func _profile_of(_kind: StringName) -> AttackProfile:
	return null


func _warn_time_of(_kind: StringName) -> float:
	return 0.5


## Po zakończeniu ataku (stan walki wrócił do IDLE).
func _attack_finished() -> void:
	_cooldown = attack_cooldown
	_set_mode(Mode.ENGAGE)


## Co klatkę, gdy jest cel: podklasy zbierają historię zachowania gracza (np. czas gardy).
func _observe_target(_delta: float) -> void:
	pass


## Podklasa zgłasza trafienie lub zablokowanie swojego ataku (do reguł o uporczywej gardzie).
func _on_attack_result(_result: Hit.Result) -> void:
	pass


## Zaczyna zapowiedź ataku. Decyzja o rodzaju ataku zapada tu, przed zapowiedzią, nie w klatce
## uderzenia: gracz ma czas zareagować, a przeciwnik nie czyta jego przycisków w trakcie.
func _begin_attack(kind: StringName) -> void:
	_warn_kind = kind
	_warn_left = _warn_time_of(kind)
	_aim_locked = false
	_aim = _direction_to_target()
	_set_mode(Mode.WARN)
	telegraphed.emit(kind, _profile_of(kind).parryable)


# --- stany -------------------------------------------------------------------------------------


func _step_watch() -> void:
	if not _acquire_target():
		return
	if target_distance() <= aggro_radius:
		_alert_left = alert_time
		_set_mode(Mode.ALERT)


func _step_alert(delta: float) -> void:
	if not has_target():
		_set_mode(Mode.WATCH)
		return
	_alert_left -= delta
	if _alert_left > 0.0:
		return
	if target_distance() > aggro_radius * 1.5:
		_set_mode(Mode.WATCH)
	elif _can_activate():
		_set_mode(Mode.ENGAGE)


func _step_warn(delta: float) -> void:
	if combat.state != Combat.State.IDLE or not has_target():
		_set_mode(Mode.ENGAGE if has_target() else Mode.RETURN)
		return
	_warn_left -= delta
	if not _aim_locked:
		_aim = _direction_to_target()
		_aim_locked = _warn_left <= warn_aim_lock
	if _warn_left <= 0.0:
		_set_mode(Mode.ATTACK)
		combat.request_attack(_aim, _target, _profile_of(_warn_kind))


func _step_return(delta: float) -> bool:
	if home_distance() <= arrive_distance:
		_set_mode(Mode.WATCH)
		velocity = Vector2.ZERO
		return false
	var moved := _walk_to(home, return_speed, delta)
	if _stuck_time > 1.0:
		home = global_position  # droga zablokowana: nowe miejsce, bez przenikania przez geometrię
	return moved


func _enter_return() -> void:
	_has_goal = false
	_set_mode(Mode.RETURN)


func _leash_exceeded() -> bool:
	if mode in [Mode.WATCH, Mode.RETURN, Mode.DEAD]:
		return false
	return home_distance() > leash_radius and combat.state != Combat.State.ATTACK


func _can_activate() -> bool:
	return (
		is_in_group(ACTIVE_GROUP) or get_tree().get_nodes_in_group(ACTIVE_GROUP).size() < MAX_ACTIVE
	)


func _acquire_target() -> bool:
	if has_target():
		return true
	_target = get_tree().get_first_node_in_group(HERO_GROUP) as Node2D
	_target_combat = _target.get_node_or_null(^"Combat") as Combat if _target else null
	return has_target()


func _set_mode(new_mode: Mode) -> void:
	if new_mode == mode:
		return
	mode = new_mode
	var active := mode in [Mode.ENGAGE, Mode.WARN, Mode.ATTACK]
	if active and not is_in_group(ACTIVE_GROUP):
		add_to_group(ACTIVE_GROUP)
	elif not active and is_in_group(ACTIVE_GROUP):
		remove_from_group(ACTIVE_GROUP)
	_set_vulnerable(mode != Mode.RETURN and mode != Mode.DEAD)
	_refresh_tint()
	mode_changed.emit(mode)


## Poza walką (powrót na miejsce) przeciwnik nie przyjmuje obrażeń: Hurtbox znika dla trafień.
func _set_vulnerable(value: bool) -> void:
	vulnerable = value
	_hurtbox.set_deferred(&"monitorable", value)


func _refresh_tint() -> void:
	match mode:
		Mode.ALERT:
			sprite.modulate = TINT_ALERT
		Mode.WARN:
			sprite.modulate = TINT_PARRYABLE if _profile_of(_warn_kind).parryable else TINT_HEAVY
		Mode.RETURN:
			sprite.modulate = TINT_RETURNING
		_:
			sprite.modulate = Color.WHITE


# --- ruch --------------------------------------------------------------------------------------


## Idzie ku punktowi po siatce nawigacji; zwraca, czy się ruszył.
func _walk_to(point: Vector2, speed: float, delta: float) -> bool:
	if not _has_goal or point.distance_to(_goal) > 8.0:
		_goal = point
		_has_goal = true
		_agent.target_position = point
	var to_next := Steering.to_world(Steering.next_point(_agent, _goal) - global_position)
	var distance := to_next.length()
	if world_distance_to(point) <= arrive_distance or distance < 0.5:
		velocity = Vector2.ZERO
		_stuck_time = 0.0
		return false
	var step_speed := minf(speed, distance / delta)
	velocity = Steering.to_screen(to_next.normalized() * step_speed)
	var before := global_position
	Steering.move(self, velocity * delta)
	var travelled := Steering.to_world(global_position - before).length()
	_stuck_time = _stuck_time + delta if travelled < step_speed * delta * 0.2 else 0.0
	return true


func _direction_to_target() -> Vector2:
	if not has_target():
		return _aim
	return (_target.global_position - global_position).normalized()


func _update_animation(move: Vector2) -> void:
	if sprite.meta.is_empty() or combat.state != Combat.State.IDLE:
		return  # animację ataku, odskoku i ogłuszenia prowadzi walka
	var anim := &"walk" if move.length_squared() > 0.0 else &"idle"
	var dir := sprite.direction
	if move.length_squared() > 0.0:
		dir = AssetSprite.direction_from_vector(move)
	elif mode in [Mode.ALERT, Mode.ENGAGE, Mode.WARN] and has_target():
		dir = AssetSprite.direction_from_vector(_direction_to_target())
	if anim != sprite.animation or dir != sprite.direction:
		sprite.play_anim(anim, dir)


func _on_dash_requested(offset: Vector2, duration: float) -> void:
	_has_goal = false
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


# --- reakcje walki -----------------------------------------------------------------------------


func _on_hit_received(_result: Hit.Result, _damage: float) -> void:
	# Trafiony w spoczynku od razu staje do walki (z limitem aktywnych wrogów).
	if mode in [Mode.WATCH, Mode.ALERT] and _acquire_target() and _can_activate():
		_set_mode(Mode.ENGAGE)


func _on_hit_landed(_target_hit: Combat, result: Hit.Result, _damage: float, _crit: bool) -> void:
	_on_attack_result(result)


func _on_died() -> void:
	if world_id != &"":
		GameState.mark_collected(world_id)
	_set_mode(Mode.DEAD)
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred(&"disabled", true)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)
