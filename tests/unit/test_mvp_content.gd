# Tests for the MVP content set (issue #15): 3 zones, 8-12 monsters, all 3
# weapon classes, and craftable armor/weapons, loaded from the real data/
# directories (not fixtures) so a broken JSON file fails the gate directly.
extends "res://tests/test_case.gd"

const CraftingSystem = preload("res://src/systems/crafting_system.gd")
const Inventory = preload("res://src/systems/inventory.gd")

func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func test_three_zones_load_and_connect() -> void:
	var result := DataLoader.load_directory("res://data/zones", ZoneDef.from_dict)
	assert_true(result["ok"], result.get("error", ""))
	var zones: Dictionary = result["defs"]
	assert_eq(zones.size(), 3)
	assert_has(zones["verdant_fields"].connections, "cinder_dunes")
	assert_has(zones["cinder_dunes"].connections, "frostpeak_ridge")
	assert_true(zones["frostpeak_ridge"].connections.is_empty())

func test_monster_count_in_mvp_range() -> void:
	var result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	assert_true(result["ok"], result.get("error", ""))
	var monsters: Dictionary = result["defs"]
	assert_gt(monsters.size(), 7, "expected at least 8 monsters")
	assert_lt(monsters.size(), 13, "expected at most 12 monsters")

func test_aspirational_marker_monster_present() -> void:
	var result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	var monster: MonsterDef = result["defs"]["voidmaw_devourer"]
	assert_gt(monster.level, 1000000000.0)
	assert_eq(monster.zone_id, "verdant_fields")

func test_every_zones_monster_ids_resolve_to_a_loaded_monster() -> void:
	var zone_result := DataLoader.load_directory("res://data/zones", ZoneDef.from_dict)
	var monster_result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	var monsters: Dictionary = monster_result["defs"]
	for zone_id in zone_result["defs"]:
		var zone: ZoneDef = zone_result["defs"][zone_id]
		for monster_id in zone.monster_ids:
			assert_true(monsters.has(monster_id), "%s references unknown monster %s" % [zone_id, monster_id])

func test_all_three_weapon_classes_present() -> void:
	var result := DataLoader.load_directory("res://data/weapons", WeaponDef.from_dict)
	assert_true(result["ok"], result.get("error", ""))
	var classes := {}
	for id in result["defs"]:
		classes[result["defs"][id].weapon_class] = true
	assert_true(classes.has("great_sword"))
	assert_true(classes.has("dual_blades"))
	assert_true(classes.has("hammer"))

func test_armor_count_around_fifteen() -> void:
	var result := DataLoader.load_directory("res://data/armor", ArmorDef.from_dict)
	assert_true(result["ok"], result.get("error", ""))
	assert_eq(result["defs"].size(), 15)

func test_every_recipe_material_id_resolves_to_a_loaded_material() -> void:
	var material_result := DataLoader.load_directory("res://data/materials", MaterialDef.from_dict)
	var materials: Dictionary = material_result["defs"]

	var weapon_result := DataLoader.load_directory("res://data/weapons", WeaponDef.from_dict)
	for id in weapon_result["defs"]:
		var weapon: WeaponDef = weapon_result["defs"][id]
		for material_id in weapon.recipe:
			assert_true(materials.has(material_id), "weapon %s recipe references unknown material %s" % [id, material_id])

	var armor_result := DataLoader.load_directory("res://data/armor", ArmorDef.from_dict)
	for id in armor_result["defs"]:
		var armor: ArmorDef = armor_result["defs"][id]
		for material_id in armor.recipe:
			assert_true(materials.has(material_id), "armor %s recipe references unknown material %s" % [id, material_id])

func test_craft_new_hammer_weapon_from_real_recipe() -> void:
	var result := DataLoader.load_directory("res://data/weapons", WeaponDef.from_dict)
	var hammer: WeaponDef = result["defs"]["boulder_hammer"]

	var inv := Inventory.new()
	for material_id in hammer.recipe:
		inv.add_material(material_id, hammer.recipe[material_id])

	var craft_result := CraftingSystem.craft(hammer, inv, _rng(7))
	assert_true(craft_result["ok"], craft_result.get("error", ""))
	assert_eq(craft_result["gear"]["def_id"], "boulder_hammer")
	assert_true(craft_result["gear"]["rolled_stats"].has("power"))

func test_craft_new_tier_armor_from_real_recipe() -> void:
	var result := DataLoader.load_directory("res://data/armor", ArmorDef.from_dict)
	var glacier_helm: ArmorDef = result["defs"]["glacier_helm"]

	var inv := Inventory.new()
	for material_id in glacier_helm.recipe:
		inv.add_material(material_id, glacier_helm.recipe[material_id])

	var craft_result := CraftingSystem.craft(glacier_helm, inv, _rng(3))
	assert_true(craft_result["ok"], craft_result.get("error", ""))
	assert_true(craft_result["gear"]["rolled_stats"].has("defense"))
