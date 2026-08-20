# Typed def for a zone's danger-tier table, loaded from data/tiers/*.json.
# Terrain tiles paint a tier id (int, JSON-keyed as a string); this table maps
# each tier id to the params EncounterSystem.tick/pick_monster consume:
# level_min, level_max, gauge_rate, weight. `loot_boost` is a reserved field
# for a future milestone — nothing reads it yet.
class_name TierTableDef
extends RefCounted

const SCHEMA := {
	"zone_id": "string",
	"tiers": "dictionary", # tier id (String) -> tier entry Dictionary
}

const TIER_ENTRY_SCHEMA := {
	"level_min": "number",
	"level_max": "number",
	"gauge_rate": "number",
	"weight": "number",
}

var id: String # == zone_id, for DataLoader.load_directory dedupe
var zone_id: String
var tiers: Dictionary = {} # tier id (String) -> {level_min, level_max, gauge_rate, weight, loot_boost?}

# Returns the tier_params Dictionary for `tier_id` (accepts int or String),
# or an empty Dictionary if the tier is unknown.
func tier_params(tier_id) -> Dictionary:
	return tiers.get(str(tier_id), {})

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err

	var raw_tiers: Dictionary = data["tiers"]
	if raw_tiers.is_empty():
		return "%s: 'tiers' must contain at least one tier entry" % source_path

	for tier_id in raw_tiers:
		var entry = raw_tiers[tier_id]
		if typeof(entry) != TYPE_DICTIONARY:
			return "%s: tier '%s' expected dictionary, got %s" % [source_path, tier_id, typeof(entry)]
		var entry_err := DataLoader.validate(entry, TIER_ENTRY_SCHEMA, "%s (tier %s)" % [source_path, tier_id])
		if entry_err != "":
			return entry_err

	var def := TierTableDef.new()
	def.id = data["zone_id"]
	def.zone_id = data["zone_id"]
	def.tiers = raw_tiers
	return def
