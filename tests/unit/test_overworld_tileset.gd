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

# gradient_color (ADR-0001 slice C): the 3-stop danger gradient now reads its
# stops from a caller-supplied palette (a zone's ZoneDef.palette) instead of
# hardcoded SAFE/MID/HOT constants, so each zone can look distinct.
func test_gradient_color_at_stops_matches_the_palette_exactly() -> void:
	var colors := OverworldTileset._palette_to_colors(["#000000", "#808080", "#ffffff"])
	assert_true(OverworldTileset.gradient_color(colors, 0.0).is_equal_approx(colors[0]))
	assert_true(OverworldTileset.gradient_color(colors, 0.5).is_equal_approx(colors[1]))
	assert_true(OverworldTileset.gradient_color(colors, 1.0).is_equal_approx(colors[2]))

func test_gradient_color_differs_between_two_zone_palettes_at_the_same_depth() -> void:
	var verdant_colors := OverworldTileset._palette_to_colors(["#408C40", "#86602D", "#CC331A"])
	var frostpeak_colors := OverworldTileset._palette_to_colors(["#AFD8E8", "#3FA9C9", "#E8F7FF"])
	var verdant_hot := OverworldTileset.gradient_color(verdant_colors, 1.0)
	var frostpeak_hot := OverworldTileset.gradient_color(frostpeak_colors, 1.0)
	assert_false(verdant_hot.is_equal_approx(frostpeak_hot), "different zone palettes should paint different colours at the same depth")

func test_build_with_custom_palette_produces_one_source_per_tier() -> void:
	var tile_set := OverworldTileset.build(16, [0, 1, 2], ["#AFD8E8", "#3FA9C9", "#E8F7FF"])
	assert_eq(tile_set.get_source_count(), 3)

func test_build_falls_back_to_default_palette_when_none_supplied() -> void:
	var tile_set := OverworldTileset.build(16, [0, 1, 2])
	assert_eq(tile_set.get_source_count(), 3)
