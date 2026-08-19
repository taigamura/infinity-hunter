# Typed def for a weapon entity, loaded from data/weapons/*.json.
class_name WeaponDef
extends RefCounted

const SCHEMA := {
	"id": "string",
	"name": "string",
	"weapon_class": "string", # great_sword | dual_blades | hammer
	"element": "string",
	"base_damage": "number",
	"recipe": "dictionary", # material_id -> required count
}

var id: String
var name: String
var weapon_class: String
var element: String
var base_damage: float # Big
var recipe: Dictionary = {}

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err
	var def := WeaponDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.weapon_class = data["weapon_class"]
	def.element = data["element"]
	def.base_damage = float(data["base_damage"])
	# Recipe counts are integer material quantities; JSON parses numbers as
	# floats, so coerce to int for exact comparisons/consumption.
	def.recipe = {}
	for mat_id in data["recipe"]:
		def.recipe[mat_id] = int(data["recipe"][mat_id])
	return def
