extends Node2D
## Sandbox: szara scena z prostych brył do prototypowania ruchu i walki (T10–T13).
##
## Zapis i wczytanie w wersji minimalnej (docs/mechaniki.md, część II D): zapis przy starcie
## sandboksa i pod klawiszem debugowym (F5), po śmierci ekran śmierci i wczytanie zapisu. Stan
## bohatera (zdrowie, miejsce, zapasy) leży w fladze GameState; stan świata dojdzie w T15.

const HERO_FLAG := &"hero"

@export var save_slot := "sandbox"
@export var respawn_delay := 2.5

var _respawning := false

@onready var _navigation: NavigationRegion2D = $NavigationRegion2D
@onready var _hero: Hero = $Hero
@onready var _death_screen: Control = $Hud/DeathScreen
@onready var _health_bar: ProgressBar = $Hud/HealthBar
@onready var _bar: ProgressBar = $Hud/StaminaBar
@onready var _supplies: Label = $Hud/Supplies
@onready var _message: Label = $Hud/Message


func _ready() -> void:
	# Dziury w siatce nawigacji wycinają się z brył zapisanych w grupie Block.NAV_GROUP.
	_navigation.bake_navigation_polygon(false)
	var saved: Variant = GameState.get_flag(HERO_FLAG, null)
	if saved is Dictionary:
		_hero.from_data(saved)
	var stamina := _hero.stamina
	stamina.changed.connect(_on_stamina_changed)
	stamina.exhausted.connect(_on_exhausted_changed.bind(true))
	stamina.recovered.connect(_on_exhausted_changed.bind(false))
	_on_stamina_changed(stamina.value, stamina.max_value)
	var combat: Combat = _hero.get_node("Combat")
	combat.health_changed.connect(_on_health_changed)
	_on_health_changed(combat.health, combat.max_health)
	_hero.healing.supplies_changed.connect(_on_supplies_changed)
	_hero.healing.blocked.connect(_on_heal_blocked)
	_on_supplies_changed(_hero.healing.bandages, _hero.healing.potions)
	_hero.died.connect(_on_hero_died)
	if save_checkpoint() != OK:
		push_warning("Zapis przy starcie sandboksa nie powiódł się")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_save"):
		_show("Zapisano" if save_checkpoint() == OK else "Nie teraz")


## Zapis tylko w stabilnym miejscu: bez walki, zapowiedzi, leczenia i odskoku.
func can_save_now() -> bool:
	if _hero.dead or _hero.healing.is_busy():
		return false
	if _hero.get_node("Combat").state != Combat.State.IDLE:
		return false
	return get_tree().get_nodes_in_group(Enemy.ACTIVE_GROUP).is_empty()


## Bezpieczny zapis; nie jest wołany w chwili śmierci, więc nie nadpisuje stanu sprzed walki.
func save_checkpoint() -> Error:
	if not can_save_now():
		return ERR_UNAVAILABLE
	GameState.set_flag(HERO_FLAG, _hero.to_data())
	return SaveSystem.save_slot(save_slot)


## Śmierć: ostatni bezpieczny zapis wraca w całości; bez zapisu zaczyna się od nowa.
func respawn() -> void:
	if SaveSystem.load_slot(save_slot) != OK:
		GameState.from_data({})
	get_tree().reload_current_scene()


func _on_hero_died() -> void:
	if _respawning:
		return
	_respawning = true
	_death_screen.show()
	await get_tree().create_timer(respawn_delay).timeout
	respawn()


func _on_stamina_changed(value: float, max_value: float) -> void:
	_bar.max_value = max_value
	_bar.value = value


func _on_exhausted_changed(exhausted: bool) -> void:
	_bar.modulate = Color(1.0, 0.4, 0.3) if exhausted else Color.WHITE


func _on_health_changed(health: float, max_health: float) -> void:
	_health_bar.max_value = max_health
	_health_bar.value = health


func _on_supplies_changed(bandages: int, potions: int) -> void:
	_supplies.text = "[1] Opatrunki: %d   [2] Nalewka: %d" % [bandages, potions]


func _on_heal_blocked(_kind: StringName, reason: StringName) -> void:
	var texts := {
		&"no_supply": "Brak zapasu",
		&"full_health": "Zdrowie pełne",
		&"active": "Poprzednia dawka jeszcze działa",
		&"not_ready": "Nie teraz",
	}
	if texts.has(reason):
		_show(texts[reason])


func _show(text: String, seconds := 1.5) -> void:
	_message.text = text
	await get_tree().create_timer(seconds).timeout
	if _message.text == text:
		_message.text = ""
