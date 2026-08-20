# Pixel-invariant checker for scripts/verify_visual.sh (issue #32). Runs
# plain --headless (no display needed): it only decodes PNGs already
# rendered to disk by _screenshot_runner.gd, it doesn't rasterize anything
# itself. Invoked as:
#   godot --headless --script res://scripts/_visual_invariants.gd -- <launch.png> <combat.png>
extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: _visual_invariants.gd -- <launch.png> <combat.png>")
		quit(1)
		return
	var ok := _check_navy_corners(args[0], "launch")
	ok = _check_navy_corners(args[1], "combat") and ok
	quit(0 if ok else 1)

# Coarse band check: dark AND blue-leaning (b clearly above r). Distinguishes
# the navy backgrounds (e.g. #151822, #12151f) from Godot's default flat
# grey clear color (~#3a3a3a, r≈g≈b) without pinning an exact hex.
func _is_navy(c: Color) -> bool:
	var is_dark := c.v < 0.4
	var is_blue_leaning := c.b > c.r + 0.02
	return is_dark and is_blue_leaning

func _check_navy_corners(path: String, label: String) -> bool:
	var img := Image.new()
	if img.load(path) != OK:
		push_error("%s: could not load rendered frame %s" % [label, path])
		return false
	var w := img.get_width()
	var h := img.get_height()
	if w < 8 or h < 8:
		push_error("%s: rendered frame too small (%dx%d)" % [label, w, h])
		return false
	var corners := [Vector2i(2, 2), Vector2i(w - 3, 2), Vector2i(2, h - 3), Vector2i(w - 3, h - 3)]
	var all_ok := true
	for c in corners:
		var px: Color = img.get_pixel(c.x, c.y)
		if not _is_navy(px):
			push_error("%s: corner pixel %s is %s, not navy (background must be dark-blue, not default grey)" % [label, c, px])
			all_ok = false
	return all_ok
