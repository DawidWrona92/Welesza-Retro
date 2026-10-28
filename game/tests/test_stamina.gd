extends "res://tests/test_case.gd"

var _root: Window
var _stamina: Stamina
var _exhausted_count := 0
var _recovered_count := 0


func setup(root: Window) -> void:
	_root = root
	_stamina = Stamina.new()
	_root.add_child(_stamina)
	_stamina.exhausted.connect(func() -> void: _exhausted_count += 1)
	_stamina.recovered.connect(func() -> void: _recovered_count += 1)


func teardown() -> void:
	_stamina.free()


func test_consume_never_refuses() -> void:
	_stamina.consume(30.0)
	check_eq(_stamina.value, 70.0, "wydatek zdejmuje wytrzymałość")
	_stamina.consume(500.0)
	check_eq(_stamina.value, 0.0, "wydatek ponad stan schodzi do zera")
	check(_stamina.is_exhausted(), "zero ogłasza wyczerpanie")
	check_eq(_exhausted_count, 1, "wyczerpanie ogłoszone raz")
	_stamina.consume(10.0)
	check_eq(_exhausted_count, 1, "kolejny wydatek nie powtarza sygnału")


func test_regen_waits_for_delay() -> void:
	_stamina.consume(50.0)
	_stamina.tick(_stamina.regen_delay * 0.9)
	check_eq(_stamina.value, 50.0, "przed upływem przerwy nic się nie odnawia")
	_stamina.tick(_stamina.regen_delay * 0.2)
	check(_stamina.value > 50.0, "po przerwie odnowa rusza")
	_stamina.consume(1.0)
	var after_spend := _stamina.value
	_stamina.tick(_stamina.regen_delay * 0.5)
	check_eq(_stamina.value, after_spend, "każdy wydatek zaczyna przerwę od nowa")


func test_drain_is_continuous_spend() -> void:
	_stamina.drain(20.0, 0.5)
	check_eq(_stamina.value, 90.0, "drain = rate * delta")
	_stamina.tick(_stamina.regen_delay * 0.5)
	check_eq(_stamina.value, 90.0, "drain też wstrzymuje odnowę")


func test_guard_slows_regen() -> void:
	_stamina.consume(60.0)
	_stamina.tick(_stamina.regen_delay)
	var before := _stamina.value
	_stamina.tick(1.0)
	var free_gain := _stamina.value - before
	_stamina.value = before
	_stamina.guarding = true
	_stamina.tick(1.0)
	var guard_gain := _stamina.value - before
	check_eq(
		snappedf(guard_gain, 0.001),
		snappedf(free_gain * _stamina.guard_regen_factor, 0.001),
		"garda"
	)


func test_exhaustion_ends_at_threshold() -> void:
	_stamina.consume(1000.0)
	_stamina.tick(_stamina.regen_delay * 0.99)
	var threshold := _stamina.max_value * _stamina.recover_threshold
	var seconds_needed := threshold / _stamina.regen_per_second
	_stamina.tick(seconds_needed * 0.9)
	check(_stamina.is_exhausted(), "poniżej progu nadal wyczerpana")
	check_eq(_recovered_count, 0, "jeszcze bez sygnału recovered")
	_stamina.tick(seconds_needed * 0.2)
	check(not _stamina.is_exhausted(), "po przekroczeniu progu wyczerpanie mija")
	check_eq(_recovered_count, 1, "recovered ogłoszone raz")
	_stamina.tick(100.0)
	check_eq(_stamina.value, _stamina.max_value, "odnowa zatrzymuje się na max")
