# InventoryScreen — shows materials/gear and lets the player craft weapons
# and armor from recipes. All crafting rules live in CraftingSystem/Inventory;
# this only lists defs and dispatches craft taps.
extends Control

@onready var materials_list: VBoxContainer = %MaterialsList
@onready var gear_list: VBoxContainer = %GearList
@onready var recipe_list: VBoxContainer = %RecipeList
@onready var back_button: Button = %BackButton

# Dense list rows use VT323 (the readable pixel font) rather than the blocky
# Press Start 2P default: the same split the design mockup uses. VT323 is far
# narrower, so long recipe ingredient lists fit within the panel instead of
# overflowing horizontally.
const LIST_FONT := preload("res://assets/fonts/vt323/VT323-Regular.woff2")
const LIST_FONT_SIZE := 22

func _style_list_label(label: Label) -> void:
	label.add_theme_font_override("font", LIST_FONT)
	label.add_theme_font_size_override("font_size", LIST_FONT_SIZE)

func _ready() -> void:
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://src/ui/launch/launch_screen.tscn"))
	_refresh()

func _refresh() -> void:
	_clear(materials_list)
	_clear(gear_list)
	_clear(recipe_list)

	for material_id in GameState.inventory.materials:
		var count: int = GameState.inventory.materials[material_id]
		if count <= 0:
			continue
		var def: MaterialDef = GameState.materials.get(material_id)
		var label := Label.new()
		label.text = "%s x%d" % [def.name if def != null else material_id, count]
		_style_list_label(label)
		materials_list.add_child(label)

	for instance in GameState.inventory.gear:
		var def_id: String = instance["def_id"]
		var def_name := def_id
		if GameState.weapons.has(def_id):
			def_name = GameState.weapons[def_id].name
		elif GameState.armors.has(def_id):
			def_name = GameState.armors[def_id].name
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_icon_rect(def_id))
		var label := Label.new()
		label.text = "%s [%s]" % [def_name, instance["rolled_stats"].get("rarity", "")]
		label.size_flags_vertical = SIZE_SHRINK_CENTER
		_style_list_label(label)
		row.add_child(label)
		gear_list.add_child(row)

	for def_id in GameState.weapons:
		_add_recipe_row(GameState.weapons[def_id])
	for def_id in GameState.armors:
		_add_recipe_row(GameState.armors[def_id])

func _add_recipe_row(def) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	row.add_child(_icon_rect(def.id))

	var label := Label.new()
	label.text = "%s (%s)" % [def.name, _recipe_text(def.recipe)]
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_list_label(label)
	row.add_child(label)

	var craft_button := Button.new()
	craft_button.text = "Craft"
	craft_button.disabled = not CraftingSystem.can_craft(def, GameState.inventory)
	craft_button.pressed.connect(_on_craft_pressed.bind(def))
	row.add_child(craft_button)

	recipe_list.add_child(row)

func _recipe_text(recipe: Dictionary) -> String:
	var parts: Array = []
	for material_id in recipe:
		var def: MaterialDef = GameState.materials.get(material_id)
		parts.append("%s x%d" % [def.name if def != null else material_id, int(recipe[material_id])])
	return ", ".join(parts)

func _on_craft_pressed(def) -> void:
	var result := CraftingSystem.craft(def, GameState.inventory, GameState.rng)
	if result["ok"]:
		GameState.persist()
		_refresh()

# A fixed 32x32 icon slot. Weapons show their sprite; anything without an icon
# (armor, or a weapon lacking art) gets an empty slot so rows stay aligned.
func _icon_rect(def_id: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(32, 32)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_vertical = SIZE_SHRINK_CENTER
	tr.texture = WeaponIcons.for_id(def_id)
	return tr

func _clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
