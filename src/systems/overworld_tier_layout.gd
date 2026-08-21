# OverworldTierLayout — pure placement logic for the overworld field
# (ADR-0001, the Deepening Trail): buckets a tilemap cell into a danger tier
# id by DEPTH along the vertical travel axis (near/bottom edge = safest,
# far/top edge = most dangerous), so EncounterSystem sees a real spread of
# tiers to tick against instead of a uniform map. Also places the near-edge
# camp (spawn), the deep-edge on-trail portal (exit_cell), and the winding
# trail spine's x-position per row. No scene/Node dependency, so it is
# headless-testable like EncounterSystem.
class_name OverworldTierLayout
extends RefCounted

# How many full left-right sine sweeps the trail makes from camp to portal.
const TRAIL_WINDINGS := 1.5
# Trail sway as a fraction of map width either side of center, clamped away
# from the map edges so the corridor never runs off the playable field.
const TRAIL_AMPLITUDE_FRACTION := 0.28

# Normalized 0..1 depth of `cell` along the vertical travel axis (0 = near
# edge / bottom row / safest, 1 = far edge / top row / most dangerous).
# Depth depends only on row (y); every cell in a row shares the same depth,
# which is what makes danger read as bands across the field rather than a
# ring. `map_cols` is accepted (and unused) to keep the call signature
# uniform with the rest of this module and its callers. Shared by
# tier_for_cell (gameplay bucketing) and OverworldTileset (continuous colour
# gradient) so both read off the same notion of "how deep toward the portal".
static func depth_ratio(cell: Vector2i, _map_cols: int, map_rows: int) -> float:
	if map_rows <= 1:
		return 0.0
	var ratio := float(map_rows - 1 - cell.y) / float(map_rows - 1)
	return clampf(ratio, 0.0, 1.0)

# Returns the tier id (from `sorted_tier_ids`, ascending by danger) that
# `cell` falls into, given a `map_cols` x `map_rows` grid. Falls back to 0
# when `sorted_tier_ids` is empty.
static func tier_for_cell(cell: Vector2i, map_cols: int, map_rows: int, sorted_tier_ids: Array) -> int:
	if sorted_tier_ids.is_empty():
		return 0

	var normalized := depth_ratio(cell, map_cols, map_rows)
	var bucket := int(normalized * sorted_tier_ids.size())
	bucket = clampi(bucket, 0, sorted_tier_ids.size() - 1)
	return sorted_tier_ids[bucket]

# The camp tile (spawn point): centered horizontally on the near (bottom,
# safest) edge of the field.
static func camp_cell(map_cols: int, map_rows: int) -> Vector2i:
	return Vector2i(map_cols / 2, map_rows - 1)

# The trail spine's column for a given row: a bounded sine sweep anchored so
# it passes through the camp's x at the near edge (row = map_rows - 1),
# widening/narrowing smoothly as it winds up toward the portal at row 0.
# Shared by exit_cell (portal placement) and the overworld screen's trail
# tint pass so both agree on where the corridor runs.
static func trail_x_for_row(row: int, map_cols: int, map_rows: int) -> int:
	var center_x := float(map_cols) / 2.0
	if map_rows <= 1:
		return int(round(center_x))
	var amplitude := float(map_cols) * TRAIL_AMPLITUDE_FRACTION
	# t = 0 at the near edge (camp row), t = 1 at the far edge (portal row),
	# so the sine starts at the camp's x (sin(0) == 0) and sweeps outward as
	# depth increases.
	var t := float(map_rows - 1 - row) / float(map_rows - 1)
	var phase := t * TAU * TRAIL_WINDINGS
	var x := center_x + amplitude * sin(phase)
	return clampi(int(round(x)), 1, map_cols - 2)

# The portal tile (issue #22 exit, ADR-0001): an on-trail cell in the
# deepest band (top row, at the trail's x for y = 0) instead of the old
# top-right corner. Always the highest-danger tier under tier_for_cell's
# depth bucketing, so the route to it crosses hotter terrain than the camp
# spawn at the near edge.
static func exit_cell(map_cols: int, map_rows: int) -> Vector2i:
	return Vector2i(trail_x_for_row(0, map_cols, map_rows), 0)
