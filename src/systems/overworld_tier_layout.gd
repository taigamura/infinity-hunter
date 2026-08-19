# OverworldTierLayout — pure placement logic for the Verdant Fields vertical
# slice (issue #20): buckets a tilemap cell into a danger tier id by distance
# from the map center (center = safest/lowest tier, edges = most dangerous),
# so EncounterSystem sees a real spread of tiers to tick against instead of a
# uniform map. No scene/Node dependency, so it is headless-testable like
# EncounterSystem.
class_name OverworldTierLayout
extends RefCounted

const CORNER_DIST := sqrt(2.0)

# Returns the tier id (from `sorted_tier_ids`, ascending by danger) that
# `cell` falls into, given a `map_cols` x `map_rows` grid. Falls back to 0
# when `sorted_tier_ids` is empty.
static func tier_for_cell(cell: Vector2i, map_cols: int, map_rows: int, sorted_tier_ids: Array) -> int:
	if sorted_tier_ids.is_empty():
		return 0

	var center := Vector2(map_cols, map_rows) / 2.0
	var nx := (cell.x + 0.5 - center.x) / center.x
	var ny := (cell.y + 0.5 - center.y) / center.y
	var dist := sqrt(nx * nx + ny * ny)
	var normalized := clampf(dist / CORNER_DIST, 0.0, 1.0)

	var bucket := int(normalized * sorted_tier_ids.size())
	bucket = clampi(bucket, 0, sorted_tier_ids.size() - 1)
	return sorted_tier_ids[bucket]

# The map-corner cell (issue #22): always the highest-danger tier under
# `tier_for_cell`'s distance-from-center bucketing, so an exit placed here
# sits inside a hot region and the route to it crosses hotter terrain than
# the spawn point at map center.
static func exit_cell(map_cols: int, map_rows: int) -> Vector2i:
	return Vector2i(map_cols - 1, 0)
