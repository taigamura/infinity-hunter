# Headless-viewport screenshot runner for scripts/screenshot.sh (issue #28).
# Invoked once per screen via `godot --script res://scripts/_screenshot_runner.gd
# -- <scene_path> <output_path> [needs_run]`. Renders under xvfb-run with the
# gl_compatibility renderer since a real window (not --headless) is required
# to produce pixels; --headless alone cannot rasterize a viewport.
extends SceneTree

var _frame_count := 0
var _output_path := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: _screenshot_runner.gd -- <scene_path> <output_path> [needs_run]")
		quit(1)
		return
	var scene_path: String = args[0]
	_output_path = args[1]
	var needs_run: bool = args.size() > 2 and args[2] == "1"

	# Referenced via get_node(), not the bare "GameState" identifier: this
	# script IS the entry point passed to --script, so it compiles before the
	# engine finishes registering autoload globals (unlike scripts loaded at
	# runtime, e.g. by tests/run_tests.gd, where the identifier works fine).
	var game_state: Node = root.get_node("GameState")
	if game_state.zones.is_empty():
		game_state._ready()
	if needs_run:
		var zone_id: String = game_state.zones.keys()[0]
		game_state.current_run = RunState.start(zone_id, "", {}, RunState.DEFAULT_HUNTS)
		var monster_id: String = game_state.monsters.keys()[0]
		game_state.pending_monster = game_state.monsters[monster_id]

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("failed to load scene: %s" % scene_path)
		quit(1)
		return
	root.add_child(packed.instantiate())
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	# A couple of frames so _ready()-deferred layout settles before capture.
	_frame_count += 1
	if _frame_count < 3:
		return
	var dir := _output_path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var texture := root.get_texture()
	var image: Image = texture.get_image() if texture != null else null
	if image == null:
		push_error("no renderable viewport texture (must run under a real display, e.g. xvfb-run + --rendering-method gl_compatibility, not plain --headless)")
		quit(1)
		return
	var err := image.save_png(_output_path)
	if err != OK:
		push_error("failed to save png: %s (err %d)" % [_output_path, err])
		quit(1)
		return
	quit(0)
