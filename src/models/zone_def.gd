# Typed def for a zone entity, loaded from data/zones/*.json.
class_name ZoneDef
extends RefCounted

const SCHEMA := {
	"id": "string",
	"name": "string",
	"min_level": "number",
	"max_level": "number",
	"monster_ids": "array", # Array[String]
	"connections": "array", # Array[String] — travel-node zone ids
}

var id: String
var name: String
var min_level: float # Big
var max_level: float # Big
var monster_ids: Array = []
var connections: Array = []

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err
	var def := ZoneDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.min_level = float(data["min_level"])
	def.max_level = float(data["max_level"])
	def.monster_ids = data["monster_ids"]
	def.connections = data["connections"]
	return def
