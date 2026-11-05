class_name Block
extends StaticBody2D
## Prosta bryła do sandboksa: podstawa na ziemi (kolizja i dziura w nawigacji) wyciągnięta w górę.
## Początek układu leży w środku podstawy, więc sortowanie po Y działa jak dla postaci.

const NAV_GROUP := &"nav_obstacles"
const EDGE := Color(0.08, 0.08, 0.1)

@export var footprint := Vector2(128.0, 64.0)
## Prostokątna podstawa zamiast rombu (izometryczny kwadrat).
@export var rectangular := false
@export var height := 90.0
@export var color := Color(0.55, 0.55, 0.58)


func _ready() -> void:
	add_to_group(NAV_GROUP)
	var shape := CollisionPolygon2D.new()
	shape.polygon = _base()
	add_child(shape)


func _draw() -> void:
	var base := _base()
	var up := Vector2(0.0, -height)
	for i in base.size():
		var a := base[i]
		var b := base[(i + 1) % base.size()]
		var mid := (a + b) / 2.0
		if mid.y <= 0.0:
			continue
		var shade := 0.7 if mid.x < 0.0 else 0.85
		_quad([a, b, b + up, a + up], color * shade)
	var top := PackedVector2Array()
	for point in base:
		top.append(point + up)
	draw_colored_polygon(top, color)
	draw_polyline(top + PackedVector2Array([top[0]]), EDGE, 1.5)


func _base() -> PackedVector2Array:
	var h := footprint / 2.0
	if rectangular:
		return PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), h, Vector2(-h.x, h.y)])
	return PackedVector2Array(
		[Vector2(0, -h.y), Vector2(h.x, 0), Vector2(0, h.y), Vector2(-h.x, 0)]
	)


func _quad(points: Array[Vector2], fill: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), fill)
	draw_polyline(PackedVector2Array(points + [points[0]]), EDGE, 1.5)
