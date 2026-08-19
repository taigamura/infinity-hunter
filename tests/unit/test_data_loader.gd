# Tests for the generic JSON content pipeline (DataLoader + typed def
# classes). Fixtures live under tests/fixtures/; real MVP content under
# data/ is exercised directly to prove the shipped JSON is itself valid.
extends "res://tests/test_case.gd"

func test_load_file_valid_material() -> void:
	var result := DataLoader.load_file("res://data/materials/slime_gel.json", MaterialDef.from_dict)
	assert_true(result["ok"], "expected valid material file to load: %s" % result.get("error", ""))
	var def: MaterialDef = result["def"]
	assert_eq(def.id, "slime_gel")
	assert_eq(def.name, "Slime Gel")
	assert_eq(def.rarity, "Common")

func test_load_file_missing_field_is_rejected() -> void:
	var path := "res://tests/fixtures/materials_missing_field/bad.json"
	var result := DataLoader.load_file(path, MaterialDef.from_dict)
	assert_false(result["ok"], "missing required field must be rejected")
	assert_true(result["error"].contains("description"), "error should name the missing field: %s" % result["error"])
	assert_true(result["error"].contains(path), "error should name the source file: %s" % result["error"])

func test_load_file_bad_type_is_rejected() -> void:
	var path := "res://tests/fixtures/materials_bad_type/bad.json"
	var result := DataLoader.load_file(path, MaterialDef.from_dict)
	assert_false(result["ok"], "wrong field type must be rejected")
	assert_true(result["error"].contains("rarity"), "error should name the mistyped field: %s" % result["error"])

func test_load_directory_duplicate_id_is_rejected() -> void:
	var result := DataLoader.load_directory("res://tests/fixtures/materials_duplicate", MaterialDef.from_dict)
	assert_false(result["ok"], "duplicate id across files must be rejected")
	assert_true(result["error"].contains("duplicate id"), "error should call out the duplicate: %s" % result["error"])

func test_load_directory_returns_all_material_defs() -> void:
	var result := DataLoader.load_directory("res://data/materials", MaterialDef.from_dict)
	assert_true(result["ok"], "expected data/materials to load cleanly: %s" % result.get("error", ""))
	var defs: Dictionary = result["defs"]
	assert_true(defs.has("slime_gel"))
	assert_true(defs.has("lizard_scale"))
	assert_true(defs.has("ember_fang"))
	assert_eq(defs.size(), 11)

func test_load_directory_monsters() -> void:
	var result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	assert_true(result["ok"], "expected data/monsters to load cleanly: %s" % result.get("error", ""))
	var defs: Dictionary = result["defs"]
	var slime: MonsterDef = defs["slime"]
	assert_eq(slime.name, "Slime")
	assert_almost_eq(slime.level, 1.0)
	assert_almost_eq(slime.base_hp, 20.0)
	assert_eq(slime.parts, ["body"])
	assert_true(slime.capturable)

func test_load_directory_zones() -> void:
	var result := DataLoader.load_directory("res://data/zones", ZoneDef.from_dict)
	assert_true(result["ok"], "expected data/zones to load cleanly: %s" % result.get("error", ""))
	var zone: ZoneDef = result["defs"]["verdant_fields"]
	assert_has(zone.monster_ids, "slime")
	assert_has(zone.monster_ids, "rock_lizard")
	assert_eq(zone.connections, ["cinder_dunes"])
	assert_eq(result["defs"].size(), 3)
	assert_true(result["defs"].has("frostpeak_ridge"))

func test_load_directory_weapons() -> void:
	var result := DataLoader.load_directory("res://data/weapons", WeaponDef.from_dict)
	assert_true(result["ok"], "expected data/weapons to load cleanly: %s" % result.get("error", ""))
	var sword: WeaponDef = result["defs"]["rusty_greatsword"]
	assert_eq(sword.weapon_class, "great_sword")
	assert_eq(sword.recipe, {"slime_gel": 3, "lizard_scale": 1})

func test_load_directory_armor() -> void:
	var result := DataLoader.load_directory("res://data/armor", ArmorDef.from_dict)
	assert_true(result["ok"], "expected data/armor to load cleanly: %s" % result.get("error", ""))
	var chest: ArmorDef = result["defs"]["scale_chestplate"]
	assert_eq(chest.slot, "chest")
	assert_eq(chest.skills, ["Attack Boost"])

func test_load_directory_companions() -> void:
	var result := DataLoader.load_directory("res://data/companions", CompanionDef.from_dict)
	assert_true(result["ok"], "expected data/companions to load cleanly: %s" % result.get("error", ""))
	var pal: CompanionDef = result["defs"]["slime_pal"]
	assert_eq(pal.source_monster_id, "slime")
	assert_almost_eq(pal.passive_value, 0.05)

func test_load_directory_tiers() -> void:
	var result := DataLoader.load_directory("res://data/tiers", TierTableDef.from_dict)
	assert_true(result["ok"], "expected data/tiers to load cleanly: %s" % result.get("error", ""))
	var table: TierTableDef = result["defs"]["verdant_fields"]
	assert_eq(table.zone_id, "verdant_fields")
	var params := table.tier_params(0)
	assert_almost_eq(params["level_min"], 1.0)
	assert_almost_eq(params["level_max"], 3.0)
	assert_almost_eq(params["gauge_rate"], 6.0)
	assert_almost_eq(params["weight"], 1.0)
	assert_true(table.tier_params(2).has("level_max"))
	assert_eq(table.tier_params(99), {})

func test_load_file_tier_entry_bad_type_is_rejected() -> void:
	var path := "res://tests/fixtures/tiers_bad_entry/bad.json"
	var result := DataLoader.load_file(path, TierTableDef.from_dict)
	assert_false(result["ok"], "malformed tier entry must be rejected")
	assert_true(result["error"].contains("gauge_rate"), "error should name the mistyped field: %s" % result["error"])

func test_load_file_not_found() -> void:
	var result := DataLoader.load_file("res://data/materials/does_not_exist.json", MaterialDef.from_dict)
	assert_false(result["ok"], "missing file must be rejected")
	assert_true(result["error"].contains("not found"), "error should say not found: %s" % result["error"])
