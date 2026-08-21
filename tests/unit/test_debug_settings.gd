# Tests for DebugSettings — the debug sprite/dot render toggle. Verifies the
# default is dot mode (as requested) and that the dot texture / dot
# SpriteFrames builders produce usable resources.
extends "res://tests/test_case.gd"

# DebugSettings is a static-var flag shared process-wide; save/restore it so a
# test flipping it never leaks into other tests.
var _saved := true

func before_each() -> void:
	_saved = DebugSettings.sprites_as_dots

func after_each() -> void:
	DebugSettings.sprites_as_dots = _saved

func test_defaults_to_dot_mode() -> void:
	# A freshly-loaded process boots in dot mode per the feature request.
	assert_true(_saved, "DebugSettings.sprites_as_dots must default to true (dot mode)")

func test_dots_enabled_reflects_flag() -> void:
	DebugSettings.sprites_as_dots = true
	assert_true(DebugSettings.dots_enabled())
	DebugSettings.sprites_as_dots = false
	assert_false(DebugSettings.dots_enabled())

func test_dot_texture_is_one_pixel_by_default() -> void:
	var tex := DebugSettings.dot_texture()
	assert_eq(tex.get_width(), 1, "default dot texture is a genuine 1px dot")
	assert_eq(tex.get_height(), 1)

func test_dot_texture_honors_size() -> void:
	var tex := DebugSettings.dot_texture(Color.WHITE, 8)
	assert_eq(tex.get_width(), 8)
	assert_eq(tex.get_height(), 8)

func test_dot_sprite_frames_has_a_frame_per_anim() -> void:
	var frames := DebugSettings.dot_sprite_frames(["idle", "attack", "hit"])
	assert_true(frames.has_animation("idle"))
	assert_true(frames.has_animation("attack"))
	assert_true(frames.has_animation("hit"))
	assert_eq(frames.get_frame_count("idle"), 1, "each dot anim is a single dot frame")
	assert_false(frames.has_animation("default"), "the placeholder 'default' anim is removed")
