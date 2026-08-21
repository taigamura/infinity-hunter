# SectionLayout — pure placement logic for the Concentric Sections overworld
# (PRD issue #36, tracer bullet issue #37): buckets a tilemap cell into a
# section id by RADIAL DISTANCE from the map center (center = safest, outer
# ring = most dangerous), replacing OverworldTierLayout's row-depth banding
# as the geometry that drives spawn placement, tile shading, and
# EncounterSystem.tick's tier_params. Section ids and their encounter params
# (gauge_rate, jitter, level_min, level_max) still come from the zone's
# existing TierTableDef — this module only decides WHICH section a cell (or
# the camp/portal) belongs to. No scene/Node dependency, so it is
# headless-testable like OverworldTierLayout/PoiLayout; callers own the rng
# (same precedent as DropSystem/EncounterSystem/PoiLayout).
class_name SectionLayout
extends RefCounted

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

# Returns the section id (from `sorted_section_ids`, ascending by recommended
# level/danger) that `cell` falls into, ring-bucketed by distance_ratio.
# Mirrors OverworldTierLayout.tier_for_cell's bucketing exactly, just keyed
# on radial distance from center instead of row depth. Falls back to 0 when
# `sorted_section_ids` is empty.
static func section_for_cell(cell: Vector2i, map_cols: int, map_rows: int, sorted_section_ids: Array) -> int:
	if sorted_section_ids.is_empty():
		return 0
	var normalized := distance_ratio(cell, map_cols, map_rows)
	var bucket := int(normalized * sorted_section_ids.size())
	bucket = clampi(bucket, 0, sorted_section_ids.size() - 1)
	return sorted_section_ids[bucket]

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

# Bundles the section geometry for a `map_cols` x `map_rows` field: the
# sorted section ids (passed through, ascending danger outward), the center
# camp cell, and an rng-placed outer-ring portal cell. The per-cell lookup
# itself is `section_for_cell` above (called per-tile/per-frame the same way
# OverworldTierLayout.tier_for_cell is), not a precomputed dictionary — keeps
# memory flat regardless of map size.
static func generate(map_cols: int, map_rows: int, sorted_section_ids: Array, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"section_ids": sorted_section_ids,
		"camp": camp_cell(map_cols, map_rows),
		"portal": portal_cell(map_cols, map_rows, rng),
	}
