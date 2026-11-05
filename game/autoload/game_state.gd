extends Node
## Trwały stan świata: flagi fabularne (persistent_flags z docs/world/world-layout.v0.2.json)
## i obiekty zebrane lub pokonane według stałego world_id, niezależnie od wczytanych sektorów.

var flags: Dictionary[StringName, Variant] = {}
var collected: Dictionary[StringName, bool] = {}


func set_flag(flag: StringName, value: Variant = true) -> void:
	if flags.get(flag) == value:
		return
	flags[flag] = value
	Events.flag_changed.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


func mark_collected(world_id: StringName) -> void:
	if collected.has(world_id):
		return
	collected[world_id] = true
	Events.object_collected.emit(world_id)


func is_collected(world_id: StringName) -> bool:
	return collected.has(world_id)


func to_data() -> Dictionary:
	return {"flags": flags.duplicate(), "collected": collected.keys()}


func from_data(data: Dictionary) -> void:
	flags.clear()
	collected.clear()
	for key: String in data.get("flags", {}):
		flags[StringName(key)] = data["flags"][key]
	for world_id: String in data.get("collected", []):
		collected[StringName(world_id)] = true
