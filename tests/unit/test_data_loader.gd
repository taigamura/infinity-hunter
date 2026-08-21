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

# Per-zone band names + 3-stop palette (ADR-0001 slice C): each zone reads
# distinctly via its own palette + terrain band names rather than the old
# hardcoded SAFE/MID/HOT constants.
func test_every_zone_defines_a_distinct_three_stop_palette_and_band_names() -> void:
	var result := DataLoader.load_directory("res://data/zones", ZoneDef.from_dict)
	assert_true(result["ok"], result.get("error", ""))
	var defs: Dictionary = result["defs"]
	var seen_palettes: Array = []
	for zone_id in defs:
		var zone: ZoneDef = defs[zone_id]
		assert_eq(zone.palette.size(), 3, "%s palette must have exactly 3 stops" % zone_id)
		for stop in zone.palette:
			assert_true(String(stop).begins_with("#") and String(stop).length() == 7, "%s palette stop '%s' should be a #RRGGBB hex color" % [zone_id, stop])
		assert_true(zone.band_names.size() >= 1, "%s must define at least one band name" % zone_id)
		assert_false(seen_palettes.has(zone.palette), "%s palette duplicates another zone's palette" % zone_id)
		seen_palettes.append(zone.palette)
	assert_eq(defs["verdant_fields"].band_names, ["Meadow", "Thicket", "Bramble", "Thornwall"])

func test_zone_bad_palette_is_rejected() -> void:
	var path := "res://tests/fixtures/zones_bad_palette/bad.json"
	var result := DataLoader.load_file(path, ZoneDef.from_dict)
	assert_false(result["ok"], "non-hex palette entry must be rejected")
	assert_true(result["error"].contains("palette"), "error should name the palette field: %s" % result["error"])

func test_zone_empty_band_names_is_rejected() -> void:
	var path := "res://tests/fixtures/zones_bad_band_names/bad.json"
	var result := DataLoader.load_file(path, ZoneDef.from_dict)
	assert_false(result["ok"], "empty band_names must be rejected")
	assert_true(result["error"].contains("band_names"), "error should name the band_names field: %s" % result["error"])

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

# All three zones now have tier tables (ADR-0001 slice C: Cinder Dunes and
# Frostpeak Ridge previously fell back to a single flat tier). Each zone's
# tier level bands must sit inside that zone's min_level..max_level, and
# gauge_rate should escalate deeper into the zone to reinforce mounting
# pressure toward the far/hot edge.
func test_all_three_zones_have_a_tier_table() -> void:
	var result := DataLoader.load_directory("res://data/tiers", TierTableDef.from_dict)
	assert_true(result["ok"], result.get("error", ""))
	assert_eq(result["defs"].size(), 3)
	for zone_id in ["verdant_fields", "cinder_dunes", "frostpeak_ridge"]:
		assert_true(result["defs"].has(zone_id), "expected a tier table for %s" % zone_id)

func test_tier_level_bands_fall_within_each_zones_level_range() -> void:
	var tier_result := DataLoader.load_directory("res://data/tiers", TierTableDef.from_dict)
	var zone_result := DataLoader.load_directory("res://data/zones", ZoneDef.from_dict)
	assert_true(tier_result["ok"], tier_result.get("error", ""))
	assert_true(zone_result["ok"], zone_result.get("error", ""))
	for zone_id in tier_result["defs"]:
		var table: TierTableDef = tier_result["defs"][zone_id]
		var zone: ZoneDef = zone_result["defs"][zone_id]
		for tier_id in table.tiers:
			var params := table.tier_params(tier_id)
			assert_true(params["level_min"] >= zone.min_level, "%s tier %s level_min below zone min_level" % [zone_id, tier_id])
			assert_true(params["level_max"] <= zone.max_level, "%s tier %s level_max above zone max_level" % [zone_id, tier_id])

func test_gauge_rate_escalates_deeper_into_each_zone() -> void:
	var result := DataLoader.load_directory("res://data/tiers", TierTableDef.from_dict)
	assert_true(result["ok"], result.get("error", ""))
	for zone_id in result["defs"]:
		var table: TierTableDef = result["defs"][zone_id]
		var tier_ids: Array = table.tiers.keys().map(func(k): return int(k))
		tier_ids.sort()
		var prev_rate := -INF
		for tier_id in tier_ids:
			var rate: float = table.tier_params(tier_id)["gauge_rate"]
			assert_true(rate > prev_rate, "%s tier %s gauge_rate should exceed the shallower tier" % [zone_id, tier_id])
			prev_rate = rate

func test_deeper_zones_fill_the_gauge_faster_than_verdant_fields() -> void:
	var result := DataLoader.load_directory("res://data/tiers", TierTableDef.from_dict)
	var verdant_max: float = result["defs"]["verdant_fields"].tier_params(2)["gauge_rate"]
	var cinder_max: float = result["defs"]["cinder_dunes"].tier_params(2)["gauge_rate"]
	var frostpeak_max: float = result["defs"]["frostpeak_ridge"].tier_params(2)["gauge_rate"]
	assert_true(cinder_max > verdant_max, "Cinder Dunes hottest gauge_rate should exceed Verdant Fields'")
	assert_true(frostpeak_max > cinder_max, "Frostpeak Ridge hottest gauge_rate should exceed Cinder Dunes'")

func test_load_file_tier_entry_bad_type_is_rejected() -> void:
	var path := "res://tests/fixtures/tiers_bad_entry/bad.json"
	var result := DataLoader.load_file(path, TierTableDef.from_dict)
	assert_false(result["ok"], "malformed tier entry must be rejected")
	assert_true(result["error"].contains("gauge_rate"), "error should name the mistyped field: %s" % result["error"])

func test_load_file_not_found() -> void:
	var result := DataLoader.load_file("res://data/materials/does_not_exist.json", MaterialDef.from_dict)
	assert_false(result["ok"], "missing file must be rejected")
	assert_true(result["error"].contains("not found"), "error should say not found: %s" % result["error"])
