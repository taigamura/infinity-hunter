# Typed def for a companion entity, loaded from data/companions/*.json.
# One passive per captured species (bond/rarity/size/crown deferred — see PRD).
class_name CompanionDef
extends RefCounted

const SCHEMA := {
	"id": "string",
	"name": "string",
	"source_monster_id": "string",
	"passive_skill": "string",
	"passive_value": "number",
}

var id: String
var name: String
var source_monster_id: String
var passive_skill: String
var passive_value: float # Big

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err
	var def := CompanionDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.source_monster_id = data["source_monster_id"]
	def.passive_skill = data["passive_skill"]
	def.passive_value = float(data["passive_value"])
	return def
