extends RefCounted
## Bazowa klasa testów uruchamianych przez run_tests.gd.

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: oczekiwano %s, jest %s" % [message, expected, actual])
