class_name Silhouette
extends Node2D
## Sylwetka postaci rysowana nad rekwizytami, gdy pień lub wóz ją zasłania (T16). Bohater
## i zapowiedź ataku przeciwnika w walce mają być zawsze widoczne. Warstwy postaci (AssetSprite)
## są kopiowane jako jednolite sylwetki, zsynchronizowane z klatką animacji i z kolorem zapowiedzi.
##
## Pokazywana tylko dla postaci z grupy Prop.OCCLUSION_GROUP, więc przeciwnik poza walką nie jest
## wyróżniany. Zanikanie koron robi Prop; sylwetka dotyczy tylko brył (trunk, full).

## Nad rysunkiem rekwizytów i koron.
const DRAW_Z := 100
const SHADER := preload("res://core/world/silhouette.gdshader")

@export var sprite: AssetSprite
@export var base_color := Color(0.85, 0.92, 1.0, 0.65)

var _clones: Array[AnimatedSprite2D] = []
var _sources: Array[AnimatedSprite2D] = []
var _material: ShaderMaterial


func _ready() -> void:
	z_index = DRAW_Z
	z_as_relative = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	hide()


func _process(_delta: float) -> void:
	update_silhouette()


## Odświeża widoczność i klatkę sylwetki; wołane z _process, testy wołają wprost.
func update_silhouette() -> void:
	var actor := get_parent() as Node2D
	if actor == null or sprite == null or sprite.meta.is_empty():
		hide()
		return
	var show_it := actor.is_in_group(Prop.OCCLUSION_GROUP) and is_occluded(actor.global_position)
	visible = show_it
	if show_it:
		_sync()


func is_occluded(feet: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group(Prop.GROUP):
		if (node as Prop).body_occludes(feet):
			return true
	return false


func _sync() -> void:
	var sources := _layer_sprites()
	if sources != _sources:
		_rebuild(sources)
	var color := Color(
		base_color.r * sprite.modulate.r,
		base_color.g * sprite.modulate.g,
		base_color.b * sprite.modulate.b,
		base_color.a * sprite.modulate.a
	)
	_material.set_shader_parameter(&"silhouette_color", color)
	for i in _clones.size():
		var clone := _clones[i]
		var source := _sources[i]
		clone.animation = source.animation
		clone.frame = source.frame
		clone.position = source.position


func _layer_sprites() -> Array[AnimatedSprite2D]:
	var layers: Array[AnimatedSprite2D] = []
	for child in sprite.get_children():
		if child is AnimatedSprite2D:
			layers.append(child)
	return layers


func _rebuild(sources: Array[AnimatedSprite2D]) -> void:
	for clone in _clones:
		clone.queue_free()
	_clones.clear()
	_sources = sources
	for source in sources:
		var clone := AnimatedSprite2D.new()
		clone.sprite_frames = source.sprite_frames
		clone.centered = source.centered
		clone.offset = source.offset
		clone.z_index = source.z_index
		clone.material = _material
		add_child(clone)
		_clones.append(clone)
