# DebugSettings — global, cross-scene debug-render toggles.
#
# `sprites_as_dots` flips every world entity sprite (the overworld player, the
# combat monster, and the combat "YOU" avatar) between its real art and a plain
# "1 pixel dot" marker, so the raw entity position/logic is visible without any
# art in the way. It's a static var, so it survives scene changes and combat
# overlay instancing, and every render site reads it fresh when it builds.
#
# It DEFAULTS ON (dot mode) per request: the game boots showing dots, and the
# in-game switch (overworld HUD) flips to real sprites.
class_name DebugSettings
extends RefCounted

# Dot mode is the default state.
static var sprites_as_dots := true

# The debug marker is a genuine 1x1-pixel texture (a "1 pixel dot"); render
# sites scale it up by DOT_DISPLAY_SCALE with nearest filtering. Sized to the
# sprites' native art (64px frames) so the dot reads as sprite-sized, not a
# speck.
const DOT_DISPLAY_SCALE := 64.0

# Fallback tint when a call site doesn't pass one.
const DOT_COLOR := Color(1, 0.24, 0.32, 1)

static func dots_enabled() -> bool:
	return sprites_as_dots

# A square opaque dot texture in `color`. `size` is 1 by default (a genuine
# "1 pixel dot" — Node2D render sites scale it up via DOT_DISPLAY_SCALE); a
# Control site that can't scale its texture cleanly can bake a bigger square.
static func dot_texture(color: Color = DOT_COLOR, size: int = 1) -> ImageTexture:
	var img := Image.create(maxi(size, 1), maxi(size, 1), false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

# A SpriteFrames whose every animation is a single dot frame, so an
# AnimatedSprite2D can drop into dot mode without any of its play()/loop
# bookkeeping changing (used by the combat monster sprite).
static func dot_sprite_frames(anims: Array, color: Color = DOT_COLOR) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var tex := dot_texture(color)
	for anim_name in anims:
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.add_frame(anim_name, tex)
	frames.remove_animation("default")
	return frames
