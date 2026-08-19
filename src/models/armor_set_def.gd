# Typed def for an armor set's piece-count bonuses, loaded from
# data/armor_sets/*.json. Bonuses stack with the flat skill points ArmorDef
# pieces already grant (see SkillSystem) once enough pieces from the same
# set are equipped simultaneously.
class_name ArmorSetDef
extends RefCounted

const SCHEMA := {
	"id": "string", # matches ArmorDef.set_id
	"name": "string",
	"thresholds": "array", # [{pieces: int, skill: String, points: number}, ...]
}

var id: String
var name: String
var thresholds: Array = []

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err
	var def := ArmorSetDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.thresholds = data["thresholds"]
	return def
