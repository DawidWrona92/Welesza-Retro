class_name Prop
extends StaticBody2D
## Rekwizyt z kontraktu assetu (PROP-…): warstwy z pipeline'u ustawione kotwicą w początku węzła,
## więc sortowanie po Y działa jak dla postaci. Kolizja z meta.json, spłaszczona do rzutu 2:1,
## i dziura w siatce nawigacji (grupa Block.NAV_GROUP).
## Warstwa „ground” (np. korzenie) leży na ziemi: rysowana pod postaciami, nad kaflami podłoża.
##
## Przesłanianie (T16): postać jest „za” rekwizytem, gdy stopami leży powyżej linii `occlusion_y`
## z meta.json (współrzędna płótna, liczona od kotwicy). Wtedy rekwizyt zasłania ją w obrysie
## nieprzezroczystych pikseli swoich warstw. Korona (`crown`) staje się wtedy półprzezroczysta,
## a pień lub wóz (`trunk`, `full`) wymaga sylwetki postaci (core/world/silhouette.gd).
## Dotyczy to postaci z grupy OCCLUSION_GROUP: bohatera i przeciwników w walce.

const GROUP := &"props"
## Postacie, które muszą być zawsze widoczne: bohater i przeciwnicy w walce (zapowiedź ataku).
const OCCLUSION_GROUP := &"always_visible"
const CROWN_LAYER := &"crown"
const GROUND_LAYER := &"ground"
## Piksel o alfie od tej wartości zasłania postać.
const OPAQUE_ALPHA := 0.5
## Obrys postaci do próbkowania: od stóp w górę (jednostki gry, bohater ma ok. 160 px).
const ACTOR_HALF_WIDTH := 28.0
const ACTOR_HEIGHT := 160.0
const SAMPLE_COLUMNS := 3
const SAMPLE_ROWS := 5
## Pod postaciami (z 0) i nad podłożem (IsoGround z -10).
const GROUND_LAYER_Z := -5

## Maski nieprzezroczystości warstw (obrazy) wspólne dla wszystkich egzemplarzy tego samego assetu.
static var _mask_cache: Dictionary[String, Image] = {}

@export var asset_id: String
## Przezroczystość korony, gdy postać jest za nią, i szybkość zmiany (alfa na sekundę).
@export var crown_alpha := 0.35
@export var fade_speed := 6.0

var meta: Dictionary = {}
var _layers: Dictionary[StringName, Sprite2D] = {}
var _anchor := Vector2.ZERO
var _line_offset := 0.0


func _ready() -> void:
	add_to_group(Block.NAV_GROUP)
	add_to_group(GROUP)
	if not asset_id.is_empty():
		load_asset(asset_id)


func load_asset(id: String) -> Error:
	var meta_path := "res://assets/%s/meta.json" % id
	if not FileAccess.file_exists(meta_path):
		push_error("Brak zbudowanego assetu %s; uruchom tools/sprite_pipeline.py" % id)
		return ERR_FILE_NOT_FOUND
	meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	asset_id = id
	var anchor := Vector2(meta["anchor"][0], meta["anchor"][1])
	_anchor = anchor
	_line_offset = float(meta.get("occlusion_y", anchor.y)) - anchor.y
	var layers: Array = meta["layers"] if not meta["layers"].is_empty() else ["full"]
	for layer: String in layers:
		var sprite := Sprite2D.new()
		sprite.name = layer
		sprite.texture = load("res://assets/%s/%s.png" % [id, layer])
		sprite.centered = false
		sprite.offset = -anchor
		if layer == "ground":
			sprite.z_index = GROUND_LAYER_Z
		add_child(sprite)
		_layers[StringName(layer)] = sprite
	var radius := float(meta.get("collision", {}).get("circle", 0.0))
	if radius > 0.0:
		var circle := CircleShape2D.new()
		circle.radius = radius
		var shape := CollisionShape2D.new()
		shape.shape = circle
		shape.scale = Vector2(1.0, AssetSprite.ISO_Y)
		add_child(shape)
	return OK


func layer(layer_name: StringName) -> Sprite2D:
	return _layers.get(layer_name)


func _process(delta: float) -> void:
	var feet: Array[Vector2] = []
	for subject: Node in get_tree().get_nodes_in_group(OCCLUSION_GROUP):
		feet.append((subject as Node2D).global_position)
	step_fade(delta, feet)


## Zanikanie korony: półprzezroczysta, gdy któraś z postaci (stopy w `feet`) jest za nią.
func step_fade(delta: float, feet: Array[Vector2]) -> void:
	var crown := layer(CROWN_LAYER)
	if crown == null:
		return
	var target := 1.0
	for point in feet:
		if crown_covers(point):
			target = crown_alpha
			break
	crown.modulate.a = move_toward(crown.modulate.a, target, fade_speed * delta)


## Korona to jedyna warstwa, która zanika; ground leży pod postaciami, pień i wóz dają sylwetkę.
static func layer_occludes(layer_name: StringName) -> bool:
	return layer_name != CROWN_LAYER and layer_name != GROUND_LAYER


## Czy postać ze stopami w tym punkcie jest za rekwizytem (powyżej linii occlusion_y).
func is_behind(feet: Vector2) -> bool:
	return feet.y < global_position.y + _line_offset


## Punkty próbkowania obrysu postaci o stopach w `feet`.
static func actor_samples(feet: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for row in SAMPLE_ROWS:
		var y := -ACTOR_HEIGHT * row / float(SAMPLE_ROWS - 1)
		for column in SAMPLE_COLUMNS:
			var x := lerpf(-ACTOR_HALF_WIDTH, ACTOR_HALF_WIDTH, column / float(SAMPLE_COLUMNS - 1))
			points.append(feet + Vector2(x, y))
	return points


## Czy w punkcie świata warstwa ma nieprzezroczysty piksel.
func opaque_at(layer_name: StringName, world_point: Vector2) -> bool:
	var sprite := layer(layer_name)
	if sprite == null:
		return false
	var image := _mask(layer_name)
	var pixel := Vector2i((world_point - global_position + _anchor).round())
	if image == null or not Rect2i(Vector2i.ZERO, image.get_size()).has_point(pixel):
		return false
	return image.get_pixelv(pixel).a >= OPAQUE_ALPHA


## Czy postać (stopy w `feet`) jest za rekwizytem i któraś warstwa `layer_name` ją zasłania.
func layer_covers(layer_name: StringName, feet: Vector2) -> bool:
	if not is_behind(feet):
		return false
	for point in actor_samples(feet):
		if opaque_at(layer_name, point):
			return true
	return false


func crown_covers(feet: Vector2) -> bool:
	return layer_covers(CROWN_LAYER, feet)


## Pień lub wóz zasłania postać: potrzebna sylwetka.
func body_occludes(feet: Vector2) -> bool:
	for layer_name in _layers:
		if layer_occludes(layer_name) and layer_covers(layer_name, feet):
			return true
	return false


func _mask(layer_name: StringName) -> Image:
	var path := "res://assets/%s/%s.png" % [asset_id, layer_name]
	if not _mask_cache.has(path):
		var texture := _layers[layer_name].texture
		if texture == null:
			return null
		_mask_cache[path] = texture.get_image()
	return _mask_cache[path]
