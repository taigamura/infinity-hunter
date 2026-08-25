extends SceneTree

func _initialize() -> void:
	var packed: PackedScene = load("res://src/ui/overworld/overworld_screen.tscn")
	var inst = packed.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	var base = inst.get_node("%Base")
	var knob = inst.get_node("%Knob")
	print("base pos ", base.position, " size ", base.size)
	print("knob pos ", knob.position, " size ", knob.size)
	quit(0)
