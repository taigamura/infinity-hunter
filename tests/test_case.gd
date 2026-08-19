# Minimal test base class. Extend this in tests/unit/*.gd and add methods
# named `test_*`. Use the assert_* helpers. The runner (tests/run_tests.gd)
# discovers and executes every test_* method and reports pass/fail.
#
# No external addon required. Keep this dependency-free.
extends RefCounted
class_name TestCase

var _failures: Array[String] = []
var _assert_count: int = 0

# Called before each test_* method (override for per-test setup).
func before_each() -> void:
	pass

# Called after each test_* method (override for per-test teardown).
func after_each() -> void:
	pass

func _fail(msg: String) -> void:
	_failures.append(msg)

func assert_true(cond: bool, msg: String = "") -> void:
	_assert_count += 1
	if not cond:
		_fail("assert_true failed: %s" % msg)

func assert_false(cond: bool, msg: String = "") -> void:
	_assert_count += 1
	if cond:
		_fail("assert_false failed: %s" % msg)

func assert_eq(actual, expected, msg: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		_fail("assert_eq failed: expected %s got %s. %s" % [str(expected), str(actual), msg])

func assert_ne(actual, other, msg: String = "") -> void:
	_assert_count += 1
	if actual == other:
		_fail("assert_ne failed: %s should not equal %s. %s" % [str(actual), str(other), msg])

# Float comparison with tolerance (essential for Big/float game quantities).
func assert_almost_eq(actual: float, expected: float, tol: float = 0.0001, msg: String = "") -> void:
	_assert_count += 1
	if absf(actual - expected) > tol:
		_fail("assert_almost_eq failed: expected ~%f got %f (tol %f). %s" % [expected, actual, tol, msg])

func assert_gt(a: float, b: float, msg: String = "") -> void:
	_assert_count += 1
	if not (a > b):
		_fail("assert_gt failed: %f not > %f. %s" % [a, b, msg])

func assert_lt(a: float, b: float, msg: String = "") -> void:
	_assert_count += 1
	if not (a < b):
		_fail("assert_lt failed: %f not < %f. %s" % [a, b, msg])

func assert_has(collection, item, msg: String = "") -> void:
	_assert_count += 1
	if not (item in collection):
		_fail("assert_has failed: %s not in %s. %s" % [str(item), str(collection), msg])

func assert_not_null(v, msg: String = "") -> void:
	_assert_count += 1
	if v == null:
		_fail("assert_not_null failed: %s" % msg)
