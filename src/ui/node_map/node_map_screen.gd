# NodeMapScreen — lists the current run's node choices (monster fights /
# travel deeper) and lets the player retreat to bank the run's haul. All
# node generation and run bookkeeping stays in RunState/NodeMap; this only
# renders run.node_map and dispatches taps to public methods.
extends Control

@onready var node_list: VBoxContainer = %NodeList
@onready var status_label: Label = %StatusLabel
@onready var retreat_button: Button = %RetreatButton

func _ready() -> void:
	retreat_button.pressed.connect(_on_retreat_pressed)
	_refresh()

func _refresh() -> void:
	var run: RunState = GameState.current_run
	if run == null or run.status != "active":
		get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
		return

	status_label.text = "Lv %s | Hunts %d/%d | Essence %s" % [
		Big.fmt(run.level), int(run.hunts_remaining), int(run.hunts_max), Big.fmt(run.essence_unbanked)
	]

	for child in node_list.get_children():
		child.queue_free()

	for node in run.node_map:
		var button := Button.new()
		if node["type"] == "monster":
			var monster: MonsterDef = GameState.monsters.get(node["monster_id"])
			var monster_name: String = monster.name if monster != null else node["monster_id"]
			button.text = "Hunt %s (Lv %s, +%s XP)" % [monster_name, Big.fmt(node["level"]), Big.fmt(node["xp_reward"])]
			button.pressed.connect(_on_monster_node_pressed.bind(node["monster_id"]))
		else:
			var target: ZoneDef = GameState.zones.get(node["target_zone_id"])
			var target_name: String = target.name if target != null else node["target_zone_id"]
			button.text = "Travel to %s" % target_name
			button.pressed.connect(_on_travel_node_pressed.bind(node["target_zone_id"]))
		node_list.add_child(button)

func _on_monster_node_pressed(monster_id: String) -> void:
	var monster: MonsterDef = GameState.monsters.get(monster_id)
	if monster == null:
		return
	GameState.mark_bestiary_seen(monster_id)
	GameState.pending_monster = monster
	get_tree().change_scene_to_file("res://src/ui/combat/combat_screen.tscn")

func _on_travel_node_pressed(target_zone_id: String) -> void:
	var run: RunState = GameState.current_run
	run.unlock_zone(target_zone_id)
	run.generate_node_map(GameState.zones[target_zone_id], GameState.monsters)
	_refresh()

func _on_retreat_pressed() -> void:
	var run: RunState = GameState.current_run
	run.retreat()
	GameState.settle_run(run)
	GameState.current_run = null
	get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn")
