# CraftingSystem — fixed recipes (WeaponDef/ArmorDef.recipe) consume
# materials from an Inventory to produce instanced gear. Crafted gear rolls a
# rarity tier (Common/Uncommon/Rare/Epic, PRD §"Rarity tiers default") that
# applies an ascending stat multiplier to the def's base stat, producing the
# `rolled_stats` an Inventory gear instance stores.
class_name CraftingSystem
extends RefCounted

# name -> {weight: odds in the roll, multiplier: applied to the def's base stat}.
# Weights/multipliers are playtest-tuned placeholders (PRD §"Further Notes").
const RARITY_TIERS := [
	{"name": "Common", "weight": 60.0, "multiplier": 1.0},
	{"name": "Uncommon", "weight": 25.0, "multiplier": 1.15},
	{"name": "Rare", "weight": 12.0, "multiplier": 1.35},
	{"name": "Epic", "weight": 3.0, "multiplier": 1.6},
]

# Weighted roll over RARITY_TIERS. `rng` is caller-supplied so rolls are
# deterministic and statistically verifiable in tests.
static func roll_rarity(rng: RandomNumberGenerator) -> Dictionary:
	var total_weight := 0.0
	for tier in RARITY_TIERS:
		total_weight += tier["weight"]

	var roll_point := rng.randf() * total_weight
	var cursor := 0.0
	for tier in RARITY_TIERS:
		cursor += tier["weight"]
		if roll_point < cursor:
			return tier
	return RARITY_TIERS[-1] # float rounding fallback

# True if `inventory` holds enough materials to craft `def`.
static func can_craft(def, inventory: Inventory) -> bool:
	return inventory.has_materials(def.recipe)

# Crafts `def` (a WeaponDef or ArmorDef) from `inventory`: consumes the
# recipe's materials, rolls a rarity tier, and adds the resulting gear
# instance to the inventory. Returns {"ok": bool, "error": String,
# "gear": Dictionary (on success)}. Rejects (no state change) when the
# inventory lacks sufficient materials.
static func craft(def, inventory: Inventory, rng: RandomNumberGenerator) -> Dictionary:
	if not can_craft(def, inventory):
		return {"ok": false, "error": "insufficient materials", "gear": null}

	inventory.consume_materials(def.recipe)

	var tier := roll_rarity(rng)
	var rolled_stats := _roll_stats(def, tier)
	var instance := inventory.add_gear(def.id, rolled_stats)
	return {"ok": true, "error": "", "gear": instance}

static func _roll_stats(def, tier: Dictionary) -> Dictionary:
	var multiplier: float = tier["multiplier"]
	var stats := {"rarity": tier["name"]}
	if def is WeaponDef:
		stats["power"] = def.base_damage * multiplier
	elif def is ArmorDef:
		stats["defense"] = def.base_defense * multiplier
	return stats
