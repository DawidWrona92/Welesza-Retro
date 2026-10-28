extends Node
## Zapis gry: jeden plik JSON z wersją formatu, zapisywany atomowo (plik tymczasowy, potem zamiana),
## żeby awaria w trakcie zapisu nie zostawiła połowicznego stanu (docs/mechaniki.md, część II D).

const FORMAT_VERSION := 1
const SAVE_DIR := "user://saves"

var state: Node


func _ready() -> void:
	state = GameState


func save_slot(slot: String) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {"version": FORMAT_VERSION, "state": state.to_data()}
	var final_path := _path(slot)
	var tmp_path := final_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(tmp_path, final_path)


func load_slot(slot: String) -> Error:
	var path := _path(slot)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ERR_FILE_CORRUPT
	if int(parsed.get("version", -1)) != FORMAT_VERSION:
		# niezgodny format: odmawiamy czytelnie, bez obietnicy zgodności (docs/mechaniki.md)
		return ERR_FILE_UNRECOGNIZED
	state.from_data(parsed["state"])
	return OK


func _path(slot: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]
