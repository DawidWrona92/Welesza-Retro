class_name Combat
extends Node
## Rdzeń walki wręcz (T11, docs/walka.md część II A i B): atak na kliknięcie, wiązanki w rytm,
## unik, garda i precyzyjna parada, przerwania, wytrzymałość, pancerz i krytyk.
##
## Czas walki wyznaczają zdarzenia animacji (hit_start, hit_end, combo_open, combo_close) z
## AssetSprite, a nie stałe w kodzie. Ruch postaci należy do właściciela: ten węzeł tylko prosi o
## odskok (dash_requested) i mówi, czy ruch jest zablokowany (is_movement_locked).
##
## Kontakt: dziecko „Hitbox” (Area2D) tego węzła jest sprawdzane w oknie trafienia; trafiane są
## obszary w grupie „hurtbox”, których rodzic ma dziecko „Combat”.

signal state_changed(state: State)
signal dash_requested(offset: Vector2, duration: float)
signal attack_started(link: int)
signal chain_ended(reason: StringName)
signal hit_landed(target: Combat, result: Hit.Result, damage: float, crit: bool)
signal hit_received(result: Hit.Result, damage: float)
signal health_changed(health: float, max_health: float)
signal died
## Użycie przedmiotu (opatrunek, nalewka): czynność w stanie USE. Efekt rozlicza właściciel
## dopiero po use_finished; przerwanie (ruch, unik, garda, trafienie) kończy się use_interrupted.
signal use_started(kind: StringName)
signal use_finished(kind: StringName)
signal use_interrupted(kind: StringName)

enum State { IDLE, ATTACK, DODGE, GUARD, STAGGER, RECOVER, USE }

@export_group("Atak")
@export var attack_animation: StringName = &"attack"
## Odległość, z której bohater zaczyna cios (jednostki świata, nie ekranu).
@export var attack_range := 70.0
## Odległość środka obszaru trafienia od postaci (jednostki świata).
@export var hit_reach := 50.0
@export var attack_cost := 12.0
@export var base_damage := 10.0
## Mnożnik obrażeń kolejnych ogniw wiązanki; długość łańcucha ogranicza max_chain.
@export var chain_multipliers: Array[float] = [1.0, 1.15, 1.3, 1.5]
## Stopień umiejętności: I i II = 3 ciosy, III = 4 ciosy.
@export_range(1, 4) var max_chain := 3
@export var base_crit_chance := 0.05
@export var finisher_crit_bonus := 0.25
@export var max_crit_chance := 0.6
@export var attack_parryable := true
@export var exhausted_attack_speed := 0.7

@export_group("Obrona")
@export var dodge_distance := 110.0
@export var dodge_duration := 0.25
@export var dodge_recovery := 0.15
@export var dodge_cost := 18.0
@export var exhausted_dodge_factor := 0.6
@export var exhausted_dodge_recovery := 0.35
@export var guard_half_angle_deg := 60.0
@export var guard_move_factor := 0.5
@export var parry_window := 0.18
@export var parry_cost_factor := 0.3
## Po opuszczeniu gardy okno parady wraca dopiero po tym czasie (bez parady z naciskania klawisza).
@export var parry_rearm := 0.4
@export var parry_stagger := 0.6
@export var guard_break_stagger := 0.8
@export var hit_stun := 0.35

@export_group("Zdrowie i pancerz")
@export var max_health := 100.0
@export var armor := 0.0
@export var max_armor_reduction := 0.8
@export var min_damage := 1.0

@export_group("Węzły")
@export var sprite: AssetSprite
## Wytrzymałość (core/stamina.gd, T10): consume(), is_exhausted(), pole guarding.
@export var stamina: Node
@export var rng_seed := 0

var state: State = State.IDLE
var health: float
var facing := Vector2.DOWN
var chain_link := 0
## Rodzaj przedmiotu używanego w stanie USE; pusty poza nim.
var using: StringName = &""

var _rng := RandomNumberGenerator.new()
var _state_time := 0.0
var _state_length := 0.0
var _attack_dir := Vector2.DOWN
var _contact_open := false
var _combo_open := false
var _chain_locked := false
var _next_queued := false
var _landed := false
var _chain_active := false
var _profile: AttackProfile
var _blocked_by_target := false
var _hit_this_link: Array[Combat] = []
var _guard_dir := Vector2.DOWN
var _guard_time := 0.0
var _parry_ready := true
var _since_guard_lowered := INF


func _init() -> void:
	health = max_health


func _ready() -> void:
	health = max_health
	if rng_seed != 0:
		_rng.seed = rng_seed
	if sprite:
		sprite.anim_event.connect(on_anim_event)
		var lead := sprite.lead_layer()
		if lead:
			lead.animation_finished.connect(on_anim_finished)


func _process(delta: float) -> void:
	tick(delta)


func _physics_process(_delta: float) -> void:
	place_hitbox()
	if state == State.ATTACK and _contact_open:
		_scan_hitbox()


## Ustawia „Hitbox” przed postacią w kierunku ciosu. Kształt jest liczony w jednostkach świata
## i spłaszczony do rzutu 2:1, więc zasięg w każdym kierunku jest taki sam.
func place_hitbox() -> void:
	var hitbox := get_node_or_null(^"Hitbox") as Area2D
	if hitbox == null:
		return
	var area := _profile.area_scale if _profile else 1.0
	if _profile and _profile.around_self:
		hitbox.global_position = _position()
	else:
		var reach := _to_world(_attack_dir).normalized() * hit_reach
		hitbox.global_position = _position() + _to_screen(reach)
	hitbox.rotation = 0.0
	hitbox.scale = Vector2(area, area * AssetSprite.ISO_Y)


## Postęp czasu stanów niezależnych od animacji (unik, ogłuszenie, garda).
func tick(delta: float) -> void:
	_state_time += delta
	_since_guard_lowered += delta
	if state == State.GUARD:
		_guard_time += delta
	if state in [State.DODGE, State.STAGGER, State.RECOVER] and _state_time >= _state_length:
		_set_state(State.IDLE)
	elif state == State.USE and _state_time >= _state_length:
		var kind := using
		using = &""  # ukończone, więc przejście do IDLE nie jest przerwaniem
		_set_state(State.IDLE)
		use_finished.emit(kind)


# --- polecenia od właściciela ---------------------------------------------------------------


## Bez profilu: cios bohatera z wiązanką. Z profilem: pojedynczy atak przeciwnika (bez wiązanki).
func request_attack(dir: Vector2, _target: Node2D = null, profile: AttackProfile = null) -> void:
	if is_dead():
		return
	match state:
		State.IDLE:
			if profile:
				_start_profile(profile, dir)
			else:
				_start_link(0, dir)
		State.ATTACK:
			if _profile == null:
				_on_attack_click()
		_:
			pass  # garda, unik, ogłuszenie: bez kolejkowania (po uniku stary atak nie wraca)


func request_dodge(dir: Vector2) -> void:
	if is_dead() or state == State.STAGGER or state == State.DODGE:
		return
	if state == State.GUARD:
		_lower_guard()
	_end_chain(&"dodge")
	var exhausted := _is_exhausted()
	_spend(dodge_cost)
	var world := _to_world(dir if dir.length_squared() > 0.0 else facing).normalized()
	var distance := dodge_distance * (exhausted_dodge_factor if exhausted else 1.0)
	var offset := _to_screen(world * distance)
	facing = offset.normalized()
	var recovery := exhausted_dodge_recovery if exhausted else dodge_recovery
	_set_state(State.DODGE, dodge_duration + recovery)
	_play(&"dodge")
	dash_requested.emit(offset, dodge_duration)


func set_guard(active: bool, dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead():
		return
	if dir.length_squared() > 0.0:
		_guard_dir = dir.normalized()
	if active and state in [State.IDLE, State.ATTACK, State.USE]:
		_end_chain(&"guard")
		_guard_time = 0.0
		if _since_guard_lowered >= parry_rearm:
			_parry_ready = true
		_set_state(State.GUARD)
		_play(&"guard")
		if stamina:
			stamina.set(&"guarding", true)
	elif not active and state == State.GUARD:
		_lower_guard()
		_set_state(State.IDLE)


func is_movement_locked() -> bool:
	return state in [State.ATTACK, State.DODGE, State.STAGGER, State.RECOVER, State.USE]


func move_speed_factor() -> float:
	return guard_move_factor if state == State.GUARD else 1.0


func is_dead() -> bool:
	return health <= 0.0


# --- zdarzenia animacji --------------------------------------------------------------------


func on_anim_event(event_name: StringName) -> void:
	if state != State.ATTACK:
		return
	match event_name:
		&"hit_start":
			_contact_open = true
			if _profile and _profile.lunge_distance > 0.0:
				var lunge := _to_world(_attack_dir).normalized() * _profile.lunge_distance
				dash_requested.emit(_to_screen(lunge), _profile.lunge_duration)
		&"hit_end":
			# Okno może trwać krócej niż krok fizyki: sprawdź kontakt choć raz przed zamknięciem.
			if _contact_open:
				_scan_hitbox()
			_contact_open = false
			if not _landed or _blocked_by_target:
				_end_chain(&"blocked" if _blocked_by_target else &"miss")
		&"combo_open":
			_combo_open = true
		&"combo_close":
			_combo_open = false


func on_anim_finished() -> void:
	if state != State.ATTACK:
		return
	if _profile:
		var rest := _profile.recovery + (0.0 if _landed else _profile.miss_recovery)
		if rest > 0.0:
			_set_state(State.RECOVER, rest)
		else:
			_set_state(State.IDLE)
		return
	if _next_queued:
		_start_link(chain_link + 1, _attack_dir)
	else:
		_end_chain(&"finished")
		_set_state(State.IDLE)


# --- trafienia -----------------------------------------------------------------------------


## Zgłasza kontakt broni z celem w otwartym oknie trafienia; każdy cel raz na cios.
func register_contact(target: Combat) -> void:
	if state != State.ATTACK or not _contact_open or target == self or target in _hit_this_link:
		return
	_hit_this_link.append(target)
	var hit := Hit.new()
	hit.attacker = self
	hit.origin = _position()
	hit.damage = base_damage * _multiplier(chain_link)
	hit.parryable = attack_parryable
	hit.crit_chance = base_crit_chance + (finisher_crit_bonus if chain_link >= 3 else 0.0)
	if _profile:
		hit.damage = _profile.damage
		hit.parryable = _profile.parryable
		hit.guard_cost = _profile.guard_cost
		hit.crit_chance = base_crit_chance
	hit.crit_chance = minf(hit.crit_chance, max_crit_chance)
	var outcome := target.receive_hit(hit)
	_landed = true
	if outcome["result"] != Hit.Result.HIT:
		_blocked_by_target = true
	hit_landed.emit(target, outcome["result"], outcome["damage"], outcome["crit"])


func receive_hit(hit: Hit) -> Dictionary:
	if state == State.GUARD and hit.parryable and _in_guard_sector(hit.origin):
		return _defend(hit)
	var crit := _rng.randf() < hit.crit_chance
	var reduction := clampf(armor - hit.armor_pierce, 0.0, max_armor_reduction)
	var amount := maxf(min_damage, hit.damage * (2.0 if crit else 1.0) * (1.0 - reduction))
	_take_damage(amount)
	interrupt_use()
	if hit.interrupts and not is_dead():
		stagger(hit_stun)
	hit_received.emit(Hit.Result.HIT, amount)
	return {"result": Hit.Result.HIT, "damage": amount, "crit": crit}


## Zaczyna użycie przedmiotu na `duration` sekund; tylko ze spokoju (IDLE). Zwraca, czy się zaczęło.
func use_item(kind: StringName, duration: float) -> bool:
	if is_dead() or state != State.IDLE:
		return false
	_set_state(State.USE, duration)
	using = kind
	use_started.emit(kind)
	return true


## Przerywa używanie przedmiotu (ruch właściciela); bez efektu poza stanem USE.
func interrupt_use() -> void:
	if state == State.USE:
		_set_state(State.IDLE)


func heal(amount: float) -> void:
	if is_dead():
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


func stagger(duration: float) -> void:
	if is_dead():
		return
	_end_chain(&"staggered")
	if state == State.GUARD:
		_lower_guard()
	_set_state(State.STAGGER, duration)
	_play(&"hit")


# --- wnętrze -------------------------------------------------------------------------------


func _start_link(link: int, dir: Vector2) -> void:
	if dir.length_squared() > 0.0:
		_attack_dir = dir.normalized()
		facing = _attack_dir
	if link == 0:
		_chain_locked = false
	_chain_active = true
	chain_link = link
	_contact_open = false
	_combo_open = false
	_next_queued = false
	_landed = false
	_blocked_by_target = false
	_hit_this_link.clear()
	var exhausted := _is_exhausted()
	_spend(attack_cost)
	_set_state(State.ATTACK)
	_play(attack_animation, exhausted_attack_speed if exhausted else 1.0)
	attack_started.emit(link)


func _start_profile(profile: AttackProfile, dir: Vector2) -> void:
	if dir.length_squared() > 0.0:
		_attack_dir = dir.normalized()
		facing = _attack_dir
	_landed = false
	_blocked_by_target = false
	_hit_this_link.clear()
	_spend(profile.cost)
	_set_state(State.ATTACK)
	_profile = profile
	_play(profile.animation)
	attack_started.emit(0)


func _on_attack_click() -> void:
	if _next_queued:
		return  # bez długiej kolejki ataków
	var can_continue := chain_link + 1 < max_chain and _landed and not _blocked_by_target
	if _combo_open and not _chain_locked and can_continue:
		_next_queued = true
	else:
		# kliknięcie poza oknem rytmu zamyka przedłużenie tej wiązanki, nie zatrzymuje ciosu
		_chain_locked = true


func _end_chain(reason: StringName) -> void:
	if not _chain_active:
		return
	_chain_active = false
	_contact_open = false
	_combo_open = false
	_next_queued = false
	_chain_locked = true
	chain_ended.emit(reason)


func _defend(hit: Hit) -> Dictionary:
	var parried := _parry_ready and _guard_time <= parry_window
	if parried:
		_parry_ready = false
		_spend(hit.guard_cost * parry_cost_factor)
		if hit.attacker:
			hit.attacker.stagger(parry_stagger)
		hit_received.emit(Hit.Result.PARRIED, 0.0)
		return {"result": Hit.Result.PARRIED, "damage": 0.0, "crit": false}
	_spend(hit.guard_cost)
	hit_received.emit(Hit.Result.BLOCKED, 0.0)
	if _is_exhausted():
		stagger(guard_break_stagger)  # wyczerpana garda pęka
	return {"result": Hit.Result.BLOCKED, "damage": 0.0, "crit": false}


func _in_guard_sector(origin: Vector2) -> bool:
	var to_attacker := _to_world(origin - _position())
	if to_attacker.length_squared() == 0.0:
		return true
	var angle := absf(_to_world(_guard_dir).angle_to(to_attacker))
	return rad_to_deg(angle) <= guard_half_angle_deg


func _lower_guard() -> void:
	_since_guard_lowered = 0.0
	if stamina:
		stamina.set(&"guarding", false)


func _take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	if is_dead():
		_end_chain(&"died")
		_set_state(State.IDLE)
		died.emit()


func _scan_hitbox() -> void:
	var hitbox := get_node_or_null(^"Hitbox") as Area2D
	if hitbox == null:
		return
	for area in hitbox.get_overlapping_areas():
		if area.is_in_group(&"hurtbox"):
			var target := area.get_parent().get_node_or_null(^"Combat") as Combat
			if target:
				register_contact(target)


func _set_state(new_state: State, length: float = 0.0) -> void:
	if state == State.USE and using != &"":
		var interrupted := using
		using = &""
		use_interrupted.emit(interrupted)
	if new_state != State.ATTACK:
		_profile = null
		_contact_open = false
	state = new_state
	_state_time = 0.0
	_state_length = length
	state_changed.emit(new_state)


func _play(anim: StringName, speed: float = 1.0) -> void:
	if sprite == null or sprite.meta.is_empty():
		return
	var dir := AssetSprite.direction_from_vector(facing)
	var lead := sprite.lead_layer()
	if lead == null or not lead.sprite_frames.has_animation("%s_%s" % [anim, dir]):
		return  # asset bez tej animacji (np. unik w teście grafiki): stan walki działa dalej
	sprite.play_anim(anim, dir)
	lead.speed_scale = speed


func _spend(amount: float) -> void:
	if stamina:
		stamina.call(&"consume", amount)


func _is_exhausted() -> bool:
	return stamina != null and bool(stamina.call(&"is_exhausted"))


func _multiplier(link: int) -> float:
	if chain_multipliers.is_empty():
		return 1.0
	return chain_multipliers[mini(link, chain_multipliers.size() - 1)]


func _position() -> Vector2:
	var actor := get_parent() as Node2D
	return actor.global_position if actor else Vector2.ZERO


static func _to_world(screen: Vector2) -> Vector2:
	return Vector2(screen.x, screen.y / AssetSprite.ISO_Y)


static func _to_screen(world: Vector2) -> Vector2:
	return Vector2(world.x, world.y * AssetSprite.ISO_Y)
