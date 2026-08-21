# Tests for XpCurve (src/systems/xp_curve.gd): threshold growth, single- and
# multi-level XP awards (including carry), and level->power scaling.
extends "res://tests/test_case.gd"

const XpCurve = preload("res://src/systems/xp_curve.gd")

func test_threshold_starts_at_base() -> void:
	assert_almost_eq(XpCurve.threshold(1.0), XpCurve.BASE_THRESHOLD)

func test_threshold_grows_exponentially() -> void:
	var t1 := XpCurve.threshold(1.0)
	var t2 := XpCurve.threshold(2.0)
	var t3 := XpCurve.threshold(3.0)
	assert_almost_eq(t2, XpCurve.BASE_THRESHOLD * XpCurve.GROWTH_RATE)
	assert_gt(t2, t1, "threshold must increase with level")
	assert_gt(t3, t2, "threshold must keep increasing with level")

func test_award_xp_partial_no_level_up() -> void:
	var result := XpCurve.award_xp(1.0, 0.0, XpCurve.BASE_THRESHOLD * 0.5)
	assert_eq(result["levels_gained"], 0)
	assert_eq(result["level"], 1.0)
	assert_almost_eq(result["xp_carry"], XpCurve.BASE_THRESHOLD * 0.5)

func test_award_xp_single_level_exact() -> void:
	var result := XpCurve.award_xp(1.0, 0.0, XpCurve.threshold(1.0))
	assert_eq(result["levels_gained"], 1)
	assert_eq(result["level"], 2.0)
	assert_almost_eq(result["xp_carry"], 0.0)

func test_award_xp_multi_level_lump_with_carry() -> void:
	# Sum the exact XP needed to climb from level 1 to level 10, then add a
	# known remainder — this must cross all 9 thresholds and leave that
	# remainder as carry.
	var needed := 0.0
	var lvl := 1.0
	while lvl < 10.0:
		needed += XpCurve.threshold(lvl)
		lvl += 1.0
	var remainder := 37.5
	var result := XpCurve.award_xp(1.0, 0.0, needed + remainder)
	assert_eq(result["levels_gained"], 9)
	assert_eq(result["level"], 10.0)
	assert_almost_eq(result["xp_carry"], remainder)

func test_award_xp_applies_xp_mult_bonus() -> void:
	# an XP Boost skill build (SkillSystem "xp_mult_bonus") scales the award
	# before it's applied to the carry/threshold math.
	var result := XpCurve.award_xp(1.0, 0.0, XpCurve.BASE_THRESHOLD * 0.5, 0.5)
	assert_almost_eq(result["xp_carry"], XpCurve.BASE_THRESHOLD * 0.75)

func test_award_xp_carry_always_below_next_threshold() -> void:
	var result := XpCurve.award_xp(1.0, 0.0, 5000.0)
	assert_lt(result["xp_carry"], XpCurve.threshold(result["level"]))

func test_power_scaling_base_at_level_one() -> void:
	assert_almost_eq(XpCurve.power_scaling(1.0), XpCurve.POWER_BASE)

func test_power_scaling_monotonic() -> void:
	var p1 := XpCurve.power_scaling(1.0)
	var p10 := XpCurve.power_scaling(10.0)
	var p100 := XpCurve.power_scaling(100.0)
	assert_gt(p10, p1, "power must increase with level")
	assert_gt(p100, p10, "power must keep increasing with level")

func test_gap_multiplier_is_flat_for_equal_or_lower_level() -> void:
	assert_almost_eq(XpCurve.gap_multiplier(5.0, 5.0), 1.0)
	assert_almost_eq(XpCurve.gap_multiplier(5.0, 3.0), 1.0)

func test_gap_multiplier_grows_for_positive_gap() -> void:
	var m1 := XpCurve.gap_multiplier(1.0, 2.0)
	var m8 := XpCurve.gap_multiplier(1.0, 9.0)
	assert_gt(m1, 1.0, "any positive gap should exceed the flat multiplier")
	assert_gt(m8, m1, "a bigger gap should multiply harder")

func test_gap_multiplier_clamps_at_cap_for_enormous_gap() -> void:
	var m := XpCurve.gap_multiplier(1.0, 1.0e10)
	assert_almost_eq(m, XpCurve.XP_GAP_MULT_CAP)

func test_gap_scaled_reward_multiplies_base() -> void:
	var expected := 50.0 * XpCurve.gap_multiplier(1.0, 9.0)
	assert_almost_eq(XpCurve.gap_scaled_reward(50.0, 1.0, 9.0), expected)

func test_fill_segments_within_one_level_single_step() -> void:
	var steps := XpCurve.fill_segments(1.0, 0.0, 1.0, XpCurve.threshold(1.0) * 0.5)
	assert_eq(steps.size(), 1)
	assert_eq(steps[0]["level"], 1)
	assert_false(steps[0]["levels_up"])
	assert_almost_eq(steps[0]["from"], 0.0)
	assert_almost_eq(steps[0]["to"], 0.5)

func test_fill_segments_multi_level_step_shape() -> void:
	var steps := XpCurve.fill_segments(1.0, 0.0, 5.0, XpCurve.threshold(5.0) * 0.25)
	var levels_up_count := 0
	for step in steps:
		if step["levels_up"]:
			levels_up_count += 1
	assert_eq(levels_up_count, 4, "levels_up count must equal level_after - level_before")
	assert_almost_eq(steps[0]["to"], 1.0)
	assert_false(steps[steps.size() - 1]["levels_up"])

func test_fill_segments_consistent_with_award_xp() -> void:
	var start_level := 1.0
	var start_carry := 10.0
	var xp := XpCurve.threshold(1.0) * 3.0 + 42.0
	var award := XpCurve.award_xp(start_level, start_carry, xp)
	var end_level: float = award["level"]
	var end_carry: float = award["xp_carry"]
	var steps := XpCurve.fill_segments(start_level, start_carry, end_level, end_carry)
	var last: Dictionary = steps[steps.size() - 1]
	assert_false(last["levels_up"])
	assert_almost_eq(last["to"], end_carry / XpCurve.threshold(end_level), 0.0001)
