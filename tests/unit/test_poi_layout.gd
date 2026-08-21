# Tests for PoiLayout (src/systems/poi_layout.gd): the points-of-interest
# overlay (ADR-0001, slice B) — deterministic placement of camp/portal/
# den/forage/cache/landmark markers relative to OverworldTierLayout's depth
# bands and trail spine.
extends "res://tests/test_case.gd"

const OverworldTierLayout = preload("res://src/systems/overworld_tier_layout.gd")
const PoiLayout = preload("res://src/systems/poi_layout.gd")

const MAP_COLS := 30
const MAP_ROWS := 40
const TIER_IDS := [0, 1, 2]

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _count_type(pois: Array, type_name: String) -> int:
	var count := 0
	for poi in pois:
		if poi["type"] == type_name:
			count += 1
	return count

func test_generate_returns_exactly_one_camp() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(1))
	assert_eq(_count_type(pois, "camp"), 1)

func test_generate_returns_exactly_one_portal() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(1))
	assert_eq(_count_type(pois, "portal"), 1)

func test_camp_poi_sits_at_camp_cell() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(1))
	var expected := OverworldTierLayout.camp_cell(MAP_COLS, MAP_ROWS)
	for poi in pois:
		if poi["type"] == "camp":
			assert_eq(poi["cell"], expected)

func test_portal_poi_sits_at_exit_cell() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(1))
	var expected := OverworldTierLayout.exit_cell(MAP_COLS, MAP_ROWS)
	for poi in pois:
		if poi["type"] == "portal":
			assert_eq(poi["cell"], expected)

func test_den_count_within_spec_range() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(7))
	var count := _count_type(pois, "den")
	assert_true(count >= 1 and count <= 3, "den count %d out of [1,3]" % count)

func test_forage_count_within_spec_range() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(7))
	var count := _count_type(pois, "forage")
	assert_true(count >= 1 and count <= 3, "forage count %d out of [1,3]" % count)

func test_cache_count_within_spec_range() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(7))
	var count := _count_type(pois, "cache")
	assert_true(count >= 0 and count <= 2, "cache count %d out of [0,2]" % count)

func test_landmark_count_within_spec_range() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(7))
	var count := _count_type(pois, "landmark")
	assert_true(count >= 0 and count <= 1, "landmark count %d out of [0,1]" % count)

func test_dens_are_biased_to_mid_or_hot_bands() -> void:
	for seed_value in range(20):
		var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(seed_value))
		for poi in pois:
			if poi["type"] == "den":
				var depth := OverworldTierLayout.depth_ratio(poi["cell"], MAP_COLS, MAP_ROWS)
				assert_true(depth >= PoiLayout.SAFE_MAX_DEPTH - 0.001,
					"den at depth %f should be mid/hot banded" % depth)

func test_caches_are_biased_to_mid_or_hot_bands() -> void:
	for seed_value in range(20):
		var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(seed_value))
		for poi in pois:
			if poi["type"] == "cache":
				var depth := OverworldTierLayout.depth_ratio(poi["cell"], MAP_COLS, MAP_ROWS)
				assert_true(depth >= PoiLayout.SAFE_MAX_DEPTH - 0.001,
					"cache at depth %f should be mid/hot banded" % depth)

func test_caches_sit_off_the_trail() -> void:
	for seed_value in range(20):
		var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(seed_value))
		for poi in pois:
			if poi["type"] == "cache":
				var cell: Vector2i = poi["cell"]
				var trail_x := OverworldTierLayout.trail_x_for_row(cell.y, MAP_COLS, MAP_ROWS)
				assert_true(absi(cell.x - trail_x) > PoiLayout.TRAIL_OFF_MARGIN,
					"cache should sit off the trail spine")

func test_nothing_is_placed_off_map() -> void:
	var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(3))
	for poi in pois:
		var cell: Vector2i = poi["cell"]
		assert_true(cell.x >= 0 and cell.x < MAP_COLS, "poi x %d out of bounds" % cell.x)
		assert_true(cell.y >= 0 and cell.y < MAP_ROWS, "poi y %d out of bounds" % cell.y)

func test_no_two_pois_share_a_cell() -> void:
	for seed_value in range(20):
		var pois := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(seed_value))
		var seen: Dictionary = {}
		for poi in pois:
			var cell: Vector2i = poi["cell"]
			assert_false(seen.has(cell), "duplicate poi cell %s" % str(cell))
			seen[cell] = true

func test_generate_is_deterministic_for_a_seed() -> void:
	var pois_a := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(42))
	var pois_b := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(42))
	assert_eq(pois_a.size(), pois_b.size())
	for i in range(pois_a.size()):
		assert_eq(pois_a[i]["cell"], pois_b[i]["cell"])
		assert_eq(pois_a[i]["type"], pois_b[i]["type"])

func test_different_seeds_can_produce_different_layouts() -> void:
	var pois_a := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(1))
	var pois_b := PoiLayout.generate(MAP_COLS, MAP_ROWS, TIER_IDS, _rng(2))
	var same := pois_a.size() == pois_b.size()
	if same:
		for i in range(pois_a.size()):
			if pois_a[i]["cell"] != pois_b[i]["cell"] or pois_a[i]["type"] != pois_b[i]["type"]:
				same = false
				break
	assert_false(same, "different seeds should not always produce identical layouts")
