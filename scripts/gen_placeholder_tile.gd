# One-off dev tool: generates the placeholder overworld ground tile at
# assets/sprites/placeholder_tile.png. Not part of the test gate. Run with:
#   godot --headless --script res://scripts/gen_placeholder_tile.gd
extends SceneTree

const TILE_SIZE := 64
const FILL := Color(0.3, 0.55, 0.25)
const EDGE := Color(0.22, 0.42, 0.18)

func _init() -> void:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(FILL)
	for x in range(TILE_SIZE):
		img.set_pixel(x, 0, EDGE)
		img.set_pixel(x, TILE_SIZE - 1, EDGE)
	for y in range(TILE_SIZE):
		img.set_pixel(0, y, EDGE)
		img.set_pixel(TILE_SIZE - 1, y, EDGE)

	var err := img.save_png("res://assets/sprites/placeholder_tile.png")
	if err != OK:
		push_error("Failed to save placeholder tile: %s" % err)
	quit(0 if err == OK else 1)
