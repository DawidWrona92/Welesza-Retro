extends "res://tests/test_case.gd"

const ControlsScript := preload("res://autoload/controls.gd")


func test_default_bindings() -> void:
	ControlsScript.apply_defaults()
	var sprint: InputEventKey = InputMap.action_get_events(&"sprint")[0]
	check_eq(sprint.physical_keycode, KEY_SHIFT, "Shift to sprint")
	var in_place: InputEventKey = InputMap.action_get_events(&"attack_in_place")[0]
	check_eq(in_place.physical_keycode, KEY_CTRL, "Ctrl to atak w miejscu")
	var attack: InputEventMouseButton = InputMap.action_get_events(&"move_attack")[0]
	check_eq(attack.button_index, MOUSE_BUTTON_LEFT, "LPM to ruch i atak")
