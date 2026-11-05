class_name Dog
extends Enemy
## ENM-zdziczaly-pies (docs/przeciwnicy.md): pilnuje miejsca → ostrzega → obiega cel po dostępnej
## stronie → atakuje po odsłonięciu → po chybieniu odzyskuje równowagę → ściga do granicy pościgu.
## Nie atakuje z zaskoczenia i nie rzuca się pod ostrze bez przerwy: czeka, aż cel się odsłoni.

const LEAP := &"leap"
const BITE := &"bite"
const CLOCKWISE := 1
const COUNTERCLOCKWISE := -1

## „Skok do gardła”: nieparowalny, odskok po stałym torze, długie odzyskiwanie po chybieniu.
@export var leap: AttackProfile
## „Kłapnięcie”: krótki atak blisko celu, nieparowalny.
@export var bite: AttackProfile
@export var leap_warn := 0.7
@export var bite_warn := 0.35
@export var run_speed := 260.0
## Promień, po którym pies obiega cel (jednostki świata); mieści się w zasięgu skoku.
@export var circle_radius := 170.0
## Zakres odległości, z których pies skacze.
@export var leap_min := 120.0
@export var leap_max := 210.0
@export var bite_range := 90.0
## Tyle musi obiegać cel, zanim skoczy; kłapnięcie nie czeka.
@export var circle_min_time := 1.2
## Kąt (rad), o jaki punkt obiegu wyprzedza psa.
@export var circle_lead := 0.4

var _side := CLOCKWISE
var _circle_time := 0.0


## Który atak pasuje do odległości: kłapnięcie z bliska, skok z dystansu, inaczej nic.
static func choose_attack(
	distance: float, bite_max: float, leap_from: float, leap_to: float
) -> StringName:
	if distance <= bite_max:
		return BITE
	if distance >= leap_from and distance <= leap_to:
		return LEAP
	return &""


## Pies nie rzuca się na cel, który właśnie zamierza się albo robi unik (inicjatywa u celu).
static func target_exposed(state: Combat.State) -> bool:
	return state != Combat.State.ATTACK and state != Combat.State.DODGE


## Obieganie po dostępnej stronie: zostaje przy obecnej, chyba że jest zablokowana.
static func pick_side(current: int, clockwise_blocked: bool, counter_blocked: bool) -> int:
	var current_blocked := clockwise_blocked if current == CLOCKWISE else counter_blocked
	if not current_blocked:
		return current
	var other_blocked := counter_blocked if current == CLOCKWISE else clockwise_blocked
	return current if other_blocked else -current


func _profile_of(kind: StringName) -> AttackProfile:
	return leap if kind == LEAP else bite


func _warn_time_of(kind: StringName) -> float:
	return leap_warn if kind == LEAP else bite_warn


func _attack_finished() -> void:
	_circle_time = 0.0
	super()


func _engage(delta: float) -> bool:
	if not has_target():
		_set_mode(Mode.RETURN)
		return false
	var distance := target_distance()
	if _cooldown <= 0.0 and target_exposed(target_state()):
		var kind := choose_attack(distance, bite_range, leap_min, leap_max)
		if kind == BITE or (kind == LEAP and _circle_time >= circle_min_time):
			_begin_attack(kind)
			return false
	if distance > circle_radius + 60.0:
		return _walk_to(_target.global_position, run_speed, delta)  # ściga
	_circle_time += delta
	return _circle(delta)


func _circle(delta: float) -> bool:
	var radial := Steering.to_world(global_position - _target.global_position)
	if radial.length() < 1.0:
		radial = Vector2.RIGHT
	var radial_dir := radial.normalized()
	_side = pick_side(
		_side,
		_path_blocked(radial_dir.rotated(circle_lead * CLOCKWISE)),
		_path_blocked(radial_dir.rotated(circle_lead * COUNTERCLOCKWISE))
	)
	var goal_dir := radial_dir.rotated(circle_lead * _side)
	var goal := _target.global_position + Steering.to_screen(goal_dir * circle_radius)
	return _walk_to(goal, run_speed, delta)


## Czy droga do punktu okręgu (kierunek od celu) jest zasłonięta geometrią świata.
func _path_blocked(dir_from_target: Vector2) -> bool:
	var point := _target.global_position + Steering.to_screen(dir_from_target * circle_radius)
	var query := PhysicsRayQueryParameters2D.create(global_position, point, Hero.LAYER_WORLD)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()
