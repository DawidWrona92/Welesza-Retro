extends Node
## Zastępstwo wytrzymałości (core/stamina.gd powstaje w T10) z tym samym interfejsem.

var value := 100.0
var guarding := false


func consume(amount: float) -> void:
	value = maxf(0.0, value - amount)


func is_exhausted() -> bool:
	return value <= 0.0
