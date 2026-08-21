# LaunchScreen — pick a zone + loadout, start a RunState, hand off to the
# walkable overworld. Thin shell: all rules (hunts, starting level, node
# generation) live in RunState/GameState; this only reads GameState and
# drives buttons.
extends Control

# Zone id -> swatch color. Purely cosmetic (matches the design canvas' tier
# colors); ZoneDef carries no color field, so this stays a UI-only lookup
# rather than something rules code needs to know about. Unknown ids fall
# back to a neutral gray.
const ZONE_SWATCH_COLORS := {
	"verdant_fields": Color("#4caf50"),
	"cinder_dunes": Color("#e07a3f"),
	"frostpeak_ridge": Color("#5eb8d9"),
}
const ZONE_SWATCH_FALLBACK := Color("#8a93a8")

@onready var zone_option: OptionButton = %ZoneOption
@onready var weapon_option: OptionButton = %WeaponOption
@onready var start_button: Button = %StartButton
@onready var essence_label: Label = %EssenceLabel
@onready var zone_swatch: ColorRect = %ZoneSwatch
@onready var zone_name_label: Label = %ZoneNameLabel
@onready var zone_level_label: Label = %ZoneLevelLabel
@onready var zone_tag_label: Label = %ZoneTagLabel
@onready var weapon_icon: TextureRect = %WeaponIcon
@onready var weapon_name_label: Label = %WeaponNameLabel
@onready var inventory_button: Button = %InventoryButton
@onready var bestiary_button: Button = %BestiaryButton
@onready var meta_button: Button = %MetaButton

var _zone_ids: Array = []
var _weapon_gear_ids: Array = [] # "" (none) or gear instance id
var _starting_zone_id: String = ""

func _ready() -> void:
	essence_label.text = "Essence %s" % Big.fmt(float(GameState.save_state.get("essence", 0.0)))
	_populate_zones()
	_populate_weapons()
	zone_option.item_selected.connect(func(_index): _update_zone_card())
	weapon_option.item_selected.connect(func(_index): _update_weapon_card())
	var starting_index := _zone_ids.find(_starting_zone_id)
	if starting_index >= 0:
		zone_option.selected = starting_index
	if _weapon_gear_ids.size() > 1:
		weapon_option.selected = 1
	_update_zone_card()
	_update_weapon_card()
	start_button.pressed.connect(_on_start_pressed)
	inventory_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/inventory/inventory_screen.tscn"))
	bestiary_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/bestiary/bestiary_screen.tscn"))
	meta_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/meta/meta_screen.tscn"))

func _populate_zones() -> void:
	zone_option.clear()
	_zone_ids.clear()
	_starting_zone_id = ""
	var lowest_min_level := INF
	var unlocked: Array = GameState.save_state.get("unlocked_zones", [])
	for zone_id in GameState.zones.keys():
		# Defensive fallback: if the durable unlock list is somehow empty,
		# show all zones rather than stranding the player with no options.
		if not unlocked.is_empty() and not unlocked.has(zone_id):
			continue
		var zone: ZoneDef = GameState.zones[zone_id]
		zone_option.add_item(zone.name)
		_zone_ids.append(zone_id)
		if zone.min_level < lowest_min_level:
			lowest_min_level = zone.min_level
			_starting_zone_id = zone_id

func _populate_weapons() -> void:
	weapon_option.clear()
	_weapon_gear_ids.clear()
	weapon_option.add_item("( none )")
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

func _update_zone_card() -> void:
	if _zone_ids.is_empty():
		return
	var zone_id: String = _zone_ids[zone_option.selected]
	var zone: ZoneDef = GameState.zones[zone_id]
	zone_swatch.color = ZONE_SWATCH_COLORS.get(zone_id, ZONE_SWATCH_FALLBACK)
	zone_name_label.text = zone.name
	zone_level_label.text = "Lv %d–%d" % [int(zone.min_level), int(zone.max_level)]
	zone_tag_label.visible = zone_id == _starting_zone_id
	zone_tag_label.text = "STARTING ZONE"

func _update_weapon_card() -> void:
	if _weapon_gear_ids.is_empty():
		return
	var weapon_def_id: String = _weapon_gear_ids[weapon_option.selected]
	if weapon_def_id == "" or not GameState.weapons.has(weapon_def_id):
		weapon_icon.texture = null
		weapon_name_label.text = "( none )"
		return
	var def: WeaponDef = GameState.weapons[weapon_def_id]
	weapon_icon.texture = WeaponIcons.for_id(def.id)
	weapon_name_label.text = def.name

func _on_start_pressed() -> void:
	if _zone_ids.is_empty():
		return
	var zone_id: String = _zone_ids[zone_option.selected]
	var weapon_def_id: String = _weapon_gear_ids[weapon_option.selected]
	GameState.start_run(zone_id, weapon_def_id, {})
	get_tree().change_scene_to_file("res://src/ui/overworld/overworld_screen.tscn")
