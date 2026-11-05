class_name Strzelec
extends Enemy
## Testowy strzelec do sprawdzania wspólnego pocisku (Łucznika i Powrotnika jeszcze nie ma):
## stoi, po wykryciu gracza ostrzega i strzela po prostej, bez naprowadzania.

const SHOT := &"shot"

## Profil z `projectile`: strzał leci na hit_start po torze ustalonym przy rozpoczęciu ataku.
@export var shot: AttackProfile
@export var shot_warn := 0.9
## Odległość (jednostki świata), z której strzela.
@export var shoot_range := 520.0


func _profile_of(_kind: StringName) -> AttackProfile:
	return shot


func _warn_time_of(_kind: StringName) -> float:
	return shot_warn


func _engage(_delta: float) -> bool:
	if not has_target():
		_set_mode(Mode.RETURN)
		return false
	if _cooldown <= 0.0 and target_distance() <= shoot_range:
		_begin_attack(SHOT)
	return false
