extends Node
## Doczytywanie sektorów świata w tle (docs/world/STREAMING.md, opcja T1).
## Sektor nie wie o sąsiadach; które sektory są wczytane, decyduje wyłącznie ten węzeł.
## Pełna wersja: zadanie T15.

const SECTOR_SCENE := "res://world/sectors/%s/%s.tscn"

var _pending: Dictionary[StringName, String] = {}


func request_sector(sector_id: StringName) -> void:
	var path := SECTOR_SCENE % [sector_id, sector_id]
	if _pending.has(sector_id) or not ResourceLoader.exists(path):
		return
	ResourceLoader.load_threaded_request(path)
	_pending[sector_id] = path


func _process(_delta: float) -> void:
	for sector_id: StringName in _pending.keys():
		var status := ResourceLoader.load_threaded_get_status(_pending[sector_id])
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_pending.erase(sector_id)
			Events.sector_ready.emit(sector_id)
		elif (
			status
			in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]
		):
			push_error("Nie udało się wczytać sektora %s" % sector_id)
			_pending.erase(sector_id)
