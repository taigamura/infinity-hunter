# Tests for the Big numeric helper. Also serves as the reference example for
# how Sonnet loop-workers should write tests: extend TestCase, name methods
# test_*, use assert_* helpers.
extends TestCase

func test_fmt_small_integer() -> void:
	assert_eq(Big.fmt(42.0), "42")

func test_fmt_thousands() -> void:
	assert_eq(Big.fmt(1500.0), "1.50K")

func test_fmt_millions() -> void:
	assert_eq(Big.fmt(3_000_000.0), "3.00M")

func test_fmt_billions() -> void:
	assert_eq(Big.fmt(9_999_999_999.0), "10.00B")

func test_fmt_negative() -> void:
	assert_eq(Big.fmt(-2500.0), "-2.50K")

func test_is_safe_within_range() -> void:
	assert_true(Big.is_safe(1.0e10), "1e10 must be safe")

func test_is_safe_beyond_range() -> void:
	assert_false(Big.is_safe(1.0e16), "1e16 exceeds float integer precision")
