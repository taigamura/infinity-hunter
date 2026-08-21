# Tests for SaveManager (src/systems/save_manager.gd): round-trip, atomic
# write with .bak retention, corrupt-file rollback, version migration, and
# debounced autosave coalescing.
extends "res://tests/test_case.gd"

const SaveManager = preload("res://src/systems/save_manager.gd")

const TEST_PATH := "user://test_save_manager.json"

func before_each() -> void:
	_cleanup()

func after_each() -> void:
	_cleanup()

func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var p: String = TEST_PATH + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

func _sample_state() -> Dictionary:
	var state := SaveManager.default_state()
	state["essence"] = 1234.5
	state["materials"] = {"slime_gel": 3, "wolf_fang": 1}
	state["consumables"] = {"health_potion": 2}
	state["gear"] = [{"id": "g1", "def_id": "rusty_greatsword", "rolled_stats": {"power": 12.0}}]
	state["captures"] = [{"monster_id": "slime"}]
	state["bestiary"] = {"slime": {"seen": true, "defeated": true}}
	state["unlocks"] = ["deep_caves"]
	state["upgrades"] = {"bag_size": 2}
	return state

func test_round_trip_preserves_all_fields() -> void:
	var state := _sample_state()
	assert_true(SaveManager.save_game(state, TEST_PATH))
	var loaded := SaveManager.load_game(TEST_PATH)
	assert_eq(loaded["essence"], 1234.5)
	# JSON has no separate int type; round-tripped numbers come back as floats.
	assert_eq(loaded["materials"], {"slime_gel": 3.0, "wolf_fang": 1.0})
	assert_eq(loaded["consumables"], {"health_potion": 2.0})
	assert_eq(loaded["gear"], [{"id": "g1", "def_id": "rusty_greatsword", "rolled_stats": {"power": 12.0}}])
	assert_eq(loaded["captures"], [{"monster_id": "slime"}])
	assert_eq(loaded["bestiary"], {"slime": {"seen": true, "defeated": true}})
	assert_eq(loaded["unlocks"], ["deep_caves"])
	assert_eq(loaded["upgrades"], {"bag_size": 2.0})
	assert_eq(loaded["version"], SaveManager.CURRENT_VERSION)

func test_load_missing_file_returns_default_state() -> void:
	var loaded := SaveManager.load_game(TEST_PATH)
	assert_eq(loaded, SaveManager.default_state())

func test_save_leaves_bak_of_previous_save() -> void:
	var first := _sample_state()
	first["essence"] = 1.0
	assert_true(SaveManager.save_game(first, TEST_PATH))

	var second := _sample_state()
	second["essence"] = 2.0
	assert_true(SaveManager.save_game(second, TEST_PATH))

	assert_true(FileAccess.file_exists(TEST_PATH + ".bak"))
	var bak_file := FileAccess.open(TEST_PATH + ".bak", FileAccess.READ)
	var bak_data = JSON.parse_string(bak_file.get_as_text())
	bak_file.close()
	assert_eq(bak_data["essence"], 1.0, "bak should hold the previous save, not the new one")

	var live := SaveManager.load_game(TEST_PATH)
	assert_eq(live["essence"], 2.0)

func test_no_temp_file_left_after_successful_save() -> void:
	assert_true(SaveManager.save_game(_sample_state(), TEST_PATH))
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"), "temp file must be renamed away, not left behind")

func test_corrupt_live_file_falls_back_to_bak() -> void:
	var good := _sample_state()
	good["essence"] = 42.0
	assert_true(SaveManager.save_game(good, TEST_PATH))
	# Simulate a second save so a .bak exists, then corrupt the live file
	# (as an interrupted write might leave behind).
	var updated := _sample_state()
	updated["essence"] = 99.0
	assert_true(SaveManager.save_game(updated, TEST_PATH))

	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{not valid json")
	f.close()

	var loaded := SaveManager.load_game(TEST_PATH)
	assert_eq(loaded["essence"], 42.0, "corrupt live file should roll back to .bak")

func test_migration_v1_to_current_adds_missing_fields() -> void:
	var old_blob := {
		"version": 1,
		"essence": 5.0,
		"materials": {},
		"consumables": {},
		"gear": [],
		"captures": [],
		"bestiary": {},
		"unlocks": [],
	}
	var migrated := SaveManager.migrate(old_blob)
	assert_eq(migrated["version"], SaveManager.CURRENT_VERSION)
	assert_eq(migrated["upgrades"], {}, "v1->v2 migration should backfill the new upgrades field")
	assert_eq(migrated["essence"], 5.0, "migration must not disturb existing fields")

func test_migrated_blob_round_trips_through_disk() -> void:
	var old_blob := {"version": 1, "essence": 7.0}
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(old_blob))
	f.close()

	var loaded := SaveManager.load_game(TEST_PATH)
	assert_eq(loaded["version"], SaveManager.CURRENT_VERSION)
	assert_eq(loaded["essence"], 7.0)
	assert_true(loaded.has("upgrades"))

func test_autosave_debounce_coalesces_rapid_requests() -> void:
	var mgr := SaveManager.new()
	mgr.debounce_ms = 1000

	mgr.request_autosave({"version": SaveManager.CURRENT_VERSION, "essence": 1.0}, 0)
	assert_false(mgr.is_flush_due(500), "should not flush before the debounce window elapses")
	mgr.request_autosave({"version": SaveManager.CURRENT_VERSION, "essence": 2.0}, 700) # resets the window
	assert_false(mgr.is_flush_due(1200), "a later request should push the due time back")
	assert_true(mgr.is_flush_due(1700))

	assert_true(mgr.flush(TEST_PATH, 1700))
	var loaded := SaveManager.load_game(TEST_PATH)
	assert_eq(loaded["essence"], 2.0, "only the latest coalesced state should be written")
	assert_false(mgr.has_pending_autosave())

func test_flush_before_due_does_nothing() -> void:
	var mgr := SaveManager.new()
	mgr.debounce_ms = 1000
	mgr.request_autosave({"essence": 1.0}, 0)
	assert_false(mgr.flush(TEST_PATH, 100))
	assert_false(FileAccess.file_exists(TEST_PATH))

func test_default_state_grants_starter_weapon_and_starting_zone() -> void:
	var state := SaveManager.default_state()
	assert_eq(state["gear"], [{"id": "gear_1", "def_id": "rusty_greatsword", "rolled_stats": {"rarity": "Common"}}])
	assert_eq(state["unlocked_zones"], ["verdant_fields"])

func test_migration_v2_with_empty_gear_grants_starter_weapon() -> void:
	var old_blob := {
		"version": 2,
		"essence": 5.0,
		"materials": {},
		"consumables": {},
		"gear": [],
		"captures": [],
		"bestiary": {},
		"unlocks": [],
		"upgrades": {},
	}
	var migrated := SaveManager.migrate(old_blob)
	assert_eq(migrated["version"], SaveManager.CURRENT_VERSION)
	assert_eq(migrated["gear"], [{"id": "gear_1", "def_id": "rusty_greatsword", "rolled_stats": {"rarity": "Common"}}])
	assert_true(migrated.has("unlocked_zones"))
	assert_eq(migrated["unlocked_zones"], ["verdant_fields"])

func test_migration_v2_with_existing_gear_does_not_add_starter_weapon() -> void:
	var old_blob := {
		"version": 2,
		"essence": 5.0,
		"materials": {},
		"consumables": {},
		"gear": [{"id": "gear_1", "def_id": "cinder_hammer", "rolled_stats": {"rarity": "Rare"}}],
		"captures": [],
		"bestiary": {},
		"unlocks": [],
		"upgrades": {},
	}
	var migrated := SaveManager.migrate(old_blob)
	assert_eq(migrated["version"], SaveManager.CURRENT_VERSION)
	assert_eq(migrated["gear"].size(), 1, "existing gear should not be duplicated or replaced")
	assert_eq(migrated["gear"][0]["def_id"], "cinder_hammer")
