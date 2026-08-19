# Typed def for a material entity, loaded from data/materials/*.json.
class_name MaterialDef
extends RefCounted

const SCHEMA := {
	"id": "string",
	"name": "string",
	"rarity": "string", # Common | Uncommon | Rare | Epic
	"description": "string",
}

var id: String
var name: String
var rarity: String
var description: String

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err
	var def := MaterialDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.rarity = data["rarity"]
	def.description = data["description"]
	return def
