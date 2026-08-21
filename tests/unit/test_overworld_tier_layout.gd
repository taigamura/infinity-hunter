# Tests for OverworldTierLayout (src/systems/overworld_tier_layout.gd):
# depth-banded danger along the vertical travel axis (ADR-0001, the
# Deepening Trail) — near/bottom edge safest, far/top edge most dangerous —
# plus camp spawn, on-trail portal exit, and the trail spine's x-per-row.
extends "res://tests/test_case.gd"

const OverworldTierLayout = preload("res://src/systems/overworld_tier_layout.gd")

const MAP_COLS := 30
const MAP_ROWS := 40

func test_near_edge_cell_gets_lowest_tier() -> void:
	var cell := Vector2i(15, MAP_ROWS - 1)
	var tier_id := OverworldTierLayout.tier_for_cell(cell, MAP_COLS, MAP_ROWS, [0, 1, 2])
	assert_eq(tier_id, 0)

func test_far_edge_cell_gets_highest_tier() -> void:
	var cell := Vector2i(15, 0)
	var tier_id := OverworldTierLayout.tier_for_cell(cell, MAP_COLS, MAP_ROWS, [0, 1, 2])
	assert_eq(tier_id, 2)

func test_tier_rises_monotonically_moving_toward_the_deep_edge() -> void:
	var tiers := [0, 1, 2]
	var prev_tier := OverworldTierLayout.tier_for_cell(Vector2i(15, MAP_ROWS - 1), MAP_COLS, MAP_ROWS, tiers)
	for step in range(1, MAP_ROWS):
		var cell := Vector2i(15, MAP_ROWS - 1 - step)
		var tier_id := OverworldTierLayout.tier_for_cell(cell, MAP_COLS, MAP_ROWS, tiers)
		assert_true(tier_id >= prev_tier, "tier should not decrease moving toward the deep/top edge")
		prev_tier = tier_id

func test_tier_is_constant_across_a_row() -> void:
	var tiers := [0, 1, 2]
	var row := 10
	var tier_a := OverworldTierLayout.tier_for_cell(Vector2i(2, row), MAP_COLS, MAP_ROWS, tiers)
	var tier_b := OverworldTierLayout.tier_for_cell(Vector2i(27, row), MAP_COLS, MAP_ROWS, tiers)
	assert_eq(tier_a, tier_b, "danger is banded by depth (row), not by column")

func test_non_sequential_tier_ids_are_respected() -> void:
	var cell := Vector2i(15, MAP_ROWS - 1)
	var tier_id := OverworldTierLayout.tier_for_cell(cell, MAP_COLS, MAP_ROWS, [5, 9])
	assert_eq(tier_id, 5)

func test_empty_tier_ids_falls_back_to_zero() -> void:
	var tier_id := OverworldTierLayout.tier_for_cell(Vector2i(0, 0), MAP_COLS, MAP_ROWS, [])
	assert_eq(tier_id, 0)

func test_depth_ratio_is_near_zero_at_near_edge() -> void:
	var ratio := OverworldTierLayout.depth_ratio(Vector2i(15, MAP_ROWS - 1), MAP_COLS, MAP_ROWS)
	assert_almost_eq(ratio, 0.0, 0.001)

func test_depth_ratio_is_near_one_at_far_edge() -> void:
	var ratio := OverworldTierLayout.depth_ratio(Vector2i(15, 0), MAP_COLS, MAP_ROWS)
	assert_almost_eq(ratio, 1.0, 0.001)

func test_depth_ratio_rises_monotonically_toward_the_deep_edge() -> void:
	var prev_ratio := OverworldTierLayout.depth_ratio(Vector2i(15, MAP_ROWS - 1), MAP_COLS, MAP_ROWS)
	for step in range(1, MAP_ROWS):
		var ratio := OverworldTierLayout.depth_ratio(Vector2i(15, MAP_ROWS - 1 - step), MAP_COLS, MAP_ROWS)
		assert_true(ratio >= prev_ratio, "depth ratio should not decrease moving toward the deep/top edge")
		prev_ratio = ratio

func test_camp_cell_sits_on_the_near_bottom_edge() -> void:
	var cell := OverworldTierLayout.camp_cell(MAP_COLS, MAP_ROWS)
	assert_eq(cell.y, MAP_ROWS - 1)
	assert_eq(cell.x, MAP_COLS / 2)

func test_camp_cell_gets_the_lowest_tier() -> void:
	var tiers := [0, 1, 2]
	var cell := OverworldTierLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var tier_id := OverworldTierLayout.tier_for_cell(cell, MAP_COLS, MAP_ROWS, tiers)
	assert_eq(tier_id, 0)

func test_exit_cell_sits_on_the_far_top_edge() -> void:
	var exit_cell := OverworldTierLayout.exit_cell(MAP_COLS, MAP_ROWS)
	assert_eq(exit_cell.y, 0)

func test_exit_cell_sits_in_the_highest_tier() -> void:
	var tiers := [0, 1, 2]
	var exit_cell := OverworldTierLayout.exit_cell(MAP_COLS, MAP_ROWS)
	var tier_id := OverworldTierLayout.tier_for_cell(exit_cell, MAP_COLS, MAP_ROWS, tiers)
	assert_eq(tier_id, 2)

func test_exit_cell_sits_on_the_trail_line() -> void:
	var exit_cell := OverworldTierLayout.exit_cell(MAP_COLS, MAP_ROWS)
	var trail_x := OverworldTierLayout.trail_x_for_row(0, MAP_COLS, MAP_ROWS)
	assert_eq(exit_cell.x, trail_x)

func test_trail_x_matches_camp_x_at_the_near_edge() -> void:
	var camp_cell := OverworldTierLayout.camp_cell(MAP_COLS, MAP_ROWS)
	var trail_x := OverworldTierLayout.trail_x_for_row(MAP_ROWS - 1, MAP_COLS, MAP_ROWS)
	assert_eq(trail_x, camp_cell.x)

func test_trail_x_stays_within_the_map_bounds() -> void:
	for row in range(MAP_ROWS):
		var trail_x := OverworldTierLayout.trail_x_for_row(row, MAP_COLS, MAP_ROWS)
		assert_true(trail_x >= 0 and trail_x < MAP_COLS, "trail x %d out of bounds at row %d" % [trail_x, row])
