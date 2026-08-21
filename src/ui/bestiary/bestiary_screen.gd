# BestiaryScreen — lists every monster def with its seen/defeated status
# from the save's bestiary Dictionary. Read-only view; no rules here.
extends Control

@onready var entry_list: VBoxContainer = %EntryList
@onready var back_button: Button = %BackButton

var _subtitle_label: Label

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn"))
	_refresh()

func _refresh() -> void:
	for child in entry_list.get_children():
		child.queue_free()

	var bestiary: Dictionary = GameState.save_state.get("bestiary", {})
	var discovered_count := 0
	var total_count := 0
	for monster_id in GameState.monsters:
		var monster: MonsterDef = GameState.monsters[monster_id]
		var entry: Dictionary = bestiary.get(monster_id, {"seen": false, "defeated": false})
		total_count += 1
		var label := Label.new()
		if entry.get("defeated", false):
			label.text = "%s (Lv %s) — Defeated" % [monster.name, Big.fmt(monster.level)]
			discovered_count += 1
		elif entry.get("seen", false):
			label.text = "%s (Lv %s) — Seen" % [monster.name, Big.fmt(monster.level)]
			discovered_count += 1
		else:
			label.text = "??? — Undiscovered"
		entry_list.add_child(label)

	_update_subtitle(discovered_count, total_count)

func _update_subtitle(discovered_count: int, total_count: int) -> void:
	if _subtitle_label == null:
		_subtitle_label = Label.new()
		_subtitle_label.modulate = Color(1, 1, 1, 0.6)
		var title: Label = entry_list.get_parent().get_parent().get_node("Title")
		title.get_parent().add_child(_subtitle_label)
		title.get_parent().move_child(_subtitle_label, title.get_index() + 1)
	_subtitle_label.text = "%d / %d discovered" % [discovered_count, total_count]
