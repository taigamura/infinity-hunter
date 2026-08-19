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
