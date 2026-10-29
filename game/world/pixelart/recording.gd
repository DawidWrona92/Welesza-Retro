extends "res://world/pixelart/pixelart.gd"
## Powtarzalny pokaz w prawdziwej scenie: osiem kierunków ruchu, potem walka z AI.

var _walk_directions: Dictionary = {}
var _review_label: Label


func _ready() -> void:
	super._ready()
	# Nagranie ma osobną scenę, więc nie zmienia sterowania ani startu zwykłej gry.
	dog.set_physics_process(false)
	dog.hide()
	var camera: Camera2D = hero.get_node("Camera2D")
	camera.zoom = Vector2(2.0, 2.0)
	camera.position_smoothing_enabled = false
	camera.offset = Vector2(0, -80)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	_review_label = _text(overlay, "Przegląd animacji — rzeczywista scena gry, tempo 1×", 24)
	_review_label.position = Vector2(450, 135)
	_run_review.call_deferred()


func _run_review() -> void:
	await get_tree().create_timer(1.0).timeout
	for index in 8:
		var angle := float(index) * TAU / 8.0
		var offset := Steering.to_screen(Vector2(-sin(angle), cos(angle)) * 150.0)
		var target := hero.global_position + offset
		var direction := AssetSprite.direction_from_vector(offset)
		_review_label.text = "Chód bohatera — %s — tempo 1×" % String(direction).to_upper()
		hero.move_to(target)
		var deadline := _elapsed + 4.0
		while hero.global_position.distance_to(target) > 8.0 and _elapsed < deadline:
			await get_tree().physics_frame
			if hero.sprite.animation == &"walk":
				_walk_directions[hero.sprite.direction] = true
		if hero.global_position.distance_to(target) > 8.0:
			push_error("Pokaz chodu nie osiągnął celu: %s" % direction)
			get_tree().quit(1)
			return
		await get_tree().create_timer(0.4).timeout
	print("PIXEL_WALK directions=%d" % _walk_directions.size())
	if _walk_directions.size() != 8:
		push_error("Nagranie nie pokazało ośmiu kierunków chodu")
		get_tree().quit(1)
		return
	_review_label.text = "Walka z psem — ruch AI i rzeczywiste trafienia — tempo 1×"
	hero.move_to(hero.global_position)
	hero.position = Vector2(-100, 100)
	dog.position = Vector2(130, 25)
	dog.show()
	await get_tree().create_timer(1.0).timeout
	_elapsed = 0.0
	dog.set_physics_process(true)
	await _run_demo()
