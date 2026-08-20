# Pixel-invariant checker for scripts/verify_visual.sh (issue #32). Runs
# plain --headless (no display needed): it only decodes PNGs already
# rendered to disk by _screenshot_runner.gd, it doesn't rasterize anything
# itself. Invoked as:
#   godot --headless --script res://scripts/_visual_invariants.gd -- <launch.png> <combat.png>
extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: _visual_invariants.gd -- <launch.png> <combat.png> <overworld.png>")
		quit(1)
		return
	var ok := _check_navy_corners(args[0], "launch")
	ok = _check_navy_corners(args[1], "combat") and ok
	ok = _check_combat_bars(args[1]) and ok
	ok = _check_overworld_hot_corner(args[2]) and ok
	quit(0 if ok else 1)

# Coarse band check: dark AND blue-leaning (b clearly above r). Distinguishes
# the navy backgrounds (e.g. #151822, #12151f) from Godot's default flat
# grey clear color (~#3a3a3a, r≈g≈b) without pinning an exact hex.
func _is_navy(c: Color) -> bool:
	var is_dark := c.v < 0.4
	var is_blue_leaning := c.b > c.r + 0.02
	return is_dark and is_blue_leaning

# Coarse "reddish"/"greenish" checks for the filled monster/player HP bars
# (issue #33): dominant channel clearly above the other two, so a rendered
# gradient fill hits this even if antialiasing shifts the exact hex.
func _is_reddish(c: Color) -> bool:
	return c.r > 0.5 and c.r > c.g + 0.15 and c.r > c.b + 0.15

func _is_greenish(c: Color) -> bool:
	return c.g > 0.4 and c.g > c.r + 0.1 and c.g > c.b + 0.1

func _check_combat_bars(path: String) -> bool:
	var img := Image.new()
	if img.load(path) != OK:
		push_error("combat: could not load rendered frame %s" % path)
		return false
	var w := img.get_width()
	var h := img.get_height()
	var found_red := false
	var found_green := false
	var step := 3
	var y := 0
	while y < h and not (found_red and found_green):
		var x := 0
		while x < w:
			var px: Color = img.get_pixel(x, y)
			if not found_red and _is_reddish(px):
				found_red = true
			if not found_green and _is_greenish(px):
				found_green = true
			x += step
		y += step
	if not found_red:
		push_error("combat: no reddish pixel found (monster HP bar must render filled red)")
	if not found_green:
		push_error("combat: no greenish pixel found (player HP bar must render filled green)")
	return found_red and found_green

# The overworld tile field must show its danger gradient rising toward the
# hot (top-right) corner (issue #34): scan the top-right quadrant of the
# rendered frame for at least one reddish pixel (the tier-2 tile colour, or
# the exit marker/hot-strip UI drawn in the same red family).
func _check_overworld_hot_corner(path: String) -> bool:
	var img := Image.new()
	if img.load(path) != OK:
		push_error("overworld: could not load rendered frame %s" % path)
		return false
	var w := img.get_width()
	var h := img.get_height()
	var x_start := int(w / 2.0)
	var y_end := int(h / 2.0)
	var step := 3
	var y := 0
	while y < y_end:
		var x := x_start
		while x < w:
			if _is_reddish(img.get_pixel(x, y)):
				return true
			x += step
		y += step
	push_error("overworld: no reddish pixel found toward the top-right (hot) corner")
	return false

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
