# Typed def for a monster entity, loaded from data/monsters/*.json.
class_name MonsterDef
extends RefCounted

const SCHEMA := {
	"id": "string",
	"name": "string",
	"level": "number",
	"element": "string",
	"base_hp": "number",
	"base_attack": "number",
	"xp_reward": "number",
	"zone_id": "string",
}

var id: String
var name: String
var level: float # Big
var element: String
var base_hp: float # Big
var base_attack: float # Big
var xp_reward: float # Big
var zone_id: String
var parts: Array = [] # Array[String] — breakable part names
var capturable: bool = false
var capture_hp_threshold: float = 0.0 # Big — fraction of base_hp, e.g. 0.2

# Returns a MonsterDef on success, or a String error naming source_path + field.
static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err
	var def := MonsterDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.level = float(data["level"])
	def.element = data["element"]
	def.base_hp = float(data["base_hp"])
	def.base_attack = float(data["base_attack"])
	def.xp_reward = float(data["xp_reward"])
	def.zone_id = data["zone_id"]
	def.parts = data.get("parts", [])
	def.capturable = data.get("capturable", false)
	def.capture_hp_threshold = float(data.get("capture_hp_threshold", 0.0))
	return def
