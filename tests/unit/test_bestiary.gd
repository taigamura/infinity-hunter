# Tests for Bestiary (src/systems/bestiary.gd): seen/kill/capture counters,
# discovered-drops/broken-parts recording, element/weakness capture, and
# round-trip persistence through a SaveManager-shaped state Dictionary.
extends "res://tests/test_case.gd"

const Bestiary = preload("res://src/systems/bestiary.gd")
const SaveManager = preload("res://src/systems/save_manager.gd")
const MonsterDef = preload("res://src/models/monster_def.gd")

func _monster(id: String = "slime", element: String = "water") -> MonsterDef:
	var m := MonsterDef.new()
	m.id = id
	m.name = "Slime"
	m.level = 1.0
	m.element = element
	m.base_hp = 20.0
	m.base_attack = 2.0
	m.xp_reward = 10.0
	m.zone_id = "verdant_fields"
	m.parts = ["body"]
	return m

func test_unrecorded_monster_defaults_to_undiscovered() -> void:
	var state := {}
	var entry := Bestiary.get_entry(state, "slime")
	assert_false(entry["seen"])
	assert_eq(entry["kills"], 0)
	assert_eq(entry["captures"], 0)
	assert_eq(entry["discovered_drops"], [])
	assert_false(state.has("bestiary"), "read-only lookup must not create a bestiary entry")

func test_record_encounter_marks_seen_and_captures_element_weakness() -> void:
	var state := {}
	Bestiary.record_encounter(state, _monster("slime", "water"))
	var entry := Bestiary.get_entry(state, "slime")
	assert_true(entry["seen"])
	assert_eq(entry["element"], "water")
	assert_eq(entry["weakness"], "fire")
	assert_eq(entry["kills"], 0)

func test_record_kill_increments_counter_and_marks_defeated() -> void:
	var state := {}
	var monster := _monster()
	Bestiary.record_kill(state, monster)
	Bestiary.record_kill(state, monster)
	var entry := Bestiary.get_entry(state, "slime")
	assert_eq(entry["kills"], 2)
	assert_true(entry["defeated"])
	assert_true(entry["seen"])

func test_record_capture_increments_counter_independent_of_kills() -> void:
	var state := {}
	var monster := _monster()
	Bestiary.record_kill(state, monster)
	Bestiary.record_capture(state, monster)
	var entry := Bestiary.get_entry(state, "slime")
	assert_eq(entry["kills"], 1)
	assert_eq(entry["captures"], 1)

func test_record_drops_dedupes_discovered_materials() -> void:
	var state := {}
	Bestiary.record_drops(state, "slime", ["slime_gel", "slime_core"])
	Bestiary.record_drops(state, "slime", ["slime_gel", "rare_dust"])
	var entry := Bestiary.get_entry(state, "slime")
	assert_eq(entry["discovered_drops"], ["slime_gel", "slime_core", "rare_dust"])

func test_record_broken_parts_dedupes() -> void:
	var state := {}
	Bestiary.record_broken_parts(state, "slime", ["body"])
	Bestiary.record_broken_parts(state, "slime", ["body", "tail"])
	var entry := Bestiary.get_entry(state, "slime")
	assert_eq(entry["broken_parts"], ["body", "tail"])

func test_persists_through_save_manager_round_trip() -> void:
	var state := SaveManager.default_state()
	var monster := _monster()
	Bestiary.record_kill(state, monster)
	Bestiary.record_drops(state, "slime", ["slime_gel"])
	Bestiary.record_broken_parts(state, "slime", ["body"])

	var path := "user://test_bestiary_save.json"
	assert_true(SaveManager.save_game(state, path))
	var loaded := SaveManager.load_game(path)

	var entry := Bestiary.get_entry(loaded, "slime")
	assert_eq(entry["kills"], 1)
	assert_eq(entry["discovered_drops"], ["slime_gel"])
	assert_eq(entry["broken_parts"], ["body"])
	assert_eq(entry["element"], "water")
	assert_eq(entry["weakness"], "fire")

	for suffix in ["", ".bak", ".tmp"]:
		var p: String = path + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
