# SpriteSheetSlicer — pure row-major frame-rect math for the fixed monster
# sprite sheet spec (docs/sprite_sheet_spec.md). No Image/Texture work here
# so this is covered by the headless logic test suite; MonsterSpriteSheet
# (src/ui/combat) turns these rects into a real SpriteFrames resource.
class_name SpriteSheetSlicer
extends RefCounted

const FRAME_SIZE := Vector2i(64, 64)
const COLUMNS := 4

# anim name -> {row, frame_count, fps}
const ANIMS := {
	"idle": {"row": 0, "frame_count": 4, "fps": 4.0, "loop": true},
	"attack": {"row": 1, "frame_count": 4, "fps": 8.0, "loop": false},
	"hit": {"row": 2, "frame_count": 2, "fps": 6.0, "loop": false},
}

# The Rect2i region (in sheet pixels) of `anim_name`'s `frame_index`-th frame.
static func frame_rect(anim_name: String, frame_index: int) -> Rect2i:
	var anim: Dictionary = ANIMS[anim_name]
	var count: int = anim["frame_count"]
	assert(frame_index >= 0 and frame_index < count)
	var column := frame_index % COLUMNS
	var row: int = anim["row"]
	return Rect2i(column * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)

# All frame rects for `anim_name`, in playback order.
static func frame_rects(anim_name: String) -> Array[Rect2i]:
	var anim: Dictionary = ANIMS[anim_name]
	var count: int = anim["frame_count"]
	var rects: Array[Rect2i] = []
	for i in range(count):
		rects.append(frame_rect(anim_name, i))
	return rects

static func fps(anim_name: String) -> float:
	return ANIMS[anim_name]["fps"]

static func loops(anim_name: String) -> bool:
	return ANIMS[anim_name]["loop"]

static func sheet_size() -> Vector2i:
	var max_row := 0
	for anim_name in ANIMS:
		max_row = maxi(max_row, ANIMS[anim_name]["row"])
	return Vector2i(COLUMNS * FRAME_SIZE.x, (max_row + 1) * FRAME_SIZE.y)
