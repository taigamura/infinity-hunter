# OverworldTileset — builds a placeholder TileSet at runtime, one solid-color
# procedural tile family per danger tier (green -> red as tier id rises), same
# "assemble the resource in code" pattern as MonsterSpriteSheet. The atlas
# source id IS the tier id, so the scene can read the tier under the
# character straight off TileMap.get_cell_source_id with no separate lookup
# table. Each tier gets VARIANT_COUNT shade-jittered, inset-bordered tiles
# (laid out side by side in one atlas strip) so the scene can paint a random
# atlas x per cell for cheap texture variety with no new art. Manual-verify
# only (rendering).
class_name OverworldTileset
extends RefCounted

const VARIANT_COUNT := 4
const SHADE_JITTER := 0.05
const BORDER_WIDTH := 2

static func build(tile_size: int, tier_ids: Array) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)

	for i in range(tier_ids.size()):
		var tier_id: int = tier_ids[i]
		var source := TileSetAtlasSource.new()
		source.texture = _tier_strip_texture(tile_size, i, tier_ids.size())
		source.texture_region_size = Vector2i(tile_size, tile_size)
		for v in range(VARIANT_COUNT):
			source.create_tile(Vector2i(v, 0))
		tile_set.add_source(source, tier_id)
	return tile_set

# Number of atlas-x variants baked per tier; callers pick a random one in
# [0, variant_count()) as the atlas_coords.x when painting a cell.
static func variant_count() -> int:
	return VARIANT_COUNT

static func _tier_strip_texture(tile_size: int, index: int, tier_count: int) -> ImageTexture:
	var t := float(index) / maxf(float(tier_count - 1), 1.0)
	var base_color := Color(0.25 + 0.55 * t, 0.55 - 0.35 * t, 0.25 - 0.15 * t)
	var img := Image.create(tile_size * VARIANT_COUNT, tile_size, false, Image.FORMAT_RGBA8)

	# Deterministic per-tier seed so the atlas is stable across rebuilds
	# (same zone always looks the same) without needing a caller-supplied rng.
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 97 + 13
	for v in range(VARIANT_COUNT):
		var jitter := rng.randf_range(-SHADE_JITTER, SHADE_JITTER)
		var tile_color := Color(
			clampf(base_color.r + jitter, 0.0, 1.0),
			clampf(base_color.g + jitter, 0.0, 1.0),
			clampf(base_color.b + jitter, 0.0, 1.0),
		)
		_paint_tile(img, v * tile_size, tile_size, tile_color)
	return ImageTexture.create_from_image(img)

static func _paint_tile(img: Image, x_offset: int, tile_size: int, color: Color) -> void:
	var border_color := color.darkened(0.35)
	for x in range(tile_size):
		for y in range(tile_size):
			var is_border := x < BORDER_WIDTH or y < BORDER_WIDTH or x >= tile_size - BORDER_WIDTH or y >= tile_size - BORDER_WIDTH
			img.set_pixel(x_offset + x, y, border_color if is_border else color)
