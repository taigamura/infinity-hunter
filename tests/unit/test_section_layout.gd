# Tests for SectionLayout (src/systems/section_layout.gd): radial danger
# banding from the map center out to the outer ring (PRD issue #36,
# Concentric Sections), plus the center camp spawn and rng-placed portal.
extends "res://tests/test_case.gd"

const SectionLayout = preload("res://src/systems/section_layout.gd")

const MAP_COLS := 30
const MAP_ROWS := 40

func test_center_cell_gets_lowest_section() -> void:
	var cell := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var section_id := SectionLayout.section_for_cell(cell, MAP_COLS, MAP_ROWS, [0, 1, 2])
	assert_eq(section_id, 0)

func test_outer_ring_cell_gets_highest_section() -> void:
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var cell := Vector2i(center.x, 0)
	var section_id := SectionLayout.section_for_cell(cell, MAP_COLS, MAP_ROWS, [0, 1, 2])
	assert_eq(section_id, 2)

func test_section_rises_monotonically_moving_outward() -> void:
	var sections := [0, 1, 2]
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var prev_section := SectionLayout.section_for_cell(center, MAP_COLS, MAP_ROWS, sections)
	for step in range(1, center.y + 1):
		var cell := Vector2i(center.x, center.y - step)
		var section_id := SectionLayout.section_for_cell(cell, MAP_COLS, MAP_ROWS, sections)
		assert_true(section_id >= prev_section, "section should not decrease moving toward the outer ring")
		prev_section = section_id

func test_section_is_constant_at_equal_radius() -> void:
	var sections := [0, 1, 2]
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var section_a := SectionLayout.section_for_cell(Vector2i(center.x, center.y - 5), MAP_COLS, MAP_ROWS, sections)
	var section_b := SectionLayout.section_for_cell(Vector2i(center.x - 5, center.y), MAP_COLS, MAP_ROWS, sections)
	assert_eq(section_a, section_b, "danger is banded by radial distance, not direction")

func test_non_sequential_section_ids_are_respected() -> void:
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var section_id := SectionLayout.section_for_cell(center, MAP_COLS, MAP_ROWS, [5, 9])
	assert_eq(section_id, 5)

func test_empty_section_ids_falls_back_to_zero() -> void:
	var section_id := SectionLayout.section_for_cell(Vector2i(0, 0), MAP_COLS, MAP_ROWS, [])
	assert_eq(section_id, 0)

func test_distance_ratio_is_zero_at_center() -> void:
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var ratio := SectionLayout.distance_ratio(center, MAP_COLS, MAP_ROWS)
	assert_almost_eq(ratio, 0.0, 0.1)

func test_distance_ratio_is_one_at_the_outer_edge() -> void:
	var center := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var ratio := SectionLayout.distance_ratio(Vector2i(center.x, 0), MAP_COLS, MAP_ROWS)
	assert_almost_eq(ratio, 1.0, 0.05)

func test_camp_cell_sits_at_the_map_center() -> void:
	var cell := SectionLayout.camp_cell(MAP_COLS, MAP_ROWS)
	assert_eq(cell.x, MAP_COLS / 2)
	assert_eq(cell.y, MAP_ROWS / 2)

func test_portal_cell_is_deterministic_for_a_fixed_seed() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 42
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 42
	var portal_a := SectionLayout.portal_cell(MAP_COLS, MAP_ROWS, rng_a)
	var portal_b := SectionLayout.portal_cell(MAP_COLS, MAP_ROWS, rng_b)
	assert_eq(portal_a, portal_b)

func test_portal_cell_sits_in_the_highest_section() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sections := [0, 1, 2]
	var portal := SectionLayout.portal_cell(MAP_COLS, MAP_ROWS, rng)
	var section_id := SectionLayout.section_for_cell(portal, MAP_COLS, MAP_ROWS, sections)
	assert_eq(section_id, 2)

func test_portal_cell_stays_within_map_bounds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for _i in range(20):
		var portal := SectionLayout.portal_cell(MAP_COLS, MAP_ROWS, rng)
		assert_true(portal.x >= 0 and portal.x < MAP_COLS, "portal x out of bounds")
		assert_true(portal.y >= 0 and portal.y < MAP_ROWS, "portal y out of bounds")

func test_generate_returns_camp_portal_and_section_ids() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var sections := [0, 1, 2]
	var result := SectionLayout.generate(MAP_COLS, MAP_ROWS, sections, rng)
	assert_eq(result["camp"], SectionLayout.camp_cell(MAP_COLS, MAP_ROWS))
	assert_eq(result["section_ids"], sections)
	assert_true(result.has("portal"))

func test_every_cell_resolves_to_exactly_one_section() -> void:
	var sections := [0, 1, 2]
	for x in range(0, MAP_COLS, 5):
		for y in range(0, MAP_ROWS, 5):
			var section_id := SectionLayout.section_for_cell(Vector2i(x, y), MAP_COLS, MAP_ROWS, sections)
			assert_true(sections.has(section_id), "every cell must resolve to a known section id")
