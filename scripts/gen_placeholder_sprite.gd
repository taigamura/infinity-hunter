# One-off dev tool: generates the shared proxy sheet at
# assets/sprites/placeholder_monster.png per docs/sprite_sheet_spec.md.
# Not part of the test gate. Run with:
#   godot --headless --script res://scripts/gen_placeholder_sprite.gd
extends SceneTree

const SpriteSheetSlicer = preload("res://src/systems/sprite_sheet_slicer.gd")

const ROW_COLORS := {
	0: Color(0.25, 0.55, 0.95), # idle — blue
	1: Color(0.9, 0.35, 0.2),   # attack — orange/red
	2: Color(0.95, 0.9, 0.2),   # hit — yellow flash
}

func _init() -> void:
	var size := SpriteSheetSlicer.sheet_size()
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for anim_name in SpriteSheetSlicer.ANIMS:
		var anim: Dictionary = SpriteSheetSlicer.ANIMS[anim_name]
		var row: int = anim["row"]
		var base_color: Color = ROW_COLORS[row]
		var rects := SpriteSheetSlicer.frame_rects(anim_name)
		for i in range(rects.size()):
			var rect: Rect2i = rects[i]
			# Slightly vary shade per frame so idle/attack/hit visibly "animate".
			var shade := base_color.lightened(float(i) / float(maxi(rects.size() - 1, 1)) * 0.35)
			_draw_frame(img, rect, shade)

	var err := img.save_png("res://assets/sprites/placeholder_monster.png")
	if err != OK:
		push_error("Failed to save placeholder sprite: %s" % err)
	quit(0 if err == OK else 1)

func _draw_frame(img: Image, rect: Rect2i, color: Color) -> void:
	const MARGIN := 6
	for y in range(rect.position.y + MARGIN, rect.position.y + rect.size.y - MARGIN):
		for x in range(rect.position.x + MARGIN, rect.position.x + rect.size.x - MARGIN):
			img.set_pixel(x, y, color)
	# Simple eye dots so orientation/"aliveness" reads even at a glance.
	var eye_y := rect.position.y + rect.size.y / 3
	img.set_pixel(rect.position.x + rect.size.x / 3, eye_y, Color.BLACK)
	img.set_pixel(rect.position.x + rect.size.x * 2 / 3, eye_y, Color.BLACK)
