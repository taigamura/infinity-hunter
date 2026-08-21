# OverworldTileset — builds a placeholder TileSet at runtime, one procedural
# tile family per danger tier, same "assemble the resource in code" pattern
# as MonsterSpriteSheet. The atlas source id IS the tier id, so the scene can
# read the tier under the character straight off TileMap.get_cell_source_id
# with no separate lookup table.
#
# Colour follows the mockup's 3-stop danger gradient (issue #34), driven by
# continuous depth along the travel axis (OverworldTierLayout.depth_ratio,
# ADR-0001), not a flat per-tier fill. The 3 stops themselves come from the
# active zone's palette (ZoneDef.palette, data/zones/*.json, ADR-0001 slice
# C) so each zone reads distinctly (e.g. Verdant Fields green -> olive-brown
# -> deep red, Cinder Dunes sand -> ember -> magma); build() falls back to
# DEFAULT_PALETTE when no palette is supplied. Each tier's atlas is a
# VARIANT_COUNT x SHADE_COUNT grid: columns are
# shade-jittered texture variety (as before), rows are SHADE_COUNT quantized
# steps of the gradient across that tier's depth band, so cells within a
# tier still darken/redden toward its far edge instead of jumping in a flat
# block. A SHADE_COUNT-th extra row (TRAIL_ROW) holds a dirt-tinted blend of
# that same band colour for the cosmetic trail spine (ADR-0001): visual only,
# it does not change the tier read off the atlas source id.
# Manual-verify only (rendering).
class_name OverworldTileset
extends RefCounted

const VARIANT_COUNT := 4
const SHADE_COUNT := 6
const SHADE_JITTER := 0.05
const BORDER_WIDTH := 2

# Fallback 3-stop palette (Verdant Fields' original hardcoded look), used
# when a caller doesn't supply a zone palette (e.g. legacy/unit-test calls).
# Zone palettes normally come from ZoneDef.palette (data/zones/*.json,
# ADR-0001 slice C) as an Array[String] of "#RRGGBB" hex colors.
const DEFAULT_PALETTE := ["#408C40", "#86602D", "#CC331A"]

# Dirt-brown tint blended over the band colour for the trail spine tiles.
# Kept modest (issue #39: the path now actually renders near the safe-band
# camp) so a trail tile still reads as a dirt corridor without fully
# canceling out the underlying band's hue — the safe band must stay
# recognizably green near the camp for the concentric-gradient visual gate.
const TRAIL_TINT := Color(0.5, 0.36, 0.2)
const TRAIL_BLEND := 0.3

static func build(tile_size: int, tier_ids: Array, palette: Array = DEFAULT_PALETTE) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	var colors := _palette_to_colors(palette)

	for i in range(tier_ids.size()):
		var tier_id: int = tier_ids[i]
		var source := TileSetAtlasSource.new()
		source.texture = _tier_strip_texture(tile_size, i, tier_ids.size(), colors)
		source.texture_region_size = Vector2i(tile_size, tile_size)
		for v in range(VARIANT_COUNT):
			for s in range(SHADE_COUNT + 1):
				source.create_tile(Vector2i(v, s))
		tile_set.add_source(source, tier_id)
	return tile_set

# Number of atlas-x variants baked per tier; callers pick a random one in
# [0, variant_count()) as the atlas_coords.x when painting a cell.
static func variant_count() -> int:
	return VARIANT_COUNT

# Row (atlas_coords.y) that best represents `depth` (0..1, see
# OverworldTierLayout.depth_ratio) within `tier_index`'s band of
# `tier_count` evenly-split bands.
static func shade_index_for_distance(depth: float, tier_index: int, tier_count: int) -> int:
	var band_width := 1.0 / maxf(float(tier_count), 1.0)
	var band_start := tier_index * band_width
	var local := 0.5 if band_width <= 0.0 else clampf((depth - band_start) / band_width, 0.0, 1.0)
	return clampi(int(local * SHADE_COUNT), 0, SHADE_COUNT - 1)

# Atlas row (atlas_coords.y) for the cosmetic trail spine tiles: the extra
# row baked past the normal SHADE_COUNT shade rows.
static func trail_shade_row() -> int:
	return SHADE_COUNT

# Converts a palette (Array[String] "#RRGGBB" hex, or already-Color values)
# into an Array[Color]. Colors are resolved once per build() call rather than
# per-pixel.
static func _palette_to_colors(palette: Array) -> Array:
	var colors: Array = []
	for stop in palette:
		colors.append(stop if stop is Color else Color(String(stop)))
	return colors

# The 3-stop danger gradient (safe -> mid -> hot) evaluated at a global
# distance ratio, independent of tier bucketing, so colour stays continuous
# across tier boundaries. `colors` is a zone's palette (ZoneDef.palette,
# ADR-0001 slice C) resolved to exactly 3 Color stops via _palette_to_colors;
# falls back to the first/last stop defensively if malformed.
static func gradient_color(colors: Array, t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	if colors.size() < 3:
		return colors[0] if not colors.is_empty() else Color.WHITE
	if t <= 0.5:
		return colors[0].lerp(colors[1], t / 0.5)
	return colors[1].lerp(colors[2], (t - 0.5) / 0.5)

static func _tier_strip_texture(tile_size: int, index: int, tier_count: int, colors: Array) -> ImageTexture:
	var band_width := 1.0 / maxf(float(tier_count), 1.0)
	var band_start := index * band_width
	var img := Image.create(tile_size * VARIANT_COUNT, tile_size * (SHADE_COUNT + 1), false, Image.FORMAT_RGBA8)

	# Deterministic per-tier seed so the atlas is stable across rebuilds
	# (same zone always looks the same) without needing a caller-supplied rng.
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 97 + 13
	for s in range(SHADE_COUNT):
		var shade_depth := band_start + (s + 0.5) / float(SHADE_COUNT) * band_width
		var base_color := gradient_color(colors, shade_depth)
		for v in range(VARIANT_COUNT):
			var jitter := rng.randf_range(-SHADE_JITTER, SHADE_JITTER)
			var tile_color := Color(
				clampf(base_color.r + jitter, 0.0, 1.0),
				clampf(base_color.g + jitter, 0.0, 1.0),
				clampf(base_color.b + jitter, 0.0, 1.0),
			)
			_paint_tile(img, v * tile_size, s * tile_size, tile_size, tile_color)

	# Trail row: the band's midpoint colour blended toward a dirt tint, so
	# the corridor reads as a distinct dirt path regardless of which shade
	# row it's cosmetically overlaid on (visual only; tier is unaffected).
	var band_mid_color := gradient_color(colors, band_start + band_width / 2.0)
	var trail_base := band_mid_color.lerp(TRAIL_TINT, TRAIL_BLEND)
	for v in range(VARIANT_COUNT):
		var jitter := rng.randf_range(-SHADE_JITTER, SHADE_JITTER)
		var tile_color := Color(
			clampf(trail_base.r + jitter, 0.0, 1.0),
			clampf(trail_base.g + jitter, 0.0, 1.0),
			clampf(trail_base.b + jitter, 0.0, 1.0),
		)
		_paint_tile(img, v * tile_size, SHADE_COUNT * tile_size, tile_size, tile_color)
	return ImageTexture.create_from_image(img)

static func _paint_tile(img: Image, x_offset: int, y_offset: int, tile_size: int, color: Color) -> void:
	var border_color := color.darkened(0.35)
	for x in range(tile_size):
		for y in range(tile_size):
			var is_border := x < BORDER_WIDTH or y < BORDER_WIDTH or x >= tile_size - BORDER_WIDTH or y >= tile_size - BORDER_WIDTH
			img.set_pixel(x_offset + x, y_offset + y, border_color if is_border else color)
