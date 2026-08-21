# Tests for SectionLayout (src/systems/section_layout.gd): the path-first
# Concentric Sections generator (PRD issue #36, full generator #39) — a
# traversable, monotonically non-decreasing camp -> portal path banded into
# rings, plus off-path fill sections partitioned by nearest-seed, bounded
# section counts, full-map coverage, and per-seed determinism.
extends "res://tests/test_case.gd"

const SectionLayout = preload("res://src/systems/section_layout.gd")

const MAP_COLS := 30
const MAP_ROWS := 40
const MIN_LEVEL := 1.0
const MAX_LEVEL := 8.0

func _generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return SectionLayout.generate(MAP_COLS, MAP_ROWS, MIN_LEVEL, MAX_LEVEL, rng)

func test_camp_cell_sits_at_the_map_center() -> void:
	var cell := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	assert_eq(cell.x, MAP_COLS / 2)
	assert_eq(cell.y, MAP_ROWS / 2)

func test_distance_ratio_is_zero_at_center() -> void:
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var ratio := SectionLayout.distance_ratio(center, MAP_COLS, MAP_ROWS)
	assert_almost_eq(ratio, 0.0, 0.1)

func test_distance_ratio_is_one_at_the_outer_edge() -> void:
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var ratio := SectionLayout.distance_ratio(Vector2i(center.x, 0), MAP_COLS, MAP_ROWS)
	assert_almost_eq(ratio, 1.0, 0.05)

func test_portal_cell_is_deterministic_for_a_fixed_seed() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 42
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 42
	var portal_a := SectionLayout.portal_cell(MAP_COLS, MAP_ROWS, rng_a)
	var portal_b := SectionLayout.portal_cell(MAP_COLS, MAP_ROWS, rng_b)
	assert_eq(portal_a, portal_b)

func test_portal_cell_stays_within_map_bounds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for _i in range(20):
		var portal := SectionLayout.portal_cell(MAP_COLS, MAP_ROWS, rng)
		assert_true(portal.x >= 0 and portal.x < MAP_COLS, "portal x out of bounds")
		assert_true(portal.y >= 0 and portal.y < MAP_ROWS, "portal y out of bounds")

func test_path_connects_camp_to_portal() -> void:
	var layout := _generate(3)
	var path: Array = layout["path_cells"]
	assert_true(path.size() > 0, "path must not be empty")
	assert_eq(path[0], layout["camp"])
	assert_eq(path[-1], layout["portal"])

func test_path_is_traversable_step_by_step() -> void:
	var layout := _generate(3)
	var path: Array = layout["path_cells"]
	for i in range(1, path.size()):
		var prev: Vector2i = path[i - 1]
		var cur: Vector2i = path[i]
		var step := (cur - prev).abs()
		assert_true(step.x <= 1 and step.y <= 1, "path must move one cell at a time with no gaps")

func test_path_level_rises_monotonically_outward() -> void:
	var layout := _generate(5)
	var path: Array = layout["path_cells"]
	var params: Dictionary = layout["params"]
	var prev_level := -INF
	for cell in path:
		var section_id := SectionLayout.section_for_cell(cell, MAP_COLS, MAP_ROWS, layout)
		var level: float = params[section_id]["level_min"]
		assert_true(level >= prev_level - 0.001, "recommended level must not decrease moving toward the portal")
		prev_level = level

func test_ring_count_is_within_intended_range() -> void:
	var layout := _generate(11)
	var ring_count: int = layout["ring_count"]
	assert_true(ring_count >= 3 and ring_count <= 4, "ring count should be 3-4")

func test_total_section_count_is_within_intended_range() -> void:
	var layout := _generate(11)
	var total: int = layout["section_ids"].size()
	assert_true(total >= 8 and total <= 14, "total sections should land in the 8-14 range")

func test_every_cell_resolves_to_a_known_section() -> void:
	var layout := _generate(7)
	var known: Array = layout["section_ids"]
	for x in range(0, MAP_COLS, 3):
		for y in range(0, MAP_ROWS, 3):
			var section_id := SectionLayout.section_for_cell(Vector2i(x, y), MAP_COLS, MAP_ROWS, layout)
			assert_true(known.has(section_id), "every cell must resolve to a generated section id")

func test_gauge_rate_scales_with_recommended_level() -> void:
	var layout := _generate(4)
	var params: Dictionary = layout["params"]
	var ids: Array = layout["section_ids"]
	var prev_rate := -INF
	for section_id in ids:
		var rate: float = params[section_id]["gauge_rate"]
		assert_true(rate >= prev_rate - 0.001, "gauge_rate should rise alongside recommended level")
		prev_rate = rate

func test_generation_is_deterministic_for_a_fixed_seed() -> void:
	var layout_a := _generate(123)
	var layout_b := _generate(123)
	assert_eq(layout_a["camp"], layout_b["camp"])
	assert_eq(layout_a["portal"], layout_b["portal"])
	assert_eq(layout_a["path_cells"], layout_b["path_cells"])
	assert_eq(layout_a["section_ids"], layout_b["section_ids"])

func test_spike_section_count_is_bounded() -> void:
	var layout := _generate(11)
	var spike_ids: Array = layout["spike_section_ids"]
	assert_true(spike_ids.size() >= 1 and spike_ids.size() <= 2, "spike count should be 1-2 per map")

func test_spike_sections_are_off_path_fill_sections() -> void:
	var layout := _generate(11)
	var spike_ids: Array = layout["spike_section_ids"]
	var path_section_ids: Array = layout["path_section_ids"]
	for spike_id in spike_ids:
		assert_false(path_section_ids.has(spike_id), "a spike must be an off-path fill section, not a ring")

func test_spike_recommended_level_is_well_above_the_zone_band() -> void:
	var layout := _generate(11)
	var params: Dictionary = layout["params"]
	var spike_ids: Array = layout["spike_section_ids"]
	assert_true(spike_ids.size() > 0, "expected at least one spike section")
	for spike_id in spike_ids:
		assert_true(params[spike_id]["level_min"] > MAX_LEVEL, "spike level_min must exceed the zone's max_level")
		assert_true(params[spike_id]["is_spike"], "spike section params must be flagged is_spike")

func test_non_spike_sections_are_not_flagged() -> void:
	var layout := _generate(11)
	var params: Dictionary = layout["params"]
	var spike_ids: Array = layout["spike_section_ids"]
	for section_id in layout["section_ids"]:
		if spike_ids.has(section_id):
			continue
		assert_false(params[section_id]["is_spike"], "non-spike section must not be flagged is_spike")

func test_degenerate_tiny_map_never_hangs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var layout := SectionLayout.generate(1, 1, MIN_LEVEL, MAX_LEVEL, rng)
	assert_true(layout.has("camp"))
	var section_id := SectionLayout.section_for_cell(Vector2i(0, 0), 1, 1, layout)
	assert_true(layout["section_ids"].has(section_id))

const BAND_NAMES := ["Meadow", "Thicket", "Bramble", "Thornwall"]

func _generate_named(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return SectionLayout.generate(MAP_COLS, MAP_ROWS, MIN_LEVEL, MAX_LEVEL, rng, BAND_NAMES)

func test_every_section_gets_a_non_empty_name_when_band_names_supplied() -> void:
	var layout := _generate_named(3)
	var params: Dictionary = layout["params"]
	for section_id in layout["section_ids"]:
		var section_name: String = params[section_id]["name"]
		assert_false(section_name.is_empty(), "section %d should have a generated name" % section_id)

func test_section_name_starts_with_a_zone_band_name() -> void:
	var layout := _generate_named(3)
	var params: Dictionary = layout["params"]
	for section_id in layout["section_ids"]:
		var section_name: String = params[section_id]["name"]
		var matches_a_band := false
		for band_name in BAND_NAMES:
			if section_name.begins_with(band_name):
				matches_a_band = true
				break
		assert_true(matches_a_band, "name '%s' should start with one of the zone's band names" % section_name)

func test_section_name_is_empty_when_no_band_names_supplied() -> void:
	var layout := _generate(3)
	var params: Dictionary = layout["params"]
	for section_id in layout["section_ids"]:
		assert_eq(params[section_id]["name"], "")

func test_section_names_are_deterministic_for_a_fixed_seed() -> void:
	var layout_a := _generate_named(9)
	var layout_b := _generate_named(9)
	for section_id in layout_a["section_ids"]:
		assert_eq(layout_a["params"][section_id]["name"], layout_b["params"][section_id]["name"])

func test_deeper_sections_prefer_later_band_names() -> void:
	var layout := _generate_named(3)
	var params: Dictionary = layout["params"]
	var path_section_ids: Array = layout["path_section_ids"]
	var first_ring_name: String = params[path_section_ids[0]]["name"]
	var last_ring_name: String = params[path_section_ids[-1]]["name"]
	assert_true(first_ring_name.begins_with(BAND_NAMES[0]),
		"the mildest ring should use the zone's first band name, got '%s'" % first_ring_name)
	assert_false(last_ring_name.begins_with(BAND_NAMES[0]),
		"the deepest ring should not reuse the zone's first band name, got '%s'" % last_ring_name)
