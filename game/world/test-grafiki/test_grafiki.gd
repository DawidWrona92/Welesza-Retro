extends Node2D
## Scena testowa grafiki M1 (T09): kafle, rekwizyty, bohater i pies z prawdziwych assetów
## w kamerze gry. Ocena na bramce B1. Z argumentem `-- --demo` bohater sam przechodzi trasę
## (za drzewem, za wozem, walka z psem) do nagrania przez --write-movie.

## Punkty trasy pokazu: za pniem drzewa, za wozem, z powrotem na trakt.
const DEMO_ROUTE: Array[Vector2] = [Vector2(-300, -30), Vector2(430, -170), Vector2(60, 40)]

@export var demo_seconds := 26.0

@onready var _navigation: NavigationRegion2D = $NavigationRegion2D
@onready var _hero: Hero = $Hero
@onready var _dog: Enemy = $Pies


func _ready() -> void:
	_navigation.bake_navigation_polygon(false)
	if "--demo" in OS.get_cmdline_user_args():
		_run_demo()


func _run_demo() -> void:
	var tree := get_tree()
	await tree.create_timer(1.0).timeout
	for point in DEMO_ROUTE:
		_hero.move_to(point)
		await _until_stopped(5.0)
		await tree.create_timer(0.6).timeout
	var started := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - started) / 1000.0 < demo_seconds - 14.0:
		if is_instance_valid(_dog) and not _hero.dead and not _hero.is_moving():
			_hero.attack_target(_dog)
		await tree.create_timer(0.3).timeout
	tree.quit()


func _until_stopped(limit: float) -> void:
	var waited := 0.0
	while _hero.is_moving() and waited < limit:
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
