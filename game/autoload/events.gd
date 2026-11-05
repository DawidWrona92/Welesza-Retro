extends Node
## Szyna sygnałów między systemami. Systemy nie sięgają bezpośrednio do węzłów innych systemów.

@warning_ignore("unused_signal")
signal anim_event(actor: Node, event_name: StringName)
@warning_ignore("unused_signal")
signal flag_changed(flag: StringName, value: Variant)
@warning_ignore("unused_signal")
signal object_collected(world_id: StringName)
@warning_ignore("unused_signal")
signal sector_ready(sector_id: StringName)
@warning_ignore("unused_signal")
signal sector_unloaded(sector_id: StringName)
