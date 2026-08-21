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
	ok = _check_overworld_concentric_gradient(args[2]) and ok
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

# The overworld tile field must show its danger gradient banded by RADIAL
# DISTANCE from the map center (PRD issue #36/#37, Concentric Sections):
# safe/green pixels around the center (where the camp spawns), hot/red
# pixels toward the outer ring (screen edges/corners). The player spawns at
# center, so the on-screen center is a reliable proxy for the camp
# regardless of which zone/portal placement generated the frame. Scans a
# small box around the frame center for a greenish pixel and the outer
# border ring for a reddish pixel (tier-hot tile colour, or exit
# marker/hot-strip UI drawn in the same red family).
func _check_overworld_concentric_gradient(path: String) -> bool:
	var img := Image.new()
	if img.load(path) != OK:
		push_error("overworld: could not load rendered frame %s" % path)
		return false
	var w := img.get_width()
	var h := img.get_height()
	var step := 3

	var found_green := false
	var cx := w / 2
	var cy := h / 2
	var half := int(minf(w, h) / 6.0)
	var y := maxi(0, cy - half)
	while y < mini(h, cy + half) and not found_green:
		var x := maxi(0, cx - half)
		while x < mini(w, cx + half):
			if _is_greenish(img.get_pixel(x, y)):
				found_green = true
				break
			x += step
		y += step
	if not found_green:
		push_error("overworld: no greenish pixel found near the center (camp)")

	var found_red := false
	var border := int(minf(w, h) / 6.0)
	y = 0
	while y < h and not found_red:
		var x := 0
		while x < w:
			var near_edge := x < border or x >= w - border or y < border or y >= h - border
			if near_edge and _is_reddish(img.get_pixel(x, y)):
				found_red = true
				break
			x += step
		y += step
	if not found_red:
		push_error("overworld: no reddish pixel found toward the outer ring (edges)")

	return found_green and found_red

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
