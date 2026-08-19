extends "res://tests/test_case.gd"

const SpriteSheetSlicer = preload("res://src/systems/sprite_sheet_slicer.gd")

func test_idle_row_zero_frames_are_row_major_across_columns() -> void:
	assert_eq(SpriteSheetSlicer.frame_rect("idle", 0), Rect2i(0, 0, 64, 64))
	assert_eq(SpriteSheetSlicer.frame_rect("idle", 1), Rect2i(64, 0, 64, 64))
	assert_eq(SpriteSheetSlicer.frame_rect("idle", 3), Rect2i(192, 0, 64, 64))

func test_attack_and_hit_rows_offset_by_frame_size() -> void:
	assert_eq(SpriteSheetSlicer.frame_rect("attack", 0), Rect2i(0, 64, 64, 64))
	assert_eq(SpriteSheetSlicer.frame_rect("hit", 0), Rect2i(0, 128, 64, 64))
	assert_eq(SpriteSheetSlicer.frame_rect("hit", 1), Rect2i(64, 128, 64, 64))

func test_frame_rects_returns_frame_count_entries_in_order() -> void:
	var rects := SpriteSheetSlicer.frame_rects("idle")
	assert_eq(rects.size(), 4)
	assert_eq(rects[0], Rect2i(0, 0, 64, 64))
	assert_eq(rects[2], Rect2i(128, 0, 64, 64))

	var hit_rects := SpriteSheetSlicer.frame_rects("hit")
	assert_eq(hit_rects.size(), 2)

func test_loop_flags_match_spec() -> void:
	assert_true(SpriteSheetSlicer.loops("idle"))
	assert_false(SpriteSheetSlicer.loops("attack"))
	assert_false(SpriteSheetSlicer.loops("hit"))

func test_sheet_size_matches_fixed_spec() -> void:
	assert_eq(SpriteSheetSlicer.sheet_size(), Vector2i(256, 192))
