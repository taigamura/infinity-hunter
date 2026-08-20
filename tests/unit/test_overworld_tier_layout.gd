# Tests for OverworldTierLayout (src/systems/overworld_tier_layout.gd):
# center-safe, edge-dangerous tier bucketing by cell distance.
extends "res://tests/test_case.gd"

const OverworldTierLayout = preload("res://src/systems/overworld_tier_layout.gd")

func test_center_cell_gets_lowest_tier() -> void:
	var tier_id := OverworldTierLayout.tier_for_cell(Vector2i(15, 20), 30, 40, [0, 1, 2])
	assert_eq(tier_id, 0)

func test_corner_cell_gets_highest_tier() -> void:
	var tier_id := OverworldTierLayout.tier_for_cell(Vector2i(0, 0), 30, 40, [0, 1, 2])
	assert_eq(tier_id, 2)

func test_tier_rises_monotonically_with_distance_from_center() -> void:
	var tiers := [0, 1, 2]
	var prev_tier := OverworldTierLayout.tier_for_cell(Vector2i(15, 20), 30, 40, tiers)
	for step in range(1, 15):
		var cell := Vector2i(15 + step, 20)
		var tier_id := OverworldTierLayout.tier_for_cell(cell, 30, 40, tiers)
		assert_true(tier_id >= prev_tier, "tier should not decrease moving away from center")
		prev_tier = tier_id

func test_non_sequential_tier_ids_are_respected() -> void:
	var tier_id := OverworldTierLayout.tier_for_cell(Vector2i(15, 20), 30, 40, [5, 9])
	assert_eq(tier_id, 5)

func test_empty_tier_ids_falls_back_to_zero() -> void:
	var tier_id := OverworldTierLayout.tier_for_cell(Vector2i(0, 0), 30, 40, [])
	assert_eq(tier_id, 0)

func test_exit_cell_sits_in_the_highest_tier() -> void:
	var tiers := [0, 1, 2]
	var exit_cell := OverworldTierLayout.exit_cell(30, 40)
	var tier_id := OverworldTierLayout.tier_for_cell(exit_cell, 30, 40, tiers)
	assert_eq(tier_id, 2)

func test_distance_ratio_is_near_zero_at_center() -> void:
	var ratio := OverworldTierLayout.distance_ratio(Vector2i(15, 20), 30, 40)
	assert_almost_eq(ratio, 0.0, 0.05)

func test_distance_ratio_is_near_one_at_corner() -> void:
	var ratio := OverworldTierLayout.distance_ratio(Vector2i(0, 0), 30, 40)
	assert_almost_eq(ratio, 1.0, 0.05)

func test_distance_ratio_rises_monotonically_with_distance_from_center() -> void:
	var prev_ratio := OverworldTierLayout.distance_ratio(Vector2i(15, 20), 30, 40)
	for step in range(1, 15):
		var ratio := OverworldTierLayout.distance_ratio(Vector2i(15 + step, 20), 30, 40)
		assert_true(ratio >= prev_ratio, "distance ratio should not decrease moving away from center")
		prev_ratio = ratio
