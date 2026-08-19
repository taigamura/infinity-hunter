# Typed def for an armor piece, loaded from data/armor/*.json.
class_name ArmorDef
extends RefCounted

const SCHEMA := {
	"id": "string",
	"name": "string",
	"slot": "string", # head | chest | legs | ...
	"base_defense": "number",
	"skills": "array", # Array[String] — Crit, Attack Boost, XP Boost, ...
	"recipe": "dictionary", # material_id -> required count
}

var id: String
var name: String
var slot: String
var base_defense: float # Big
var skills: Array = []
var recipe: Dictionary = {}

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err
	var def := ArmorDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.slot = data["slot"]
	def.base_defense = float(data["base_defense"])
	def.skills = data["skills"]
	def.recipe = data["recipe"]
	return def
