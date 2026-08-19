# BestiaryScreen — lists every monster def with its seen/defeated status
# from the save's bestiary Dictionary. Read-only view; no rules here.
extends Control

@onready var entry_list: VBoxContainer = %EntryList
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn"))
	_refresh()

func _refresh() -> void:
	for child in entry_list.get_children():
		child.queue_free()

	var bestiary: Dictionary = GameState.save_state.get("bestiary", {})
	for monster_id in GameState.monsters:
		var monster: MonsterDef = GameState.monsters[monster_id]
		var entry: Dictionary = bestiary.get(monster_id, {"seen": false, "defeated": false})
		var label := Label.new()
		if entry.get("defeated", false):
			label.text = "%s (Lv %s) — Defeated" % [monster.name, Big.fmt(monster.level)]
		elif entry.get("seen", false):
			label.text = "%s (Lv %s) — Seen" % [monster.name, Big.fmt(monster.level)]
		else:
			label.text = "??? — Undiscovered"
		entry_list.add_child(label)
