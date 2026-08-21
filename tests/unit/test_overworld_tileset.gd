# Tests for OverworldTileset (src/ui/overworld/overworld_tileset.gd): the
# pure distance-to-shade-row mapping backing the danger-gradient tile colour
# (issue #34). Texture painting itself is manual-verify only (rendering).
extends "res://tests/test_case.gd"

const OverworldTileset = preload("res://src/ui/overworld/overworld_tileset.gd")

func test_shade_index_at_band_start_is_lowest_row() -> void:
	var shade := OverworldTileset.shade_index_for_distance(0.0, 0, 3)
	assert_eq(shade, 0)

func test_shade_index_at_band_end_is_highest_row() -> void:
	var shade := OverworldTileset.shade_index_for_distance(0.999, 2, 3)
	assert_eq(shade, OverworldTileset.SHADE_COUNT - 1)

func test_shade_index_rises_monotonically_within_a_band() -> void:
	var prev_shade := OverworldTileset.shade_index_for_distance(1.0 / 3.0, 1, 3)
	for step in range(1, 10):
		var distance := 1.0 / 3.0 + step * 0.03
		var shade := OverworldTileset.shade_index_for_distance(distance, 1, 3)
		assert_true(shade >= prev_shade, "shade row should not decrease moving away within a band")
		prev_shade = shade
