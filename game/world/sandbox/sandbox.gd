extends Node2D
## Sandbox: szara scena z prostych brył do prototypowania ruchu i walki (T10, T11).

@onready var _navigation: NavigationRegion2D = $NavigationRegion2D
@onready var _bar: ProgressBar = $Hud/StaminaBar
@onready var _hero: Hero = $Hero


func _ready() -> void:
	# Dziury w siatce nawigacji wycinają się z brył zapisanych w grupie Block.NAV_GROUP.
	_navigation.bake_navigation_polygon(false)
	var stamina := _hero.stamina
	stamina.changed.connect(_on_stamina_changed)
	stamina.exhausted.connect(_on_exhausted_changed.bind(true))
	stamina.recovered.connect(_on_exhausted_changed.bind(false))
	_on_stamina_changed(stamina.value, stamina.max_value)


func _on_stamina_changed(value: float, max_value: float) -> void:
	_bar.max_value = max_value
	_bar.value = value


func _on_exhausted_changed(exhausted: bool) -> void:
	_bar.modulate = Color(1.0, 0.4, 0.3) if exhausted else Color.WHITE
