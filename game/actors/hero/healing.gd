class_name Healing
extends Node
## Zapasy leczące bohatera i ich reguły (docs/mechaniki.md, część II B). Czynność użycia to stan USE
## w Combat, więc przerywają ją te same zdarzenia co inne akcje: ruch, unik, garda i trafienie.
## Zdrowie i zużycie przedmiotu rozliczają się razem dopiero po use_finished; przerwanie nie zużywa
## przedmiotu ani nie leczy częściowo.
##
## Nalewka leczy stopniowo po wypiciu; w czasie efektu kolejna jest zablokowana, a przedmiot nie
## przepada.
## Leczenie nie daje niewrażliwości: wróg dalej atakuje i nie traci zainteresowania.

## Użycie odrzucone bez utraty przedmiotu; powód: no_supply, full_health, active, not_ready.
signal blocked(kind: StringName, reason: StringName)
signal started(kind: StringName)
signal completed(kind: StringName)
signal interrupted(kind: StringName)
signal supplies_changed(bandages: int, potions: int)

const BANDAGE := &"bandage"
const POTION := &"potion"

@export var bandages := 3
@export var potions := 1
@export var bandage_time := 2.5
@export var bandage_heal := 35.0
@export var potion_time := 0.8
@export var potion_heal := 40.0
## Czas, w którym wypita nalewka oddaje całe leczenie.
@export var potion_duration := 5.0
@export var combat: Combat

var _regen_left := 0.0


func _ready() -> void:
	combat.use_started.connect(started.emit)
	combat.use_finished.connect(_on_use_finished)
	combat.use_interrupted.connect(interrupted.emit)
	combat.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	tick(delta)


func is_busy() -> bool:
	return combat.state == Combat.State.USE


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
	return combat.use_item(kind, bandage_time if kind == BANDAGE else potion_time)


## Stopniowe leczenie po wypiciu nalewki.
func tick(delta: float) -> void:
	if _regen_left <= 0.0 or combat.is_dead():
		return
	var slice := minf(delta, _regen_left)
	_regen_left -= slice
	combat.heal(potion_heal / potion_duration * slice)


func to_data() -> Dictionary:
	return {"bandages": bandages, "potions": potions}


func from_data(data: Dictionary) -> void:
	bandages = int(data.get("bandages", bandages))
	potions = int(data.get("potions", potions))
	_regen_left = 0.0
	supplies_changed.emit(bandages, potions)


func _refusal(kind: StringName) -> StringName:
	if supply_of(kind) <= 0:
		return &"no_supply"
	if combat.health >= combat.max_health:
		return &"full_health"
	if kind == POTION and is_regenerating():
		return &"active"
	if combat.state != Combat.State.IDLE:
		return &"not_ready"
	return &""


func _on_use_finished(kind: StringName) -> void:
	if kind == BANDAGE:
		bandages -= 1
		combat.heal(bandage_heal)
	else:
		potions -= 1
		_regen_left = potion_duration
	supplies_changed.emit(bandages, potions)
	completed.emit(kind)


func _on_died() -> void:
	_regen_left = 0.0
