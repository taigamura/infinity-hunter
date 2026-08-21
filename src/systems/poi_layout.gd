# PoiLayout — pure placement logic for the overworld points-of-interest layer
# (ADR-0001, the Deepening Trail, slice B; re-homed onto the Concentric
# Sections map by issue #41). Given the field's size, a SectionLayout.generate()
# result, and a seeded RandomNumberGenerator, returns a deterministic Array of
# POIs as {"cell": Vector2i, "type": String} so the ground reads as a place
# instead of a bare danger gradient: exactly one camp (spawn, at the section
# layout's camp cell) and one portal (exit, at its portal cell), a handful of
# dens biased toward mid/hot radial bands, forage nodes hugging the visible
# optimal path in safer bands, off-path caches as a detour in mid/hot bands,
# and at most one mid-field landmark. No scene/Node dependency, so it is
# headless-testable like SectionLayout/EncounterSystem; callers own the rng
# (same precedent as DropSystem/EncounterSystem) so results are reproducible
# for a given seed.
class_name PoiLayout
extends RefCounted

const SectionLayout = preload("res://src/systems/section_layout.gd")

# Band thresholds are cut on SectionLayout.distance_ratio (0 = camp/center,
# 1 = outer-ring edge) rather than on the zone's actual section count,
# because a map may resolve as few as one section for a degenerate tiny grid,
# which would otherwise collapse "mid"/"hot" into "safe" for every cell.
# Depth is continuous and always has range, so thirds are meaningful
# regardless of how many sections a layout happens to generate.
const SAFE_MAX_DEPTH := 1.0 / 3.0
const HOT_MIN_DEPTH := 2.0 / 3.0

# How close (in tiles, Chebyshev distance to the nearest path cell) a cell
# must be to the visible optimal path to count as "near the path" (forage)
# or "off the path" (cache, a deliberate detour).
const TRAIL_NEAR_MARGIN := 3
const TRAIL_OFF_MARGIN := 5

# Bounded retries when hunting for a cell that satisfies a band/path/
# occupancy constraint, so a pathological map size can never hang generation.
const MAX_PLACEMENT_ATTEMPTS := 300

# Builds the full POI list for a `map_cols` x `map_rows` field, given
# `section_layout` (a SectionLayout.generate() result — its camp/portal/
# path_cells drive placement here). Band classification is done on the
# continuous distance ratio (see the comment on the band constants above),
# not on section-id count.
static func generate(map_cols: int, map_rows: int, section_layout: Dictionary, rng: RandomNumberGenerator) -> Array:
	var pois: Array = []
	var occupied: Dictionary = {}

	var camp: Vector2i = section_layout.get("camp", SectionLayout.camp_cell(map_cols, map_rows))
	pois.append({"cell": camp, "type": "camp"})
	occupied[camp] = true

	var portal: Vector2i = section_layout.get("portal", camp)
	if not occupied.has(portal):
		pois.append({"cell": portal, "type": "portal"})
		occupied[portal] = true

	var path_cells: Array = section_layout.get("path_cells", [])

	_place_many(pois, occupied, rng, map_cols, map_rows, path_cells,
		rng.randi_range(1, 3), "den", SAFE_MAX_DEPTH, 1.0, "")
	_place_many(pois, occupied, rng, map_cols, map_rows, path_cells,
		rng.randi_range(1, 3), "forage", 0.0, HOT_MIN_DEPTH, "near")
	_place_many(pois, occupied, rng, map_cols, map_rows, path_cells,
		rng.randi_range(0, 2), "cache", SAFE_MAX_DEPTH, 1.0, "off")
	_place_many(pois, occupied, rng, map_cols, map_rows, path_cells,
		rng.randi_range(0, 1), "landmark", SAFE_MAX_DEPTH, HOT_MIN_DEPTH, "")

	return pois

# Attempts to place `count` POIs of `type_name` into `pois`/`occupied`,
# constrained to depth in [min_depth, max_depth] and, when `path_mode` is
# "near"/"off", within/beyond TRAIL_NEAR_MARGIN/TRAIL_OFF_MARGIN tiles of the
# nearest `path_cells` cell. Silently places fewer than `count` if the map is
# too small/constrained to find a free cell within MAX_PLACEMENT_ATTEMPTS —
# never hangs, never throws.
static func _place_many(pois: Array, occupied: Dictionary, rng: RandomNumberGenerator, map_cols: int, map_rows: int,
		path_cells: Array, count: int, type_name: String, min_depth: float, max_depth: float, path_mode: String) -> void:
	for _i in range(count):
		var cell := _pick_cell(rng, map_cols, map_rows, occupied, path_cells, min_depth, max_depth, path_mode)
		if cell.x < 0:
			continue
		pois.append({"cell": cell, "type": type_name})
		occupied[cell] = true

# Random-samples cells until one satisfies the depth band + path constraint
# and isn't already occupied, or gives up after MAX_PLACEMENT_ATTEMPTS and
# returns the (-1, -1) sentinel for "couldn't place".
static func _pick_cell(rng: RandomNumberGenerator, map_cols: int, map_rows: int, occupied: Dictionary,
		path_cells: Array, min_depth: float, max_depth: float, path_mode: String) -> Vector2i:
	for _attempt in range(MAX_PLACEMENT_ATTEMPTS):
		var x := rng.randi_range(0, map_cols - 1)
		var y := rng.randi_range(0, map_rows - 1)
		var cell := Vector2i(x, y)
		if occupied.has(cell):
			continue
		var depth := SectionLayout.distance_ratio(cell, map_cols, map_rows)
		if depth < min_depth or depth > max_depth:
			continue
		if path_mode != "":
			var dist := _distance_to_path(cell, path_cells)
			if path_mode == "near" and dist > TRAIL_NEAR_MARGIN:
				continue
			if path_mode == "off" and dist <= TRAIL_OFF_MARGIN:
				continue
		return cell
	return Vector2i(-1, -1)

# Chebyshev distance from `cell` to the nearest cell in `path_cells`. Returns
# a large sentinel when `path_cells` is empty (degenerate layout) so "near"
# placement simply never matches and "off" placement always matches.
static func _distance_to_path(cell: Vector2i, path_cells: Array) -> int:
	var best := 999999
	for path_cell in path_cells:
		var dist := maxi(absi(cell.x - path_cell.x), absi(cell.y - path_cell.y))
		if dist < best:
			best = dist
	return best
