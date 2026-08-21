# SectionLayout — path-first section generator for the Concentric Sections
# overworld (PRD issue #36, tracer bullet #37, full generator #39). Builds a
# radial map in two passes: (1) carve a straight path from the center camp
# out to the rng-placed outer-ring portal, banding it into 3-4 concentric
# RINGS with a gently-rising recommended level so the path is guaranteed
# traversable and monotonically non-decreasing in danger by construction;
# (2) scatter the remaining space with ~8-14 total variable-size FILL
# sections, each an rng-picked seed cell with a recommended level loosely
# correlated with how far out its seed sits (own ring, plus jitter), and each
# section's gauge_rate derived from its recommended level so deadlier
# sections swarm harder. Off-path cells resolve to their nearest fill seed
# (a cheap Voronoi partition) instead of a precomputed per-cell dictionary,
# keeping memory flat regardless of map size, same precedent as the old ring
# bucketing this replaces. No scene/Node dependency, so it is
# headless-testable like OverworldTierLayout/PoiLayout; callers own the rng.
class_name SectionLayout
extends RefCounted

const MIN_RINGS := 3
const MAX_RINGS := 4
const MIN_FILL_SECTIONS := 5
const MAX_FILL_SECTIONS := 10

# Bounded retries when hunting for a free fill-seed cell, so a pathological
# map size can never hang generation (same precedent as PoiLayout).
const MAX_PLACEMENT_ATTEMPTS := 300

# gauge_rate = BASE_GAUGE_RATE + level * GAUGE_RATE_PER_LEVEL — deadlier
# (higher recommended level) sections swarm harder. Tuned to land in the same
# ballpark as the old hand-authored data/tiers/*.json rates (roughly 6..16
# across verdant_fields' level 1..8 span).
const BASE_GAUGE_RATE := 5.0
const GAUGE_RATE_PER_LEVEL := 1.5

# Fill-section level roll: the seed's own ring midpoint level, jittered by up
# to this fraction of the zone's full level span either way — "loosely
# correlated with ring distance" per the spec, not a hard band.
const FILL_LEVEL_JITTER_FRACTION := 0.15

# Normalized 0..1 radial distance of `cell` from the map center (0 = center,
# 1 = the outer ring). Normalized against the largest radius that still fits
# on-grid (half of the shorter map dimension) so the outer ring never runs
# off the playable field on a non-square map.
static func distance_ratio(cell: Vector2i, map_cols: int, map_rows: int) -> float:
	var center := Vector2(float(map_cols - 1) / 2.0, float(map_rows - 1) / 2.0)
	var max_radius := minf(center.x, center.y)
	if max_radius <= 0.0:
		return 0.0
	var dist := Vector2(cell).distance_to(center)
	return clampf(dist / max_radius, 0.0, 1.0)

# The camp cell (spawn point): the map's center — the mildest section.
static func camp_cell(map_cols: int, map_rows: int) -> Vector2i:
	return Vector2i(map_cols / 2, map_rows / 2)

# The portal cell: on the outer ring, at an rng-picked angle around the
# center so a run doesn't always place it at the same compass point. Caller
# supplies the rng, so this stays deterministic for a fixed seed.
static func portal_cell(map_cols: int, map_rows: int, rng: RandomNumberGenerator) -> Vector2i:
	var center := Vector2(float(map_cols - 1) / 2.0, float(map_rows - 1) / 2.0)
	var max_radius := minf(center.x, center.y)
	var angle := rng.randf_range(0.0, TAU)
	var x := center.x + max_radius * cos(angle)
	var y := center.y + max_radius * sin(angle)
	return Vector2i(clampi(int(round(x)), 0, map_cols - 1), clampi(int(round(y)), 0, map_rows - 1))

# Builds the full path-first section layout for a `map_cols` x `map_rows`
# field. `min_level`/`max_level` (a zone's recommended level span, e.g.
# ZoneDef.min_level/max_level) drive the level roll for both the path rings
# and the fill sections. Returns a Dictionary consumed by section_for_cell:
# {
#   "camp": Vector2i, "portal": Vector2i,
#   "path_cells": Array[Vector2i]  (ordered camp -> portal, for trail render),
#   "ring_count": int,
#   "path_section_ids": Array[int] (ascending by ring/level, index == ring),
#   "fill_sections": Array[{"id": int, "seed": Vector2i, "level": float}],
#   "params": Dictionary  (section id -> {level_min, level_max, gauge_rate}),
#   "section_ids": Array[int]  (every section id, ascending by level),
# }
static func generate(map_cols: int, map_rows: int, min_level: float, max_level: float, rng: RandomNumberGenerator) -> Dictionary:
	var camp := camp_cell(map_cols, map_rows)
	var portal := portal_cell(map_cols, map_rows, rng)
	var path_cells := _line_cells(camp, portal)
	var path_cell_set := {}
	for cell in path_cells:
		path_cell_set[cell] = true

	var ring_count := rng.randi_range(MIN_RINGS, MAX_RINGS)
	var level_span := maxf(max_level - min_level, 0.0)

	var params := {}
	var path_section_ids: Array = []
	for ring in range(ring_count):
		var ring_mid := (float(ring) + 0.5) / float(ring_count)
		var level := min_level + level_span * ring_mid
		var section_id := ring
		path_section_ids.append(section_id)
		params[section_id] = _section_params(level, level_span, ring_count)

	var fill_count := rng.randi_range(MIN_FILL_SECTIONS, MAX_FILL_SECTIONS)
	var next_id := ring_count
	var fill_sections: Array = []
	var occupied := path_cell_set.duplicate()
	for _i in range(fill_count):
		var seed_cell := _pick_fill_seed(rng, map_cols, map_rows, occupied)
		if seed_cell.x < 0:
			continue
		occupied[seed_cell] = true
		var ratio := distance_ratio(seed_cell, map_cols, map_rows)
		var ring := clampi(int(ratio * ring_count), 0, ring_count - 1)
		var base_level: float = min_level + level_span * ((float(ring) + 0.5) / float(ring_count))
		var jitter := level_span * FILL_LEVEL_JITTER_FRACTION
		var level := clampf(base_level + rng.randf_range(-jitter, jitter), min_level, max_level)
		var section_id := next_id
		next_id += 1
		fill_sections.append({"id": section_id, "seed": seed_cell, "level": level})
		params[section_id] = _section_params(level, level_span, ring_count)

	var section_ids: Array = path_section_ids.duplicate()
	for fill in fill_sections:
		section_ids.append(fill["id"])
	section_ids.sort_custom(func(a, b): return params[a]["level_min"] < params[b]["level_min"])

	return {
		"camp": camp,
		"portal": portal,
		"path_cells": path_cells,
		"path_cell_set": path_cell_set,
		"ring_count": ring_count,
		"path_section_ids": path_section_ids,
		"fill_sections": fill_sections,
		"params": params,
		"section_ids": section_ids,
	}

# Returns the section id `cell` falls into: an on-path cell resolves to its
# ring's path section (ring picked by the cell's own radial distance, so
# level rises monotonically walking outward along the path); every other
# cell resolves to its nearest fill-section seed (a cheap Voronoi partition,
# no precomputed per-cell dictionary needed). Falls back to path section 0
# when a layout has no fill sections at all (degenerate tiny map).
static func section_for_cell(cell: Vector2i, map_cols: int, map_rows: int, layout: Dictionary) -> int:
	var path_section_ids: Array = layout.get("path_section_ids", [])
	if path_section_ids.is_empty():
		return 0
	var path_cell_set: Dictionary = layout.get("path_cell_set", {})
	if path_cell_set.has(cell):
		var ring_count: int = layout.get("ring_count", path_section_ids.size())
		var ratio := distance_ratio(cell, map_cols, map_rows)
		var ring := clampi(int(ratio * ring_count), 0, ring_count - 1)
		return path_section_ids[ring]

	var fill_sections: Array = layout.get("fill_sections", [])
	if fill_sections.is_empty():
		var ring_count: int = layout.get("ring_count", path_section_ids.size())
		var ratio := distance_ratio(cell, map_cols, map_rows)
		var ring := clampi(int(ratio * ring_count), 0, ring_count - 1)
		return path_section_ids[ring]

	var best_id: int = fill_sections[0]["id"]
	var best_dist := INF
	for fill in fill_sections:
		var seed: Vector2i = fill["seed"]
		var dist := Vector2(cell - seed).length_squared()
		if dist < best_dist:
			best_dist = dist
			best_id = fill["id"]
	return best_id

# level_min/level_max/gauge_rate for a section rolled at `level`. Spread is a
# ring-width's worth of levels either side (bounded to at least 1) so bands
# overlap gently like the old hand-authored tier tables did.
static func _section_params(level: float, level_span: float, ring_count: int) -> Dictionary:
	var spread := maxf(1.0, level_span / float(maxi(ring_count, 1)))
	var level_min := maxf(1.0, level - spread / 2.0)
	var level_max := level_min + spread
	return {
		"level_min": level_min,
		"level_max": level_max,
		"gauge_rate": BASE_GAUGE_RATE + level * GAUGE_RATE_PER_LEVEL,
	}

# Random-samples cells until one is free of `occupied`, or gives up after
# MAX_PLACEMENT_ATTEMPTS and returns the (-1, -1) sentinel for "couldn't
# place" (bounded retries so a pathological map size never hangs, same
# precedent as PoiLayout._pick_cell).
static func _pick_fill_seed(rng: RandomNumberGenerator, map_cols: int, map_rows: int, occupied: Dictionary) -> Vector2i:
	for _attempt in range(MAX_PLACEMENT_ATTEMPTS):
		var cell := Vector2i(rng.randi_range(0, map_cols - 1), rng.randi_range(0, map_rows - 1))
		if not occupied.has(cell):
			return cell
	return Vector2i(-1, -1)

# Bresenham line rasterization from `from` to `to`, inclusive of both
# endpoints — always terminates in a bounded number of steps (the Chebyshev
# distance between the two cells), so the path is guaranteed connected and
# generation never hangs regardless of map size.
static func _line_cells(from: Vector2i, to: Vector2i) -> Array:
	var cells: Array = []
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return cells
