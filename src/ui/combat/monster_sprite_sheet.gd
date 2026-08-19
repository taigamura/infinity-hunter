# MonsterSpriteSheet — builds a runtime SpriteFrames resource from a proxy
# or real sheet PNG, per the fixed layout in docs/sprite_sheet_spec.md. Manual
# -verify only (rendering); the frame math it delegates to lives in
# SpriteSheetSlicer, which IS covered by the headless logic test suite.
class_name MonsterSpriteSheet
extends RefCounted

const SpriteSheetSlicer = preload("res://src/systems/sprite_sheet_slicer.gd")

const PLACEHOLDER_PATH := "res://assets/sprites/placeholder_monster.png"
const PER_MONSTER_DIR := "res://assets/sprites/"

# Per-monster sheet if one exists at assets/sprites/<monster_id>.png, else the
# shared placeholder. Swapping a same-spec real sheet in at that path needs no
# code change.
static func path_for(monster_id: String) -> String:
	var per_monster_path := "%s%s.png" % [PER_MONSTER_DIR, monster_id]
	if ResourceLoader.exists(per_monster_path):
		return per_monster_path
	return PLACEHOLDER_PATH

static func build(monster_id: String) -> SpriteFrames:
	var texture := load(path_for(monster_id)) as Texture2D
	var frames := SpriteFrames.new()
	for anim_name in SpriteSheetSlicer.ANIMS:
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, SpriteSheetSlicer.loops(anim_name))
		frames.set_animation_speed(anim_name, SpriteSheetSlicer.fps(anim_name))
		for rect in SpriteSheetSlicer.frame_rects(anim_name):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(rect)
			frames.add_frame(anim_name, atlas)
	frames.remove_animation("default")
	return frames
