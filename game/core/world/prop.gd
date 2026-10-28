class_name Prop
extends StaticBody2D
## Rekwizyt z kontraktu assetu (PROP-…): warstwy z pipeline'u ustawione kotwicą w początku węzła,
## więc sortowanie po Y działa jak dla postaci. Kolizja z meta.json, spłaszczona do rzutu 2:1,
## i dziura w siatce nawigacji (grupa Block.NAV_GROUP). Zanikanie korony robi T16.
## Warstwa „ground” (np. korzenie) leży na ziemi: rysowana pod postaciami, nad kaflami podłoża.

## Pod postaciami (z 0) i nad podłożem (IsoGround z -10).
const GROUND_LAYER_Z := -5

@export var asset_id: String

var meta: Dictionary = {}
var _layers: Dictionary[StringName, Sprite2D] = {}


func _ready() -> void:
	add_to_group(Block.NAV_GROUP)
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
