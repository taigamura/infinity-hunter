# Typed def for a zone entity, loaded from data/zones/*.json.
#
# `palette` + `band_names` are the Deepening Trail's per-zone identity
# (ADR-0001 slice C): a 3-stop hex-colour gradient (safe -> mid -> hot) that
# OverworldTileset paints tiles from instead of a hardcoded constant, and an
# ordered list of terrain band names (shallow -> deep) surfaced by the
# overworld's hot-region strip. Kept as data so each zone can look and read
# distinctly with no code change.
class_name ZoneDef
extends RefCounted

const PALETTE_STOPS := 3
const HEX_COLOR_REGEX := "^#[0-9A-Fa-f]{6}$"

const SCHEMA := {
	"id": "string",
	"name": "string",
	"min_level": "number",
	"max_level": "number",
	"monster_ids": "array", # Array[String]
	"connections": "array", # Array[String] — travel-node zone ids
	"palette": "array", # Array[String], exactly 3 "#RRGGBB" hex colors: safe, mid, hot
	"band_names": "array", # Array[String], >=1 entries, shallow -> deep terrain names
}

var id: String
var name: String
var min_level: float # Big
var max_level: float # Big
var monster_ids: Array = []
var connections: Array = []
var palette: Array = [] # Array[String] hex colors, 3-stop safe -> mid -> hot
var band_names: Array = [] # Array[String], shallow -> deep terrain names

static func from_dict(data: Dictionary, source_path: String) -> Variant:
	var err := DataLoader.validate(data, SCHEMA, source_path)
	if err != "":
		return err

	var raw_palette: Array = data["palette"]
	if raw_palette.size() != PALETTE_STOPS:
		return "%s: 'palette' must contain exactly %d hex colors, got %d" % [source_path, PALETTE_STOPS, raw_palette.size()]
	var regex := RegEx.new()
	regex.compile(HEX_COLOR_REGEX)
	for stop in raw_palette:
		if typeof(stop) != TYPE_STRING or not regex.search(stop):
			return "%s: 'palette' entries must be '#RRGGBB' hex color strings, got '%s'" % [source_path, str(stop)]

	var raw_band_names: Array = data["band_names"]
	if raw_band_names.is_empty():
		return "%s: 'band_names' must contain at least one name" % source_path
	for band_name in raw_band_names:
		if typeof(band_name) != TYPE_STRING or band_name.is_empty():
			return "%s: 'band_names' entries must be non-empty strings, got '%s'" % [source_path, str(band_name)]

	var def := ZoneDef.new()
	def.id = data["id"]
	def.name = data["name"]
	def.min_level = float(data["min_level"])
	def.max_level = float(data["max_level"])
	def.monster_ids = data["monster_ids"]
	def.connections = data["connections"]
	def.palette = raw_palette
	def.band_names = raw_band_names
	return def

# Band name for a tier index within a zone's danger tiers (0 = safest), scaled
# onto however many band_names this zone defines (they needn't match tier
# count 1:1 — e.g. 4 named bands over 3 gauge tiers). Clamped defensively.
func band_name_for_tier_index(tier_index: int, tier_count: int) -> String:
	if band_names.is_empty():
		return ""
	if tier_count <= 0:
		return band_names[0]
	var ratio := clampf(float(tier_index) / float(tier_count), 0.0, 0.999)
	var idx := clampi(int(ratio * band_names.size()), 0, band_names.size() - 1)
	return band_names[idx]
