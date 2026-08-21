# Tests for EncounterSystem (src/systems/encounter_system.gd): gauge
# fill/fire/reset, jitter bounds, and band-filtered weighted monster pick,
# built off the real MVP zone/monster data.
extends "res://tests/test_case.gd"

const EncounterSystem = preload("res://src/systems/encounter_system.gd")

var _monster_defs: Dictionary
var _verdant: ZoneDef

func before_each() -> void:
	var monster_result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	_monster_defs = monster_result["defs"]
	var zone_result := DataLoader.load_directory("res://data/zones", ZoneDef.from_dict)
	_verdant = zone_result["defs"]["verdant_fields"]

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func test_tick_accumulates_and_does_not_fire_below_threshold() -> void:
	var tier := {"gauge_rate": 10.0}
	var result := EncounterSystem.tick(tier, 0.0, _rng(1))
	assert_false(result["fired"])
	assert_almost_eq(result["gauge"], 10.0)

func test_higher_rate_tier_fires_in_fewer_ticks() -> void:
	var slow_tier := {"gauge_rate": 5.0}
	var fast_tier := {"gauge_rate": 25.0}

	var slow_gauge := 0.0
	var slow_ticks := 0
	while slow_ticks < 1000:
		var result := EncounterSystem.tick(slow_tier, slow_gauge, _rng(slow_ticks))
		slow_ticks += 1
		if result["fired"]:
			break
		slow_gauge = result["gauge"]

	var fast_gauge := 0.0
	var fast_ticks := 0
	while fast_ticks < 1000:
		var result := EncounterSystem.tick(fast_tier, fast_gauge, _rng(fast_ticks))
		fast_ticks += 1
		if result["fired"]:
			break
		fast_gauge = result["gauge"]

	assert_lt(fast_ticks, slow_ticks, "higher gauge_rate tier should fire in fewer ticks")

func test_firing_resets_gauge() -> void:
	var tier := {"gauge_rate": 40.0}
	var gauge := 0.0
	var fired := false
	for i in range(10):
		var result := EncounterSystem.tick(tier, gauge, _rng(i))
		gauge = result["gauge"]
		if result["fired"]:
			fired = true
			break
	assert_true(fired, "expected the gauge to fire within 10 ticks at rate 40")
	assert_almost_eq(gauge, 0.0)

func test_jitter_stays_within_declared_bound_across_seeds() -> void:
	var tier := {"gauge_rate": 10.0, "jitter": 3.0}
	for s in range(50):
		var result := EncounterSystem.tick(tier, 0.0, _rng(s))
		assert_true(result["gauge"] >= 7.0 and result["gauge"] <= 13.0,
			"gauge %f out of jitter bound for seed %d" % [result["gauge"], s])

func test_jitter_varies_the_fire_step_across_seeds() -> void:
	var tier := {"gauge_rate": 10.0, "jitter": 3.0}
	var seen_values := {}
	for s in range(20):
		var result := EncounterSystem.tick(tier, 0.0, _rng(s))
		seen_values[result["gauge"]] = true
	assert_true(seen_values.size() > 1, "jitter should produce varying gauge deltas across seeds")

func test_pick_monster_only_returns_ids_within_level_band() -> void:
	var tier := {"level_min": 1, "level_max": 5}
	for s in range(50):
		var monster_id := EncounterSystem.pick_monster(_verdant, tier, _monster_defs, _rng(s))
		var monster: MonsterDef = _monster_defs[monster_id]
		assert_true(monster.level >= 1 and monster.level <= 5,
			"monster %s (level %f) outside band [1,5]" % [monster_id, monster.level])

func test_pick_monster_respects_uniform_weighting_across_seeds() -> void:
	var tier := {"level_min": 1, "level_max": 10}
	var counts := {}
	for s in range(200):
		var monster_id := EncounterSystem.pick_monster(_verdant, tier, _monster_defs, _rng(s))
		counts[monster_id] = counts.get(monster_id, 0) + 1
	assert_true(counts.size() > 1, "expected more than one distinct monster picked across 200 seeded rolls")

func test_pick_monster_falls_back_gracefully_when_band_is_empty() -> void:
	var tier := {"level_min": 500, "level_max": 600}
	var monster_id := EncounterSystem.pick_monster(_verdant, tier, _monster_defs, _rng(7))
	assert_true(_monster_defs.has(monster_id), "fallback must still return a known monster id")

func test_pick_monster_returns_empty_string_when_zone_has_no_known_monsters() -> void:
	var tier := {"level_min": 1, "level_max": 5}
	var monster_id := EncounterSystem.pick_monster(_verdant, tier, {}, _rng(1))
	assert_eq(monster_id, "")

# A spike section's tier_params (SectionLayout.generate) opens a level window
# far above the zone's normal band, up to SPIKE_LEVEL_MAX_SENTINEL. The
# existing level-window filter should select only the apex pool (here,
# voidmaw_devourer, the reference apex already listed in verdant_fields'
# monster_ids) — normal zone species never qualify for a spike-shaped band.
func test_pick_monster_selects_the_apex_pool_for_a_spike_shaped_band() -> void:
	var spike_tier := {"level_min": 1000.0, "level_max": 1_000_000_000_000.0, "is_spike": true}
	for s in range(20):
		var monster_id := EncounterSystem.pick_monster(_verdant, spike_tier, _monster_defs, _rng(s))
		assert_eq(monster_id, "voidmaw_devourer", "spike band should only ever select the apex monster")
