# Headless test runner. Run with:
#   godot --headless --path . --script res://tests/run_tests.gd
#
# Discovers every tests/unit/*.gd script (which must `extends TestCase`),
# instantiates it, runs each `test_*` method with before_each/after_each,
# prints a summary, and exits 0 if all pass, 1 if any fail.
#
# The overnight /loop uses the exit code as its pass/fail gate.
extends SceneTree

const UNIT_DIR := "res://tests/unit"

# _initialize() is the SceneTree/MainLoop entry point in Godot 4 (NOT _init()).
# quit() called from _init() runs before the main loop starts and is ignored,
# leaving the process hanging forever headlessly — so all logic lives here.
func _initialize() -> void:
	var total := 0
	var passed := 0
	var failed := 0
	var failed_names: Array[String] = []

	var files := _list_test_scripts(UNIT_DIR)
	if files.is_empty():
		print("[test] no test scripts found in %s" % UNIT_DIR)

	for path in files:
		var script: GDScript = load(path)
		if script == null:
			print("[test] FAILED to load %s" % path)
			failed += 1
			failed_names.append(path)
			continue
		var instance = script.new()
		# Duck-type instead of `is TestCase` (no global class_name — see test_case.gd).
		# A real test case exposes the assert helpers and the _failures array.
		if not instance.has_method("assert_eq"):
			continue
		for method in instance.get_method_list():
			var mname: String = method.get("name", "")
			if not mname.begins_with("test_"):
				continue
			total += 1
			instance._failures.clear()
			instance.before_each()
			instance.call(mname)
			instance.after_each()
			if instance._failures.is_empty():
				passed += 1
			else:
				failed += 1
				var label := "%s::%s" % [path.get_file(), mname]
				failed_names.append(label)
				print("[FAIL] %s" % label)
				for f in instance._failures:
					print("       %s" % f)

	print("\n==================================================")
	print("[test] %d passed, %d failed, %d total" % [passed, failed, total])
	if failed > 0:
		print("[test] failures:")
		for n in failed_names:
			print("   - %s" % n)
	print("==================================================")

	quit(1 if failed > 0 else 0)

func _list_test_scripts(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".gd"):
			out.append("%s/%s" % [dir_path, fname])
		fname = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out
