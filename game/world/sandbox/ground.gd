extends Node2D
## Szare podłoże sandboksa: romb z siatką wzdłuż osi izometrii 2:1, żeby było widać ruch kamery.

const HALF := Vector2(1400.0, 700.0)
const STEP := 256.0
const FILL := Color(0.22, 0.22, 0.24)
const GRID := Color(0.3, 0.3, 0.33)


func _draw() -> void:
	draw_colored_polygon(
		PackedVector2Array(
			[Vector2(0, -HALF.y), Vector2(HALF.x, 0), Vector2(0, HALF.y), Vector2(-HALF.x, 0)]
		),
		FILL
	)
	var c := -HALF.x + STEP
	while c < HALF.x:
		# linie x - 2y = c oraz x + 2y = c, przycięte do rombu
		draw_line(
			Vector2((c - HALF.x) / 2.0, (-HALF.x - c) / 4.0),
			Vector2((c + HALF.x) / 2.0, (HALF.x - c) / 4.0),
			GRID
		)
		draw_line(
			Vector2((c - HALF.x) / 2.0, (c + HALF.x) / 4.0),
			Vector2((c + HALF.x) / 2.0, (c - HALF.x) / 4.0),
			GRID
		)
		c += STEP
