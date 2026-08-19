# OverworldTileset — builds a placeholder TileSet at runtime, one solid-color
# procedural tile per danger tier (green -> red as tier id rises), same
# "assemble the resource in code" pattern as MonsterSpriteSheet. The atlas
# source id IS the tier id, so the scene can read the tier under the
# character straight off TileMap.get_cell_source_id with no separate lookup
# table. Manual-verify only (rendering).
class_name OverworldTileset
extends RefCounted

static func build(tile_size: int, tier_ids: Array) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)

	for i in range(tier_ids.size()):
		var tier_id: int = tier_ids[i]
		var source := TileSetAtlasSource.new()
		source.texture = _tier_texture(tile_size, i, tier_ids.size())
		source.texture_region_size = Vector2i(tile_size, tile_size)
		source.create_tile(Vector2i.ZERO)
		tile_set.add_source(source, tier_id)
	return tile_set

static func _tier_texture(tile_size: int, index: int, tier_count: int) -> ImageTexture:
	var t := float(index) / maxf(float(tier_count - 1), 1.0)
	var color := Color(0.25 + 0.55 * t, 0.55 - 0.35 * t, 0.25 - 0.15 * t)
	var img := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
