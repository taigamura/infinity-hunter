# Tests for CraftingSystem + Inventory (src/systems/crafting_system.gd,
# src/systems/inventory.gd): successful craft, insufficient-mats rejection,
# rarity roll distribution, and inventory add/remove.
extends "res://tests/test_case.gd"

const CraftingSystem = preload("res://src/systems/crafting_system.gd")
const Inventory = preload("res://src/systems/inventory.gd")
const WeaponDef = preload("res://src/models/weapon_def.gd")
const ArmorDef = preload("res://src/models/armor_def.gd")

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _weapon_def() -> WeaponDef:
	var data := {
		"id": "rusty_greatsword",
		"name": "Rusty Greatsword",
		"weapon_class": "great_sword",
		"element": "neutral",
		"base_damage": 10.0,
		"recipe": {"lizard_scale": 2, "slime_gel": 1},
	}
	return WeaponDef.from_dict(data, "test")

func _armor_def() -> ArmorDef:
	var data := {
		"id": "scale_chestplate",
		"name": "Scale Chestplate",
		"slot": "chest",
		"base_defense": 5.0,
		"skills": [],
		"recipe": {"lizard_scale": 3},
	}
	return ArmorDef.from_dict(data, "test")

# ---- crafting ---------------------------------------------------------------

func test_successful_craft_consumes_materials_and_adds_gear() -> void:
	var def := _weapon_def()
	var inv := Inventory.new()
	inv.add_material("lizard_scale", 2)
	inv.add_material("slime_gel", 1)

	var result := CraftingSystem.craft(def, inv, _rng(1))

	assert_true(result["ok"], "craft should succeed with sufficient materials")
	assert_eq(inv.materials["lizard_scale"], 0)
	assert_eq(inv.materials["slime_gel"], 0)
	assert_eq(inv.gear.size(), 1)
	assert_eq(inv.gear[0]["def_id"], "rusty_greatsword")
	assert_true(inv.gear[0]["rolled_stats"].has("power"))
	assert_true(inv.gear[0]["rolled_stats"].has("rarity"))

func test_insufficient_materials_rejected_without_state_change() -> void:
	var def := _weapon_def()
	var inv := Inventory.new()
	inv.add_material("lizard_scale", 1) # short one, and missing slime_gel entirely

	var result := CraftingSystem.craft(def, inv, _rng(1))

	assert_false(result["ok"], "craft should reject insufficient materials")
	assert_eq(result["error"], "insufficient materials")
	assert_eq(inv.materials["lizard_scale"], 1, "materials must not be consumed on rejection")
	assert_true(inv.gear.is_empty(), "no gear should be granted on rejection")

func test_can_craft_reflects_material_sufficiency() -> void:
	var def := _armor_def()
	var inv := Inventory.new()
	assert_false(CraftingSystem.can_craft(def, inv))
	inv.add_material("lizard_scale", 3)
	assert_true(CraftingSystem.can_craft(def, inv))

func test_armor_craft_rolls_defense_stat() -> void:
	var def := _armor_def()
	var inv := Inventory.new()
	inv.add_material("lizard_scale", 3)

	var result := CraftingSystem.craft(def, inv, _rng(2))

	assert_true(result["ok"])
	var stats: Dictionary = result["gear"]["rolled_stats"]
	assert_true(stats.has("defense"))
	assert_gt(stats["defense"], 0.0)

# ---- rarity roll distribution -------------------------------------------------

func test_rarity_distribution_within_tolerance() -> void:
	var counts := {"Common": 0, "Uncommon": 0, "Rare": 0, "Epic": 0}
	var n := 4000
	var rng := _rng(42)
	for i in range(n):
		var tier := CraftingSystem.roll_rarity(rng)
		counts[tier["name"]] += 1

	assert_almost_eq(float(counts["Common"]) / float(n), 0.60, 0.03)
	assert_almost_eq(float(counts["Uncommon"]) / float(n), 0.25, 0.03)
	assert_almost_eq(float(counts["Rare"]) / float(n), 0.12, 0.03)
	assert_almost_eq(float(counts["Epic"]) / float(n), 0.03, 0.02)

func test_higher_rarity_applies_larger_stat_multiplier() -> void:
	var def := _weapon_def()
	var common_stats := CraftingSystem._roll_stats(def, {"name": "Common", "multiplier": 1.0})
	var epic_stats := CraftingSystem._roll_stats(def, {"name": "Epic", "multiplier": 1.6})
	assert_gt(epic_stats["power"], common_stats["power"])

# ---- inventory add/remove -----------------------------------------------------

func test_inventory_add_remove_gear() -> void:
	var inv := Inventory.new()
	var g1 := inv.add_gear("rusty_greatsword", {"power": 10.0, "rarity": "Common"})
	var g2 := inv.add_gear("scale_chestplate", {"defense": 5.0, "rarity": "Rare"})

	assert_ne(g1["id"], g2["id"], "gear instance ids must be unique")
	assert_eq(inv.gear.size(), 2)
	assert_not_null(inv.get_gear(g1["id"]))

	assert_true(inv.remove_gear(g1["id"]))
	assert_eq(inv.gear.size(), 1)
	assert_true(inv.get_gear(g1["id"]) == null)
	assert_false(inv.remove_gear("nonexistent"))

func test_inventory_consume_materials_is_atomic() -> void:
	var inv := Inventory.new()
	inv.add_material("lizard_scale", 1)
	# recipe needs 2 lizard_scale and 1 slime_gel; inventory has neither in full.
	var recipe := {"lizard_scale": 2, "slime_gel": 1}

	assert_false(inv.consume_materials(recipe))
	assert_eq(inv.materials["lizard_scale"], 1, "partial recipe must not partially consume")

func test_inventory_state_round_trip() -> void:
	var inv := Inventory.new()
	inv.add_material("lizard_scale", 5)
	inv.add_consumable("trap", 2)
	inv.add_gear("rusty_greatsword", {"power": 10.0, "rarity": "Common"})

	var state := inv.to_state({})
	var restored := Inventory.from_state(state)

	assert_eq(restored.materials, inv.materials)
	assert_eq(restored.consumables, inv.consumables)
	assert_eq(restored.gear, inv.gear)

	# next gear id should continue past the restored instances, not collide.
	var g := restored.add_gear("scale_chestplate", {"defense": 5.0, "rarity": "Common"})
	assert_ne(g["id"], inv.gear[0]["id"])
