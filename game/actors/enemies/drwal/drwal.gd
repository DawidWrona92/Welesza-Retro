class_name Drwal
extends Enemy
## ENM-drwal (docs/przeciwnicy.md): nie atakuje z zaskoczenia → ostrzega ruchem topora → broni
## wejścia → zwykłe cięcie w zasięgu → przy uporczywej gardzie gracza wybiera ciężkie rozłupanie →
## po ciosie wraca do gotowości; wobec gracza krążącego blisko, rzadko i nigdy dwa razy z rzędu,
## robi atak obrotowy. Decyzja o rozłupaniu opiera się na historii (zablokowane cięcia,
## czas gardy), a nie na przycisku gracza w klatce ataku.

const SLASH := &"slash"
const CLEAVE := &"cleave"
const SPIN := &"spin"

## „Cięcie z boku”: parowalny zamach toporem.
@export var slash: AttackProfile
## „Rozłupanie”: nieparowalne pionowe uderzenie; po nim długie odzyskiwanie.
@export var cleave: AttackProfile
## „Atak obrotowy”: pełny obrót wokół siebie (Hitbox wokół Drwala), parowalny; po nim długie
## odzyskiwanie, w którym Drwal jest odsłonięty.
@export var spin: AttackProfile
@export var slash_warn := 0.5
@export var cleave_warn := 0.9
@export var spin_warn := 1.1
@export var attack_reach := 120.0
## Obrót tylko wobec gracza bliżej niż to.
@export var spin_range := 150.0
## Gracz „krąży”, gdy w tym zasięgu nabije taki kąt (rad) obiegu wokół Drwala...
@export var circling_angle := 1.5
## ...a nabity kąt opada o tyle rad/s, gdy gracz przestaje krążyć.
@export var circling_decay := 0.4
## Obrót jest rzadki: najwcześniej po tylu sekundach od poprzedniego (i od początku walki).
@export var spin_cooldown := 8.0
## Gdy gracz wejdzie w ten promień (poza zasięgiem ciosu), Drwal naciska; dalej tylko pilnuje.
@export var defend_radius := 300.0
## Uporczywa garda: tyle zablokowanych cięć z rzędu albo tyle sekund gardy.
@export var blocked_streak_limit := 2
@export var guard_seconds_limit := 4.0
## Po tylu sekundach bez gardy czas gardy jest zapominany.
@export var guard_forget_time := 1.0

var _blocked_streak := 0
var _guard_seconds := 0.0
var _guard_idle := 0.0
var _swept := 0.0
var _last_angle := NAN
var _spin_wait := 0.0
var _last_kind: StringName = &""


## Uporczywa garda → rozłupanie; krążący gracz blisko, gdy obrót dozwolony → obrót; inaczej
## zwykłe cięcie w zasięgu.
static func choose_attack(
	distance: float, reach: float, persistent_guard: bool, spin_ok := false, spin_reach := 0.0
) -> StringName:
	if persistent_guard and distance <= reach:
		return CLEAVE
	if spin_ok and distance <= spin_reach:
		return SPIN
	return SLASH if distance <= reach else &""


## Obrót wymaga krążącego gracza, minionego odstępu i innego poprzedniego ataku.
static func spin_allowed(circling: bool, wait_left: float, last_kind: StringName) -> bool:
	return circling and wait_left <= 0.0 and last_kind != SPIN


## Kąt obiegu nabijany tylko z bliska i opadający, gdy gracz przestaje krążyć.
static func update_swept(
	swept: float, angle_change: float, delta: float, decay: float, near: bool
) -> float:
	if not near:
		return 0.0
	return maxf(0.0, swept + absf(angle_change) - decay * delta)


static func is_persistent_guard(
	streak: int, guard_seconds: float, streak_limit: int, seconds_limit: float
) -> bool:
	return streak >= streak_limit or guard_seconds >= seconds_limit


func persistent_guard() -> bool:
	return is_persistent_guard(
		_blocked_streak, _guard_seconds, blocked_streak_limit, guard_seconds_limit
	)


func circling() -> bool:
	return _swept >= circling_angle


func _profile_of(kind: StringName) -> AttackProfile:
	match kind:
		CLEAVE:
			return cleave
		SPIN:
			return spin
		_:
			return slash


func _warn_time_of(kind: StringName) -> float:
	match kind:
		CLEAVE:
			return cleave_warn
		SPIN:
			return spin_warn
		_:
			return slash_warn


func _on_attack_result(result: Hit.Result) -> void:
	_blocked_streak = _blocked_streak + 1 if result == Hit.Result.BLOCKED else 0


func _begin_attack(kind: StringName) -> void:
	if kind == CLEAVE:
		_blocked_streak = 0
		_guard_seconds = 0.0
	if kind == SPIN:
		_spin_wait = spin_cooldown
		_swept = 0.0
	_last_kind = kind
	super(kind)


func _engage(delta: float) -> bool:
	if not has_target():
		_set_mode(Mode.RETURN)
		return false
	var distance := target_distance()
	if _cooldown <= 0.0:
		var spin_ok := spin_allowed(circling(), _spin_wait, _last_kind)
		var kind := choose_attack(distance, attack_reach, persistent_guard(), spin_ok, spin_range)
		if kind != &"":
			_begin_attack(kind)
			return false
	if distance <= defend_radius and distance > attack_reach * 0.8:
		return _walk_to(_target.global_position, walk_speed, delta)
	return false  # broni wejścia: stoi i patrzy


func _observe_target(delta: float) -> void:
	_spin_wait = maxf(0.0, _spin_wait - delta)
	var angle := Steering.to_world(_target.global_position - global_position).angle()
	var change := 0.0 if is_nan(_last_angle) else angle_difference(_last_angle, angle)
	_last_angle = angle
	_swept = update_swept(_swept, change, delta, circling_decay, target_distance() <= spin_range)
	if target_state() == Combat.State.GUARD:
		_guard_seconds += delta
		_guard_idle = 0.0
		return
	_guard_idle += delta
	if _guard_idle >= guard_forget_time:
		_guard_seconds = 0.0
