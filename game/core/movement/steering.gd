class_name Steering
extends RefCounted
## Wspólne narzędzia ruchu postaci (bohater i przeciwnicy): rzut 2:1, trasa z siatki nawigacji
## i ruch z jawnym krokiem czasu, który ślizga się po przeszkodzie zamiast się zatrzymywać.


## Wektor na ekranie -> wektor płaskiego świata (pion rozciągnięty z powrotem o ISO_Y).
static func to_world(screen_vector: Vector2) -> Vector2:
	return Vector2(screen_vector.x, screen_vector.y / AssetSprite.ISO_Y)


static func to_screen(world_vector: Vector2) -> Vector2:
	return Vector2(world_vector.x, world_vector.y * AssetSprite.ISO_Y)


## Następny punkt trasy; bez siatki nawigacji (pusta lub niezsynchronizowana) prosto do celu.
static func next_point(agent: NavigationAgent2D, goal: Vector2) -> Vector2:
	var map := agent.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map) == 0:
		return goal
	if NavigationServer2D.map_get_regions(map).is_empty():
		return goal
	return agent.get_next_path_position()


static func move(body: CharacterBody2D, motion: Vector2) -> void:
	var hit := body.move_and_collide(motion)
	if hit:
		body.move_and_collide(hit.get_remainder().slide(hit.get_normal()))
