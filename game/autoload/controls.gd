extends Node
## Domyślne przypisanie klawiszy (docs/walka.md, część II A). Logika gry używa akcji, nie klawiszy,
## żeby zmiana przypisań i późniejsze dodanie pada nie zmieniały zasad walki.

const DEFAULTS: Dictionary[StringName, Array] = {
	&"move_attack": [MOUSE_BUTTON_LEFT],
	&"skill": [MOUSE_BUTTON_RIGHT],
	&"sprint": [KEY_SHIFT],
	&"attack_in_place": [KEY_CTRL],
	&"dodge": [KEY_SPACE],
	&"guard": [KEY_Q],
	&"heal_bandage": [KEY_1],
	&"heal_potion": [KEY_2],
	&"journal": [KEY_J],
	&"map": [KEY_M],
	&"pause": [KEY_ESCAPE],
}


func _ready() -> void:
	apply_defaults()


static func apply_defaults() -> void:
	for action: StringName in DEFAULTS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		for code: int in DEFAULTS[action]:
			InputMap.action_add_event(action, _event_for(code))


static func _event_for(code: int) -> InputEvent:
	if code <= MOUSE_BUTTON_XBUTTON2:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = code as MouseButton
		return mouse
	var key := InputEventKey.new()
	key.physical_keycode = code as Key
	return key
