# LaunchScreen — pick a zone + loadout, start a RunState, hand off to the
# walkable overworld. Thin shell: all rules (hunts, starting level, node
# generation) live in RunState/GameState; this only reads GameState and
# drives buttons.
extends Control

@onready var zone_option: OptionButton = %ZoneOption
@onready var weapon_option: OptionButton = %WeaponOption
@onready var start_button: Button = %StartButton
@onready var essence_label: Label = %EssenceLabel
@onready var inventory_button: Button = %InventoryButton
@onready var bestiary_button: Button = %BestiaryButton
@onready var meta_button: Button = %MetaButton

var _zone_ids: Array = []
var _weapon_gear_ids: Array = [] # "" (none) or gear instance id

func _ready() -> void:
	essence_label.text = "Essence: %s" % Big.fmt(float(GameState.save_state.get("essence", 0.0)))
	_populate_zones()
	_populate_weapons()
	start_button.pressed.connect(_on_start_pressed)
	inventory_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/inventory/inventory_screen.tscn"))
	bestiary_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/bestiary/bestiary_screen.tscn"))
	meta_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/meta/meta_screen.tscn"))

func _populate_zones() -> void:
	zone_option.clear()
	_zone_ids.clear()
	for zone_id in GameState.zones.keys():
		var zone: ZoneDef = GameState.zones[zone_id]
		zone_option.add_item(zone.name)
		_zone_ids.append(zone_id)

func _populate_weapons() -> void:
	weapon_option.clear()
	_weapon_gear_ids.clear()
	weapon_option.add_item("(none)")
	_weapon_gear_ids.append("")
	for instance in GameState.inventory.gear:
		if GameState.weapons.has(instance["def_id"]):
			var def: WeaponDef = GameState.weapons[instance["def_id"]]
			var text := "%s (%s)" % [def.name, instance["rolled_stats"].get("rarity", "")]
			var icon := WeaponIcons.for_id(def.id)
			if icon != null:
				weapon_option.add_icon_item(icon, text)
			else:
				weapon_option.add_item(text)
			_weapon_gear_ids.append(instance["def_id"])

func _on_start_pressed() -> void:
	if _zone_ids.is_empty():
		return
	var zone_id: String = _zone_ids[zone_option.selected]
	var weapon_def_id: String = _weapon_gear_ids[weapon_option.selected]
	GameState.start_run(zone_id, weapon_def_id, {})
	get_tree().change_scene_to_file("res://src/ui/overworld/overworld_screen.tscn")
