extends SceneTree
## Uruchamia wszystkie testy res://tests/test_*.gd bez okna:
## godot --headless --path game --script res://tests/run_tests.gd

var _started := false


## Testy ruszają w pierwszej klatce: w _initialize root nie jest jeszcze w drzewie, więc węzły
## dodane do niego nie dostają _ready ani fizyki.
func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run_all()
	return false


func _run_all() -> void:
	var failed := 0
	var total := 0
	for file in DirAccess.get_files_at("res://tests"):
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load("res://tests/" + file)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			var suite: Object = script.new()
			if suite.has_method("setup"):
				suite.call("setup", root)
			await suite.call(name)
			if suite.has_method("teardown"):
				suite.call("teardown")
			if suite.failures.is_empty():
				print("ok   %s::%s" % [file, name])
			else:
				failed += 1
				for f in suite.failures:
					print("FAIL %s::%s — %s" % [file, name, f])
	print("%d testów, %d nieudanych" % [total, failed])
	quit(1 if failed > 0 or total == 0 else 0)
