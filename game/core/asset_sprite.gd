class_name AssetSprite
extends Node2D
## Postać zbudowana przez tools/sprite_pipeline.py: jedna lub kilka zsynchronizowanych warstw
## (korpus, głowa, broń, tarcza) z kotwicą w punkcie węzła i zdarzeniami animacji z meta.json.
## Zdarzenia (hit_start, combo_open itd.) wyznaczają okna walki zamiast stałych czasów w kodzie.

signal anim_event(event_name: StringName)

const DIRECTIONS: Array[StringName] = [&"s", &"sw", &"w", &"nw", &"n", &"ne", &"e", &"se"]
## Rzut izometryczny 2:1: ruch o 1 w pionie ekranu odpowiada 2 w świecie.
const ISO_Y := 0.5
## Kierunki, w których broń i tarcza są za ciałem.
const BACK_FACING: Array[StringName] = [&"nw", &"n", &"ne"]
const BEHIND_LAYERS: Array[StringName] = [&"weapon", &"shield"]
## Zastępstwo brakującej animacji nieruchomą klatką 0 innej (pies nie ma jeszcze bezczynności).
const STILL_FALLBACK := {&"idle": &"walk"}

@export var asset_id: String
## Opcjonalna długość pełnego cyklu chodu w świecie; 0 zachowuje dotychczasowe tempo.
@export var walk_cycle_distance := 0.0

var meta: Dictionary = {}
var animation: StringName = &"idle"
var direction: StringName = &"s"
var _layers: Dictionary[StringName, AnimatedSprite2D] = {}
var _events: Dictionary = {}
## Ostatnia klatka, której zdarzenia już wysłano; przy przeskoku klatek wysyłamy też pominięte.
var _last_frame := -1
var _changing_walk_direction := false


func _ready() -> void:
	if not asset_id.is_empty():
		load_asset(asset_id)


func load_asset(id: String) -> Error:
	var meta_path := "res://assets/%s/meta.json" % id
	if not FileAccess.file_exists(meta_path):
		push_error("Brak zbudowanego assetu %s; uruchom tools/sprite_pipeline.py" % id)
		return ERR_FILE_NOT_FOUND
	meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	walk_cycle_distance = float(meta.get("walk_cycle_distance", walk_cycle_distance))
	asset_id = id
	_events = build_event_table(meta.get("animations", {}))
	for child in _layers.values():
		child.queue_free()
	_layers.clear()
	var cell := Vector2(meta["cell"][0], meta["cell"][1])
	var anchor := Vector2(meta["anchor"][0], meta["anchor"][1])
	for layer: String in meta["layers"]:
		var file := "sprite_frames.tres" if layer == "full" else "sprite_frames_%s.tres" % layer
		var sprite := AnimatedSprite2D.new()
		sprite.name = layer
		sprite.sprite_frames = load("res://assets/%s/%s" % [id, file])
		sprite.centered = true
		sprite.offset = cell / 2.0 - anchor
		add_child(sprite)
		_layers[StringName(layer)] = sprite
	var lead := lead_layer()
	if lead:
		lead.frame_changed.connect(_on_frame_changed)
	return OK


func play_anim(anim: StringName, dir: StringName = direction) -> void:
	var lead_before := lead_layer()
	var preserve_walk := (
		walk_cycle_distance > 0.0
		and animation == &"walk"
		and anim == &"walk"
		and lead_before != null
	)
	var previous_frame := lead_before.frame if preserve_walk else 0
	var previous_progress := lead_before.frame_progress if preserve_walk else 0.0
	animation = anim
	direction = dir
	var source := anim
	var still := false
	if not has_anim(anim, dir) and has_anim(STILL_FALLBACK.get(anim, &""), dir):
		source = STILL_FALLBACK[anim]
		still = true
	var name := StringName("%s_%s" % [source, dir])
	_changing_walk_direction = preserve_walk
	for layer: StringName in _layers:
		var sprite := _layers[layer]
		sprite.z_index = -1 if layer in BEHIND_LAYERS and dir in BACK_FACING else 0
		sprite.play(name)
		sprite.speed_scale = 1.0
		if preserve_walk:
			sprite.set_frame_and_progress(previous_frame, previous_progress)
		if still:
			sprite.pause()
			sprite.frame = 0
	_changing_walk_direction = false
	if preserve_walk:
		_last_frame = previous_frame
		return
	_last_frame = -1
	_on_frame_changed()


## Tempo zależy od drogi, nie od samego stanu „idzie”; sprint nie ślizga stóp przy 12 fps.
func match_walk_speed(screen_velocity: Vector2) -> void:
	if walk_cycle_distance <= 0.0 or animation != &"walk":
		return
	var spec: Dictionary = meta["animations"]["walk"]
	var nominal_speed := walk_cycle_distance * float(spec["fps"]) / float(spec["frames"])
	var world_speed := Vector2(screen_velocity.x, screen_velocity.y / ISO_Y).length()
	for layer: AnimatedSprite2D in _layers.values():
		layer.speed_scale = world_speed / nominal_speed


func face(screen_vector: Vector2) -> void:
	if screen_vector.length_squared() > 0.0:
		play_anim(animation, direction_from_vector(screen_vector))


func has_anim(anim: StringName, dir: StringName = direction) -> bool:
	var lead := lead_layer()
	if lead == null or lead.sprite_frames == null:
		return false
	return lead.sprite_frames.has_animation("%s_%s" % [anim, dir])


func lead_layer() -> AnimatedSprite2D:
	for layer: StringName in [&"full", &"body"]:
		if _layers.has(layer):
			return _layers[layer]
	return null if _layers.is_empty() else _layers.values()[0]


func _on_frame_changed() -> void:
	if _changing_walk_direction:
		return
	var lead := lead_layer()
	if lead == null:
		return
	# Przy długiej klatce AnimatedSprite2D przeskakuje klatki; ich zdarzenia (np. hit_start)
	# nie mogą zginąć, bo cios by nie trafił. Wysyłamy je po kolei, także przez zawinięcie pętli.
	var frame := lead.frame
	var first := _last_frame + 1
	if frame < first:
		for skipped in range(first, lead.sprite_frames.get_frame_count(lead.animation)):
			_emit_frame(skipped)
		first = 0
	for passed in range(first, frame + 1):
		_emit_frame(passed)
	_last_frame = frame


func _emit_frame(frame: int) -> void:
	for event_name: StringName in events_at(animation, frame):
		anim_event.emit(event_name)
		Events.anim_event.emit(self, event_name)


func events_at(anim: StringName, frame: int) -> Array:
	return _events.get(anim, {}).get(frame, [])


## Wektor na ekranie -> jeden z 8 kierunków (s = ku kamerze, dalej zgodnie z ruchem wskazówek).
static func direction_from_vector(screen_vector: Vector2) -> StringName:
	var world := Vector2(screen_vector.x, screen_vector.y / ISO_Y)
	var angle := fposmod(rad_to_deg(atan2(-world.x, world.y)), 360.0)
	return DIRECTIONS[int(round(angle / 45.0)) % 8]


## {animacja: {klatka: [zdarzenia]}} z sekcji "animations" pliku meta.json.
static func build_event_table(animations: Dictionary) -> Dictionary:
	var table := {}
	for anim: String in animations:
		var by_frame := {}
		for ev: Dictionary in animations[anim].get("events", []):
			var frame := int(ev["frame"])
			if not by_frame.has(frame):
				by_frame[frame] = []
			by_frame[frame].append(StringName(ev["name"]))
		table[StringName(anim)] = by_frame
	return table
