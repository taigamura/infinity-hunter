# Tests for RunState (src/systems/run_state.gd): start, hunt/XP resolution,
# banking on retreat/hunt-exhaustion, forfeiture on death, and zone unlock.
extends "res://tests/test_case.gd"

const RunState = preload("res://src/systems/run_state.gd")

var _monster_defs: Dictionary
var _slime: MonsterDef # level 1 — player can beat it
var _ember_wolf: MonsterDef # level 9 — crushes a level 1 player

func before_each() -> void:
	var result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	_monster_defs = result["defs"]
	_slime = _monster_defs["slime"]
	_ember_wolf = _monster_defs["ember_wolf"]

func test_start_sets_level_hunts_and_zone() -> void:
	var run := RunState.start("verdant_fields", "rusty_greatsword", {}, 10.0)
	assert_almost_eq(run.level, 1.0)
	assert_almost_eq(run.hunts_remaining, 10.0)
	assert_almost_eq(run.hunts_max, 10.0)
	assert_eq(run.zone_id, "verdant_fields")
	assert_eq(run.equipped_weapon_id, "rusty_greatsword")
	assert_eq(run.status, "active")
	assert_has(run.unlocked_zone_ids, "verdant_fields")

func test_winning_fight_spends_a_hunt_and_awards_xp() -> void:
	var run := RunState.start("verdant_fields", "", {}, 10.0)
	var result := run.resolve_fight(_slime)
	assert_true(result["won"])
	assert_almost_eq(run.hunts_remaining, 9.0)
	assert_almost_eq(result["xp_awarded"], _slime.xp_reward)
	assert_eq(run.status, "active")

func test_winning_fight_can_level_up() -> void:
	var run := RunState.start("verdant_fields")
	# xp_carry sits one XP short of the level-1 threshold; slime's reward
	# pushes it over into a level-up.
	run.xp_carry = XpCurve.threshold(1.0) - 1.0
	var result := run.resolve_fight(_slime)
	assert_true(result["won"])
	assert_gt(result["levels_gained"], 0)
	assert_gt(run.level, 1.0)

func test_losing_fight_kills_and_forfeits_unbanked_haul() -> void:
	var run := RunState.start("verdant_fields")
	run.resolve_fight(_slime) # banks some essence into the unbanked haul
	assert_gt(run.essence_unbanked, 0.0)
	var result := run.resolve_fight(_ember_wolf) # far above a level-1 player: a loss
	assert_false(result["won"])
	assert_true(result["died"])
	assert_eq(run.status, "dead")
	assert_eq(run.end_reason, "death")
	assert_almost_eq(run.essence_unbanked, 0.0)
	assert_almost_eq(run.essence_banked, 0.0, 0.0001, "death must forfeit, not bank")

func test_retreat_banks_unbanked_haul() -> void:
	var run := RunState.start("verdant_fields")
	run.resolve_fight(_slime)
	var unbanked_before := run.essence_unbanked
	var slime_gel_before: int = run.materials_unbanked.get("slime_gel", 0)
	run.add_material_haul("slime_gel", 2)
	run.retreat()
	assert_eq(run.status, "banked")
	assert_eq(run.end_reason, "retreat")
	assert_almost_eq(run.essence_banked, unbanked_before)
	assert_almost_eq(run.essence_unbanked, 0.0)
	assert_eq(run.materials_banked.get("slime_gel", 0), slime_gel_before + 2)
	assert_true(run.materials_unbanked.is_empty())

func test_hunt_exhaustion_auto_banks_on_last_hunt() -> void:
	var run := RunState.start("verdant_fields", "", {}, 1.0)
	var result := run.resolve_fight(_slime)
	assert_true(result["won"])
	assert_almost_eq(run.hunts_remaining, 0.0)
	assert_eq(run.status, "banked")
	assert_eq(run.end_reason, "hunt_exhaustion")
	assert_gt(run.essence_banked, 0.0)

func test_winning_fight_rolls_drops_into_unbanked_haul() -> void:
	var run := RunState.start("verdant_fields")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var result := run.resolve_fight(_slime, [], rng)
	assert_false(result["materials_dropped"].is_empty())
	var dropped_id: String = result["materials_dropped"][0]
	assert_eq(run.materials_unbanked.get(dropped_id, 0), 1)

func test_breaking_tied_part_guarantees_that_materials_drop() -> void:
	var run := RunState.start("cinder_dunes")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	# _ember_wolf's drop table guarantees ember_fang when "head" is broken;
	# beat its level-9 defense first by pre-leveling the run so it's a win.
	run.level = 20.0
	var result := run.resolve_fight(_ember_wolf, ["head"], rng)
	assert_true(result["won"])
	assert_has(result["materials_dropped"], "ember_fang")
	assert_eq(run.materials_unbanked.get("ember_fang", 0), 1)

func test_death_forfeits_materials_dropped_this_call() -> void:
	var run := RunState.start("verdant_fields")
	run.resolve_fight(_slime) # some unbanked haul exists
	var result := run.resolve_fight(_ember_wolf) # a loss at level 1
	assert_true(result["died"])
	assert_true(result["materials_dropped"].is_empty(), "no drops are rolled on a loss")
	assert_true(run.materials_unbanked.is_empty(), "death must forfeit the whole unbanked haul")

func test_resolve_fight_applies_armor_skill_profile_xp_bonus() -> void:
	var baseline := RunState.start("verdant_fields")
	baseline.resolve_fight(_slime)

	var boosted := RunState.start("verdant_fields")
	boosted.resolve_fight(_slime, [], null, {"xp_mult_bonus": 0.5})

	assert_gt(boosted.xp_carry, baseline.xp_carry, "an XP Boost skill profile should grant more effective XP")

func test_combat_outcome_win_overrides_losing_level_compare() -> void:
	var run := RunState.start("verdant_fields")
	var result := run.resolve_fight(_ember_wolf, [], null, {}, {"won": true})
	assert_true(result["won"])
	assert_false(result["died"])
	assert_eq(run.status, "active")

func test_combat_outcome_loss_overrides_winning_level_compare() -> void:
	var run := RunState.start("verdant_fields")
	var result := run.resolve_fight(_slime, [], null, {}, {"won": false})
	assert_true(result["died"])
	assert_eq(run.status, "dead")

func test_winning_fight_against_far_above_level_monster_explodes_xp() -> void:
	var run := RunState.start("verdant_fields")
	var result := run.resolve_fight(_ember_wolf, [], null, {}, {"won": true})
	assert_true(result["won"])
	assert_true(result["levels_gained"] >= 5, "an over-level gap kill should vault many levels")
	assert_gt(run.level, 1.0)
	assert_gt(result["xp_awarded"], _ember_wolf.xp_reward, "gap-scaled reward must exceed the flat base reward")
	assert_eq(result["level_before"], 1.0)
	assert_almost_eq(result["level_after"], run.level)

func test_unlock_zone_records_new_zone_and_moves_run() -> void:
	var run := RunState.start("verdant_fields")
	assert_false(run.unlocked_zone_ids.has("cinder_dunes"))
	run.unlock_zone("cinder_dunes")
	assert_has(run.unlocked_zone_ids, "cinder_dunes")
	assert_eq(run.zone_id, "cinder_dunes")
