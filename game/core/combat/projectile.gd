class_name Projectile
extends Area2D
## Wspólny pocisk przeciwników (strzał Łucznika, rzut Powrotnika; docs/przeciwnicy.md): leci prosto
## po torze ustalonym w chwili wystrzału, bez naprowadzania, i znika przy przeszkodzie, trafieniu
## albo po przebyciu zasięgu. Mija postacie przeciwników (nie ma ognia przyjacielskiego).
##
## Trafienie idzie przez Combat.receive_hit: nieparowalne, ale garda w dobrą stronę je blokuje
## (Hit.blockable); kąt gardy liczony od pozycji pocisku. Tor leży na płaszczyźnie ziemi jak
## Hitbox i Hurtbox, a rysunek unosi się o visual_height, żeby pocisk leciał na wysokości tułowia.

const HURTBOX_GROUP := &"hurtbox"

@export var speed := 520.0
## Zasięg w jednostkach świata, po którym pocisk znika.
@export var max_range := 700.0
@export var damage := 12.0
@export var guard_cost := 12.0
@export var visual_height := 50.0
@export var color := Color(0.85, 0.8, 0.6)

var shooter: Combat

var _world_direction := Vector2.RIGHT
var _travelled := 0.0
var _spent := false


## Tworzy pocisk w `parent` i wypuszcza z `from` w kierunku `direction` (wektor na ekranie).
static func launch(
	scene: PackedScene, parent: Node, from_combat: Combat, from: Vector2, direction: Vector2
) -> Projectile:
	var projectile: Projectile = scene.instantiate()
	projectile.shooter = from_combat
	projectile.set_direction(direction)
	parent.add_child(projectile)
	projectile.global_position = from
	return projectile


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	step(delta)


## Jeden krok lotu po stałym torze (rzut 2:1); wołany z _physics_process i z testów.
func step(delta: float) -> void:
	var distance := minf(speed * delta, max_range - _travelled)
	global_position += Steering.to_screen(_world_direction * distance)
	_travelled += distance
	if _travelled >= max_range:
		_finish()


## Kierunek ustalany raz, przy wystrzale; potem tor się nie zmienia.
func set_direction(screen_direction: Vector2) -> void:
	_world_direction = Steering.to_world(screen_direction).normalized()
	if _world_direction == Vector2.ZERO:
		_world_direction = Vector2.RIGHT
	queue_redraw()


func world_direction() -> Vector2:
	return _world_direction


func _draw() -> void:
	var along := Steering.to_screen(_world_direction).normalized() * 16.0
	var lift := Vector2(0.0, -visual_height)
	draw_line(lift - along, lift + along, color, 3.0)
	draw_circle(lift + along, 3.0, color)
	draw_circle(Vector2.ZERO, 3.0, Color(0.0, 0.0, 0.0, 0.35))


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area.is_in_group(HURTBOX_GROUP):
		return
	var target := area.get_parent().get_node_or_null(^"Combat") as Combat
	if target == null or target == shooter:
		return
	var hit := Hit.new()
	hit.attacker = shooter
	hit.origin = global_position
	hit.damage = damage
	hit.parryable = false
	hit.guard_cost = guard_cost
	hit.crit_chance = 0.0
	hit.blockable = true
	_finish()
	target.receive_hit(hit)


func _on_body_entered(_body: Node2D) -> void:
	_finish()


func _finish() -> void:
	if _spent:
		return
	_spent = true
	set_deferred(&"monitoring", false)
	queue_free()
