# OverworldTileset — builds a placeholder TileSet at runtime, one procedural
# tile family per danger tier, same "assemble the resource in code" pattern
# as MonsterSpriteSheet. The atlas source id IS the tier id, so the scene can
# read the tier under the character straight off TileMap.get_cell_source_id
# with no separate lookup table.
#
# Colour follows the mockup's 3-stop danger gradient (issue #34): safe green
# -> olive-brown -> danger red, driven by continuous distance-from-center
# (OverworldTierLayout.distance_ratio), not a flat per-tier fill. Each tier's
# atlas is a VARIANT_COUNT x SHADE_COUNT grid: columns are shade-jittered
# texture variety (as before), rows are SHADE_COUNT quantized steps of the
# gradient across that tier's distance band, so cells within a tier still
# darken/redden toward its far edge instead of jumping in a flat block.
# Manual-verify only (rendering).
class_name OverworldTileset
extends RefCounted

const VARIANT_COUNT := 4
const SHADE_COUNT := 6
const SHADE_JITTER := 0.05
const BORDER_WIDTH := 2

const SAFE_COLOR := Color(64.0 / 255.0, 140.0 / 255.0, 64.0 / 255.0)
const MID_COLOR := Color(134.0 / 255.0, 96.0 / 255.0, 45.0 / 255.0)
const HOT_COLOR := Color(204.0 / 255.0, 51.0 / 255.0, 26.0 / 255.0)

static func build(tile_size: int, tier_ids: Array) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)

	for i in range(tier_ids.size()):
		var tier_id: int = tier_ids[i]
		var source := TileSetAtlasSource.new()
		source.texture = _tier_strip_texture(tile_size, i, tier_ids.size())
		source.texture_region_size = Vector2i(tile_size, tile_size)
		for v in range(VARIANT_COUNT):
			for s in range(SHADE_COUNT):
				source.create_tile(Vector2i(v, s))
		tile_set.add_source(source, tier_id)
	return tile_set

# Number of atlas-x variants baked per tier; callers pick a random one in
# [0, variant_count()) as the atlas_coords.x when painting a cell.
static func variant_count() -> int:
	return VARIANT_COUNT

# Row (atlas_coords.y) that best represents `distance` (0..1, see
# OverworldTierLayout.distance_ratio) within `tier_index`'s band of
# `tier_count` evenly-split bands.
static func shade_index_for_distance(distance: float, tier_index: int, tier_count: int) -> int:
	var band_width := 1.0 / maxf(float(tier_count), 1.0)
	var band_start := tier_index * band_width
	var local := 0.5 if band_width <= 0.0 else clampf((distance - band_start) / band_width, 0.0, 1.0)
	return clampi(int(local * SHADE_COUNT), 0, SHADE_COUNT - 1)

# The 3-stop danger gradient (safe -> mid -> hot) evaluated at a global
# distance ratio, independent of tier bucketing, so colour stays continuous
# across tier boundaries.
static func _gradient_color(t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	if t <= 0.5:
		return SAFE_COLOR.lerp(MID_COLOR, t / 0.5)
	return MID_COLOR.lerp(HOT_COLOR, (t - 0.5) / 0.5)

static func _tier_strip_texture(tile_size: int, index: int, tier_count: int) -> ImageTexture:
	var band_width := 1.0 / maxf(float(tier_count), 1.0)
	var band_start := index * band_width
	var img := Image.create(tile_size * VARIANT_COUNT, tile_size * SHADE_COUNT, false, Image.FORMAT_RGBA8)

	# Deterministic per-tier seed so the atlas is stable across rebuilds
	# (same zone always looks the same) without needing a caller-supplied rng.
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 97 + 13
	for s in range(SHADE_COUNT):
		var shade_distance := band_start + (s + 0.5) / float(SHADE_COUNT) * band_width
		var base_color := _gradient_color(shade_distance)
		for v in range(VARIANT_COUNT):
			var jitter := rng.randf_range(-SHADE_JITTER, SHADE_JITTER)
			var tile_color := Color(
				clampf(base_color.r + jitter, 0.0, 1.0),
				clampf(base_color.g + jitter, 0.0, 1.0),
				clampf(base_color.b + jitter, 0.0, 1.0),
			)
			_paint_tile(img, v * tile_size, s * tile_size, tile_size, tile_color)
	return ImageTexture.create_from_image(img)

static func _paint_tile(img: Image, x_offset: int, y_offset: int, tile_size: int, color: Color) -> void:
	var border_color := color.darkened(0.35)
	for x in range(tile_size):
		for y in range(tile_size):
			var is_border := x < BORDER_WIDTH or y < BORDER_WIDTH or x >= tile_size - BORDER_WIDTH or y >= tile_size - BORDER_WIDTH
			img.set_pixel(x_offset + x, y_offset + y, border_color if is_border else color)
