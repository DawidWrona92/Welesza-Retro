class_name Healing
extends Node
## Leczenie bohatera (docs/mechaniki.md, część II B): opatrunek i nalewka to widoczne czynności.
## Zdrowie i zużycie przedmiotu rozliczają się razem dopiero po ich zakończeniu; przerwanie nie
## zużywa przedmiotu ani nie daje częściowego leczenia.
##
## Opatrunek: bohater stoi; ruch, unik, garda, własny atak i trafienie go przerywają.
## Nalewka: można ją pić w walce; przerywa ją tylko unik, garda i własny atak, trafienie nie.
## Po wypiciu leczenie płynie stopniowo, a w jego trakcie kolejna nalewka jest zablokowana
## bez utraty przedmiotu.

signal started(kind: StringName)
signal completed(kind: StringName)
signal interrupted(kind: StringName)
## Użycie odrzucone bez utraty przedmiotu; powód: no_supply, full_health, busy, not_ready, active.
signal blocked(kind: StringName, reason: StringName)
signal supplies_changed(bandages: int, potions: int)

const BANDAGE := &"bandage"
const POTION := &"potion"
const CAUSE_MOVE := &"move"
const CAUSE_DODGE := &"dodge"
const CAUSE_GUARD := &"guard"
const CAUSE_ATTACK := &"attack"
const CAUSE_HIT := &"hit"

@export var bandages := 3
@export var potions := 1
@export var bandage_time := 2.5
@export var bandage_heal := 35.0
@export var potion_time := 0.8
@export var potion_heal := 40.0
## Czas, w którym wypita nalewka oddaje całe leczenie.
@export var potion_duration := 5.0
@export var combat: Combat

var _kind: StringName = &""
var _left := 0.0
var _regen_left := 0.0


func _ready() -> void:
	combat.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	tick(delta)


## Czy ta przyczyna przerywa tę czynność (docs/mechaniki.md: opatrunek wszystko, nalewka mniej).
static func is_interrupted_by(kind: StringName, cause: StringName) -> bool:
	if kind == BANDAGE:
		return true
	return cause in [CAUSE_DODGE, CAUSE_GUARD, CAUSE_ATTACK]


## Przyczyna przerwania wynikająca ze stanu walki bohatera; pusta, gdy nic nie przeszkadza.
static func cause_from_state(state: Combat.State) -> StringName:
	match state:
		Combat.State.DODGE:
			return CAUSE_DODGE
		Combat.State.GUARD:
			return CAUSE_GUARD
		Combat.State.ATTACK:
			return CAUSE_ATTACK
		Combat.State.STAGGER, Combat.State.RECOVER:
			return CAUSE_HIT
		_:
			return &""


func is_busy() -> bool:
	return _kind != &""


func active_kind() -> StringName:
	return _kind


func is_regenerating() -> bool:
	return _regen_left > 0.0


func supply_of(kind: StringName) -> int:
	return bandages if kind == BANDAGE else potions


## Zaczyna czynność; zwraca, czy się zaczęła. Odrzucenie niczego nie kosztuje.
func start(kind: StringName) -> bool:
	var reason := _refusal(kind)
	if reason != &"":
		blocked.emit(kind, reason)
		return false
	_kind = kind
	_left = bandage_time if kind == BANDAGE else potion_time
	started.emit(kind)
	return true


## Przerywa czynność z podanej przyczyny, jeśli ta ją przerywa.
func interrupt(cause: StringName) -> void:
	if is_busy() and is_interrupted_by(_kind, cause):
		var kind := _kind
		_kind = &""
		interrupted.emit(kind)


func tick(delta: float) -> void:
	if combat.is_dead():
		return
	var cause := cause_from_state(combat.state)
	if is_busy() and cause != &"":
		interrupt(cause)
	if is_busy():
		_left -= delta
		if _left <= 0.0:
			_complete()
	if _regen_left > 0.0:
		var slice := minf(delta, _regen_left)
		_regen_left -= slice
		_heal(potion_heal / potion_duration * slice)


func to_data() -> Dictionary:
	return {"bandages": bandages, "potions": potions}


func from_data(data: Dictionary) -> void:
	bandages = int(data.get("bandages", bandages))
	potions = int(data.get("potions", potions))
	_kind = &""
	_left = 0.0
	_regen_left = 0.0
	supplies_changed.emit(bandages, potions)


func _refusal(kind: StringName) -> StringName:
	if combat.is_dead() or is_busy():
		return &"busy"
	if supply_of(kind) <= 0:
		return &"no_supply"
	if combat.health >= combat.max_health:
		return &"full_health"
	if kind == POTION and is_regenerating():
		return &"active"
	if combat.state != Combat.State.IDLE:
		return &"not_ready"
	return &""


func _complete() -> void:
	var kind := _kind
	_kind = &""
	if kind == BANDAGE:
		bandages -= 1
		_heal(bandage_heal)
	else:
		potions -= 1
		_regen_left = potion_duration
	supplies_changed.emit(bandages, potions)
	completed.emit(kind)


## Combat nie ma jeszcze leczenia (T11, PM): zdrowie ustawiamy tu i ogłaszamy zmianę.
func _heal(amount: float) -> void:
	if combat.is_dead():
		return
	combat.health = minf(combat.max_health, combat.health + amount)
	combat.health_changed.emit(combat.health, combat.max_health)


func _on_died() -> void:
	_kind = &""
	_regen_left = 0.0
