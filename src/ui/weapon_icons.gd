# Loads per-weapon icons by the convention assets/weapons/<weapon_id>.png.
# Mirrors the per-monster sprite convention in combat/monster_sprite_sheet.gd.
# Returns null when a weapon has no icon yet, so callers degrade gracefully.
class_name WeaponIcons
extends RefCounted

const WEAPON_DIR := "res://assets/weapons/"

static var _cache: Dictionary = {}

static func for_id(weapon_id: String) -> Texture2D:
	if _cache.has(weapon_id):
		return _cache[weapon_id]
	var path := WEAPON_DIR + weapon_id + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[weapon_id] = tex
	return tex
