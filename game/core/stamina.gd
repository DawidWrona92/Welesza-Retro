class_name Stamina
extends Node
## Odnawialny zasób walki i sprintu (docs/walka.md, część II B). Wydatek nigdy nie jest odmawiany:
## wytrzymałość schodzi do 0 i ogłasza wyczerpanie, które mija dopiero po odnowie do progu.

signal changed(value: float, max_value: float)
signal exhausted
signal recovered

@export var max_value := 100.0
@export var regen_per_second := 25.0
## Przerwa po wydatku, zanim ruszy odnowa.
@export var regen_delay := 0.5
## Mnożnik odnowy przy podniesionej gardzie.
@export var guard_regen_factor := 0.4
## Część max_value, od której wyczerpanie mija.
@export var recover_threshold := 0.3

var value: float
## Ustawia walka.
var guarding := false
var _exhausted := false
var _since_spend := 0.0


func _ready() -> void:
	value = max_value
	_since_spend = regen_delay


func _process(delta: float) -> void:
	tick(delta)


func consume(amount: float) -> void:
	_since_spend = 0.0
	_set_value(value - maxf(amount, 0.0))


## Wydatek ciągły, np. sprint: rate jednostek na sekundę przez delta sekund.
func drain(rate: float, delta: float) -> void:
	consume(rate * delta)


func is_exhausted() -> bool:
	return _exhausted


## Odnowa po regen_delay od ostatniego wydatku. Wywołuje _process; testy wołają wprost.
func tick(delta: float) -> void:
	_since_spend += delta
	if _since_spend < regen_delay or value >= max_value:
		return
	var rate := regen_per_second * (guard_regen_factor if guarding else 1.0)
	_set_value(value + rate * delta)


func _set_value(new_value: float) -> void:
	var clamped := clampf(new_value, 0.0, max_value)
	var moved := not is_equal_approx(clamped, value)
	value = clamped
	if moved:
		changed.emit(value, max_value)
	if value <= 0.0 and not _exhausted:
		_exhausted = true
		exhausted.emit()
	elif _exhausted and value >= max_value * recover_threshold:
		_exhausted = false
		recovered.emit()
