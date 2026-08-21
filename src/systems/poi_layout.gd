# PoiLayout — pure placement logic for the overworld points-of-interest layer
# (ADR-0001, the Deepening Trail, slice B). Given the field's size and a
# seeded RandomNumberGenerator, returns a deterministic Array of POIs as
# {"cell": Vector2i, "type": String} so the ground reads as a place instead
# of a bare danger gradient: exactly one camp (spawn) and one portal (exit),
# a handful of dens biased toward mid/hot depth, forage nodes hugging the
# trail in safer bands, off-trail caches as a detour in mid/hot bands, and at
# most one mid-field landmark. No scene/Node dependency, so it is
# headless-testable like OverworldTierLayout/EncounterSystem; callers own the
# rng (same precedent as DropSystem/EncounterSystem) so results are
# reproducible for a given seed.
class_name PoiLayout
extends RefCounted

# Band thresholds are cut on OverworldTierLayout.depth_ratio (0 = camp edge,
# 1 = portal edge) rather than on the zone's actual tier-id count, because a
# zone may define as few as one danger tier (see verdant_fields.json) which
# would otherwise collapse "mid"/"hot" into "safe" for every cell. Depth is
# continuous and always has range, so thirds are meaningful regardless of how
# many discrete tiers a zone's table happens to define.
const SAFE_MAX_DEPTH := 1.0 / 3.0
const HOT_MIN_DEPTH := 2.0 / 3.0

# How close (in tiles) a cell must be to the trail spine to count as "near
# the trail" (forage) or "off the trail" (cache, a deliberate detour).
const TRAIL_NEAR_MARGIN := 3
const TRAIL_OFF_MARGIN := 5

# Bounded retries when hunting for a cell that satisfies a band/trail/
# occupancy constraint, so a pathological map size can never hang generation.
const MAX_PLACEMENT_ATTEMPTS := 300

# Builds the full POI list for a `map_cols` x `map_rows` field. `sorted_tier_ids`
# is accepted (ascending by danger, same shape OverworldTierLayout callers
# already carry) to mirror that module's call signature and leave room for
# per-zone tier-aware placement later; band classification itself is done on
# the continuous depth ratio (see the comment on the band constants above),
# not on tier-id count, so a single-tier zone still gets a real mid/hot spread.
static func generate(map_cols: int, map_rows: int, sorted_tier_ids: Array, rng: RandomNumberGenerator) -> Array:
	var pois: Array = []
	var occupied: Dictionary = {}

	var camp := OverworldTierLayout.camp_cell(map_cols, map_rows)
	pois.append({"cell": camp, "type": "camp"})
	occupied[camp] = true

	var portal := OverworldTierLayout.exit_cell(map_cols, map_rows)
	if not occupied.has(portal):
		pois.append({"cell": portal, "type": "portal"})
		occupied[portal] = true

	_place_many(pois, occupied, rng, map_cols, map_rows,
		rng.randi_range(1, 3), "den", SAFE_MAX_DEPTH, 1.0, "")
	_place_many(pois, occupied, rng, map_cols, map_rows,
		rng.randi_range(1, 3), "forage", 0.0, HOT_MIN_DEPTH, "near")
	_place_many(pois, occupied, rng, map_cols, map_rows,
		rng.randi_range(0, 2), "cache", SAFE_MAX_DEPTH, 1.0, "off")
	_place_many(pois, occupied, rng, map_cols, map_rows,
		rng.randi_range(0, 1), "landmark", SAFE_MAX_DEPTH, HOT_MIN_DEPTH, "")

	return pois

# Attempts to place `count` POIs of `type_name` into `pois`/`occupied`,
# constrained to depth in [min_depth, max_depth] and, when `trail_mode` is
# "near"/"off", within/beyond TRAIL_NEAR_MARGIN/TRAIL_OFF_MARGIN tiles of the
# trail spine for that row. Silently places fewer than `count` if the map is
# too small/constrained to find a free cell within MAX_PLACEMENT_ATTEMPTS —
# never hangs, never throws.
static func _place_many(pois: Array, occupied: Dictionary, rng: RandomNumberGenerator, map_cols: int, map_rows: int,
		count: int, type_name: String, min_depth: float, max_depth: float, trail_mode: String) -> void:
	for _i in range(count):
		var cell := _pick_cell(rng, map_cols, map_rows, occupied, min_depth, max_depth, trail_mode)
		if cell.x < 0:
			continue
		pois.append({"cell": cell, "type": type_name})
		occupied[cell] = true

# Random-samples cells until one satisfies the depth band + trail constraint
# and isn't already occupied, or gives up after MAX_PLACEMENT_ATTEMPTS and
# returns the (-1, -1) sentinel for "couldn't place".
static func _pick_cell(rng: RandomNumberGenerator, map_cols: int, map_rows: int, occupied: Dictionary,
		min_depth: float, max_depth: float, trail_mode: String) -> Vector2i:
	for _attempt in range(MAX_PLACEMENT_ATTEMPTS):
		var x := rng.randi_range(0, map_cols - 1)
		var y := rng.randi_range(0, map_rows - 1)
		var cell := Vector2i(x, y)
		if occupied.has(cell):
			continue
		var depth := OverworldTierLayout.depth_ratio(cell, map_cols, map_rows)
		if depth < min_depth or depth > max_depth:
			continue
		if trail_mode != "":
			var trail_x := OverworldTierLayout.trail_x_for_row(y, map_cols, map_rows)
			var dist := absi(x - trail_x)
			if trail_mode == "near" and dist > TRAIL_NEAR_MARGIN:
				continue
			if trail_mode == "off" and dist <= TRAIL_OFF_MARGIN:
				continue
		return cell
	return Vector2i(-1, -1)
