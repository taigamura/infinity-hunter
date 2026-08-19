# OverworldTileset — builds a single-tile placeholder TileSet at runtime from
# assets/sprites/placeholder_tile.png (regenerate via
# scripts/gen_placeholder_tile.gd), same "load a proxy texture, assemble the
# resource in code" pattern as MonsterSpriteSheet. Swapping a real tileset PNG
# in at that path needs no code change. Manual-verify only (rendering).
class_name OverworldTileset
extends RefCounted

const PLACEHOLDER_PATH := "res://assets/sprites/placeholder_tile.png"

static func build(tile_size: int) -> TileSet:
	var texture := load(PLACEHOLDER_PATH) as Texture2D
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, 0)
	return tile_set
