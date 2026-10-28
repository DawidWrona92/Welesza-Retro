extends "res://tests/test_case.gd"

const GameStateScript := preload("res://autoload/game_state.gd")
const SaveScript := preload("res://autoload/save_system.gd")

var _state: Node
var _save: Node


func setup(_root: Window) -> void:
	_state = GameStateScript.new()
	_save = SaveScript.new()
	_save.state = _state


func teardown() -> void:
	_state.free()
	_save.free()


func test_save_roundtrip() -> void:
	_state.flags[&"village_lamp_lit"] = true
	_state.collected[&"wagon_parcels"] = true
	check_eq(_save.save_slot("test_roundtrip"), OK, "zapis")
	_state.flags.clear()
	_state.collected.clear()
	check_eq(_save.load_slot("test_roundtrip"), OK, "wczytanie")
	check_eq(_state.flags.get(&"village_lamp_lit"), true, "flaga po wczytaniu")
	check(_state.collected.has(&"wagon_parcels"), "zebrany obiekt po wczytaniu")


func test_wrong_version_is_refused() -> void:
	DirAccess.make_dir_recursive_absolute(SaveScript.SAVE_DIR)
	var f := FileAccess.open(SaveScript.SAVE_DIR + "/test_old.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 0, "state": {}}))
	f.close()
	check_eq(_save.load_slot("test_old"), ERR_FILE_UNRECOGNIZED, "stary format odrzucony")
