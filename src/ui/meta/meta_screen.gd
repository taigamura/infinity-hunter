# MetaScreen — spend banked essence on permanent upgrades. All caps/costs
# live in MetaProgression; this only lists upgrade ids and dispatches
# purchase taps.
extends Control

@onready var essence_label: Label = %EssenceLabel
@onready var upgrade_list: VBoxContainer = %UpgradeList
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn"))
	_refresh()

func _refresh() -> void:
	essence_label.text = "Essence: %s" % Big.fmt(float(GameState.save_state.get("essence", 0.0)))

	for child in upgrade_list.get_children():
		child.queue_free()

	for upgrade_id in MetaProgression.UPGRADES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var level := MetaProgression.upgrade_level(GameState.save_state, upgrade_id)
		var max_level: int = MetaProgression.UPGRADES[upgrade_id]["max_level"]
		var label := Label.new()
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		if level >= max_level:
			label.text = "%s: Lv %d/%d (MAX)" % [upgrade_id, level, max_level]
		else:
			var cost := MetaProgression.upgrade_cost(GameState.save_state, upgrade_id)
			label.text = "%s: Lv %d/%d (cost %s)" % [upgrade_id, level, max_level, Big.fmt(cost)]
		row.add_child(label)

		var buy_button := Button.new()
		buy_button.text = "Upgrade"
		buy_button.disabled = not MetaProgression.can_purchase(GameState.save_state, upgrade_id)
		buy_button.pressed.connect(_on_purchase_pressed.bind(upgrade_id))
		row.add_child(buy_button)

		upgrade_list.add_child(row)

func _on_purchase_pressed(upgrade_id: String) -> void:
	if MetaProgression.purchase_upgrade(GameState.save_state, upgrade_id):
		GameState.persist()
		_refresh()
