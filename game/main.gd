extends Node2D
## Scena startowa M0: manekin testowy w kamerze gry. Zastąpi ją scena testowa grafiki (T09).

@onready var _sprite: AssetSprite = $Manekin


func _ready() -> void:
	if not _sprite.meta.is_empty():
		_sprite.play_anim(&"walk", &"s")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not _sprite.meta.is_empty():
		_sprite.face(get_global_mouse_position() - _sprite.global_position)
