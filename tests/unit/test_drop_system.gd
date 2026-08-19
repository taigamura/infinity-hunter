# Tests for DropSystem (src/systems/drop_system.gd): weighted table rolls,
# part-break boost/guarantee, and distribution correctness over many rolls.
extends "res://tests/test_case.gd"

const DropSystem = preload("res://src/systems/drop_system.gd")

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func test_empty_table_yields_no_drops() -> void:
	var drops := DropSystem.roll_table([], [], _rng(1))
	assert_true(drops.is_empty())

func test_single_entry_table_always_yields_that_material() -> void:
	var table := [{"material_id": "slime_gel", "weight": 100}]
	for i in range(20):
		var drops := DropSystem.roll_table(table, [], _rng(i))
		assert_eq(drops, ["slime_gel"])

func test_weighted_distribution_within_tolerance() -> void:
	var table := [
		{"material_id": "common_mat", "weight": 80},
		{"material_id": "rare_mat", "weight": 20},
	]
	var counts := {"common_mat": 0, "rare_mat": 0}
	var n := 4000
	var rng := _rng(42)
	for i in range(n):
		var drops := DropSystem.roll_table(table, [], rng)
		counts[drops[0]] += 1

	var common_fraction := float(counts["common_mat"]) / float(n)
	var rare_fraction := float(counts["rare_mat"]) / float(n)
	assert_almost_eq(common_fraction, 0.8, 0.03, "common material should land near its 80% weight")
	assert_almost_eq(rare_fraction, 0.2, 0.03, "rare material should land near its 20% weight")

func test_part_break_boosts_weight_toward_tied_material() -> void:
	var table := [
		{"material_id": "rare_mat", "weight": 10, "part": "head", "break_boost": 9.0},
		{"material_id": "common_mat", "weight": 90},
	]
	var counts := {"rare_mat": 0, "common_mat": 0}
	var n := 3000
	var rng := _rng(7)
	for i in range(n):
		var drops := DropSystem.roll_table(table, ["head"], rng)
		counts[drops[0]] += 1

	# boosted weight 10*9=90 vs 90 unboosted -> ~50/50, a sharp jump from the
	# unboosted 10/90 split.
	var rare_fraction := float(counts["rare_mat"]) / float(n)
	assert_almost_eq(rare_fraction, 0.5, 0.05, "breaking the tied part should sharply boost its material's odds")

func test_part_not_broken_leaves_weight_unboosted() -> void:
	var table := [
		{"material_id": "rare_mat", "weight": 10, "part": "head", "break_boost": 9.0},
		{"material_id": "common_mat", "weight": 90},
	]
	var counts := {"rare_mat": 0, "common_mat": 0}
	var n := 3000
	var rng := _rng(11)
	for i in range(n):
		var drops := DropSystem.roll_table(table, [], rng)
		counts[drops[0]] += 1

	var rare_fraction := float(counts["rare_mat"]) / float(n)
	assert_almost_eq(rare_fraction, 0.1, 0.03, "without the part break the base 10% weight should hold")

func test_guaranteed_on_break_always_grants_material() -> void:
	var table := [
		{"material_id": "ember_fang", "weight": 50, "part": "head", "guaranteed_on_break": true},
		{"material_id": "slime_gel", "weight": 50},
	]
	for i in range(20):
		var drops := DropSystem.roll_table(table, ["head"], _rng(i))
		assert_has(drops, "ember_fang", "guaranteed_on_break must always grant the material")

func test_guaranteed_on_break_skips_weighted_roll_for_that_entry() -> void:
	# With the part broken, ember_fang is granted directly and the weighted
	# pool only contains slime_gel, so the second slot is always slime_gel.
	var table := [
		{"material_id": "ember_fang", "weight": 50, "part": "head", "guaranteed_on_break": true},
		{"material_id": "slime_gel", "weight": 50},
	]
	for i in range(20):
		var drops := DropSystem.roll_table(table, ["head"], _rng(i))
		assert_eq(drops, ["ember_fang", "slime_gel"])

func test_unbroken_part_does_not_guarantee_material() -> void:
	var table := [
		{"material_id": "ember_fang", "weight": 1, "part": "head", "guaranteed_on_break": true},
		{"material_id": "slime_gel", "weight": 99},
	]
	var counts := {"ember_fang": 0, "slime_gel": 0}
	var n := 500
	var rng := _rng(3)
	for i in range(n):
		var drops := DropSystem.roll_table(table, [], rng)
		for material_id in drops:
			counts[material_id] += 1
	assert_lt(counts["ember_fang"], 20, "ember_fang should only appear from its small unboosted weighted odds")

func test_real_monster_data_ember_wolf_head_break_guarantees_ember_fang() -> void:
	var result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	var ember_wolf: MonsterDef = result["defs"]["ember_wolf"]
	var drops := DropSystem.roll(ember_wolf, ["head"], _rng(5))
	assert_has(drops, "ember_fang")
