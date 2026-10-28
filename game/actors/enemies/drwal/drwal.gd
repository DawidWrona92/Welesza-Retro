class_name Drwal
extends Enemy
## ENM-drwal (docs/przeciwnicy.md): nie atakuje z zaskoczenia → ostrzega ruchem topora → broni
## wejścia → zwykłe cięcie w zasięgu → przy uporczywej gardzie gracza wybiera ciężkie rozłupanie →
## po ciosie wraca do gotowości. Decyzja o rozłupaniu opiera się na historii (zablokowane cięcia,
## czas gardy), a nie na przycisku gracza w klatce ataku.

const SLASH := &"slash"
const CLEAVE := &"cleave"

## „Cięcie z boku”: parowalny zamach toporem.
@export var slash: AttackProfile
## „Rozłupanie”: nieparowalne pionowe uderzenie; po nim długie odzyskiwanie.
@export var cleave: AttackProfile
@export var slash_warn := 0.5
@export var cleave_warn := 0.9
@export var attack_reach := 120.0
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


## Zwykłe cięcie w zasięgu; rozłupanie dopiero przy uporczywej gardzie.
static func choose_attack(distance: float, reach: float, persistent_guard: bool) -> StringName:
	if distance > reach:
		return &""
	return CLEAVE if persistent_guard else SLASH


static func is_persistent_guard(
	streak: int, guard_seconds: float, streak_limit: int, seconds_limit: float
) -> bool:
	return streak >= streak_limit or guard_seconds >= seconds_limit


func persistent_guard() -> bool:
	return is_persistent_guard(
		_blocked_streak, _guard_seconds, blocked_streak_limit, guard_seconds_limit
	)


func _profile_of(kind: StringName) -> AttackProfile:
	return cleave if kind == CLEAVE else slash


func _warn_time_of(kind: StringName) -> float:
	return cleave_warn if kind == CLEAVE else slash_warn


func _on_attack_result(result: Hit.Result) -> void:
	_blocked_streak = _blocked_streak + 1 if result == Hit.Result.BLOCKED else 0


func _begin_attack(kind: StringName) -> void:
	if kind == CLEAVE:
		_blocked_streak = 0
		_guard_seconds = 0.0
	super(kind)


func _engage(delta: float) -> bool:
	if not has_target():
		_set_mode(Mode.RETURN)
		return false
	var distance := target_distance()
	if _cooldown <= 0.0:
		var kind := choose_attack(distance, attack_reach, persistent_guard())
		if kind != &"":
			_begin_attack(kind)
			return false
	if distance <= defend_radius and distance > attack_reach * 0.8:
		return _walk_to(_target.global_position, walk_speed, delta)
	return false  # broni wejścia: stoi i patrzy


func _observe_target(delta: float) -> void:
	if target_state() == Combat.State.GUARD:
		_guard_seconds += delta
		_guard_idle = 0.0
		return
	_guard_idle += delta
	if _guard_idle >= guard_forget_time:
		_guard_seconds = 0.0
